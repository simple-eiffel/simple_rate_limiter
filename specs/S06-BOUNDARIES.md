# S06: BOUNDARIES - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. API Boundaries

### 1.1 Public Interface (SIMPLE_RATE_LIMITER)
- All creation procedures
- Configuration features
- Whitelist/blacklist management
- Rate limiting operations
- HTTP header generation
- Query features

### 1.2 Private Features
| Feature | Visibility | Purpose |
|---------|------------|---------|
| entries | {NONE} | Entry storage |
| whitelist | {NONE} | Whitelist storage |
| blacklist | {NONE} | Blacklist storage |
| get_or_create_entry | {NONE} | Entry management |
| check_token_bucket | {NONE} | Algorithm impl |
| check_sliding_window | {NONE} | Algorithm impl |
| refill_tokens | {NONE} | Token refill |
| tokens_per_second | {NONE} | Rate calculation |
| seconds_between | {NONE} | Time calculation |
| list_has_string | {NONE} | List helper |

## 2. Input Boundaries

### 2.1 Keys
| Constraint | Validation |
|------------|------------|
| Not Void | Precondition |
| Not empty | Precondition |
| Type | STRING |

### 2.2 Numeric Parameters
| Parameter | Min | Max |
|-----------|-----|-----|
| limit | 1 | MAX_INTEGER |
| window_seconds | 1 | MAX_INTEGER |
| burst_limit | 1 | MAX_INTEGER |
| tokens | 1 | burst_limit |

## 3. Output Boundaries

### 3.1 RATE_LIMIT_RESULT
| Field | Range |
|-------|-------|
| is_allowed | BOOLEAN |
| remaining | 0 to limit |
| reset_time | Future or now |
| retry_after | 0 to window_seconds |

### 3.2 HTTP Headers
| Header | Format |
|--------|--------|
| RateLimit-Limit | Integer string |
| RateLimit-Remaining | Integer string (0+) |
| RateLimit-Reset | Seconds string |
| Retry-After | Seconds string (only if blocked) |

## 4. Behavioral Boundaries

### 4.1 Whitelist Behavior
- Whitelisted keys always allowed
- Full remaining count returned
- No token consumption

### 4.2 Blacklist Behavior
- Blacklisted keys always denied
- Zero remaining returned
- Retry-After set to window_seconds

### 4.3 Normal Behavior
- Token bucket: Refill, consume, return result
- Sliding window: Count, check limit, return result
