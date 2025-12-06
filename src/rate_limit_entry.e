note
	description: "Internal rate limit entry for tracking request state"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	RATE_LIMIT_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_tokens: REAL; a_start: DATE_TIME)
			-- Create entry with `a_tokens` starting at `a_start`.
		require
			start_not_void: a_start /= Void
		do
			tokens := a_tokens
			window_start := a_start.twin
			last_refill := a_start.twin
			request_count := 0
		ensure
			tokens_set: tokens = a_tokens
			window_start_set: window_start /= Void
			last_refill_set: last_refill /= Void
		end

feature -- Access

	tokens: REAL
			-- Current token count (for token bucket).

	window_start: DATE_TIME
			-- When current window started.

	last_refill: DATE_TIME
			-- When tokens were last refilled.

	request_count: INTEGER
			-- Request count in current window (for sliding window).

feature -- Modification

	set_tokens (a_tokens: REAL)
			-- Set token count.
		do
			tokens := a_tokens
		ensure
			tokens_set: tokens = a_tokens
		end

	set_window_start (a_time: DATE_TIME)
			-- Set window start time.
		require
			time_not_void: a_time /= Void
		do
			window_start := a_time.twin
		ensure
			window_start_set: window_start.is_equal (a_time)
		end

	set_last_refill (a_time: DATE_TIME)
			-- Set last refill time.
		require
			time_not_void: a_time /= Void
		do
			last_refill := a_time.twin
		ensure
			last_refill_set: last_refill.is_equal (a_time)
		end

	set_request_count (a_count: INTEGER)
			-- Set request count.
		require
			non_negative: a_count >= 0
		do
			request_count := a_count
		ensure
			count_set: request_count = a_count
		end

invariant
	window_start_attached: window_start /= Void
	last_refill_attached: last_refill /= Void
	non_negative_count: request_count >= 0

end
