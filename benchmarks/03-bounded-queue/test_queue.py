#!/usr/bin/env python3
"""Comprehensive test suite for Thread-Safe Bounded Queue.

22 test cases across 5 categories:
  - Functionality (6)
  - Boundary (4)
  - Concurrency correctness (5)
  - Stress (3)
  - Trap cases (4)

Run with:
  python -m pytest test_queue.py -v --tb=short
  python test_queue.py
"""

import collections
import sys
import threading
import time
import unittest

from solution import BoundedQueue


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _collect(target, args, results_list, index):
    """Thread wrapper that stores return value in results_list[index]."""
    results_list[index] = target(*args)


# ===================================================================
# 1. Functionality (6 cases)
# ===================================================================


class TestFunctionality(unittest.TestCase):
    """Basic functional correctness."""

    def test_basic_put_and_get(self):
        """Put an item then get it back."""
        q = BoundedQueue(capacity=5)
        q.put("hello")
        self.assertEqual(q.get(timeout=1.0), "hello")

    def test_fifo_ordering(self):
        """Items come out in the order they were put in."""
        q = BoundedQueue(capacity=10)
        items = list(range(10))
        for item in items:
            q.put(item)
        result = [q.get(timeout=1.0) for _ in items]
        self.assertEqual(result, items)

    def test_put_returns_true(self):
        """put() returns True when the item is successfully enqueued."""
        q = BoundedQueue(capacity=5)
        self.assertTrue(q.put("x", timeout=1.0))

    def test_get_returns_correct_item(self):
        """get() returns the exact object that was put."""
        sentinel = object()
        q = BoundedQueue(capacity=5)
        q.put(sentinel)
        self.assertIs(q.get(timeout=1.0), sentinel)

    def test_size_reflects_count(self):
        """size() accurately tracks insertions and removals."""
        q = BoundedQueue(capacity=10)
        self.assertEqual(q.size(), 0)
        q.put("a")
        q.put("b")
        self.assertEqual(q.size(), 2)
        q.get(timeout=1.0)
        self.assertEqual(q.size(), 1)
        q.get(timeout=1.0)
        self.assertEqual(q.size(), 0)

    def test_multiple_items_in_sequence(self):
        """Sequential put-get cycles all succeed."""
        q = BoundedQueue(capacity=3)
        for i in range(20):
            self.assertTrue(q.put(i, timeout=1.0))
            self.assertEqual(q.get(timeout=1.0), i)
        self.assertEqual(q.size(), 0)


# ===================================================================
# 2. Boundary (4 cases)
# ===================================================================


class TestBoundary(unittest.TestCase):
    """Edge and boundary conditions."""

    def test_empty_get_timeout(self):
        """get() on an empty queue with timeout returns None."""
        q = BoundedQueue(capacity=5)
        start = time.monotonic()
        result = q.get(timeout=0.1)
        elapsed = time.monotonic() - start
        self.assertIsNone(result)
        self.assertGreaterEqual(elapsed, 0.05)

    def test_full_put_timeout(self):
        """put() on a full queue with timeout returns False."""
        q = BoundedQueue(capacity=1)
        q.put("fill")
        start = time.monotonic()
        result = q.put("overflow", timeout=0.1)
        elapsed = time.monotonic() - start
        self.assertFalse(result)
        self.assertGreaterEqual(elapsed, 0.05)

    def test_capacity_one(self):
        """Queue with capacity=1 works correctly for put/get cycles."""
        q = BoundedQueue(capacity=1)
        for i in range(10):
            self.assertTrue(q.put(i, timeout=1.0))
            self.assertEqual(q.get(timeout=1.0), i)

    def test_size_never_exceeds_capacity(self):
        """Size must never exceed the declared capacity."""
        cap = 3
        q = BoundedQueue(capacity=cap)
        for i in range(cap):
            q.put(i)
        self.assertEqual(q.size(), cap)
        # put with 0 timeout should fail immediately or nearly so
        self.assertFalse(q.put("extra", timeout=0.05))
        self.assertLessEqual(q.size(), cap)


# ===================================================================
# 3. Concurrency correctness (5 cases)
# ===================================================================


class TestConcurrency(unittest.TestCase):
    """Multi-threaded correctness invariants."""

    def test_two_producers_one_consumer(self):
        """2 producers, 1 consumer: all items received exactly once."""
        q = BoundedQueue(capacity=10)
        items_per_producer = 500
        produced = []  # guarded by lock
        consumed = []
        lock = threading.Lock()
        barrier = threading.Barrier(3)  # 2 producers + 1 consumer

        def producer(start_val):
            barrier.wait(timeout=5)
            for i in range(start_val, start_val + items_per_producer):
                with lock:
                    produced.append(i)
                ok = q.put(i, timeout=5.0)
                self.assertTrue(ok)

        def consumer():
            barrier.wait(timeout=5)
            while True:
                item = q.get(timeout=1.0)
                if item is None:
                    break
                with lock:
                    consumed.append(item)

        t1 = threading.Thread(target=producer, args=(0,))
        t2 = threading.Thread(target=producer, args=(items_per_producer,))
        tc = threading.Thread(target=consumer)
        for t in (t1, t2, tc):
            t.start()
        t1.join(timeout=10)
        t2.join(timeout=10)
        # After producers finish, close to signal consumer
        q.close()
        tc.join(timeout=10)

        self.assertEqual(sorted(consumed), sorted(produced))
        self.assertEqual(len(consumed), 2 * items_per_producer)

    def test_one_producer_two_consumers(self):
        """1 producer, 2 consumers: all items received, no duplicates."""
        q = BoundedQueue(capacity=10)
        total = 1000
        consumed = []
        lock = threading.Lock()
        barrier = threading.Barrier(3)

        def producer():
            barrier.wait(timeout=5)
            for i in range(total):
                q.put(i, timeout=5.0)
            q.close()

        def consumer():
            barrier.wait(timeout=5)
            while True:
                item = q.get(timeout=2.0)
                if item is None:
                    break
                with lock:
                    consumed.append(item)

        tp = threading.Thread(target=producer)
        c1 = threading.Thread(target=consumer)
        c2 = threading.Thread(target=consumer)
        for t in (tp, c1, c2):
            t.start()
        for t in (tp, c1, c2):
            t.join(timeout=15)

        self.assertEqual(len(consumed), total)
        self.assertEqual(len(set(consumed)), total)

    def test_four_by_four(self):
        """4 producers, 4 consumers: total in == total out."""
        q = BoundedQueue(capacity=20)
        items_per_producer = 250
        num_producers = 4
        num_consumers = 4
        total = items_per_producer * num_producers
        consumed = []
        lock = threading.Lock()
        barrier = threading.Barrier(num_producers + num_consumers)
        producers_done = threading.Event()

        def producer(pid):
            barrier.wait(timeout=5)
            for i in range(items_per_producer):
                q.put(pid * items_per_producer + i, timeout=5.0)

        def consumer():
            barrier.wait(timeout=5)
            while True:
                item = q.get(timeout=2.0)
                if item is None:
                    break
                with lock:
                    consumed.append(item)

        threads = []
        for pid in range(num_producers):
            t = threading.Thread(target=producer, args=(pid,))
            threads.append(t)
        for _ in range(num_consumers):
            t = threading.Thread(target=consumer)
            threads.append(t)
        for t in threads:
            t.start()
        # Wait for producers
        for t in threads[:num_producers]:
            t.join(timeout=15)
        q.close()
        for t in threads[num_producers:]:
            t.join(timeout=15)

        self.assertEqual(len(consumed), total)

    def test_no_items_lost(self):
        """Producer count exactly equals consumer count."""
        q = BoundedQueue(capacity=5)
        total = 500
        produced_count = threading.atomic = {"count": 0}  # use list for mutability
        consumed_count = {"count": 0}
        lock = threading.Lock()
        barrier = threading.Barrier(4)

        def producer():
            barrier.wait(timeout=5)
            for i in range(total):
                if q.put(i, timeout=5.0):
                    with lock:
                        produced_count["count"] += 1

        def consumer():
            barrier.wait(timeout=5)
            while True:
                item = q.get(timeout=2.0)
                if item is None:
                    break
                with lock:
                    consumed_count["count"] += 1

        p1 = threading.Thread(target=producer)
        p2 = threading.Thread(target=producer)
        c1 = threading.Thread(target=consumer)
        c2 = threading.Thread(target=consumer)
        for t in (p1, p2, c1, c2):
            t.start()
        p1.join(timeout=15)
        p2.join(timeout=15)
        q.close()
        c1.join(timeout=15)
        c2.join(timeout=15)

        self.assertEqual(produced_count["count"], consumed_count["count"])

    def test_no_duplicates(self):
        """No item is received by more than one consumer."""
        q = BoundedQueue(capacity=10)
        total = 1000
        consumed = []
        lock = threading.Lock()
        barrier = threading.Barrier(5)

        def producer():
            barrier.wait(timeout=5)
            for i in range(total):
                q.put(i, timeout=5.0)

        def consumer():
            barrier.wait(timeout=5)
            local = []
            while True:
                item = q.get(timeout=2.0)
                if item is None:
                    break
                local.append(item)
            with lock:
                consumed.extend(local)

        tp = threading.Thread(target=producer)
        consumers = [threading.Thread(target=consumer) for _ in range(4)]
        for t in [tp] + consumers:
            t.start()
        tp.join(timeout=15)
        q.close()
        for t in consumers:
            t.join(timeout=15)

        self.assertEqual(len(consumed), total, "Wrong total count")
        self.assertEqual(len(set(consumed)), len(consumed), "Duplicates detected")


# ===================================================================
# 4. Stress (3 cases)
# ===================================================================


class TestStress(unittest.TestCase):
    """High-contention stress tests."""

    def test_100_threads_10k_items(self):
        """100 threads, 10K items total, must complete within 10 seconds."""
        q = BoundedQueue(capacity=50)
        items_per_producer = 200  # 50 producers * 200 = 10K
        num_producers = 50
        num_consumers = 50
        consumed = []
        lock = threading.Lock()
        barrier = threading.Barrier(num_producers + num_consumers)

        def producer(pid):
            barrier.wait(timeout=10)
            for i in range(items_per_producer):
                q.put(pid * items_per_producer + i, timeout=10.0)

        def consumer():
            barrier.wait(timeout=10)
            local = []
            while True:
                item = q.get(timeout=3.0)
                if item is None:
                    break
                local.append(item)
            with lock:
                consumed.extend(local)

        threads = []
        for pid in range(num_producers):
            threads.append(threading.Thread(target=producer, args=(pid,)))
        for _ in range(num_consumers):
            threads.append(threading.Thread(target=consumer))

        start = time.monotonic()
        for t in threads:
            t.start()
        for t in threads[:num_producers]:
            t.join(timeout=10)
        q.close()
        for t in threads[num_producers:]:
            t.join(timeout=10)
        elapsed = time.monotonic() - start

        self.assertEqual(len(consumed), num_producers * items_per_producer)
        self.assertLess(elapsed, 10.0, f"Took {elapsed:.2f}s, exceeds 10s limit")

    def test_alternating_put_get_no_deadlock(self):
        """50 threads alternating put/get, no deadlock within 10 seconds."""
        q = BoundedQueue(capacity=10)
        barrier = threading.Barrier(50)
        errors = []
        lock = threading.Lock()

        def worker(wid):
            try:
                barrier.wait(timeout=10)
                for i in range(100):
                    q.put(wid * 100 + i, timeout=2.0)
                    q.get(timeout=2.0)
            except Exception as e:
                with lock:
                    errors.append(e)

        threads = [threading.Thread(target=worker, args=(w,)) for w in range(50)]
        start = time.monotonic()
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=10)
        elapsed = time.monotonic() - start

        # Drain any remaining items
        q.close()

        self.assertEqual(errors, [], f"Errors: {errors}")
        self.assertLess(elapsed, 10.0, f"Took {elapsed:.2f}s, possible deadlock")

    def test_rapid_close_reopen_cycles(self):
        """Rapid create/use/close cycles don't crash."""
        for _ in range(100):
            q = BoundedQueue(capacity=5)
            q.put(1)
            q.put(2)
            q.get(timeout=0.1)
            q.close()
            # After close, operations must not raise
            self.assertFalse(q.put("x", timeout=0.01))
            result = q.get(timeout=0.01)
            # Should get remaining item or None
            self.assertIn(result, [2, None])


# ===================================================================
# 5. Trap cases (4 cases)
# ===================================================================


class TestTrapCases(unittest.TestCase):
    """Subtle correctness traps: spurious wakeups, close semantics."""

    def test_spurious_wakeup_correctness(self):
        """Queue works correctly even when notify_all causes extra wakeups.

        We simulate high notify_all pressure by having a dedicated thread
        broadcast on the queue's internal condition variable. The queue
        must still produce correct results under this barrage.
        """
        q = BoundedQueue(capacity=5)
        stop = threading.Event()
        results = []
        lock = threading.Lock()

        # Bombardment thread: call notify_all on every condition we can find
        def bombardier():
            while not stop.is_set():
                # Try to trigger spurious wakeups via the queue's internals.
                # If the queue uses Condition, notify_all is safe but stresses
                # the while-loop guards.
                for attr_name in dir(q):
                    attr = getattr(q, attr_name, None)
                    if isinstance(attr, threading.Condition):
                        try:
                            with attr:
                                attr.notify_all()
                        except Exception:
                            pass
                time.sleep(0.001)

        bomb = threading.Thread(target=bombardier, daemon=True)
        bomb.start()

        # Normal producer/consumer under bombardment
        def producer():
            for i in range(200):
                q.put(i, timeout=5.0)

        def consumer():
            local = []
            while True:
                item = q.get(timeout=2.0)
                if item is None:
                    break
                local.append(item)
            with lock:
                results.extend(local)

        tp = threading.Thread(target=producer)
        tc = threading.Thread(target=consumer)
        tp.start()
        tc.start()
        tp.join(timeout=10)
        q.close()
        tc.join(timeout=10)
        stop.set()
        bomb.join(timeout=2)

        self.assertEqual(sorted(results), list(range(200)))

    def test_close_unblocks_put(self):
        """close() unblocks threads stuck in put(), which then return False."""
        q = BoundedQueue(capacity=1)
        q.put("fill")  # queue is now full
        unblocked = threading.Event()
        put_result = [None]

        def blocked_producer():
            put_result[0] = q.put("blocked", timeout=10.0)
            unblocked.set()

        t = threading.Thread(target=blocked_producer)
        t.start()
        time.sleep(0.1)  # let producer block
        q.close()
        unblocked.wait(timeout=5.0)
        t.join(timeout=5)

        self.assertTrue(unblocked.is_set(), "Producer was not unblocked by close()")
        self.assertFalse(put_result[0], "put() after close() must return False")

    def test_close_unblocks_get_then_drains(self):
        """close() lets get() drain remaining items, then return None."""
        q = BoundedQueue(capacity=10)
        q.put("a")
        q.put("b")
        q.put("c")
        get_results = []
        lock = threading.Lock()
        done = threading.Event()

        def draining_consumer():
            while True:
                item = q.get(timeout=5.0)
                if item is None:
                    break
                with lock:
                    get_results.append(item)
            done.set()

        t = threading.Thread(target=draining_consumer)
        t.start()
        time.sleep(0.05)  # let consumer grab existing items
        q.close()
        done.wait(timeout=5.0)
        t.join(timeout=5)

        # Consumer must have drained all items
        self.assertTrue(done.is_set())
        self.assertEqual(sorted(get_results), ["a", "b", "c"])

    def test_put_after_close_returns_false_immediately(self):
        """put() after close() must return False without blocking."""
        q = BoundedQueue(capacity=10)
        q.close()

        start = time.monotonic()
        result = q.put("nope", timeout=10.0)  # large timeout
        elapsed = time.monotonic() - start

        self.assertFalse(result)
        self.assertLess(elapsed, 1.0, "put() after close() blocked too long")


# ===================================================================
# Custom test runner with summary
# ===================================================================


def run_with_summary():
    """Run all tests and print a summary table."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    categories = [
        ("Functionality", TestFunctionality),
        ("Boundary", TestBoundary),
        ("Concurrency", TestConcurrency),
        ("Stress", TestStress),
        ("Trap Cases", TestTrapCases),
    ]

    for _, cls in categories:
        suite.addTests(loader.loadTestsFromTestCase(cls))

    runner = unittest.TextTestRunner(verbosity=2, stream=sys.stdout)
    result = runner.run(suite)

    # Summary
    total = result.testsRun
    failures = len(result.failures)
    errors = len(result.errors)
    passed = total - failures - errors

    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"  Total:    {total}")
    print(f"  Passed:   {passed}")
    print(f"  Failed:   {failures}")
    print(f"  Errors:   {errors}")
    print("=" * 60)

    for category, cls in categories:
        tests = loader.loadTestsFromTestCase(cls)
        cat_ids = {t.id() for t in tests}
        cat_fail = sum(1 for t, _ in result.failures if t.id() in cat_ids)
        cat_err = sum(1 for t, _ in result.errors if t.id() in cat_ids)
        cat_total = len(cat_ids)
        cat_pass = cat_total - cat_fail - cat_err
        status = "PASS" if cat_fail == 0 and cat_err == 0 else "FAIL"
        print(f"  [{status}] {category}: {cat_pass}/{cat_total}")

    print("=" * 60)

    if failures or errors:
        print("\nFailed/errored tests:")
        for t, _ in result.failures + result.errors:
            print(f"  - {t.id()}")
        print()

    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(run_with_summary())
