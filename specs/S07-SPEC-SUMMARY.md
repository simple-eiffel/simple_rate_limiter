# S07: SPEC SUMMARY - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Library Overview

**Name**: simple_rate_limiter
**Purpose**: Token bucket and sliding window rate limiting
**Status**: Production ready

## 2. Quick Reference

### 2.1 Creation
```eiffel
-- Default (100/minute)
create limiter.make

-- Custom limits
create limiter.make_with_limit (1000, 3600)  -- 1000/hour

-- Sliding window algorithm
create limiter.make_sliding_window (100, 60)
```

### 2.2 Basic Usage
```eiffel
-- Check and consume
result := limiter.check_limit ("user_123")
if result.is_allowed then
    -- Process request
else
    -- Reject, suggest retry after result.retry_after seconds
end

-- Quick check
if limiter.is_allowed ("user_123") then
    -- Process
end
```

### 2.3 Whitelist/Blacklist
```eiffel
limiter.add_whitelist ("admin_key")  -- Always allowed
limiter.add_blacklist ("bad_actor")   -- Always denied
```

### 2.4 HTTP Headers
```eiffel
headers := limiter.rate_limit_headers ("user_123")
-- Returns: RateLimit-Limit, RateLimit-Remaining, RateLimit-Reset
-- Plus Retry-After if blocked
```

## 3. Key Specifications

| Aspect | Specification |
|--------|---------------|
| Classes | 3 |
| Algorithms | Token Bucket, Sliding Window |
| Dependencies | simple_date_time |
| Thread Safety | No |
| Persistence | No |

## 4. Warnings

1. **In-memory only** - State lost on restart
2. **Single-process** - Not distributed
3. **No cleanup** - Memory grows with unique keys
4. **Not thread-safe** - Needs external synchronization
