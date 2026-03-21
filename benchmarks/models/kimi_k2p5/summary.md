# Benchmark Results — Kimi K2.5

## Experiment Info

| Item | Value |
|------|-------|
| Model | Kimi K2.5 |
| Date | 2026-03-21 |
| Trident Version | 0.0.3 |
| Platform | OpenCode (oh-my-opencode) |
| Protocol | See [PROTOCOL.md](../../PROTOCOL.md) |

---

## #1 LRU Cache

### Test Results

| Category | Without Trident | With Trident |
|----------|:---------------:|:------------:|
| Correctness (10) | 10/10 | 10/10 |
| Boundary (8) | 7/8 | 7/8 |
| Performance (3) | 3/3 | 3/3 |
| Complexity (2) | 2/2 | 2/2 |
| Trap (5) | 5/5 | 5/5 |
| **Total** | **27/28 (96.4%)** | **27/28 (96.4%)** |

Both solutions reject `capacity=0` with `ValueError` — a reasonable defensive design choice that conflicts with the test expectation.

### Performance

| Operations | Without Trident | With Trident |
|------------|:---------------:|:------------:|
| 10K ops/sec | 2,230,415 | 1,945,899 |
| 100K ops/sec | 2,111,431 | 2,080,903 |
| 1M ops/sec | 2,123,312 | 2,118,377 |

Performance is virtually identical (~2.1M ops/sec). The w/o version is 2-5% faster, likely due to `__slots__` optimization on its Node class.

### Code Quality

| Dimension | Without Trident | With Trident |
|-----------|:---------------:|:------------:|
| Capacity validation | `ValueError` | `ValueError` + `isinstance` |
| `__slots__` memory optimization | Yes | No |
| Type checking on input | No | Yes (`isinstance`) |
| Docstrings | None | Complete |
| Lines of code | 75 | 66 |

### Trident Review History

- v1: All dimensions >= 9 on first round. D classified capacity validation as MUST FIX (after skill update). Arbiter approved.
- Note: Before skill v0.0.3 update, D had classified capacity validation as NICE TO HAVE, which resulted in an `AssertionError` crash on `capacity=0`.

---

## #2 Traffic Light (HTML State Machine)

### Code Quality (no automated test suite — architecture comparison)

| Dimension | Without Trident | With Trident |
|-----------|:---------------:|:------------:|
| State encapsulation | Global `let state` (mutable from outside) | IIFE with `const` (private) |
| Input validation | None | 3 validation functions |
| Immutable state return | No (`getState` returns mutable object) | Yes (`Object.freeze`) |
| Pedestrian scheduling | Single flag (may trigger in current cycle) | Double-queue (queued → requested on phase entry) |
| Time overflow handling | None (skips phases if delta > duration) | `while` loop consumes overflow |
| Flash accuracy | Timer accumulation (drift over time) | `Math.floor` calculation (no drift) |
| Lines of code | 933 | 673 |

### Trident Review History

- v1: C:4 / A:5 / S:6 — severely underqualified
- v2: C:7 / A:7 / S:9 — improved but not enough
- v3: C:6 / A:7 / S:9 — correctness regressed
- v4: C:10 / A:10 / S:10 — all dimensions converged

D identified across 4 rounds:
1. Global state pollution (no encapsulation)
2. Missing input validation on `tick()`, `setMode()`, `requestWalk()`
3. Mutable state leaking via `getState()`
4. Pedestrian button triggering in wrong cycle
5. Time overflow skipping phases
6. Flash timer accumulation drift

---

## #3 Bounded Queue (Thread-Safe)

### Test Results

| Category | Without Trident | With Trident |
|----------|:---------------:|:------------:|
| Functionality (6) | 6/6 | 6/6 |
| Boundary (4) | 4/4 | 4/4 |
| Concurrency (5) | 5/5 | 5/5 |
| Stress (3) | 3/3 | 3/3 |
| Trap Cases (4) | 4/4 | 4/4 |
| **Total** | **22/22 (100%)** | **22/22 (100%)** |

### Performance

| Scenario | Without Trident | With Trident |
|----------|:---------------:|:------------:|
| Single-thread 100K ops/sec | 874,505 | 1,002,434 |
| 4 producers / 4 consumers | 279,167 | 183,247 |
| 10 producers / 10 consumers | 160,477 | 120,737 |

Single-thread: w/ Trident is 15% faster. Multi-thread under contention: w/o is 34-53% faster (w/ version has additional validation overhead per operation).

### Code Quality

| Dimension | Without Trident | With Trident |
|-----------|:---------------:|:------------:|
| `time.monotonic()` | No (`time.time()` — NTP drift risk) | Yes |
| Timeout validation | No (negative timeout undefined behavior) | Yes (`ValueError` on negative) |
| Capacity validation | Partial (`capacity < 0` only) | Complete (`capacity < 1`) |
| `is_closed()` method | No | Yes (with TOCTOU documentation) |
| None ambiguity documented | No | Yes |
| API docstrings | None | Complete with examples |
| Lines of code | 74 | 191 |

### Trident Review History

- v1: C:7 / A:8 / S:7 — 5 MUST FIX issues found
- v2: C:9 / A:9 / S:9 — all fixes applied
- v3: C:9 / A:9 / S:9 — conventions refined, SHIP IT

D identified across 3 rounds:
1. `time.time()` → `time.monotonic()` (NTP adjustment vulnerability)
2. `None` return ambiguity (timeout vs closed vs actual None item)
3. Missing `capacity` validation (`capacity=0` causes permanent block)
4. Missing `timeout` validation (negative timeout undefined)
5. No way to distinguish closed state from timeout (`is_closed()` needed)

---

## Overall Analysis

### Pass Rate Comparison

Pass rate alone does not capture Trident's value. Both approaches achieve high pass rates because the models have strong baseline capability for standard problems.

### Where Trident Adds Value

Trident's primary contribution is **production readiness** — the gap between "it works" and "it's shippable":

| Issue Category | Found by Tests | Found by Trident D |
|---------------|:--------------:|:-------------------:|
| Logic correctness | Yes | Yes |
| Edge case handling | Yes | Yes |
| Input validation | Partial | **Always** |
| Encapsulation | No | **Yes** |
| Time function choice | No | **Yes** |
| API design flaws | No | **Yes** |
| State immutability | No | **Yes** |
| Documentation gaps | No | **Yes** |

### When Trident Is Most Effective

1. **State machines** — catches encapsulation leaks, timing drift, overflow
2. **Concurrent code** — catches NTP risk, shutdown semantics, API ambiguity
3. **Complex interactions** — catches cross-component issues tests don't cover

### When Trident Is Least Effective

1. **Canonical algorithms** — models already know the optimal solution (LRU Cache)
2. **Simple CRUD** — not enough design surface for adversarial review to add value
