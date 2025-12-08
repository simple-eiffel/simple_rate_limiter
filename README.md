<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_rate_limiter

**[Documentation](https://simple-eiffel.github.io/simple_rate_limiter/)**

Rate limiting library for Eiffel supporting token bucket and sliding window algorithms with RFC 6585 compliant headers.

## Features

- **Token bucket algorithm** - Smooth rate limiting with burst support
- **Sliding window algorithm** - Fixed window request counting
- **Whitelist/Blacklist** - Bypass or block specific keys
- **Burst limiting** - Control maximum burst size
- **RFC 6585 headers** - Standard RateLimit-* header generation
- **Per-key tracking** - Independent limits per identifier
- **Design by Contract** - Full preconditions/postconditions

## Installation

Add to your ECF:

```xml
<library name="simple_rate_limiter" location="$SIMPLE_RATE_LIMITER\simple_rate_limiter.ecf"/>
```

Set environment variable:
```
SIMPLE_RATE_LIMITER=D:\prod\simple_rate_limiter
```

## Usage

### Basic Rate Limiting

```eiffel
local
    limiter: SIMPLE_RATE_LIMITER
    result: RATE_LIMIT_RESULT
do
    create limiter.make  -- 100 requests per minute (default)

    result := limiter.check_limit ("user_123")
    if result.is_allowed then
        -- Process request
        print ("Allowed, " + result.remaining.out + " remaining")
    else
        -- Rate limited
        print ("Try again in " + result.retry_after.out + " seconds")
    end
end
```

### Custom Limits

```eiffel
-- 50 requests per 30 seconds
create limiter.make_with_limit (50, 30)

-- Or configure later
limiter.set_limit (200, 60)  -- 200 per minute
```

### Sliding Window

```eiffel
-- Sliding window: 100 requests per 2 minutes
create limiter.make_sliding_window (100, 120)
```

### Convenience Check

```eiffel
if limiter.is_allowed ("api_key_xyz") then
    -- Process request
end
```

### Consume Multiple Tokens

```eiffel
-- For expensive operations, consume multiple tokens
if limiter.consume ("user_123", 5) then
    -- Process heavy operation (costs 5 tokens)
end
```

### Whitelist/Blacklist

```eiffel
-- VIP users bypass rate limiting
limiter.add_whitelist ("admin")
limiter.add_whitelist ("premium_user")

-- Block abusive users entirely
limiter.add_blacklist ("spammer_ip")
limiter.add_blacklist ("banned_key")

-- Check status
if limiter.is_whitelisted ("admin") then
    print ("Admin is whitelisted")
end

-- Remove from lists
limiter.remove_whitelist ("former_vip")
limiter.remove_blacklist ("reformed_user")
```

### Burst Limiting

```eiffel
-- Allow up to 200 burst, refill at 100/minute
create limiter.make_with_limit (100, 60)
limiter.set_burst_limit (200)
```

### HTTP Response Headers

```eiffel
local
    headers: HASH_TABLE [STRING, STRING]
do
    headers := limiter.rate_limit_headers ("user_123")

    -- Returns:
    -- "RateLimit-Limit" -> "100"
    -- "RateLimit-Remaining" -> "95"
    -- "RateLimit-Reset" -> "45"
    -- "Retry-After" -> "45" (only if rate limited)

    across headers as h loop
        response.add_header (h.key, h.item)
    end
end
```

### Reset Limits

```eiffel
-- Reset single user
limiter.reset ("user_123")

-- Reset everyone
limiter.reset_all
```

## API Reference

### Initialization

| Feature | Description |
|---------|-------------|
| `make` | Create with defaults (100 req/60 sec, token bucket) |
| `make_with_limit (limit, window)` | Create with custom limit and window |
| `make_sliding_window (limit, window)` | Create with sliding window algorithm |

### Configuration

| Feature | Description |
|---------|-------------|
| `set_limit (requests, window)` | Set rate limit |
| `set_burst_limit (max)` | Set maximum burst size (token bucket) |

### Whitelist/Blacklist

| Feature | Description |
|---------|-------------|
| `add_whitelist (key)` | Add key to whitelist (always allowed) |
| `add_blacklist (key)` | Add key to blacklist (always denied) |
| `remove_whitelist (key)` | Remove from whitelist |
| `remove_blacklist (key)` | Remove from blacklist |
| `is_whitelisted (key)` | Is key whitelisted? |
| `is_blacklisted (key)` | Is key blacklisted? |

### Rate Limiting

| Feature | Description |
|---------|-------------|
| `check_limit (key): RATE_LIMIT_RESULT` | Check and consume 1 token |
| `is_allowed (key): BOOLEAN` | Quick allow/deny check |
| `consume (key, tokens): BOOLEAN` | Consume multiple tokens |
| `remaining (key): INTEGER` | Tokens remaining |
| `reset_time (key): DATE_TIME` | When limits reset |
| `reset (key)` | Reset single key |
| `reset_all` | Reset all keys |

### Response Headers

| Feature | Description |
|---------|-------------|
| `rate_limit_headers (key)` | Generate RateLimit-* headers |

### Query

| Feature | Description |
|---------|-------------|
| `limit: INTEGER` | Maximum requests per window |
| `window_seconds: INTEGER` | Window duration |
| `burst_limit: INTEGER` | Maximum burst size |
| `algorithm: STRING` | "token_bucket" or "sliding_window" |

## RATE_LIMIT_RESULT

The result object from `check_limit`:

| Feature | Description |
|---------|-------------|
| `is_allowed: BOOLEAN` | Was request allowed? |
| `remaining: INTEGER` | Requests remaining |
| `reset_time: DATE_TIME` | When window resets |
| `retry_after: INTEGER` | Seconds until next token (if denied) |

## Algorithm Comparison

| Algorithm | Pros | Cons |
|-----------|------|------|
| **Token Bucket** | Smooth rate limiting, allows bursts, gradual refill | Slightly more complex state |
| **Sliding Window** | Simple, predictable, exact count | Can allow double rate at window boundaries |

## Design Decisions

This library was designed after researching rate limiting algorithms, RFC standards, and common implementation patterns:

### Research Findings

**Algorithm Analysis:**
- **Token bucket** - Preferred for APIs due to smooth rate limiting and burst handling
- **Sliding window** - Simpler, good for fixed-window requirements
- **Leaky bucket** - Not implemented (token bucket is more flexible)
- **Fixed window** - Avoided due to thundering herd problem at window boundaries

**RFC 6585 Compliance:**
- Implements [RFC 6585](https://tools.ietf.org/html/rfc6585) 429 Too Many Requests semantics
- Follows draft-ietf-httpapi-ratelimit-headers for header format:
  - `RateLimit-Limit` - Maximum requests
  - `RateLimit-Remaining` - Requests left
  - `RateLimit-Reset` - Seconds until reset
  - `Retry-After` - When to retry (on 429)

**Competitor Pain Points Addressed:**
1. **Complex configuration** - Simple constructor with sensible defaults
2. **No whitelist/blacklist** - First-class support for VIP and banned users
3. **Missing burst control** - Separate burst limit from refill rate
4. **Hard to test** - `reset` and `reset_all` for test isolation

**Key Design Choices:**
1. **Per-key state** - Each identifier tracked independently
2. **Floating-point tokens** - Smooth refill without quantization
3. **Result object** - Rich return type with remaining, reset time, retry-after
4. **Header generation** - Standard-compliant headers ready for HTTP response

## Use Cases

- **API rate limiting** - Limit requests per API key
- **Login protection** - Prevent brute force attacks
- **Resource protection** - Limit expensive operations
- **Fair usage** - Ensure equal access across users
- **DDoS mitigation** - First line of defense

## Dependencies

- EiffelBase
- EiffelTime

## License

MIT License - Copyright (c) 2024-2025, Larry Rix
