---
name: trident
description: "Trident Design Review — adversarial design workflow with Generator, Discriminator, and Arbiter roles (Triforce). Combines GAN-style iteration, 7-dimension scoring, and Three Strikes implementation verification. Use when designing algorithm changes, architecture decisions, state machine modifications, or any non-trivial design that benefits from adversarial evaluation. Triggers on keywords like 'design review', 'trident', 'adversarial review', 'design iteration'."
---

# Trident Design Review 🔱

A design review methodology built on three pillars:

```
        ▲ Generator
       ╱ ╲     Design + Implement
      ╱   ╲
     ▲─────▲
Discriminator  Arbiter
Review + Verify  Arbitrate + Monitor
```

| Pillar | Origin | Principle |
|--------|--------|-----------|
| **Triforce** | Western | Three roles in balance — Generator, Discriminator, Arbiter |
| **Three Strikes** | Chinese proverb | Maximum 3 rounds, then hard stop |
| **GAN** | AI | Adversarial iteration produces quality through tension |

**Generator** produces designs, **Discriminator** evaluates them across 7 dimensions, and **Arbiter** prevents collusion. Converges when all dimension thresholds are met, then transitions to implementation with Three Strikes verification.

## Full Lifecycle

```
/tri new     → Design iteration (G ↔ D ↔ A) → READY
/tri apply   → Implement (Three Strikes) → Verified
/tri status  → Show active and completed tasks
/tri archive → Move completed task to archive
```

---

## 1. Triforce — Three Roles

| Role | Analogy | Memory | File | Responsibility |
|------|---------|--------|------|----------------|
| **Generator** | GAN-G | Yes (main session) | `generator.md` | `/tri new`: produce designs, iterate. `/tri apply`: implement. NEVER implement during `/tri new`. |
| **Discriminator** | GAN-D | Yes (session_id continuity) | `discriminator.md` | Multi-dimensional scoring, accumulate codebase knowledge, verify implementation |
| **Arbiter** | Independent eval metric | **None** (fresh each time) | None (output recorded in generator.md) | Monitor G/D interaction quality, prevent collusion |

### Isolation Rules (MANDATORY)

- Generator MUST NOT write to `discriminator.md`
- Discriminator MUST NOT write to `generator.md`
- Arbiter MUST NOT write to any file EXCEPT the `.done` signal file (other output recorded by Generator)

### Agent Mapping (Platform-Specific)

| Role | Default Mode | Agent Mode | Agent Definition |
|------|-------------|-----------|-----------------|
| **Generator** | You (main session) | `@"trident-generator (agent)"` | `.claude/agents/trident-generator.md` |
| **Discriminator** | Background agent (oracle) | `@"trident-discriminator (agent)"` | `.claude/agents/trident-discriminator.md` |
| **Arbiter** | Background agent (oracle, fresh) | `@"trident-arbiter (agent)"` | `.claude/agents/trident-arbiter.md` |

**Default Mode:** Generator is the main session agent. D and A are background agents.
**Agent Mode:** All three roles can be spawned as independent agents for multi-agent architectures.

#### OpenCode Invocation
```python
# Discriminator (first round)
task(subagent_type="oracle", load_skills=["{domain-skill}"],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)
# Store session_id for continuation rounds

# Discriminator (continuation)
task(session_id="{stored_session_id}", load_skills=[],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)

# Arbiter (always fresh — no session_id)
task(subagent_type="oracle", load_skills=[],
     description="Trident Arbiter review", prompt="...", run_in_background=true)
```

#### Discriminator Session Recovery

If the Discriminator's session_id expires (context compaction, platform restart, etc.):
1. Start a FRESH Discriminator session (no session_id)
2. Include `discriminator.md` content in the prompt — this contains D's accumulated knowledge
3. Summarize all previous version scores from `generator.md` in the prompt
4. D can rebuild its context from these files — session loss is recoverable

```python
# Recovery — fresh session with accumulated knowledge
task(subagent_type="oracle", load_skills=["{domain-skill}"],
     description="Trident Discriminator v{N} (session recovery)",
     prompt="""
You are a DISCRIMINATOR resuming after session loss. Your previous
knowledge is preserved in discriminator.md (included below).

## Your Previous Knowledge
{paste full content of discriminator.md}

## Score History
{paste score table from generator.md}

## Current Design (v{N})
{latest design}

Continue from where you left off. Do NOT re-verify facts already
marked as verified in your knowledge base.
""",
     run_in_background=true)
# Store NEW session_id for future rounds
```

#### Claude Code Invocation
```text
# Discriminator
@"trident-discriminator (agent)" evaluate the design in .trident/{task-slug}/generator.md

# Arbiter
@"trident-arbiter (agent)" assess interaction quality in .trident/{task-slug}/
```

Agent definitions are in `.claude/agents/trident-{generator,discriminator,arbiter}.md`. Install globally at `~/.claude/agents/` for cross-project use.

### Role Participation by Phase

| Phase | Generator | Discriminator | Arbiter |
|-------|-----------|---------------|---------|
| **Design** (`new`) | Produce designs | Score 7 dimensions | MANDATORY final review before READY + conditional mid-iteration |
| **Apply** (`apply`) | Round 1-3: Implement + Fix | Round 1-2: Review + Re-review | MANDATORY final review after each D PASS + Round 3 collaborative |
| **Archive** (`archive`) | Organize + archive | — | — |

---

## 2. Seven-Dimension Scoring Framework

```
┌─────────────────────────┬────────┬──────────────────────────────────────────┐
│ Dimension               │ Gate   │ Definition                               │
├─────────────────────────┼────────┼──────────────────────────────────────────┤
│ Correctness             │ ≥ 9    │ Logic correct, timing correct, no crash, │
│                         │        │ no unhandled exceptions on any input     │
│ Algorithmic Soundness   │ ≥ 9    │ Behavior under all scenarios, boundary   │
│                         │        │ analysis, cross-component interaction    │
│ Safety                  │ ≥ 9    │ Backward compat, null-safe, fail-safe,   │
│                         │        │ defensive input validation, graceful     │
│                         │        │ handling of invalid/edge-case inputs     │
│ Measurability           │ ≥ 9    │ Max verification with available resources│
│ Minimality              │ ≥ 9    │ Minimal change surface, no new patterns  │
│ Testability             │ ≥ 9    │ Test coverage, edge cases, executable    │
│ Conventions             │ ≥ 9    │ Matches existing codebase patterns       │
└─────────────────────────┴────────┴──────────────────────────────────────────┘
```

### Blocking Rules

- **Any dimension < 9** → BLOCKED. ALL 7 dimensions must score ≥ 9 to reach READY.
- Prioritize fixing the lowest-scoring dimensions first.
- All 7 dimensions at ≥ 9 → **READY**.

### MUST FIX vs NICE TO HAVE Classification (MANDATORY)

Discriminator MUST classify every issue. Use these rules — do NOT use judgment calls:

**Always MUST FIX (no exceptions):**
- Missing input validation on public API parameters
- Unhandled exception paths (any input that causes crash/assert/uncaught error)
- Missing boundary checks (empty, zero, negative, overflow)
- Race conditions, deadlocks, data corruption in concurrent code
- Security vulnerabilities (injection, unvalidated input passed to system calls)
- Violation of stated API contract (return type, behavior mismatch)

**Always NICE TO HAVE:**
- Performance optimizations (`__slots__`, caching, micro-optimizations)
- Additional convenience methods (`__len__`, `__repr__`, `is_closed`)
- Documentation improvements (docstrings, type hints completeness)
- Style/naming preferences that don't affect correctness

**The golden rule: if an issue can cause a crash, data loss, or incorrect behavior
under ANY valid or edge-case input, it is MUST FIX. Period.**

"The spec doesn't mention this input" is NOT a valid reason to classify input
validation as NICE TO HAVE. Production code must handle all inputs gracefully,
not just the ones the spec explicitly mentions.

### Measurability Grading (adapts to task type)

| Score | Available Verification |
|-------|----------------------|
| 9-10 | Golden data regression + quantified FPR/FNR delta |
| 7-8 | Unit test asserts + numerical verification |
| 5-6 | Paper analysis — exhaustive path enumeration + state table |
| 3-4 | Only "should be correct" — unacceptable |
| 1-2 | Blind change — blocking |

### Task-Type Weight Adjustment

The Generator MUST declare task type in `generator.md` Meta section. Discriminator adjusts emphasis accordingly:

| Task Type | Elevated Dimensions | Rationale |
|-----------|-------------------|-----------|
| Algorithm design | Algorithmic Soundness, Measurability | Novel logic needs rigorous validation |
| Refactoring | Minimality, Safety | Behavior must not change |
| Hotfix | Correctness, Safety | Speed matters, but must not break |
| New feature | Testability, Algorithmic Soundness | Long-lived code needs coverage |

---

## 3. Convergence Flow

```
Generator produces v1
      │
      ▼
Discriminator scores (7 dims) ─── All ≥ 9? ─── YES ──┐
      │                                                │
      NO                                               │
      │                                                │
      ▼                                                │
Generator iterates v(N+1) based on feedback            │
      │                                                │
      ▼                                                │
 Trigger Arbiter? ── YES ──► Arbiter reviews ──┐       │
      │                         │              │       │
      NO                   meta-feedback       │       │
      │                         │              │       │
      └─────────────────────────┘              │       │
                                               ▼       ▼
                                          Arbiter Final Review (MANDATORY)
                                               │
                                          PASS ──→ READY
                                          FAIL ──→ Continue iterating
```

### Efficiency Rules (learned from practice)

- **9+ on all dimensions required to reach READY** — do not iterate just to chase 10s, but if work genuinely deserves 10, score it 10. Be honest, not deflating.
- First round: strict (find architectural issues) — use Oracle
- Later rounds: focused (verify previous issues resolved) — use session_id continuation
- If 3+ rounds yield no score improvement → consult Arbiter to determine if the design has fundamental issues. Do NOT force READY — escalate to user if genuinely stuck.

---

## 4. Arbiter Trigger Conditions

Arbiter is invoked at READY and may also be invoked mid-iteration:

**MANDATORY trigger (cannot skip):**
1. **About to READY** → Arbiter MUST review before finalizing. If Arbiter rejects, continue iterating. This is NOT optional.

**Conditional triggers (invoke when detected):**
2. **Discriminator gives all 9+ for 2 consecutive rounds** → possible leniency
3. **Generator rejects Discriminator's suggestion** → need arbitration on who is correct
4. **Score jumps ≥ 3 points in a single round** → possible scoring standard shift

### Arbiter Prompt Template

```
You are an ARBITER reviewing the interaction quality between a Generator
and Discriminator in a Trident design review process.

You do NOT evaluate the design itself. You evaluate the PROCESS.

## Interaction History
{paste version history + feedback from generator.md}

## Your Task
1. Is the Discriminator becoming more lenient over iterations? (score inflation)
2. Did the Generator skip or dismiss valid feedback without evidence?
3. Are there blind spots neither G nor D addressed?
4. Is the convergence genuine or artificial?

## Output
- Process Quality: 1-10
- Issues Found: list
- Recommendation: READY / ITERATE / RESET DISCRIMINATOR
```

---

## 5. File Structure

```
.trident/{task-slug}/
├── generator.md        # Design + version history + D/A feedback
├── discriminator.md    # D's accumulated knowledge
├── tasks.md            # Implementation tasks (created by /tri apply)
├── apply-log.md        # Round log with scores and fixes (created by /tri apply)
└── .done               # Signal file: created by D/A on completion, deleted before each invocation
```

### generator.md Template

```markdown
# {Task Title} — Trident Design Review

## Meta
- Task: {bug/feature description}
- Task Type: {algorithm | refactoring | hotfix | new-feature}
- Root Cause: {if applicable}
- Status: iterating | ready | implementing | done
- Current Version: v{N}
- Score History:

| Dimension | v1 | v2 | ... |
|-----------|----|----|-----|
| Correctness | _ | _ | |
| Algorithmic Soundness | _ | _ | |
| Safety | _ | _ | |
| Measurability | _ | _ | |
| Minimality | _ | _ | |
| Testability | _ | _ | |
| Conventions | _ | _ | |
| **Verdict** | | | |

## Context for Review

### Modified Code (before)
{code snippets of functions being changed — BEFORE modification}

### Related Code (not modified)
{code that constrains or interacts with the change}

### Pattern Reference
{similar patterns in codebase that this change should follow}

### Verification Checklist
- [ ] {specific question D must answer}
- [ ] {specific question D must answer}

## Version History

### v1 — {title}
#### Design
{complete design description}

#### Discriminator Feedback (v1)
| Dimension | Score | MUST FIX | NICE TO HAVE |
|-----------|-------|----------|--------------|

#### Arbiter Evaluation
{arbiter output — MANDATORY before READY, optional during iteration}
```

### discriminator.md Template

```markdown
# Discriminator Knowledge Base — {Task Slug}

## Verified Facts
- {fact} ✓ (verified in v{N})

## Codebase Patterns Learned
- {pattern description} (v{N})

## My Previous Assessments
### v{N} — {summary}
| Dimension | Score |
|-----------|-------|
| Correctness | _ |
| Algorithmic Soundness | _ |
| Safety | _ |
| Measurability | _ |
| Minimality | _ |
| Testability | _ |
| Conventions | _ |

## Known Blind Spots
- {area not yet verified}
```

### tasks.md Template

```markdown
# Implementation Tasks — {Task Slug}

Generated from Trident design v{N} (READY).

## Summary
{one-line description of what this change does}

## Design Reference
See `generator.md` for full design, scoring history, and context.

## Tasks

- [ ] {File: path/to/file.h — Description of change}
- [ ] {File: path/to/file.cc — Description of change}
- [ ] {File: tests/path/test.cc — Create test file with N test cases}
- [ ] {File: tests/CMakeLists.txt — Register new test}
- [ ] {Verify: build passes}
- [ ] {Verify: tests pass}
```

### apply-log.md Template

```markdown
# Apply Log — {Task Slug}

Design: v{N} (READY)
Started: {YYYY-MM-DD}

## Round 1 — Generator Implements + Discriminator Reviews
### Implementation
- [ ] Task 1: {description}
- [ ] Task 2: {description}
- Build: ⏳ | Tests: ⏳

### Discriminator Review
- Reviewer: Discriminator (session: {session_id})
- Verdict: ⏳
- Issues: {list or "None"}

| Dimension | Score |
|-----------|-------|
| Correctness | _ |
| Algorithmic Soundness | _ |
| Safety | _ |
| Measurability | _ |
| Minimality | _ |
| Testability | _ |
| Conventions | _ |

## Round 2 — Generator Fixes + Discriminator Re-reviews (if needed)
### Fixes Applied
{list of issues fixed from Round 1, or "Skipped — passed in Round 1"}

### Discriminator Re-review
- Verdict: ⏳
- Issues: {list or "None"}

| Dimension | Score |
|-----------|-------|
| Correctness | _ |
| Algorithmic Soundness | _ |
| Safety | _ |
| Measurability | _ |
| Minimality | _ |
| Testability | _ |
| Conventions | _ |

## Round 3 — Arbiter + Generator Collaborate (if needed)
### Arbiter Review
- Reviewer: Arbiter (fresh — no session)
- Verdict: ⏳
- Issues: {list or "None"}

| Dimension | Score |
|-----------|-------|
| Correctness | _ |
| Algorithmic Soundness | _ |
| Safety | _ |
| Measurability | _ |
| Minimality | _ |
| Testability | _ |
| Conventions | _ |

### Collaborative Fixes
{list of fixes made with Arbiter, or "Skipped — passed in Round {1|2}"}
```

### Language Rules

**Internal files (agent-to-agent) → English ONLY:**
- `generator.md`, `discriminator.md`, `tasks.md`, `apply-log.md`
- These are consumed by LLMs — English gives better token efficiency and comprehension

**User-facing output → Match the user's language:**
- Convergence Report, Completion Report, `/tri status` output, Archive Report
- Progress tracking messages and todo items
- All reports, summaries, explanations, and prompts shown to the user
- Detect the user's language from their input and respond in the same language

### File Rules

- Only keep latest 2 versions in full detail; compress earlier versions to summary
- Generator.md is the single source of truth for design history

---

## 6. Discriminator Prompt Template

### First Round (no session_id)

```
You are a DISCRIMINATOR in a Trident Design Review.
Evaluate the proposed design across 7 dimensions. Be HARSH but FAIR.

## Scoring (per dimension, 1-10)
- Correctness: Logic correct, timing correct, no crash, no unhandled exceptions on any input
- Algorithmic Soundness: Behavior under all scenarios, boundary analysis, interactions
- Safety: Backward compat, null-safe, fail-safe, defensive input validation, graceful handling of invalid/edge-case inputs
- Measurability: Verification coverage with available resources
- Minimality: Change surface area, no unnecessary new patterns
- Testability: Test coverage, edge cases, executability
- Conventions: Matches existing codebase patterns

## Gate Thresholds
ALL dimensions ≥ 9. No exceptions.

## Rules
- If ANY dimension < 9: BLOCKED. List all dimensions below 9 with specific issues.
- Score honestly: if work genuinely deserves 10, give 10. Do not deflate scores.
- For each dimension: cite specific method names, line numbers, data flow.
- You MAY grep the codebase to verify claims in the design doc.

## MUST FIX vs NICE TO HAVE Classification
Classify EVERY issue. Use these rules — do NOT use judgment calls:

Always MUST FIX (no exceptions):
- Missing input validation on public API parameters
- Unhandled exception paths (any input that causes crash/assert/uncaught error)
- Missing boundary checks (empty, zero, negative, overflow)
- Race conditions, deadlocks, data corruption in concurrent code
- Security vulnerabilities (injection, unvalidated input passed to system calls)
- Violation of stated API contract (return type, behavior mismatch)

Always NICE TO HAVE:
- Performance optimizations (__slots__, caching, micro-optimizations)
- Additional convenience methods (__len__, __repr__)
- Documentation improvements (docstrings, type hints completeness)
- Style/naming preferences that don't affect correctness

Golden rule: if an issue can cause a crash, data loss, or incorrect behavior
under ANY input, it is MUST FIX. "The spec doesn't mention it" is NOT a valid
reason to classify input validation as NICE TO HAVE.

## Bug Context
{from generator.md}

## Proposed Design
{from generator.md current version}

## Verification Checklist (you MUST answer each)
{from generator.md}

## Output Format
| Dimension | Score | MUST FIX | NICE TO HAVE |
|-----------|-------|----------|--------------|

Verdict: READY / ITERATE (list blocking issues)

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: <READY or ITERATE>" > .trident/{task-slug}/.done
This signals the Generator that your evaluation is complete.
```

### Continuation Rounds (WITH session_id)

```
Generator has submitted v{N} addressing your previous feedback.

## Changes from v{N-1}
{diff table from generator.md}

## Your Previous Issues
{list from previous round}

## Task
1. Verify each previous MUST FIX is resolved
2. Score all 7 dimensions for v{N}
3. Identify any NEW issues
4. Update your discriminator.md knowledge base

Do NOT re-verify issues you already confirmed in previous rounds.

If you LOWER a score from a previous round, you MUST explain why:
- New issue introduced by the fix? → state what changed and what broke
- Missed in previous round? → acknowledge and explain why you missed it
- Score regression without explanation is NOT allowed

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: <READY or ITERATE>" > .trident/{task-slug}/.done
This signals the Generator that your evaluation is complete.
```

---

## 7. Design Workflow — `/tri new`

### Smart Behavior

`/tri new {description}` is smart:
- If `.trident/{task-slug}/` does NOT exist → **create new** design review
- If `.trident/{task-slug}/` already exists → **continue** iterating from current version

### Step 1: Auto-Slug and Initialize

**Auto-generate task slug from the user's description:**
Convert to kebab-case: "fix intrusion FSM false positive" → `fix-intrusion-fsm-false-positive`.
Do NOT ask the user to confirm the slug. Just use it.

If no description provided, ask the user ONCE, then auto-slugify.

**Initialize (new task only):**

```bash
mkdir -p .trident/{task-slug}
```

Create `generator.md` from template. Fill Meta, Context, v1 Design.
Create empty `discriminator.md` from template.

**YOU ARE THE GENERATOR. Start working immediately after initialization.**
Do NOT tell the user to run `/tri new` — you are ALREADY executing it.

### Progress Tracking (MANDATORY for /tri new)

Create a todo list IMMEDIATELY after initialization to track each design
iteration. Update it in real-time as G and D work. The user must see exactly
where the process is at any moment.

**Format — one item per action, with scores and specific issues:**

```
- [x] v1: G produces design (root cause + proposed fix)
- [x] v1: D scores — ITERATE
         | Dimension             | Score |
         |-----------------------|-------|
         | Correctness           |   9   |
         | Algorithmic Soundness |   7   | ← MUST FIX: transient suppression during SM warmup
         | Safety                |   9   |
         | Measurability         |   8   |
         | Minimality            |  10   |
         | Testability           |   8   |
         | Conventions           |   9   |
- [x] v2: G addresses AlgoSound — adds m_infOdometer>15 warmup bypass
- [x] v2: D scores — all ≥ 9, ready for Arbiter Final Review
- [x] Arbiter Final Review: Process quality 9/10 — READY ✅
```

**Rules:**
- Mark `in_progress` when starting each step, `completed` when done
- Include ALL 7 dimension scores after every D evaluation
- Show which dimensions are below gate with the specific issue
- `/tri new` has NO round limit — G and D iterate until convergence
- Add Arbiter entries only when triggered (not every round)

### Step 2: Submit to Discriminator and Wait via Heartbeat

**Selecting domain skills for the Discriminator:**

Load skills that give D codebase-specific knowledge. Choose based on the task:
- If working on a specific framework/language → load that skill (e.g., `cpp-expert`, `wifi-sensing-expert`)
- If no domain skill exists → use `load_skills=[]` (D will rely on grep/read)
- Only load skills for the FIRST round — continuation rounds use `load_skills=[]` (D already has context)

```python
# 1. Clear previous signal
bash("rm -f .trident/{task-slug}/.done")

# 2. Fire background task
result = task(
    subagent_type="oracle",
    load_skills=["{relevant-domain-skill}"],
    description="Trident Discriminator v{N}",
    prompt="{discriminator prompt with design}",
    run_in_background=true
)
# Store session_id for continuation rounds
discriminator_session_id = result.session_id

# 3. Wait for Discriminator to create .done signal file (up to 5 min)
# Use platform-agnostic heartbeat (see "Heartbeat Invocation" above)
bash("{heartbeat} {task-slug} 300")

# 4. Collect full results
output = background_output(task_id=result.task_id)
```

**Heartbeat Wait Pattern (MANDATORY):**

After firing any background agent (Discriminator or Arbiter), use heartbeat.sh
to wait for completion. The background agent creates `.trident/{task-slug}/.done`
when finished. heartbeat.sh polls for this file every 3 seconds.

**Heartbeat Invocation (platform-agnostic):**

Choose based on what shell is available. No external dependencies needed:

```bash
# Auto-detect: if bash exists → use .sh, otherwise → use .ps1
if command -v bash &>/dev/null; then
  HEARTBEAT="$(find . ~/.config ~/.claude -name heartbeat.sh -path '*/trident/*' 2>/dev/null | head -1)"
  bash "$HEARTBEAT" {task-slug} 300
else
  powershell -File "$(Get-ChildItem -Recurse -Filter heartbeat.ps1 | Select -First 1)" -TaskSlug "{task-slug}" -Timeout 300
fi
```

All heartbeat calls in this document use `{heartbeat}` as placeholder.
Replace with the correct command for your platform:

| Platform | `{heartbeat}` replacement |
|----------|--------------------------|
| Linux/macOS | `bash /path/to/heartbeat.sh` |
| Windows | `powershell -File /path/to/heartbeat.ps1 -TaskSlug` |

```
Generator                          Background Agent
   |                                     |
   +-- rm .done                          |
   +-- fire task ----------------------->+-- starts working
   +-- bash heartbeat.sh (blocks)        |   reads code, scores
   |        polling .done ...            |   writes discriminator.md
   |        polling .done ...            +-- echo verdict > .done
   |        .done found!                 |
   +-- background_output() ------------>result
   +-- process feedback, continue
```

This pattern is platform-agnostic and works on both OpenCode and Claude Code.

**Heartbeat Timeout Recovery:**

If `heartbeat.sh` exits with code 1 (timeout — `.done` not created within 5 min):
1. Check if the background task is still running via `background_output(task_id, block=false)`
2. If still running → increase timeout and retry: `{heartbeat} {task-slug} 600`
3. If task completed but forgot `.done` → collect results directly via `background_output()`
4. If task failed/crashed → report error to user, suggest re-firing the background agent

### Step 3: Process Feedback

1. Read the Discriminator output from `background_output()` and `discriminator.md`
2. Record scores in generator.md version history
3. Check gate thresholds
4. If NOT all ≥ 9 → iterate design, submit v(N+1) with session_id continuation
5. Check conditional Arbiter triggers (leniency, rejection, score jump)
6. If all ≥ 9 → proceed to Step 4 (Arbiter Final Review)

### Step 4: Arbiter (conditional — mid-iteration)

If any conditional trigger fires during iteration, invoke Arbiter:

```python
bash("rm -f .trident/{task-slug}/.done")
result = task(
    subagent_type="oracle",
    load_skills=[],
    description="Trident Arbiter mid-review",
    prompt="{arbiter prompt with interaction history}",
    run_in_background=true
)
bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

Process Arbiter feedback, continue iterating.

### Step 5: Arbiter Final Review (MANDATORY before READY)

When Discriminator scores all ≥ 9, the Arbiter MUST do a final review before
READY. This is NOT optional — it prevents G/D collusion and catches blind spots.

```python
bash("rm -f .trident/{task-slug}/.done")
result = task(
    subagent_type="oracle",
    load_skills=[],
    description="Trident Arbiter Final Review",
    prompt="""
You are the ARBITER performing the MANDATORY final review before READY.

## Interaction History
{paste version history + all D feedback from generator.md}

## Current Design (final version)
{latest design from generator.md}

## Your Task
1. Is the Discriminator becoming more lenient over iterations? (score inflation)
2. Did the Generator skip or dismiss valid feedback without evidence?
3. Are there blind spots neither G nor D addressed?
4. Is the convergence genuine or artificial?
5. Does the design actually solve the stated problem?

## Output
- Process Quality: 1-10
- Issues Found: list
- Recommendation: READY / ITERATE (with specific issues to address)

## Signal Completion
echo "VERDICT: <READY or ITERATE>" > .trident/{task-slug}/.done
""",
    run_in_background=true
)
bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

**If Arbiter says READY** → proceed to Step 6.
**If Arbiter says ITERATE** → address Arbiter's issues, re-submit to Discriminator, iterate.

### Step 6: Finalize Design (HARD STOP — design only, no implementation)

When Discriminator scores all ≥ 9 AND Arbiter approves:
1. Update generator.md Status to `ready`
2. Record final scores
3. Produce the Convergence Report (see below)
4. **STOP. Do NOT proceed to implementation.**

**CRITICAL BOUNDARY: `/tri new` ends here. The lifecycle is strictly sequential:**
```
/tri new → design only → READY → STOP
                                     ↓
                              user decides when
                                     ↓
/tri apply → implement → verify → done → STOP
                                          ↓
                                   user decides when
                                          ↓
/tri archive → archive → suggest skill extraction → STOP
```

**The Generator MUST NOT:**
- Implement any code during `/tri new`
- Create `tasks.md` or `apply-log.md` during `/tri new`
- Start `/tri apply` automatically after READY
- Skip ahead in the lifecycle without the user explicitly invoking the next command

**The Generator MUST:**
- Output the Convergence Report
- End with: "Run `/tri apply {task-slug}` to implement this design."
- Wait for the user to invoke `/tri apply`

### Convergence Report (MANDATORY)

After reaching READY, the Generator MUST produce a comprehensive design summary.
This is NOT optional — the user needs to understand the design at a glance.

**The report MUST include ALL of the following sections:**

#### 1. Status + Score History

```
## Design Converged 🔱

**Task:** {task-slug}
**Status:** ready
**Iterations:** {N} versions to convergence

### Score History
| Dimension             | v1 | v2 |
|-----------------------|----|----|
| Correctness           |  9 |  9 |
| Algorithmic Soundness |  7 |  9 |
| Safety                |  9 |  9 |
| Measurability         |  8 |  9 |
| Minimality            | 10 | 10 |
| Testability           |  8 |  9 |
| Conventions           |  9 |  9 |
| **Verdict**           | ITERATE | **READY** |

### Arbiter Final Review
Process quality: {score}/10 — READY
```

#### 2. Design Summary

One paragraph describing what the design does and why, PLUS a key-point table:

```
| Item | Detail |
|------|--------|
| Problem | {what is broken / what is missing} |
| Root Cause | {why it happens} |
| Fix | {what the design does to solve it} |
| Scope | {which modules/files are affected} |
| Risk | {what could go wrong, or "Low — backward compatible"} |
```

For modification tasks (bugfix, refactoring), add Before/After columns:

```
| Item | Before | After |
|------|--------|-------|
| Behavior | {broken behavior} | {fixed behavior} |
| Guard | {none / insufficient} | {new guard description} |
| Data Flow | {isolated} | {cross-checked} |
```

#### 3. ASCII Architecture Diagram (REQUIRED)

Show WHERE in the system the change lives and HOW data flows through it.
Same quality expectation as the `/tri apply` completion report.

#### 4. Change Surface

List every file that will be modified/created, with one-line descriptions.
This previews what `/tri apply` will do.

#### 5. Next Step

```
Run `/tri apply {task-slug}` to implement this design.
```

---

## 8. Apply Workflow — `/tri apply` (Three Strikes)

Converts a READY design into implementation with **Three Strikes** verification.

> Three Strikes — things shall not exceed three. If three rounds cannot complete the work, escalate.

```
Round 1: Generator implements all tasks
              |
              v
         Discriminator reviews (session continuity from design phase)
              |
         D FAIL ──→ Round 2 (consumes round)
         D PASS ──→ Arbiter Final Review (MANDATORY)
                       |
                  A PASS ──→ Done ✅
                  A FAIL ──→ G fixes A's issues
                               |
                               v
                          Re-submit to D+A (still Round 1, does NOT consume round)

Round 2: Generator fixes D's issues
              |
              v
         Discriminator re-reviews (same session)
              |
         D FAIL ──→ Round 3 (consumes round)
         D PASS ──→ Arbiter Final Review (MANDATORY)
                       |
                  A PASS ──→ Done ✅
                  A FAIL ──→ G fixes, re-submit D+A (still Round 2)

Round 3: Arbiter (fresh) + Generator collaborate (last chance)
              |
         Arbiter reviews, Generator fixes interactively
              |
         A PASS ──→ Done ✅
         A FAIL ──→ G fixes, re-submit to A (still Round 3)
                       |
                  (max 3 fix attempts in Round 3, then hard stop ❌)

IMPORTANT: Only D FAIL consumes a round. A FAIL does NOT consume a round —
Generator fixes the issues and re-submits within the same round.
Round 3 has a 3-attempt limit to prevent infinite loops.
```

### Progress Tracking (MANDATORY for /tri apply)

Create a todo list IMMEDIATELY to track each round. Update in real-time.

**Format — one item per action, with scores and specific issues:**

```
- [x] Round 1: G implements 7/7 tasks — build OK
- [x] Round 1: D reviews — FAIL
         | Dimension             | Score |
         |-----------------------|-------|
         | Correctness           |   9   |
         | Algorithmic Soundness |   9   |
         | Safety                |   7   | ← MUST FIX: null check missing
         | Measurability         |   8   |
         | Minimality            |  10   |
         | Testability           |   8   |
         | Conventions           |   9   |
- [x] Round 1: D FAIL → Round 2 (round consumed)
- [x] Round 2: G fixes Safety — adds null guard on m_presenceSM
- [x] Round 2: D re-reviews — PASS (all ≥ 9)
- [x] Round 2: Arbiter Final Review — FAIL (missed edge case in test)
- [x] Round 2: G fixes Arbiter's issue (still Round 2, not consumed)
- [x] Round 2: D re-reviews — PASS (all ≥ 9)
- [x] Round 2: Arbiter Final Review — PASS, process quality 9/10 ✅
- [ ] (Round 3 skipped — passed in Round 2)
```

**Rules:**
- Mark `in_progress` when starting each step, `completed` when done
- Include ALL 7 dimension scores after every D/A evaluation
- Show which dimensions are below gate with the specific issue
- If passed early (Round 1 or 2), mark Round 3 as skipped
- Show implementation task count: "G implements N/M tasks"

### Precondition

`generator.md` must have `Status: ready`. If not, reject with: "Design has not converged yet. Run `/tri new` to continue iteration."

### Step 1: Select task

If task-slug is provided, use it. Otherwise:
- If only one task has `Status: ready`, auto-select
- If multiple, list them and ask user to choose
- If none, report: "No tasks ready for implementation."

### Step 2: Generate tasks.md + apply-log.md

Read the final version from `generator.md` and extract implementation tasks:

- Each file change → one task with file path and description
- Each test file → one task
- Build verification → one task
- Test execution → one task

Write `tasks.md` and `apply-log.md` to `.trident/{task-slug}/`.
Update `generator.md` Status to `implementing`.

### Step 3: Round 1 — Generator Implements + Discriminator Reviews

**Generator implements all tasks:**

For each pending task in `tasks.md`:
1. Show which task is being worked on: "Working on task N/M: {description}"
2. Make the code changes
3. Keep changes minimal and scoped to each task
4. Mark task complete: `- [ ]` → `- [x]`
5. Continue to next task

After all tasks:
- Run build (if build command available)
- Run tests (if test command available)
- Update apply-log.md Round 1 section

**Pause if:**
- Task is unclear → ask for clarification
- Implementation reveals a design issue → suggest updating design (may need another round)
- Error or blocker encountered → report and wait for guidance

**Discriminator reviews implementation:**

```python
bash("rm -f .trident/{task-slug}/.done")

result = task(
    session_id="{discriminator_session_id}",  # Reuse from design phase
    load_skills=[],
    description="Trident Round 1 Review",
    prompt="""
You are reviewing the IMPLEMENTATION of a Trident design (Round 1 of 3).

## Design Spec
{full design from generator.md final version}

## Implementation Summary
{list of files changed and tasks completed}

## Your Task
1. Read the actual code changes (grep/read the modified files)
2. Compare against the design spec — does the code match the design EXACTLY?
3. Score the implementation across 7 dimensions
4. List specific issues to fix (if any)

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: PASS or FAIL" > .trident/{task-slug}/.done

## Output
| Dimension | Score | Issues |
|-----------|-------|--------|

Verdict: PASS (all gates met) / FAIL (list specific issues to fix)
""",
    run_in_background=true
)

bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

```text
# Claude Code
@"trident-discriminator (agent)" review implementation in .trident/{task-slug}/ (Round 1)
```

**If FAIL → proceed to Round 2.**
**If PASS → Arbiter Final Review (MANDATORY):**

```python
bash("rm -f .trident/{task-slug}/.done")
result = task(
    subagent_type="oracle",
    load_skills=[],
    description="Trident Apply Arbiter Final Review (Round 1)",
    prompt="""
You are the ARBITER performing the MANDATORY final review of an implementation.
The Discriminator scored all dimensions ≥ 9. Verify independently.

## Design Spec
{from generator.md}

## Implementation
{files changed}

## Discriminator's Verdict
PASS — all ≥ 9

## Your Task
1. Read the actual code independently
2. Verify against design spec
3. Check for blind spots D may have missed
4. Is the PASS verdict genuine?

## Signal Completion
echo "VERDICT: PASS or FAIL" > .trident/{task-slug}/.done

Verdict: PASS / FAIL (list issues)
""",
    run_in_background=true
)
bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

**If Arbiter PASS → skip to Step 6 (Resolution).**
**If Arbiter FAIL → does NOT consume round.** Generator fixes Arbiter's issues,
then re-submits to Discriminator + Arbiter within the same round (loop back to
the Discriminator review in this step). Only a Discriminator FAIL advances to Round 2.

### Step 4: Round 2 — Generator Fixes + Discriminator Re-reviews

Generator addresses each issue from Round 1:

1. Read Discriminator's feedback from Round 1
2. Fix each issue listed as MUST FIX
3. Record fixes in apply-log.md Round 2 section
4. Run build + tests again after fixes

**Discriminator re-reviews (session continuity — knows previous context):**

```python
bash("rm -f .trident/{task-slug}/.done")

result = task(
    session_id="{discriminator_session_id}",  # Same session — remembers Round 1
    load_skills=[],
    description="Trident Round 2 Re-review",
    prompt="""
Round 2 of 3. Generator has addressed your Round 1 feedback.

## Your Previous Issues (Round 1)
{list of issues from Round 1}

## Fixes Applied
{from apply-log.md Round 2 section}

## Task
1. Verify each previous MUST FIX is resolved
2. Re-score all 7 dimensions
3. Identify any NEW issues introduced by the fixes
4. Do NOT re-verify issues you already confirmed

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: PASS or FAIL" > .trident/{task-slug}/.done

Verdict: PASS (all gates met) / FAIL (list remaining issues)
""",
    run_in_background=true
)

bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

**If FAIL → proceed to Round 3.**
**If PASS → Arbiter Final Review (MANDATORY):**

Same Arbiter invocation as Round 1 (see Step 3 above), with updated context.
Remember: clear `.done` before firing, wait via heartbeat, Arbiter MUST create `.done` on completion.

**If Arbiter PASS → skip to Step 6 (Resolution).**
**If Arbiter FAIL → does NOT consume round.** Generator fixes, re-submits D+A
within Round 2. Only a Discriminator FAIL advances to Round 3.

### Step 5: Round 3 — Arbiter + Generator Collaborate

The Arbiter is invoked fresh (no session history, no bias from G/D interaction).
Unlike Rounds 1-2, the Arbiter and Generator work collaboratively:

1. Arbiter independently reviews the implementation
2. Arbiter provides feedback
3. Generator fixes issues based on Arbiter's feedback
4. Arbiter confirms fixes are adequate

This is the FINAL round. If issues remain after collaboration, hard stop.

```python
bash("rm -f .trident/{task-slug}/.done")

result = task(
    subagent_type="oracle",  # Fresh — NO session_id
    load_skills=[],
    description="Trident Round 3 Arbiter Review",
    prompt="""
You are the ARBITER performing the final review (Round 3 of 3) in a Trident Apply.
This is a fresh, independent review — you have no prior context.

## Design Spec
{full design from generator.md}

## Implementation
{list of files changed}

## Previous Review History
Round 1: Discriminator found {N} issues.
Round 2: Discriminator found {M} remaining issues.

## Your Task
1. Read the actual code changes independently
2. Compare against the design spec
3. Score the implementation across 7 dimensions
4. Be especially attentive to issues that persisted through Rounds 1-2
5. List specific fixes needed (if any) — Generator will address them

## MUST FIX vs NICE TO HAVE Classification
Always MUST FIX (no exceptions):
- Missing input validation on public API parameters
- Unhandled exception paths (crash/assert/uncaught error on any input)
- Missing boundary checks (empty, zero, negative, overflow)
- Race conditions, deadlocks, data corruption
- Security vulnerabilities
- Violation of stated API contract

Always NICE TO HAVE:
- Performance optimizations, convenience methods, documentation, style

Golden rule: if it can crash or produce incorrect behavior on ANY input → MUST FIX.

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: PASS or FAIL" > .trident/{task-slug}/.done

Verdict: PASS (all gates met) / FAIL (list issues for Generator to fix)
""",
    run_in_background=true
)

bash("{heartbeat} {task-slug} 300")
output = background_output(task_id=result.task_id)
```

```text
# Claude Code
@"trident-arbiter (agent)" final review of implementation in .trident/{task-slug}/
```

**If Arbiter reports issues:**
1. Generator fixes them immediately
2. Record fixes in apply-log.md Round 3 section
3. Re-submit to Arbiter for review (still Round 3, same rule — A FAIL does NOT consume round)
4. Repeat until Arbiter PASS or hard stop

**Hard stop condition:** If Generator cannot resolve Arbiter's issues after 3 fix
attempts within Round 3, trigger **Human-in-the-Loop Escalation** (see below).

### Step 6: Resolution

| Verdict | Action |
|---------|--------|
| **PASS** (D all ≥ 9 + Arbiter approves, any round) | Update Status to `done`, produce Completion Report, **STOP**. Suggest `/tri archive`. Do NOT auto-archive. |
| **FAIL** (Round 3 exhausted) | **Human-in-the-Loop Escalation** (see below) |

### Human-in-the-Loop Escalation (Round 3 Hard Stop)

This is rare but critical. When all 3 rounds are exhausted, the agents cannot
resolve the issue autonomously. The human becomes the final judge.

**The Generator MUST produce a structured escalation report with ALL THREE
perspectives so the human can make an informed decision:**

```
## Trident Escalation — Human Decision Required 🔱

**Task:** {task-slug}
**Status:** Round 3 exhausted — all automated review paths failed

---

### Generator Report (G)
**What I implemented:**
{summary of implementation — what was done, which files changed}

**My assessment:**
{why I believe the implementation is correct, or what I'm uncertain about}

### Discriminator Report (D)
**My review history:**
| Dimension             | Round 1 | Round 2 |
|-----------------------|---------|---------|
| Correctness           |         |         |
| Algorithmic Soundness |         |         |
| Safety                |         |         |
| Measurability         |         |         |
| Minimality            |         |         |
| Testability           |         |         |
| Conventions           |         |         |

**Issues I found and their resolution status:**
{list of all issues across rounds, which were fixed, which remain}

### Arbiter Report (A)
**Why I rejected (honest assessment):**
{specific reasons for rejection — what blind spots, what risks, what concerns}

**What would need to change for me to approve:**
{concrete, actionable criteria}

---

### Human Decision Options
1. **Accept as-is** — override Arbiter, mark as done
2. **Accept with noted risks** — mark as done, document limitations
3. **Fix manually** — human addresses Arbiter's concerns directly
4. **Restart implementation** — re-run `/tri apply` with fresh attempt
5. **Redesign** — go back to `/tri new` to revise the design
```

**CRITICAL:** The Arbiter report MUST be honest and specific. Vague rejections
like "not confident" are not acceptable — the Arbiter must cite concrete code
paths, scenarios, or evidence that justify the rejection. The human needs
actionable information to make their decision.

### Completion Report (MANDATORY)

After any round PASS, the Generator MUST produce a comprehensive completion summary.
This is NOT optional — the user needs to understand what changed at a glance.

**The report MUST include ALL of the following sections:**

#### 1. Status Table

```
## Implementation Complete 🔱

**Task:** {task-slug}
**Status:** done
**Three Strikes:** Completed in Round {1|2|3} of 3

### Round Summary
| Round | Roles | Result |
|-------|-------|--------|
| 1. Implement + Review | Generator + Discriminator | ✅ / ❌ {result} |
| 1. Arbiter Final Review | Arbiter | ✅ / (skipped if D failed) |
| 2. Fix + Re-review | Generator + Discriminator | ✅ / ❌ / (skipped) |
| 2. Arbiter Final Review | Arbiter | ✅ / (skipped) |
| 3. Collaborate | Generator + Arbiter | ✅ / ❌ / (skipped) |

### Final Scores
| Dimension             | Score |
|-----------------------|-------|
| Correctness           |       |
| Algorithmic Soundness |       |
| Safety                |       |
| Measurability         |       |
| Minimality            |       |
| Testability           |       |
| Conventions           |       |
```

#### 2. Implementation Summary

One paragraph describing what was implemented, PLUS a key-point table:

```
| Item | Detail |
|------|--------|
| Problem | {what was broken / what was missing} |
| Fix | {what was implemented} |
| Files Changed | {N files modified, M lines added} |
| Tests | {N tests added/modified} |
| Risk | {any noted limitations or deferred items} |
```

For modification tasks, add Before/After columns:

```
| Item | Before | After |
|------|--------|-------|
| Behavior | {broken behavior} | {fixed behavior} |
| Guard | {none} | {new guard description} |
```

#### 3. Files Changed

List every file modified/created with a one-line description of what changed.

#### 4. ASCII Architecture Diagram (REQUIRED)

Produce an ASCII diagram showing the change in context of the system.
Use box-drawing characters for clarity. The diagram should help the user
understand WHERE in the system the change lives and HOW data flows through it.

#### 5. Before/After Comparison (REQUIRED for bugfix / algorithm / refactoring)

For tasks that modify existing behavior, produce a side-by-side or sequential
ASCII diagram showing:
- **Before**: How the system behaved (including the bug or limitation)
- **After**: How it behaves now (with the fix or improvement)

Focus on the behavioral difference, not line-by-line code diff.
Use arrows, state transitions, and data flow to make the change intuitive.

Example structure:
```
## Before                          ## After
┌──────────┐  ┌──────────┐       ┌──────────┐──→┌──────────┐
│ Module A │  │ Module B │       │ Module A │   │ Module B │
│ (no link)│  │ (isolated)│       │ (linked) │   │ (guarded)│
└──────────┘  └──────────┘       └──────────┘   └──────────┘
  ★ Problem: ...                    ★ Fix: ...
```

#### 6. Suggest Next Step

```
Run `/tri archive` to finalize.
```

Update `generator.md` Status to `done`.

**Heartbeat Wait (MANDATORY for each Round):**

Same pattern as Section 7: clear `.done`, fire background agent, run heartbeat.sh,
then collect results via `background_output()`. If the final round passes,
produce the Completion Report in the same response turn.

---

## 9. Status Workflow — `/tri status`

Shows a dashboard of all Trident tasks: what's in progress and what's completed.

### Steps

1. List all directories under `.trident/` (exclude `archive/`)
2. For each directory, read `generator.md` and extract:
   - Task name (from Meta → Task)
   - Status (from Meta → Status)
   - Current version (from Meta → Current Version)
   - Task type (from Meta → Task Type)
3. If `tasks.md` exists, count completed vs total tasks
4. Group by status: in-progress (iterating/ready/implementing) vs completed (done)
5. List archived tasks from `.trident/archive/` if it exists

### Output Format

```
## Trident Status 🔱

### In Progress

┌─ {task-slug}
│  Task: {description}
│  Type: {algorithm | hotfix | ...}
│  Status: {iterating | ready | implementing}
│  Version: v{N}
│  Progress: {context-dependent}
│    - iterating: "Design phase — v{N}, D reviewing"
│    - ready: "Design converged — ready for /tri apply"
│    - implementing: "Round {N} — tasks {done}/{total}"
└──────────────────────────

┌─ {another task}
│  ...
└──────────────────────────

### Completed

┌─ {task-slug}
│  Task: {description}
│  Status: done
│  Summary: {one-line description of what was done}
│  Iterations: {N} design versions, completed in Round {M}
│  Action: Run `/tri archive {task-slug}` to finalize
└──────────────────────────

### Archived

| # | Task | Archived Date | Summary |
|---|------|---------------|---------|
| 1 | {description} | 2026-03-15 | {one-line summary} |
```

If no tasks exist in any category, show "No {category} tasks."

---

## 10. Archive Workflow — `/tri archive`

Moves a completed task to the archive.

### Precondition

`generator.md` should have `Status: done`. If status is `ready` (design done but not implemented), warn but allow archiving. If status is `iterating`, reject.

### Steps

1. **Select task** — same logic as apply (auto-select if only one `done`, ask if multiple)

2. **Check task completion** — if `tasks.md` exists, count incomplete tasks
   - If incomplete tasks: warn and ask for confirmation
   - If no tasks.md: proceed (design-only task)

3. **Archive**
   ```bash
   mkdir -p .trident/archive
   mv .trident/{task-slug} .trident/archive/YYYY-MM-DD-{task-slug}
   ```

4. **Report**
   ```
   ## Archive Complete 🔱

   **Task:** {task-slug}
   **Archived to:** .trident/archive/YYYY-MM-DD-{task-slug}/
   **Final Status:** done
   **Design Iterations:** N versions
   **Implementation:** M/M tasks complete
   **Three Strikes:** Completed in Round {1|2|3} of 3

   | Dimension             | Final Score |
   |-----------------------|:-----------:|
   | Correctness           |      9      |
   | Algorithmic Soundness |      9      |
   | Safety                |      9      |
   | Measurability         |      9      |
   | Minimality            |     10      |
   | Testability           |      9      |
   | Conventions           |      9      |
   ```

5. **Suggest skill extraction**

   After the archive report, ask the user:

   > This task produced reusable knowledge (design patterns, domain insights,
   > debugging techniques). Would you like to extract it into an agent skill
   > for future use?

   If the user agrees:
   - Summarize the key learnings from `generator.md` (root cause, design decisions,
     patterns discovered, pitfalls avoided)
   - Propose a skill name and description
   - Use the platform's skill creation mechanism (e.g., `continuous-learning` skill
     or manual SKILL.md creation) to persist the knowledge
   - The skill should capture the DOMAIN KNOWLEDGE, not the Trident process itself

   Example prompt to user:
   ```
   This review uncovered insights about [domain area]. Want me to create a skill?

   Proposed skill:
   - Name: {domain-specific-name}
   - Covers: {key patterns, pitfalls, design decisions}
   - Use when: {trigger conditions}
   ```

   If the user declines, proceed without creating a skill.

---

## 11. Quick Reference

### When to Use Trident

| Scenario | Use Trident? |
|----------|--------------|
| State machine logic change | YES |
| Algorithm design / tuning | YES |
| Architecture decision | YES |
| Single-file bug fix (obvious root cause) | NO — overkill |
| Config change | NO |
| Documentation update | NO |

### Command Reference

| Command | Description |
|---------|-------------|
| `/tri new {description}` | Start new design or continue iterating existing |
| `/tri apply {task-slug}` | Implement with Three Strikes verification |
| `/tri status` | Show active and completed tasks |
| `/tri archive {task-slug}` | Archive completed task |

### Convergence Checklist (Design Phase)

- [ ] All 7 dimensions at ≥ 9
- [ ] No MUST FIX issues remaining
- [ ] Arbiter Final Review passed (MANDATORY — not optional)
- [ ] Generator.md fully updated with final version
- [ ] Status set to `ready`

### Apply Checklist (Implementation Phase)

- [ ] Round 1: All tasks implemented + Discriminator review passed (or issues listed)
- [ ] Round 2: All Round 1 issues fixed + Discriminator re-review passed (if needed)
- [ ] Round 3: Arbiter collaborative review passed (if needed)
- [ ] apply-log.md fully updated

### Status Lifecycle

```
iterating → ready → implementing → done → archived
```

---

## 12. Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|-------------|
| Fresh Discriminator every round | Loses accumulated knowledge, repeats same verifications |
| Generator writes discriminator.md | Pollutes D's independent knowledge base |
| Iterating past 9 just to chase 10 | Diminishing returns; 9+ is the gate, don't waste tokens pushing to 10 |
| Skipping Context Section | D gives wrong advice without understanding surrounding code |
| Arbiter every D round during `/tri new` | Expensive; trigger conditionally mid-iteration, but MANDATORY before READY |
| Internal files (.md) in non-English | LLM token inefficiency, weaker comprehension |
| User-facing reports in wrong language | User can't read the output — match their language |
| Skipping apply, implementing directly | Loses task tracking; no progress visibility |
| Archiving before implementation | Loses the design reference; archive after done |
| Attempting Round 4+ after failure | Three Strikes — escalate to user, don't keep trying |
| Same agent doing Round 3 | Round 3 MUST be independent (Arbiter), not Discriminator again |
