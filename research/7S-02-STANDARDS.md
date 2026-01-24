# 7S-02: STANDARDS - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Applicable Standards

### 1.1 RFC 6585 - Additional HTTP Status Codes
- Defines HTTP 429 Too Many Requests
- Referenced for rate limit response handling

### 1.2 draft-ietf-httpapi-ratelimit-headers
- RateLimit-Limit: Maximum requests per window
- RateLimit-Remaining: Requests remaining in window
- RateLimit-Reset: Seconds until reset
- Retry-After: Seconds until next allowed request

## 2. Algorithm Standards

### 2.1 Token Bucket Algorithm
- Tokens added at constant rate
- Requests consume tokens
- Allows controlled bursting
- Industry standard for rate limiting

### 2.2 Sliding Window Counter
- Tracks requests within time window
- Window slides with time
- Simpler than token bucket
- Less flexible for bursting

## 3. Eiffel Standards

### 3.1 Design by Contract
- Preconditions on parameters
- Postconditions on results
- Class invariants on state

### 3.2 Void Safety
- Full void safety compliance
- Detachable used appropriately

## 4. Simple Ecosystem Standards

### 4.1 Dependencies
- simple_date_time (for timestamp handling)

### 4.2 Testing Pattern
- lib_tests.e for test suite
- test_app.e for test runner
