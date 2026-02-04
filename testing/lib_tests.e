note
	description: "Tests for SIMPLE_RATE_LIMITER"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature {NONE} -- Fixtures

	fixtures: LIMITER_FIXTURES
		once
			create Result
		end

feature -- Test: Initialization

	test_make_default
			-- Test default initialization.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.make"
		do
			assert_integers_equal ("default limit", 100, fixtures.default_limiter.limit)
			assert_integers_equal ("default window", 60, fixtures.default_limiter.window_seconds)
			assert_true ("default algorithm", fixtures.default_limiter.algorithm.same_string ("token_bucket"))
		end

	test_make_with_limit
			-- Test custom limit initialization.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.make_with_limit"
		do
			assert_integers_equal ("custom limit", 50, fixtures.custom_limiter.limit)
			assert_integers_equal ("custom window", 30, fixtures.custom_limiter.window_seconds)
		end

	test_make_sliding_window
			-- Test sliding window initialization.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.make_sliding_window"
		do
			assert_integers_equal ("limit", 200, fixtures.sliding_window_limiter.limit)
			assert_integers_equal ("window", 120, fixtures.sliding_window_limiter.window_seconds)
			assert_true ("algorithm", fixtures.sliding_window_limiter.algorithm.same_string ("sliding_window"))
		end

feature -- Test: Configuration

	test_set_limit
			-- Test setting limit.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.set_limit"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.set_limit (500, 300)
			assert_integers_equal ("new limit", 500, limiter.limit)
			assert_integers_equal ("new window", 300, limiter.window_seconds)
		end

	test_set_burst_limit
			-- Test setting burst limit.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.set_burst_limit"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.set_burst_limit (200)
			assert_integers_equal ("burst limit", 200, limiter.burst_limit)
		end

feature -- Test: Whitelist/Blacklist

	test_add_whitelist
			-- Test adding to whitelist.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.add_whitelist"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.add_whitelist ("admin")
			assert_true ("is whitelisted", limiter.is_whitelisted ("admin"))
		end

	test_add_blacklist
			-- Test adding to blacklist.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.add_blacklist"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.add_blacklist ("spammer")
			assert_true ("is blacklisted", limiter.is_blacklisted ("spammer"))
		end

	test_remove_whitelist
			-- Test removing from whitelist.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.remove_whitelist"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.add_whitelist ("temp")
			assert_true ("added", limiter.is_whitelisted ("temp"))
			limiter.remove_whitelist ("temp")
			assert_false ("removed", limiter.is_whitelisted ("temp"))
		end

	test_remove_blacklist
			-- Test removing from blacklist.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.remove_blacklist"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make
			limiter.add_blacklist ("temp")
			assert_true ("added", limiter.is_blacklisted ("temp"))
			limiter.remove_blacklist ("temp")
			assert_false ("removed", limiter.is_blacklisted ("temp"))
		end

	test_whitelist_bypasses_limit
			-- Test that whitelisted keys bypass limit.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.check_limit"
		local
			l_result: RATE_LIMIT_RESULT
		do
			l_result := fixtures.whitelisted_limiter.check_limit ("vip")
			assert_true ("first allowed", l_result.is_allowed)
			l_result := fixtures.whitelisted_limiter.check_limit ("vip")
			assert_true ("second allowed", l_result.is_allowed)
			l_result := fixtures.whitelisted_limiter.check_limit ("vip")
			assert_true ("third allowed", l_result.is_allowed)
		end

	test_blacklist_always_denied
			-- Test that blacklisted keys are always denied.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.check_limit"
		local
			l_result: RATE_LIMIT_RESULT
		do
			l_result := fixtures.blacklisted_limiter.check_limit ("banned")
			assert_false ("denied", l_result.is_allowed)
			assert_integers_equal ("no remaining", 0, l_result.remaining)
		end

feature -- Test: Rate Limiting - Token Bucket

	test_initial_request_allowed
			-- Test that first request is allowed.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.check_limit"
		local
			l_result: RATE_LIMIT_RESULT
		do
			l_result := fixtures.default_limiter.check_limit ("user1")
			assert_true ("allowed", l_result.is_allowed)
			assert_integers_equal ("remaining", 99, l_result.remaining)
		end

	test_is_allowed
			-- Test is_allowed convenience function.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.is_allowed"
		do
			assert_true ("first allowed", fixtures.default_limiter.is_allowed ("user1"))
		end

	test_consume_tokens
			-- Test consuming multiple tokens.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.consume"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make_with_limit (10, 60)
			assert_true ("consume 5", limiter.consume ("user1", 5))
			assert_integers_equal ("5 remaining", 5, limiter.remaining ("user1"))
		end

	test_consume_too_many
			-- Test consuming more tokens than available.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.consume"
		local
			limiter: SIMPLE_RATE_LIMITER
		do
			create limiter.make_with_limit (5, 60)
			assert_false ("cannot consume 10", limiter.consume ("user1", 10))
		end

	test_remaining
			-- Test remaining query.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.remaining"
		local
			limiter: SIMPLE_RATE_LIMITER
			l_result: RATE_LIMIT_RESULT
		do
			create limiter.make_with_limit (10, 60)
			assert_integers_equal ("initial remaining", 10, limiter.remaining ("user1"))
			l_result := limiter.check_limit ("user1")
			assert_integers_equal ("after one request", 9, limiter.remaining ("user1"))
		end

	test_rate_limit_exceeded
			-- Test exceeding rate limit.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.check_limit"
		local
			l_result: RATE_LIMIT_RESULT
		do
			l_result := fixtures.exhausted_limiter.check_limit ("test_user")
			assert_false ("fourth denied", l_result.is_allowed)
			assert_integers_equal ("no remaining", 0, l_result.remaining)
			assert_true ("has retry-after", l_result.retry_after > 0)
		end

feature -- Test: Rate Limiting - Sliding Window

	test_sliding_window_initial
			-- Test sliding window initial request.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.make_sliding_window"
		local
			l_result: RATE_LIMIT_RESULT
		do
			l_result := fixtures.sliding_window_limiter.check_limit ("user1")
			assert_true ("allowed", l_result.is_allowed)
			assert_integers_equal ("remaining", 199, l_result.remaining)
		end

	test_sliding_window_limit
			-- Test sliding window hits limit.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.check_limit"
		local
			limiter: SIMPLE_RATE_LIMITER
			l_result: RATE_LIMIT_RESULT
			i: INTEGER
		do
			create limiter.make_sliding_window (3, 60)

			-- Use all requests
			from i := 1 until i > 3 loop
				l_result := limiter.check_limit ("user1")
				assert_true ("request " + i.out + " allowed", l_result.is_allowed)
				i := i + 1
			variant
				4 - i
			end

			-- Next should be denied
			l_result := limiter.check_limit ("user1")
			assert_false ("fourth denied", l_result.is_allowed)
		end

feature -- Test: Reset

	test_reset
			-- Test resetting a key.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.reset"
		local
			limiter: SIMPLE_RATE_LIMITER
			l_result: RATE_LIMIT_RESULT
		do
			create limiter.make_with_limit (5, 60)
			l_result := limiter.check_limit ("user1")
			l_result := limiter.check_limit ("user1")
			assert_integers_equal ("3 remaining", 3, limiter.remaining ("user1"))
			limiter.reset ("user1")
			assert_integers_equal ("5 remaining after reset", 5, limiter.remaining ("user1"))
		end

	test_reset_all
			-- Test resetting all keys.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.reset_all"
		local
			limiter: SIMPLE_RATE_LIMITER
			l_result: RATE_LIMIT_RESULT
		do
			create limiter.make_with_limit (5, 60)
			l_result := limiter.check_limit ("user1")
			l_result := limiter.check_limit ("user2")
			limiter.reset_all
			assert_integers_equal ("user1 reset", 5, limiter.remaining ("user1"))
			assert_integers_equal ("user2 reset", 5, limiter.remaining ("user2"))
		end

feature -- Test: Headers

	test_rate_limit_headers
			-- Test RateLimit header generation.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.rate_limit_headers"
		local
			headers: HASH_TABLE [STRING, STRING]
		do
			headers := fixtures.custom_limiter.rate_limit_headers ("user1")
			assert_true ("has limit", headers.has ("RateLimit-Limit"))
			assert_true ("has remaining", headers.has ("RateLimit-Remaining"))
			assert_true ("has reset", headers.has ("RateLimit-Reset"))
		end

	test_rate_limit_headers_when_limited
			-- Test headers include Retry-After when rate limited.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.rate_limit_headers"
		local
			headers: HASH_TABLE [STRING, STRING]
		do
			headers := fixtures.exhausted_limiter.rate_limit_headers ("test_user")
			assert_true ("has retry-after", headers.has ("Retry-After"))
		end

feature -- Test: Reset Time

	test_reset_time
			-- Test reset_time query.
		note
			testing: "covers/{SIMPLE_RATE_LIMITER}.reset_time"
		local
			now: SIMPLE_DATE_TIME
			l_reset: SIMPLE_DATE_TIME
			l_result: RATE_LIMIT_RESULT
		do
			create now.make_now
			l_result := fixtures.custom_limiter.check_limit ("test_user")
			l_reset := fixtures.custom_limiter.reset_time ("test_user")
			assert_true ("reset in future", l_reset > now)
		end

end
