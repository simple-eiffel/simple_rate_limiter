# S04: FEATURE SPECS - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. SIMPLE_RATE_LIMITER Features

### 1.1 Initialization

| Feature | Signature | Description |
|---------|-----------|-------------|
| make | `make` | Default 100/minute |
| make_with_limit | `(a_limit, a_window_seconds: INTEGER)` | Custom limits |
| make_sliding_window | `(a_limit, a_window_seconds: INTEGER)` | Sliding window |

### 1.2 Configuration

| Feature | Signature | Description |
|---------|-----------|-------------|
| set_limit | `(a_requests, a_window_seconds: INTEGER)` | Set rate limit |
| set_burst_limit | `(a_max_burst: INTEGER)` | Set max burst |

### 1.3 Whitelist/Blacklist

| Feature | Signature | Description |
|---------|-----------|-------------|
| add_whitelist | `(a_key: STRING)` | Bypass rate limit |
| add_blacklist | `(a_key: STRING)` | Always deny |
| remove_whitelist | `(a_key: STRING)` | Remove from whitelist |
| remove_blacklist | `(a_key: STRING)` | Remove from blacklist |

### 1.4 Rate Limiting

| Feature | Signature | Description |
|---------|-----------|-------------|
| check_limit | `(a_key: STRING): RATE_LIMIT_RESULT` | Check and consume |
| is_allowed | `(a_key: STRING): BOOLEAN` | Quick check |
| consume | `(a_key: STRING; a_tokens: INTEGER): BOOLEAN` | Consume multiple |
| remaining | `(a_key: STRING): INTEGER` | Remaining requests |
| reset_time | `(a_key: STRING): SIMPLE_DATE_TIME` | When reset occurs |
| reset | `(a_key: STRING)` | Reset key state |
| reset_all | | Reset all state |

### 1.5 Response Headers

| Feature | Signature | Description |
|---------|-----------|-------------|
| rate_limit_headers | `(a_key: STRING): HASH_TABLE [STRING, STRING]` | RFC headers |

### 1.6 Query

| Feature | Signature | Description |
|---------|-----------|-------------|
| limit | `: INTEGER` | Max requests |
| window_seconds | `: INTEGER` | Window duration |
| burst_limit | `: INTEGER` | Max burst size |
| algorithm | `: STRING` | Current algorithm |
| is_whitelisted | `(a_key: STRING): BOOLEAN` | Check whitelist |
| is_blacklisted | `(a_key: STRING): BOOLEAN` | Check blacklist |

### 1.7 Constants

| Constant | Value | Description |
|----------|-------|-------------|
| Default_limit | 100 | Default requests |
| Default_window | 60 | Default seconds |
| Algorithm_token_bucket | "token_bucket" | Token bucket |
| Algorithm_sliding_window | "sliding_window" | Sliding window |

## 2. RATE_LIMIT_ENTRY Features

| Feature | Type | Description |
|---------|------|-------------|
| tokens | REAL | Current token count |
| window_start | SIMPLE_DATE_TIME | Window start |
| last_refill | SIMPLE_DATE_TIME | Last refill time |
| request_count | INTEGER | Requests in window |
| set_tokens | Procedure | Set token count |
| set_window_start | Procedure | Set window start |
| set_last_refill | Procedure | Set refill time |
| set_request_count | Procedure | Set request count |

## 3. RATE_LIMIT_RESULT Features

| Feature | Type | Description |
|---------|------|-------------|
| is_allowed | BOOLEAN | Request permitted? |
| remaining | INTEGER | Remaining requests |
| reset_time | SIMPLE_DATE_TIME | When reset |
| retry_after | INTEGER | Seconds to wait |
