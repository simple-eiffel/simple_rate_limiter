# S05: CONSTRAINTS - simple_rate_limiter

**BACKWASH DOCUMENT** - Generated: 2026-01-23
**Status**: Reverse-engineered from existing implementation

## 1. Technical Constraints

### 1.1 Platform Constraints
- **EiffelStudio**: Requires EiffelStudio 25.02 or compatible
- **Platform**: Cross-platform (no platform-specific code)

### 1.2 Dependency Constraints
- Requires simple_date_time library

### 1.3 Memory Constraints
- Entries not automatically cleaned up
- Memory grows with unique keys
- Long-running services may need manual cleanup

## 2. Design Constraints

### 2.1 Algorithm Constraints
| Algorithm | Bursting | Precision | Memory |
|-----------|----------|-----------|--------|
| Token Bucket | Yes | High | Higher |
| Sliding Window | No | Medium | Lower |

### 2.2 Time Constraints
- Resolution limited by system clock
- Minimum practical window: 1 second
- Token refill calculated on access

### 2.3 Concurrency Constraints
- NOT thread-safe without synchronization
- For SCOOP: Requires separate region handling
- Mutable state (entries, whitelist, blacklist)

## 3. Operational Constraints

### 3.1 State Persistence
- In-memory only
- State lost on restart
- No automatic persistence

### 3.2 Distribution Constraints
- Single process only
- Not distributed (no shared state mechanism)
- Each instance maintains independent state

## 4. Value Constraints

| Parameter | Minimum | Maximum |
|-----------|---------|---------|
| limit | 1 | MAX_INTEGER |
| window_seconds | 1 | MAX_INTEGER |
| burst_limit | 1 | MAX_INTEGER |
| tokens consumed | 1 | burst_limit |
