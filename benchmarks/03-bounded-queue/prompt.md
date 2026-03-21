# Thread-Safe Bounded Queue

Implement the following. Write production-quality code.

## Requirements

Implement a thread-safe bounded queue in Python using **only the standard library** (`threading`, `collections`, etc.). No external dependencies.

### Class: `BoundedQueue`

**Constructor:**
```python
BoundedQueue(capacity: int)
```

**Methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `put`  | `put(item, timeout=None) -> bool` | Add an item to the queue. Blocks if the queue is full. Returns `True` on success, `False` if the operation times out. |
| `get`  | `get(timeout=None) -> Optional[Any]` | Remove and return the front item. Blocks if the queue is empty. Returns `None` if the operation times out. |
| `size` | `size() -> int` | Return the current number of items in the queue. |
| `close`| `close()` | Signal graceful shutdown. After `close()` is called: `put()` must return `False` immediately; `get()` must drain any remaining items, then return `None`. |

### Constraints

1. **Thread safety:** The queue must be safe for concurrent use by multiple producers and multiple consumers simultaneously.
2. **Graceful shutdown:** Calling `close()` must unblock any threads currently waiting in `put()` or `get()`. Threads blocked on `put()` must return `False`. Threads blocked on `get()` must first drain remaining items (returning them normally), then return `None` once the queue is empty.
3. **Spurious wakeup correctness:** The implementation must handle spurious wakeups. Use `while`-loop condition checks around all `wait()` calls, not `if` statements.
4. **Blocking with timeout:** When `timeout` is specified, the operation must respect the deadline precisely. When `timeout=None`, the operation blocks indefinitely until it succeeds or the queue is closed.
5. **FIFO ordering:** Items must be returned in the order they were inserted.
6. **Bounded capacity:** The queue must never hold more items than the specified `capacity`. `put()` must block (or timeout) when the queue is at capacity.

### Example Usage

```python
from solution import BoundedQueue

q = BoundedQueue(capacity=10)

# Producer thread
def producer():
    for i in range(100):
        if not q.put(i):
            break  # queue was closed

# Consumer thread
def consumer():
    while True:
        item = q.get(timeout=1.0)
        if item is None:
            break  # queue closed and drained, or timeout
        process(item)
```

Save your implementation in a file named `solution.py`.
