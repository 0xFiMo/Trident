# Trident Benchmarks

Does adversarial design review actually produce better code?

These benchmarks measure the difference between code produced **with** and **without** Trident, using the same model and the same prompt.

## Benchmarks

| # | Task | Tests | What It Measures |
|---|------|-------|-----------------|
| 1 | [LRU Cache](01-lru-cache/) | Python unit tests (28 cases) | Algorithm correctness, O(1) complexity, edge cases |
| 2 | [Traffic Light](02-traffic-light/) | HTML logic tests (18 cases) + visual | State machine safety, timing, mode transitions |
| 3 | [Bounded Queue](03-bounded-queue/) | Python threading tests (22 cases) | Concurrency correctness, deadlock freedom, shutdown |

## How to Run

See [PROTOCOL.md](PROTOCOL.md) for the full experiment methodology.

Quick start:

```bash
# 1. Pick a benchmark
cd benchmarks/01-lru-cache

# 2. Give prompt.md to your model WITHOUT Trident
#    Save output as solutions/without/solution.py

# 3. Give prompt.md to your model WITH Trident (/tri new)
#    Save output as solutions/with/solution.py

# 4. Run tests
./run.sh solutions/without/solution.py
./run.sh solutions/with/solution.py

# 5. Compare results
```

## Results

### Kimi K2.5 (2026-03-21, Trident v0.0.3)

[Full details](models/kimi_k2p5/summary.md)

#### Pass Rates

| Benchmark | Without Trident | With Trident |
|-----------|:---------------:|:------------:|
| #1 LRU Cache | 27/28 (96%) | 27/28 (96%) |
| #2 Traffic Light | (visual comparison) | (visual comparison) |
| #3 Bounded Queue | 22/22 (100%) | 22/22 (100%) |

#### Performance (ops/sec)

| Benchmark | Scenario | Without Trident | With Trident |
|-----------|----------|:---------------:|:------------:|
| #1 LRU Cache | 1M mixed ops | 2,123,312 | 2,118,377 |
| #3 Bounded Queue | Single-thread 100K | 874,505 | 1,002,434 |
| #3 Bounded Queue | 4P/4C 100K | 279,167 | 183,247 |
| #3 Bounded Queue | 10P/10C 100K | 160,477 | 120,737 |

#### Code Quality Issues Found by Trident D (missed by w/o)

| Issue | #1 LRU | #2 Traffic Light | #3 Queue |
|-------|:------:|:----------------:|:--------:|
| Input validation gaps | - | 3 validators added | timeout + capacity |
| Encapsulation leak | - | IIFE + Object.freeze | - |
| Time function risk | - | flash drift fix | time.monotonic() |
| API design flaw | - | pedestrian double-queue | is_closed() + TOCTOU |
| Overflow handling | - | while-loop consume | - |
| **Trident iterations** | **1** | **4** | **3** |

#### Key Insight

Pass rates don't capture Trident's value. The Discriminator catches **production readiness** issues that tests don't cover: input validation, encapsulation, API semantics, timing correctness, and documentation.

---

### Submit Your Own Results

1. Follow [PROTOCOL.md](PROTOCOL.md) exactly
2. Save all artifacts (conversations, solutions, test output)
3. Create `models/{model-name}/summary.md` using the template
4. Submit a PR
