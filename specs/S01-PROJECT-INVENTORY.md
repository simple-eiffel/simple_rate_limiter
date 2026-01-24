# S01: PROJECT INVENTORY - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Project Structure

```
simple_rate_limiter/
  src/
    simple_rate_limiter.e        # Main rate limiter facade
    rate_limit_entry.e           # Per-key state tracking
    rate_limit_result.e          # Immutable result object
  testing/
    lib_tests.e                  # Library test suite
    test_app.e                   # Test application
  research/                      # Research documents
  specs/                         # Specification documents
  simple_rate_limiter.ecf        # EiffelStudio configuration
```

## 2. Source Files

| File | Purpose | Lines |
|------|---------|-------|
| simple_rate_limiter.e | Main facade with algorithms | ~530 |
| rate_limit_entry.e | Per-key state tracking | ~90 |
| rate_limit_result.e | Result object | ~50 |

## 3. Test Files

| File | Purpose |
|------|---------|
| lib_tests.e | Test suite class |
| test_app.e | Test runner application |

## 4. Dependencies

### 4.1 External Libraries
| Library | Purpose |
|---------|---------|
| simple_date_time | Timestamp handling |

### 4.2 EiffelBase Dependencies
- HASH_TABLE: Entry storage
- ARRAYED_LIST: Whitelist/blacklist
- STRING: Key handling
