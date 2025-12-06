note
	description: "Result of a rate limit check"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	RATE_LIMIT_RESULT

create
	make

feature {NONE} -- Initialization

	make (a_allowed: BOOLEAN; a_remaining: INTEGER; a_reset_time: DATE_TIME; a_retry_after: INTEGER)
			-- Create result.
		require
			reset_time_not_void: a_reset_time /= Void
			non_negative_remaining: a_remaining >= 0
			non_negative_retry: a_retry_after >= 0
		do
			is_allowed := a_allowed
			remaining := a_remaining
			reset_time := a_reset_time.twin
			retry_after := a_retry_after
		ensure
			allowed_set: is_allowed = a_allowed
			remaining_set: remaining = a_remaining
			reset_time_set: reset_time /= Void
			retry_after_set: retry_after = a_retry_after
		end

feature -- Access

	is_allowed: BOOLEAN
			-- Is the request allowed?

	remaining: INTEGER
			-- Remaining requests in current window.

	reset_time: DATE_TIME
			-- When the rate limit will reset.

	retry_after: INTEGER
			-- Seconds until next request allowed (if denied).

invariant
	reset_time_attached: reset_time /= Void
	non_negative_remaining: remaining >= 0
	non_negative_retry: retry_after >= 0

end
