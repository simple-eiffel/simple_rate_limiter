# S02: CLASS CATALOG - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Class Overview

| Class | Type | Purpose |
|-------|------|---------|
| SIMPLE_RATE_LIMITER | Effective | Main rate limiting facade |
| RATE_LIMIT_ENTRY | Effective | Per-key state tracking |
| RATE_LIMIT_RESULT | Effective | Immutable result object |

## 2. Class Details

### 2.1 SIMPLE_RATE_LIMITER

**Purpose**: Token bucket and sliding window rate limiting.

**Creation Procedures**:
- `make` - Default 100 requests/minute
- `make_with_limit (a_limit, a_window_seconds)` - Custom limits
- `make_sliding_window (a_limit, a_window_seconds)` - Sliding window algorithm

**Feature Groups**:
- Configuration
- Whitelist/Blacklist
- Rate Limiting
- Response Headers
- Query
- Constants

**Invariants**:
- entries_attached, whitelist_attached, blacklist_attached
- positive_limit, positive_window, positive_burst

### 2.2 RATE_LIMIT_ENTRY

**Purpose**: Track rate limit state for a single key.

**Creation Procedures**:
- `make (a_tokens, a_start)` - Create with initial state

**Attributes**:
- tokens: REAL - Current token count
- window_start: SIMPLE_DATE_TIME - Window start time
- last_refill: SIMPLE_DATE_TIME - Last token refill time
- request_count: INTEGER - Requests in window

### 2.3 RATE_LIMIT_RESULT

**Purpose**: Immutable result of rate limit check.

**Creation Procedures**:
- `make (a_allowed, a_remaining, a_reset_time, a_retry_after)`

**Attributes**:
- is_allowed: BOOLEAN
- remaining: INTEGER
- reset_time: SIMPLE_DATE_TIME
- retry_after: INTEGER
