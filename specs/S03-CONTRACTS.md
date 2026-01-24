# S03: CONTRACTS - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. SIMPLE_RATE_LIMITER Contracts

### 1.1 Creation Procedures

#### make
```eiffel
ensure
    default_limit: limit = Default_limit
    default_window: window_seconds = Default_window
```

#### make_with_limit
```eiffel
require
    positive_limit: a_limit > 0
    positive_window: a_window_seconds > 0
ensure
    limit_set: limit = a_limit
    window_set: window_seconds = a_window_seconds
```

#### make_sliding_window
```eiffel
require
    positive_limit: a_limit > 0
    positive_window: a_window_seconds > 0
ensure
    limit_set: limit = a_limit
    window_set: window_seconds = a_window_seconds
    sliding_algorithm: algorithm.same_string (Algorithm_sliding_window)
```

### 1.2 Configuration

#### set_limit
```eiffel
require
    positive_requests: a_requests > 0
    positive_window: a_window_seconds > 0
ensure
    limit_set: limit = a_requests
    window_set: window_seconds = a_window_seconds
```

#### set_burst_limit
```eiffel
require
    positive_burst: a_max_burst > 0
ensure
    burst_set: burst_limit = a_max_burst
```

### 1.3 Whitelist/Blacklist

#### add_whitelist
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
ensure
    whitelisted: is_whitelisted (a_key)
```

#### add_blacklist
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
ensure
    blacklisted: is_blacklisted (a_key)
```

### 1.4 Rate Limiting

#### check_limit
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
ensure
    result_attached: Result /= Void
```

#### is_allowed
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
```

#### consume
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
    positive_tokens: a_tokens > 0
```

### 1.5 Response Headers

#### rate_limit_headers
```eiffel
require
    key_not_void: a_key /= Void
    key_not_empty: not a_key.is_empty
ensure
    has_limit: Result.has ("RateLimit-Limit")
    has_remaining: Result.has ("RateLimit-Remaining")
    has_reset: Result.has ("RateLimit-Reset")
```

### 1.6 Class Invariant

```eiffel
invariant
    entries_attached: entries /= Void
    whitelist_attached: whitelist /= Void
    blacklist_attached: blacklist /= Void
    positive_limit: limit > 0
    positive_window: window_seconds > 0
    positive_burst: burst_limit > 0
```

## 2. RATE_LIMIT_ENTRY Contracts

### 2.1 Creation
```eiffel
require
    start_not_void: a_start /= Void
ensure
    tokens_set: tokens = a_tokens
    window_start_set: window_start /= Void
    last_refill_set: last_refill /= Void
```

### 2.2 Invariant
```eiffel
invariant
    window_start_attached: window_start /= Void
    last_refill_attached: last_refill /= Void
    non_negative_count: request_count >= 0
```

## 3. RATE_LIMIT_RESULT Contracts

### 3.1 Creation
```eiffel
require
    reset_time_not_void: a_reset_time /= Void
    non_negative_remaining: a_remaining >= 0
    non_negative_retry: a_retry_after >= 0
ensure
    allowed_set: is_allowed = a_allowed
    remaining_set: remaining = a_remaining
    reset_time_set: reset_time /= Void
    retry_after_set: retry_after = a_retry_after
```

### 3.2 Invariant
```eiffel
invariant
    reset_time_attached: reset_time /= Void
    non_negative_remaining: remaining >= 0
    non_negative_retry: retry_after >= 0
```
