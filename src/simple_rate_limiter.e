note
	description: "Rate limiter using token bucket algorithm"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	EIS: "name=RFC 6585", "protocol=URI", "src=https://tools.ietf.org/html/rfc6585"

class
	SIMPLE_RATE_LIMITER

create
	make,
	make_with_limit,
	make_sliding_window

feature {NONE} -- Initialization

	make
			-- Create with default limit: 100 requests per minute.
		do
			create entries.make (100)
			create whitelist.make (10)
			create blacklist.make (10)
			limit := Default_limit
			window_seconds := Default_window
			algorithm := Algorithm_token_bucket
			burst_limit := limit
		ensure
			default_limit: limit = Default_limit
			default_window: window_seconds = Default_window
		end

	make_with_limit (a_limit: INTEGER; a_window_seconds: INTEGER)
			-- Create with custom `a_limit` requests per `a_window_seconds`.
		require
			positive_limit: a_limit > 0
			positive_window: a_window_seconds > 0
		do
			make
			limit := a_limit
			window_seconds := a_window_seconds
			burst_limit := a_limit
		ensure
			limit_set: limit = a_limit
			window_set: window_seconds = a_window_seconds
		end

	make_sliding_window (a_limit: INTEGER; a_window_seconds: INTEGER)
			-- Create using sliding window counter algorithm.
		require
			positive_limit: a_limit > 0
			positive_window: a_window_seconds > 0
		do
			make_with_limit (a_limit, a_window_seconds)
			algorithm := Algorithm_sliding_window
		ensure
			limit_set: limit = a_limit
			window_set: window_seconds = a_window_seconds
			sliding_algorithm: algorithm.same_string (Algorithm_sliding_window)
		end

feature -- Configuration

	set_limit (a_requests: INTEGER; a_window_seconds: INTEGER)
			-- Set rate limit to `a_requests` per `a_window_seconds`.
		require
			positive_requests: a_requests > 0
			positive_window: a_window_seconds > 0
		do
			limit := a_requests
			window_seconds := a_window_seconds
			if burst_limit < limit then
				burst_limit := limit
			end
		ensure
			limit_set: limit = a_requests
			window_set: window_seconds = a_window_seconds
		end

	set_burst_limit (a_max_burst: INTEGER)
			-- Set maximum burst size for token bucket.
		require
			positive_burst: a_max_burst > 0
		do
			burst_limit := a_max_burst
		ensure
			burst_set: burst_limit = a_max_burst
		end

feature -- Whitelist/Blacklist

	add_whitelist (a_key: STRING)
			-- Add `a_key` to whitelist (always allowed).
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			if not list_has_string (whitelist, a_key) then
				whitelist.extend (a_key)
			end
		ensure
			whitelisted: is_whitelisted (a_key)
		end

	add_blacklist (a_key: STRING)
			-- Add `a_key` to blacklist (always denied).
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			if not list_has_string (blacklist, a_key) then
				blacklist.extend (a_key)
			end
		ensure
			blacklisted: is_blacklisted (a_key)
		end

	remove_whitelist (a_key: STRING)
			-- Remove `a_key` from whitelist.
		require
			key_not_void: a_key /= Void
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > whitelist.count
			loop
				if whitelist [i].same_string (a_key) then
					whitelist.go_i_th (i)
					whitelist.remove
				else
					i := i + 1
				end
			variant
				whitelist.count - i + 2
			end
		ensure
			not_whitelisted: not is_whitelisted (a_key)
		end

	remove_blacklist (a_key: STRING)
			-- Remove `a_key` from blacklist.
		require
			key_not_void: a_key /= Void
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > blacklist.count
			loop
				if blacklist [i].same_string (a_key) then
					blacklist.go_i_th (i)
					blacklist.remove
				else
					i := i + 1
				end
			variant
				blacklist.count - i + 2
			end
		ensure
			not_blacklisted: not is_blacklisted (a_key)
		end

feature -- Rate Limiting

	check_limit (a_key: STRING): RATE_LIMIT_RESULT
			-- Check rate limit for `a_key` and return result.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		local
			l_entry: detachable RATE_LIMIT_ENTRY
			l_allowed: BOOLEAN
			l_remaining: INTEGER
			l_reset_time: SIMPLE_DATE_TIME
			l_retry_after: INTEGER
		do
			-- Handle whitelist/blacklist
			if is_whitelisted (a_key) then
				create l_reset_time.make_now
				create Result.make (True, limit, l_reset_time, 0)
			elseif is_blacklisted (a_key) then
				create l_reset_time.make_now
				l_reset_time := l_reset_time.plus_seconds (window_seconds)
				create Result.make (False, 0, l_reset_time, window_seconds)
			else
				l_entry := get_or_create_entry (a_key)
				check attached l_entry as le then
					if algorithm.same_string (Algorithm_token_bucket) then
						Result := check_token_bucket (le)
					else
						Result := check_sliding_window (le)
					end
				end
			end
		ensure
			result_attached: Result /= Void
		end

	is_allowed (a_key: STRING): BOOLEAN
			-- Is `a_key` allowed to make a request?
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		do
			Result := check_limit (a_key).is_allowed
		end

	consume (a_key: STRING; a_tokens: INTEGER): BOOLEAN
			-- Consume `a_tokens` for `a_key`. Returns True if allowed.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
			positive_tokens: a_tokens > 0
		local
			l_entry: detachable RATE_LIMIT_ENTRY
			i: INTEGER
		do
			if is_whitelisted (a_key) then
				Result := True
			elseif is_blacklisted (a_key) then
				Result := False
			else
				l_entry := get_or_create_entry (a_key)
				check attached l_entry as le then
					-- Refill tokens first
					refill_tokens (le)
					if le.tokens >= a_tokens then
						le.set_tokens (le.tokens - a_tokens)
						Result := True
					end
				end
			end
		end

	remaining (a_key: STRING): INTEGER
			-- Number of remaining requests for `a_key`.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		local
			l_entry: detachable RATE_LIMIT_ENTRY
		do
			if is_whitelisted (a_key) then
				Result := limit
			elseif is_blacklisted (a_key) then
				Result := 0
			else
				l_entry := entries.item (a_key)
				if attached l_entry as le then
					refill_tokens (le)
					Result := le.tokens.floor.max (0)
				else
					Result := limit
				end
			end
		end

	reset_time (a_key: STRING): SIMPLE_DATE_TIME
			-- When will limits reset for `a_key`?
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		local
			l_entry: detachable RATE_LIMIT_ENTRY
		do
			l_entry := entries.item (a_key)
			if attached l_entry as le then
				Result := le.window_start.twin
				Result := Result.plus_seconds (window_seconds)
			else
				create Result.make_now
				Result := Result.plus_seconds (window_seconds)
			end
		end

	reset (a_key: STRING)
			-- Reset rate limit state for `a_key`.
		require
			key_not_void: a_key /= Void
		do
			entries.remove (a_key)
		ensure
			removed: not entries.has (a_key)
		end

	reset_all
			-- Reset all rate limit state.
		do
			entries.wipe_out
		ensure
			empty: entries.is_empty
		end

feature -- Response Headers (draft-ietf-httpapi-ratelimit-headers)

	rate_limit_headers (a_key: STRING): HASH_TABLE [STRING, STRING]
			-- Generate RateLimit-* headers for `a_key`.
		require
			key_not_void: a_key /= Void
			key_not_empty: not a_key.is_empty
		local
			l_result: RATE_LIMIT_RESULT
			l_reset_seconds: INTEGER
			l_now: SIMPLE_DATE_TIME
		do
			create Result.make (4)
			l_result := check_limit (a_key)

			-- RateLimit-Limit: maximum requests per window
			Result.put (limit.out, "RateLimit-Limit")

			-- RateLimit-Remaining: requests remaining
			Result.put (l_result.remaining.max (0).out, "RateLimit-Remaining")

			-- RateLimit-Reset: seconds until reset
			create l_now.make_now
			l_reset_seconds := seconds_between (l_now, l_result.reset_time).max (0)
			Result.put (l_reset_seconds.out, "RateLimit-Reset")

			-- Retry-After (only if rate limited)
			if not l_result.is_allowed then
				Result.put (l_result.retry_after.out, "Retry-After")
			end
		ensure
			has_limit: Result.has ("RateLimit-Limit")
			has_remaining: Result.has ("RateLimit-Remaining")
			has_reset: Result.has ("RateLimit-Reset")
		end

feature -- Query

	limit: INTEGER
			-- Maximum requests per window.

	window_seconds: INTEGER
			-- Window duration in seconds.

	burst_limit: INTEGER
			-- Maximum burst size (token bucket).

	algorithm: STRING
			-- Algorithm in use.

	is_whitelisted (a_key: STRING): BOOLEAN
			-- Is `a_key` in the whitelist?
		require
			key_not_void: a_key /= Void
		do
			Result := list_has_string (whitelist, a_key)
		end

	is_blacklisted (a_key: STRING): BOOLEAN
			-- Is `a_key` in the blacklist?
		require
			key_not_void: a_key /= Void
		do
			Result := list_has_string (blacklist, a_key)
		end

feature -- Constants

	Default_limit: INTEGER = 100
			-- Default: 100 requests.

	Default_window: INTEGER = 60
			-- Default: per minute (60 seconds).

	Algorithm_token_bucket: STRING = "token_bucket"
	Algorithm_sliding_window: STRING = "sliding_window"

feature {NONE} -- Implementation

	entries: HASH_TABLE [RATE_LIMIT_ENTRY, STRING]
			-- Rate limit entries by key.

	whitelist: ARRAYED_LIST [STRING]
			-- Keys that bypass rate limiting.

	blacklist: ARRAYED_LIST [STRING]
			-- Keys that are always denied.

	get_or_create_entry (a_key: STRING): RATE_LIMIT_ENTRY
			-- Get existing entry or create new one.
		require
			key_not_void: a_key /= Void
		local
			l_now: SIMPLE_DATE_TIME
		do
			if attached entries.item (a_key) as l_entry then
				Result := l_entry
			else
				create l_now.make_now
				create Result.make (burst_limit.to_real, l_now)
				entries.put (Result, a_key)
			end
		ensure
			result_attached: Result /= Void
			entry_exists: entries.has (a_key)
		end

	check_token_bucket (a_entry: RATE_LIMIT_ENTRY): RATE_LIMIT_RESULT
			-- Check rate limit using token bucket algorithm.
		require
			entry_not_void: a_entry /= Void
		local
			l_allowed: BOOLEAN
			l_remaining: INTEGER
			l_reset_time: SIMPLE_DATE_TIME
			l_retry_after: INTEGER
		do
			-- Refill tokens based on elapsed time
			refill_tokens (a_entry)

			-- Check if we have at least 1 token
			if a_entry.tokens >= 1.0 then
				a_entry.set_tokens (a_entry.tokens - 1.0)
				l_allowed := True
				l_remaining := a_entry.tokens.floor
			else
				l_allowed := False
				l_remaining := 0
				-- Calculate when next token will be available
				l_retry_after := ((1.0 - a_entry.tokens) / tokens_per_second).ceiling
			end

			l_reset_time := a_entry.window_start.twin
			l_reset_time := l_reset_time.plus_seconds (window_seconds)

			create Result.make (l_allowed, l_remaining, l_reset_time, l_retry_after)
		end

	check_sliding_window (a_entry: RATE_LIMIT_ENTRY): RATE_LIMIT_RESULT
			-- Check rate limit using sliding window counter algorithm.
		require
			entry_not_void: a_entry /= Void
		local
			l_now: SIMPLE_DATE_TIME
			l_elapsed: INTEGER
			l_allowed: BOOLEAN
			l_remaining: INTEGER
			l_reset_time: SIMPLE_DATE_TIME
			l_retry_after: INTEGER
			l_count: INTEGER
		do
			create l_now.make_now
			l_elapsed := seconds_between (a_entry.window_start, l_now)

			-- Check if we're in a new window
			if l_elapsed >= window_seconds then
				-- Reset window
				a_entry.set_window_start (l_now)
				a_entry.set_request_count (1)
				l_allowed := True
				l_remaining := limit - 1
			else
				l_count := a_entry.request_count
				if l_count < limit then
					a_entry.set_request_count (l_count + 1)
					l_allowed := True
					l_remaining := limit - l_count - 1
				else
					l_allowed := False
					l_remaining := 0
					l_retry_after := window_seconds - l_elapsed
				end
			end

			l_reset_time := a_entry.window_start.twin
			l_reset_time := l_reset_time.plus_seconds (window_seconds)

			create Result.make (l_allowed, l_remaining, l_reset_time, l_retry_after)
		end

	refill_tokens (a_entry: RATE_LIMIT_ENTRY)
			-- Refill tokens based on elapsed time.
		require
			entry_not_void: a_entry /= Void
		local
			l_now: SIMPLE_DATE_TIME
			l_elapsed: INTEGER
			l_new_tokens: REAL
		do
			create l_now.make_now
			l_elapsed := seconds_between (a_entry.last_refill, l_now)

			if l_elapsed > 0 then
				l_new_tokens := l_elapsed.to_real * tokens_per_second
				a_entry.set_tokens ((a_entry.tokens + l_new_tokens).min (burst_limit.to_real))
				a_entry.set_last_refill (l_now)
			end
		end

	tokens_per_second: REAL
			-- Token refill rate per second.
		do
			Result := limit.to_real / window_seconds.to_real
		ensure
			positive: Result > 0
		end

	seconds_between (a_start, a_end: SIMPLE_DATE_TIME): INTEGER
			-- Seconds between two times.
		require
			start_not_void: a_start /= Void
			end_not_void: a_end /= Void
		do
			Result := (a_end.to_timestamp - a_start.to_timestamp).as_integer_32
		end

	list_has_string (a_list: ARRAYED_LIST [STRING]; a_string: STRING): BOOLEAN
			-- Does `a_list` contain a string equal to `a_string`?
		require
			list_not_void: a_list /= Void
			string_not_void: a_string /= Void
		do
			across a_list as item loop
				if item.same_string (a_string) then
					Result := True
				end
			end
		end

invariant
	entries_attached: entries /= Void
	whitelist_attached: whitelist /= Void
	blacklist_attached: blacklist /= Void
	positive_limit: limit > 0
	positive_window: window_seconds > 0
	positive_burst: burst_limit > 0

end
