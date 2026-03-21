#!/usr/bin/env python3
"""Comprehensive test suite for LRU Cache benchmark (28 cases)."""

import threading
import time
import unittest
from collections import defaultdict

from solution import LRUCache


class _CategoryTracker:
    results: dict = defaultdict(lambda: {"passed": 0, "failed": 0, "errors": 0})

    @classmethod
    def record(cls, category: str, outcome: str):
        cls.results[category][outcome] += 1


def _category(name: str):
    """Decorator that tags a test method with a scoring category."""

    def decorator(fn):
        fn._category = name
        return fn

    return decorator


# ---------------------------------------------------------------------------
# Correctness (10)
# ---------------------------------------------------------------------------
class TestCorrectness(unittest.TestCase):
    @_category("correctness")
    def test_basic_get_put(self):
        """Put a key then get it back."""
        c = LRUCache(2)
        c.put(1, 10)
        self.assertEqual(c.get(1), 10)

    @_category("correctness")
    def test_get_updates_recency(self):
        """Accessing a key via get should protect it from eviction."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.get(1)  # 1 is now most-recent
        c.put(3, 3)  # should evict 2
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(1), 1)

    @_category("correctness")
    def test_put_updates_recency(self):
        """Overwriting a key via put should refresh its recency."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.put(1, 10)  # refresh key 1
        c.put(3, 3)  # should evict 2
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(1), 10)

    @_category("correctness")
    def test_eviction_of_lru(self):
        """Least recently used item is the one evicted."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.put(3, 3)  # evicts 1
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(2), 2)
        self.assertEqual(c.get(3), 3)

    @_category("correctness")
    def test_multiple_evictions(self):
        """Several evictions in sequence maintain correct order."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.put(3, 3)  # evicts 1
        c.put(4, 4)  # evicts 2
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(3), 3)
        self.assertEqual(c.get(4), 4)

    @_category("correctness")
    def test_update_existing_value(self):
        """Putting a key that already exists updates its value."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(1, 100)
        self.assertEqual(c.get(1), 100)

    @_category("correctness")
    def test_update_existing_updates_recency(self):
        """Updating an existing key moves it to most-recent."""
        c = LRUCache(3)
        c.put(1, 1)
        c.put(2, 2)
        c.put(3, 3)
        c.put(1, 11)  # refresh 1
        c.put(4, 4)  # evicts 2 (oldest untouched)
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(1), 11)

    @_category("correctness")
    def test_get_nonexistent_returns_neg1(self):
        """Getting a key that was never inserted returns -1."""
        c = LRUCache(2)
        self.assertEqual(c.get(99), -1)

    @_category("correctness")
    def test_sequential_operations(self):
        """A longer deterministic sequence of operations."""
        c = LRUCache(3)
        c.put(1, 1)
        c.put(2, 2)
        c.put(3, 3)
        self.assertEqual(c.get(1), 1)
        c.put(4, 4)  # evicts 2
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(3), 3)
        c.put(5, 5)  # LRU order: [4,3,5] — evicts 1
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(4), 4)
        self.assertEqual(c.get(5), 5)

    @_category("correctness")
    def test_interleaved_get_put(self):
        """Interleaved gets and puts in a specific pattern."""
        c = LRUCache(2)
        c.put(2, 1)
        c.put(1, 1)
        c.put(2, 3)
        c.put(4, 1)  # evicts 1
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(2), 3)


# ---------------------------------------------------------------------------
# Boundary (8)
# ---------------------------------------------------------------------------
class TestBoundary(unittest.TestCase):
    @_category("boundary")
    def test_capacity_one_single(self):
        """Cache with capacity 1 holds exactly one item."""
        c = LRUCache(1)
        c.put(1, 42)
        self.assertEqual(c.get(1), 42)

    @_category("boundary")
    def test_capacity_one_eviction(self):
        """Cache with capacity 1 evicts on every new key."""
        c = LRUCache(1)
        c.put(1, 1)
        c.put(2, 2)
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(2), 2)

    @_category("boundary")
    def test_capacity_zero(self):
        """Cache with capacity 0 should never store anything."""
        c = LRUCache(0)
        c.put(1, 1)
        self.assertEqual(c.get(1), -1)

    @_category("boundary")
    def test_put_same_key_many_times(self):
        """Repeatedly putting the same key should not grow cache size."""
        c = LRUCache(2)
        for i in range(100):
            c.put(1, i)
        self.assertEqual(c.get(1), 99)
        c.put(2, 2)
        self.assertEqual(c.get(1), 99)
        self.assertEqual(c.get(2), 2)

    @_category("boundary")
    def test_large_capacity(self):
        """Cache with 1000 items stores and retrieves all."""
        c = LRUCache(1000)
        for i in range(1000):
            c.put(i, i * 10)
        for i in range(1000):
            self.assertEqual(c.get(i), i * 10)

    @_category("boundary")
    def test_get_after_eviction(self):
        """Getting an evicted key returns -1."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.put(3, 3)
        self.assertEqual(c.get(1), -1)

    @_category("boundary")
    def test_put_after_get_changes_eviction(self):
        """A get followed by a put should change which key is evicted."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.get(1)  # 1 is now most-recent
        c.put(3, 3)  # evicts 2, not 1
        self.assertEqual(c.get(2), -1)
        self.assertEqual(c.get(1), 1)
        self.assertEqual(c.get(3), 3)

    @_category("boundary")
    def test_empty_cache_get(self):
        """Getting from a freshly created cache returns -1."""
        c = LRUCache(5)
        self.assertEqual(c.get(0), -1)
        self.assertEqual(c.get(1), -1)


# ---------------------------------------------------------------------------
# Performance (3)
# ---------------------------------------------------------------------------
class TestPerformance(unittest.TestCase):
    @_category("performance")
    def test_10k_ops(self):
        """10 000 mixed operations should complete in under 1 second."""
        c = LRUCache(500)
        start = time.perf_counter()
        for i in range(10_000):
            c.put(i, i)
            c.get(i - 5)
        elapsed = time.perf_counter() - start
        self.assertLess(elapsed, 1.0, f"10K ops took {elapsed:.3f}s (limit 1s)")

    @_category("performance")
    def test_100k_ops(self):
        """100 000 mixed operations should complete in under 5 seconds."""
        c = LRUCache(5000)
        start = time.perf_counter()
        for i in range(100_000):
            c.put(i, i)
            c.get(i - 50)
        elapsed = time.perf_counter() - start
        self.assertLess(elapsed, 5.0, f"100K ops took {elapsed:.3f}s (limit 5s)")

    @_category("performance")
    def test_1m_ops(self):
        """1 000 000 mixed operations should complete in under 30 seconds."""
        c = LRUCache(50_000)
        start = time.perf_counter()
        for i in range(1_000_000):
            c.put(i, i)
            c.get(i - 500)
        elapsed = time.perf_counter() - start
        self.assertLess(elapsed, 30.0, f"1M ops took {elapsed:.3f}s (limit 30s)")


# ---------------------------------------------------------------------------
# Complexity verification (2)
# ---------------------------------------------------------------------------
class TestComplexity(unittest.TestCase):
    @staticmethod
    def _bench(n: int, capacity: int) -> float:
        c = LRUCache(capacity)
        start = time.perf_counter()
        for i in range(n):
            c.put(i, i)
            c.get(i - 5)
        return time.perf_counter() - start

    @_category("complexity")
    def test_linear_scaling(self):
        """100K should not be more than ~15x slower than 10K (ideal ~10x for O(1))."""
        t1 = self._bench(10_000, 500)
        t2 = self._bench(100_000, 5000)
        ratio = t2 / max(t1, 1e-9)
        self.assertLess(ratio, 15.0, f"100K/10K ratio = {ratio:.1f}x (expected ~10x for O(1))")

    @_category("complexity")
    def test_scaling_consistency(self):
        """Run two sizes and verify the ratio stays reasonable."""
        t1 = self._bench(50_000, 2500)
        t2 = self._bench(200_000, 10_000)
        ratio = t2 / max(t1, 1e-9)
        self.assertLess(ratio, 6.0, f"200K/50K ratio = {ratio:.1f}x (expected ~4x for O(1))")


# ---------------------------------------------------------------------------
# Trap cases (5)
# ---------------------------------------------------------------------------
class TestTraps(unittest.TestCase):
    @_category("trap")
    def test_thread_safety_basic(self):
        """Concurrent puts and gets should not crash or corrupt state."""
        c = LRUCache(100)
        errors = []

        def writer(start: int):
            try:
                for i in range(start, start + 500):
                    c.put(i, i)
            except Exception as exc:
                errors.append(exc)

        def reader(start: int):
            try:
                for i in range(start, start + 500):
                    val = c.get(i)
                    if val not in (-1, i):
                        errors.append(ValueError(f"get({i}) returned {val}, expected {i} or -1"))
            except Exception as exc:
                errors.append(exc)

        threads = []
        for base in range(0, 2000, 500):
            threads.append(threading.Thread(target=writer, args=(base,)))
            threads.append(threading.Thread(target=reader, args=(base,)))
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=10)

        self.assertEqual(errors, [], f"Thread errors: {errors[:5]}")

    @_category("trap")
    def test_cache_never_exceeds_capacity(self):
        """Internal size should never grow beyond the stated capacity."""
        cap = 5
        c = LRUCache(cap)
        for i in range(50):
            c.put(i, i)
            present = sum(1 for k in range(i + 1) if c.get(k) != -1)
            self.assertLessEqual(
                present, cap, f"After put({i}), {present} items present (cap={cap})"
            )

    @_category("trap")
    def test_overwrite_does_not_increase_size(self):
        """Updating an existing key must not count as a new entry."""
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.put(1, 10)  # overwrite, not insert
        c.put(2, 20)  # overwrite, not insert
        self.assertEqual(c.get(1), 10)
        self.assertEqual(c.get(2), 20)

    @_category("trap")
    def test_tricky_eviction_sequence(self):
        """A specific sequence that trips naive linked-list implementations.

        Sequence: put(1,1) put(2,2) get(1) put(3,3) get(2) put(4,4)
        After put(3,3): evicts 2 -> cache=[1,3]
        get(2) -> -1, cache unchanged -> [1,3] (but 1 was accessed last via get)
        Actually after get(1): [2,1] -> put(3,3) evicts 2 -> [1,3]
        get(2) -> -1 -> [1,3]
        put(4,4) -> evicts 1 (LRU) -> [3,4]
        """
        c = LRUCache(2)
        c.put(1, 1)
        c.put(2, 2)
        c.get(1)
        c.put(3, 3)  # evicts 2
        self.assertEqual(c.get(2), -1)
        c.put(4, 4)  # evicts 1 (3 was touched more recently via put)
        self.assertEqual(c.get(1), -1)
        self.assertEqual(c.get(3), 3)
        self.assertEqual(c.get(4), 4)

    @_category("trap")
    def test_negative_and_zero_keys(self):
        """Negative and zero keys should work like any other integer key."""
        c = LRUCache(3)
        c.put(0, 100)
        c.put(-1, 200)
        c.put(-99, 300)
        self.assertEqual(c.get(0), 100)
        self.assertEqual(c.get(-1), 200)
        self.assertEqual(c.get(-99), 300)
        c.put(1, 400)  # evicts 0 (LRU)
        self.assertEqual(c.get(0), -1)


# ---------------------------------------------------------------------------
# Runner with per-category summary
# ---------------------------------------------------------------------------
class _CategoryResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.category_stats = defaultdict(lambda: {"passed": 0, "failed": 0, "errors": 0})

    def _get_category(self, test: unittest.TestCase) -> str:
        method = getattr(test, test._testMethodName, None)
        return getattr(method, "_category", "unknown") if method else "unknown"

    def addSuccess(self, test):
        super().addSuccess(test)
        self.category_stats[self._get_category(test)]["passed"] += 1

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self.category_stats[self._get_category(test)]["failed"] += 1

    def addError(self, test, err):
        super().addError(test, err)
        self.category_stats[self._get_category(test)]["errors"] += 1


class _CategoryRunner(unittest.TextTestRunner):
    resultclass = _CategoryResult

    def run(self, test):
        result = super().run(test)
        print("\n" + "=" * 60)
        print("CATEGORY SUMMARY")
        print("=" * 60)
        total_pass = 0
        total_fail = 0
        total_err = 0
        order = ["correctness", "boundary", "performance", "complexity", "trap"]
        for cat in order:
            s = result.category_stats.get(cat, {"passed": 0, "failed": 0, "errors": 0})
            total = s["passed"] + s["failed"] + s["errors"]
            status = "ALL PASSED" if s["failed"] == 0 and s["errors"] == 0 else "ISSUES"
            print(f"  {cat:<14s}  {s['passed']}/{total} passed  [{status}]")
            total_pass += s["passed"]
            total_fail += s["failed"]
            total_err += s["errors"]
        print("-" * 60)
        grand = total_pass + total_fail + total_err
        print(
            f"  TOTAL          {total_pass}/{grand} passed, {total_fail} failed, {total_err} errors"
        )
        verdict = "PASS" if total_fail == 0 and total_err == 0 else "FAIL"
        print(f"  VERDICT:       {verdict}")
        print("=" * 60)
        return result


if __name__ == "__main__":
    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(__import__(__name__))
    runner = _CategoryRunner(verbosity=2)
    result = runner.run(suite)
    raise SystemExit(0 if result.wasSuccessful() else 1)
