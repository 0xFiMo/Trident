# Trident Benchmark Protocol

Fair, reproducible comparison of code quality with and without Trident Design Review.

## Experiment Design

### Principle

Same model, same prompt, same task — different process.
The ONLY variable is whether Trident is used.

### Environment Isolation (CRITICAL)

The control group (without Trident) must have ZERO exposure to Trident skills,
agents, or methodology. Skill leakage invalidates the experiment.

| | Environment A (Control) | Environment B (Experiment) |
|---|---|---|
| **Trident installed** | NO | YES |
| **Skills directory** | Empty (.claude/, .opencode/) | Trident installed |
| **Agent definitions** | None | Discriminator + Arbiter |
| **Session** | Fresh, clean | Fresh, clean |
| **Model** | Same (record exact model ID) | Same |
| **Prompt** | prompt.md verbatim | prompt.md via `/tri new` |

### Setup

**Environment A (Control):**
```bash
mkdir -p /tmp/bench-control && cd /tmp/bench-control
# Ensure NO skills are loaded:
# - No .claude/ directory
# - No .opencode/ directory
# - No global skills (~/.claude/skills/ and ~/.config/opencode/skills/ cleared or renamed)
# Start a fresh agent session
```

**Environment B (Experiment):**
```bash
mkdir -p /tmp/bench-trident && cd /tmp/bench-trident
# Install Trident:
cd /path/to/trident && ./install.sh --all
# Start a fresh agent session
```

### Execution Order

Alternate which environment goes first to avoid ordering bias:

| Benchmark | First | Second |
|-----------|-------|--------|
| #1 LRU Cache | Control (A) | Trident (B) |
| #2 Traffic Light | Trident (B) | Control (A) |
| #3 Bounded Queue | Control (A) | Trident (B) |

### Prompt Delivery

**Control (A):**
> Read the prompt.md file, then say:
> "Implement the following. Write production-quality code."

**Experiment (B):**
> `/tri new {task description from prompt.md}`
> After READY: `/tri apply {task-slug}`

### Prohibited Actions

- Do NOT hint at edge cases to either environment
- Do NOT tell Environment A to "think about safety" or "consider boundaries"
- Do NOT show test_*.py to either environment before implementation
- Do NOT modify the prompt based on one environment's results
- Do NOT give follow-up hints like "what about thread safety?"
- Do NOT run the same benchmark twice in the same session

### Result Collection

For each benchmark × environment, save:

```
benchmarks/{NN}-{name}/
├── conversations/
│   ├── without-trident.md    # Full conversation transcript
│   └── with-trident.md       # Full conversation transcript
├── solutions/
│   ├── without/              # Code produced by control
│   └── with/                 # Code produced by experiment
├── results/
│   ├── without-results.txt   # Test suite output
│   └── with-results.txt      # Test suite output
└── summary.md                # Comparison table
```

### Metrics

| Metric | How to Measure | Applies To |
|--------|---------------|------------|
| Pass Rate | test cases passed / total | All |
| Bug Count | test cases failed | All |
| Safety Violations | safety-critical test failures | #2, #3 |
| Performance | ops/sec or timing | #1, #3 |
| Deadlock Free | completes within timeout | #2, #3 |
| Visual Bugs | manual observation count | #2 |

### Reporting

Use the summary.md template in each benchmark directory.
Final results aggregated in benchmarks/README.md.

### Reproducibility

Anyone can reproduce this experiment:
1. Clone the trident repo
2. Follow this protocol exactly
3. Record model ID, date, platform
4. Submit results via PR to `benchmarks/results/`
