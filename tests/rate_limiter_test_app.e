note
	description: "Test application for simple_rate_limiter"
	author: "Larry Rix"

class
	RATE_LIMITER_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: SIMPLE_RATE_LIMITER_TEST_SET
		do
			create tests
			print ("simple_rate_limiter test runner%N")
			print ("=================================%N%N")

			passed := 0
			failed := 0

			-- Initialization
			run_test (agent tests.test_make_default, "test_make_default")
			run_test (agent tests.test_make_with_limit, "test_make_with_limit")
			run_test (agent tests.test_make_sliding_window, "test_make_sliding_window")

			-- Configuration
			run_test (agent tests.test_set_limit, "test_set_limit")
			run_test (agent tests.test_set_burst_limit, "test_set_burst_limit")

			-- Whitelist/Blacklist
			run_test (agent tests.test_add_whitelist, "test_add_whitelist")
			run_test (agent tests.test_add_blacklist, "test_add_blacklist")
			run_test (agent tests.test_remove_whitelist, "test_remove_whitelist")
			run_test (agent tests.test_remove_blacklist, "test_remove_blacklist")
			run_test (agent tests.test_whitelist_bypasses_limit, "test_whitelist_bypasses_limit")
			run_test (agent tests.test_blacklist_always_denied, "test_blacklist_always_denied")

			-- Token Bucket
			run_test (agent tests.test_initial_request_allowed, "test_initial_request_allowed")
			run_test (agent tests.test_is_allowed, "test_is_allowed")
			run_test (agent tests.test_consume_tokens, "test_consume_tokens")
			run_test (agent tests.test_consume_too_many, "test_consume_too_many")
			run_test (agent tests.test_remaining, "test_remaining")
			run_test (agent tests.test_rate_limit_exceeded, "test_rate_limit_exceeded")

			-- Sliding Window
			run_test (agent tests.test_sliding_window_initial, "test_sliding_window_initial")
			run_test (agent tests.test_sliding_window_limit, "test_sliding_window_limit")

			-- Reset
			run_test (agent tests.test_reset, "test_reset")
			run_test (agent tests.test_reset_all, "test_reset_all")

			-- Headers
			run_test (agent tests.test_rate_limit_headers, "test_rate_limit_headers")
			run_test (agent tests.test_rate_limit_headers_when_limited, "test_rate_limit_headers_when_limited")

			-- Reset Time
			run_test (agent tests.test_reset_time, "test_reset_time")

			print ("%N=================================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
