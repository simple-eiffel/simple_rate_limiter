note
	description: "Three-tier fixture hierarchy for simple_rate_limiter tests"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	LIMITER_FIXTURES

inherit
	TEST_SET_BASE

feature -- Tier 1: Default Limiters

	default_limiter: SIMPLE_RATE_LIMITER
			-- Default rate limiter (100/60s token bucket)
		once
			create Result.make
		ensure
			limiter_created: Result /= Void
			default_limit: Result.limit = 100
			default_window: Result.window_seconds = 60
		end

	custom_limiter: SIMPLE_RATE_LIMITER
			-- Custom limiter (50 tokens / 30 seconds)
		once
			create Result.make_with_limit (50, 30)
		ensure
			limiter_created: Result /= Void
			custom_limit: Result.limit = 50
			custom_window: Result.window_seconds = 30
		end

feature -- Tier 2: Specialized Limiters

	sliding_window_limiter: SIMPLE_RATE_LIMITER
			-- Sliding window algorithm (200/120s)
		once
			create Result.make_sliding_window (200, 120)
		ensure
			limiter_created: Result /= Void
			algorithm_sliding: Result.algorithm.same_string ("sliding_window")
		end

	exhausted_limiter: SIMPLE_RATE_LIMITER
			-- Limiter with all tokens consumed
		local
			l_result: RATE_LIMIT_RESULT
			i: INTEGER
		once
			create Result.make_with_limit (3, 60)
			from i := 1 until i > 3 loop
				l_result := Result.check_limit ("test_user")
				i := i + 1
			end
		ensure
			limiter_created: Result /= Void
			tokens_exhausted: not (Result.check_limit ("test_user")).is_allowed
		end

feature -- Tier 3: Configured Limiters

	whitelisted_limiter: SIMPLE_RATE_LIMITER
			-- Limiter with VIP user whitelisted
		once
			create Result.make_with_limit (1, 60)
			Result.add_whitelist ("vip")
		ensure
			limiter_created: Result /= Void
			has_whitelist: Result.is_whitelisted ("vip")
		end

	blacklisted_limiter: SIMPLE_RATE_LIMITER
			-- Limiter with banned user blacklisted
		once
			create Result.make
			Result.add_blacklist ("banned")
		ensure
			limiter_created: Result /= Void
			has_blacklist: Result.is_blacklisted ("banned")
		end

	burst_limiter: SIMPLE_RATE_LIMITER
			-- Limiter with burst capacity configured
		once
			create Result.make
			Result.set_burst_limit (200)
		ensure
			limiter_created: Result /= Void
			burst_set: Result.burst_limit = 200
		end

end
