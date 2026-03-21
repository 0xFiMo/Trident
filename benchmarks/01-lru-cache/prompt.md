# LRU Cache

Implement the following. Write production-quality code.

## Requirements

Implement an LRU (Least Recently Used) Cache in Python.

- **Class name:** `LRUCache`
- **Constructor:** `LRUCache(capacity: int)` — creates a cache with the given positive capacity.
- **Method:** `get(key: int) -> int` — returns the value associated with `key` if it exists in the cache, otherwise returns `-1`.
- **Method:** `put(key: int, value: int) -> None` — inserts or updates the value for `key`. If the number of keys exceeds the capacity, evict the least recently used key.

Both `get` and `put` must run in **O(1)** average time complexity.

A key is considered "used" whenever it is accessed via `get` or `put`.

## Output

Save your implementation in a file named `solution.py`. The class `LRUCache` must be importable from it:

```python
from solution import LRUCache
```
