---
name: trident
description: "Trident Design Review — adversarial design with Generator, Discriminator, Arbiter. 7-dimension scoring, Three Strikes verification. Use for algorithm changes, architecture decisions, state machines, or any non-trivial design."
---

# Trident Design Review

Three roles. Seven dimensions. Three strikes.

## Lifecycle

```
/tri new     → Design (Generator ↔ Discriminator ↔ Arbiter) → READY → STOP
/tri apply   → Implement (Three Strikes) → done → STOP
/tri archive → Archive → suggest skill extraction → STOP
/tri status  → Dashboard
```

**Hard stops:** Each phase STOPS. Agent MUST NOT skip ahead. User invokes next phase.

Status lifecycle: `iterating` → `ready` → `implementing` → `done` → `archived`

---

## 1. Three Roles (Triforce)

| Role | Memory | File | Responsibility |
|------|--------|------|----------------|
| **Generator** | Persistent (main session) | `generator.md` | `/tri new`: design + iterate. `/tri apply`: implement. NEVER implement during `/tri new`. |
| **Discriminator** | Session continuity | `discriminator.md` | Score 7 dimensions, accumulate knowledge, verify implementation |
| **Arbiter** | None (fresh each time) | `.done` signal only | Monitor Generator/Discriminator quality, prevent collusion. MANDATORY before READY and before any PASS. |

### Isolation Rules

- Generator MUST NOT write to `discriminator.md`
- Discriminator MUST NOT write to `generator.md`
- Arbiter writes ONLY `.done` signal file (output recorded by Generator)

### Handoff Protocol (G → D/A)

When Generator constructs a prompt for Discriminator or Arbiter, it MUST include:

**Always include:**
- User's original request (verbatim from generator.md)
- Current version design (latest only, not full history)
- Actual file paths and function names involved
- Verification checklist

**Include for continuation rounds:**
- Discriminator's previous scores and MUST FIX items (from last round only)
- Summary of what changed since last round
- Discriminator's knowledge from discriminator.md (verified facts, blind spots)

**Never include:**
- Full version history (only latest + summary of changes)
- Old resolved MUST FIX items
- Template boilerplate
- Unrelated codebase context

**Size guideline:** D/A prompt should be under 200 lines. If longer, trim old history.

### Verification Rules

- Generator MUST paste the user's original request verbatim in generator.md "User Request" section — no paraphrasing
- Discriminator and Arbiter MUST read actual source files — never trust Generator's description blindly
- Discriminator and Arbiter MUST verify the design/implementation addresses the user's original request, not just Generator's interpretation
- All scoring must cite specific file paths, method names, line numbers from the real codebase
- "I verified the design doc" is NOT sufficient — verify the actual code AND the user's intent

### Agent Invocation

**OpenCode:**
```python
# Discriminator (first round — load domain skill)
task(subagent_type="oracle", load_skills=["{domain-skill}"],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)

# Discriminator (continuation — reuse session)
task(session_id="{stored_session_id}", load_skills=[],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)

# Arbiter (always fresh — NO session_id)
task(subagent_type="oracle", load_skills=[],
     description="Trident Arbiter review", prompt="...", run_in_background=true)
```

**Claude Code:**
```
@"trident-discriminator (agent)" ...
@"trident-arbiter (agent)" ...
```

**Domain skill selection:** Load skills that give D codebase-specific knowledge (e.g., `cpp-expert`). Only first round — continuation rounds use `load_skills=[]`.

**Session recovery:** If Discriminator's session expires, start fresh with `discriminator.md` content in prompt. See `reference/session-recovery.md`.

---

## 2. Seven Dimensions

ALL must reach **≥ 9** to pass. No exceptions.

| Dimension | Definition |
|-----------|-----------|
| Correctness | Logic correct, no crash, no unhandled exceptions on any input |
| Algorithmic Soundness | All scenarios, boundaries, cross-component interactions |
| Safety | Backward compat, null-safe, fail-safe, defensive input validation |
| Measurability | Max verification with available resources |
| Minimality | Minimal change surface, no new patterns |
| Testability | Test coverage, edge cases, executable |
| Conventions | Matches existing codebase patterns |

### MUST FIX Rules (deterministic — no judgment calls)

**Always MUST FIX:**
- Missing input validation on public API parameters
- Unhandled exception paths (crash/assert on any input)
- Missing boundary checks (empty, zero, negative, overflow)
- Race conditions, deadlocks, data corruption
- Security vulnerabilities
- API contract violations

**Always NICE TO HAVE:**
- Performance optimizations, convenience methods, docs, style

**Golden rule:** If it can crash or produce incorrect behavior on ANY input → MUST FIX.

### Scoring Rules

- Score honestly: if work deserves 10, give 10. Do not deflate.
- If Discriminator lowers a score from previous round, Discriminator MUST explain why.
- Do not iterate just to chase 10 — 9+ is the gate.

### Task-Type Emphasis

| Task Type | Elevated Dimensions |
|-----------|-------------------|
| Algorithm | Algorithmic Soundness, Measurability |
| Refactoring | Minimality, Safety |
| Hotfix | Correctness, Safety |
| New feature | Testability, Algorithmic Soundness |

---

## 3. Arbiter Trigger Conditions

**MANDATORY (cannot skip):**
1. Before READY — Arbiter MUST review before design convergence
2. After each Discriminator PASS in `/tri apply` — Arbiter MUST verify before completion

**Conditional (invoke when detected):**
3. Discriminator gives all 9+ for 2 consecutive rounds → possible leniency
4. Generator rejects Discriminator's suggestion → need arbitration
5. Score jumps ≥ 3 points in single round → possible standard shift

---

## 4. Design Workflow — `/tri new`

### Step 1: Auto-Slug and Initialize

Convert description to kebab-case. Do NOT ask user to confirm.
If `.trident/{task-slug}/` exists → continue. If not → create from templates.

Load templates from `templates/generator-template.md` and `templates/discriminator-template.md`.

### Step 2: Submit to Discriminator

Clear `.done`, fire Discriminator with prompt from `prompts/discriminator-first.md`, wait via heartbeat.
See `reference/heartbeat.md` for platform-agnostic invocation.

### Step 3: Process Feedback

Parse Discriminator output. Record scores in generator.md. Check gates.
- NOT all ≥ 9 → iterate, re-submit with prompt from `prompts/discriminator-continuation.md`
- All ≥ 9 → proceed to Arbiter Final Review

### Step 4: Arbiter (conditional mid-iteration)

If triggered by conditions 3-5 above. Use prompt from `prompts/arbiter-design.md`.

### Step 5: Arbiter Final Review (MANDATORY before READY)

Fire Arbiter with prompt from `prompts/arbiter-design.md`. Arbiter MUST create `.done`.
- Arbiter says READY → Step 6
- Arbiter says ITERATE → address issues, back to Step 2

### Step 6: Finalize Design (HARD STOP)

1. Update generator.md Status to `ready`
2. Produce Convergence Report (score history table, design summary with key-point table, ASCII diagram, change surface)
3. **STOP. Do NOT implement. User must invoke `/tri apply`.**

### File Size Control

- generator.md: Keep only latest 2 versions in full detail. Compress older versions to one-line summary.
- discriminator.md: Prune resolved facts. Keep only current blind spots and active patterns.
- Goal: no working file exceeds 300 lines.

### Progress Tracking (MANDATORY)

Create todo list immediately. Update in real-time with 7-dimension score table (full names, no abbreviations) after every Discriminator/Arbiter evaluation.

When firing Discriminator or Arbiter, always display the model name being used:

```
- [ ] v1: Discriminator reviewing (model: {model_name})...
- [x] v1: Discriminator scored (model: claude-sonnet-4-20250514) — ITERATE
- [ ] v1: Arbiter Final Review (model: {model_name})...
```

This helps the user understand which model is powering each role.

---

## 5. Apply Workflow — `/tri apply` (Three Strikes)

Precondition: `generator.md` Status must be `ready`.

### Round Rules

- Discriminator FAIL → consumes round, advance to next
- Arbiter FAIL → does NOT consume round, Generator fixes and re-submits within same round
- Round 3: max 3 fix attempts, then Human-in-the-Loop Escalation

### Step 1: Generate tasks.md + apply-log.md

Load templates from `templates/apply-log-template.md`. Update Status to `implementing`.

### Step 2: Round 1 — Generator Implements + Verifies + Discriminator Reviews

Generator implements all tasks, then **MUST verify before submitting to Discriminator:**

**Build & Verify (ALL roles have Bash — ALL roles verify):**

All three roles have Bash tool access. Each role independently verifies:

| Role | Verify When | What to Check |
|------|-------------|---------------|
| Generator | After implementing, BEFORE firing Discriminator | Build, runtime, functional |
| Discriminator | During review, BEFORE scoring | Build the code, run tests, verify claims |
| Arbiter | During review, BEFORE verdict | Independent build + runtime check |

**"I read the code and it looks correct" is NOT sufficient for any role.
If you have Bash, RUN the code.**

Verification commands to try:

| Output Type | Commands |
|-------------|----------|
| Python | `python script.py`, `python -m pytest` |
| JavaScript/Node | `node file.js`, `npx tsc --noEmit` |
| HTML/Web | `python -m http.server` + `curl localhost` |
| C/C++ | `make`, `cmake --build .`, `gcc -fsyntax-only` |
| API | `curl -X GET/POST endpoint` |
| Any language | syntax check, lint, unit test, dry run |

Generator fixes build/runtime errors BEFORE firing Discriminator.
Discriminator and Arbiter independently verify — do NOT trust Generator's evidence alone.

**Verification Fallback (when a role cannot execute):**

Each role tries to verify independently. If it can't, fall back:

```
Level 1: Run it yourself (build + execute + test)
    ↓ can't?
Level 2: Review Generator's verification evidence (build logs, test output)
    ↓ no evidence?
Level 3: Code review only — flag as "unverified" in scores
```

Each role MUST state which level it operated at:
```
Verification Level: 1 (independent build + runtime)
Verification Level: 2 (reviewed Generator's evidence)
Verification Level: 3 (code review only — could not verify)
```

Scoring impact:
- Level 1: Measurability can reach 10
- Level 2: Measurability capped at 9
- Level 3: Measurability capped at 8 — flag limitation to user

Fire Discriminator with prompt from `prompts/discriminator-first.md` (implementation variant).
- Discriminator FAIL → Round 2
- Discriminator PASS → Arbiter Final Review. Arbiter PASS → Step 5. Arbiter FAIL → Generator fixes, re-submit.

### Step 3: Round 2 — Generator Fixes + Discriminator Re-reviews

Fire Discriminator with `prompts/discriminator-continuation.md`. Same Discriminator+Arbiter flow as Round 1.
- Discriminator FAIL → Round 3
- Discriminator PASS → Arbiter. Arbiter PASS → Step 5. Arbiter FAIL → Generator fixes, re-submit.

### Step 4: Round 3 — Generator + Arbiter Collaborate

Fire Arbiter with `prompts/arbiter-apply.md`. Generator fixes Arbiter's issues, re-submit (max 3 attempts).
Exhausted → Human-in-the-Loop Escalation (G/D/A each submit perspective, human decides).

### Step 5: Resolution

Update Status to `done`. Produce Completion Report (round summary, implementation summary with key-point table, files changed, ASCII diagram, before/after comparison).
**STOP. Do NOT auto-archive.**

### Progress Tracking (MANDATORY)

Todo list with 7-dimension score table after every Discriminator/Arbiter evaluation.

---

## 6. Status Workflow — `/tri status`

Scan `.trident/` (exclude `archive/`). Group by: In Progress vs Completed. List archived from `.trident/archive/`.

---

## 7. Archive Workflow — `/tri archive`

Precondition: Status `done` (warn if `ready`, reject if `iterating`).

1. Move to `.trident/archive/YYYY-MM-DD-{task-slug}/`
2. Produce archive report with final scores
3. Ask user: "Want to extract domain knowledge into a reusable skill?"

---

## 8. File Structure

```
.trident/{task-slug}/
├── generator.md        ← Generator's design + versions + feedback
├── discriminator.md    ← Discriminator's accumulated knowledge
├── tasks.md            ← Implementation tasks (/tri apply)
├── apply-log.md        ← Round log with scores
└── .done               ← Signal file (transient)
```

---

## 9. Language Rules

- Internal files (generator.md, discriminator.md, etc.) → English ONLY
- User-facing output (reports, summaries, todos) → match user's language

---

## 10. Quick Reference

| Command | Description |
|---------|-------------|
| `/tri new {description}` | Start or continue design review |
| `/tri apply {task-slug}` | Implement with Three Strikes |
| `/tri status` | Show active and completed tasks |
| `/tri archive {task-slug}` | Archive completed task |

### Convergence Checklist

- [ ] All 7 dimensions at ≥ 9
- [ ] No MUST FIX issues remaining
- [ ] Arbiter Final Review passed (MANDATORY)
- [ ] Generator.md fully updated
- [ ] Status set to `ready`

### Apply Checklist

- [ ] Round 1: All tasks implemented + Discriminator review + Arbiter review
- [ ] Round 2: Issues fixed + Discriminator re-review + Arbiter review (if needed)
- [ ] Round 3: Arbiter collaborative review (if needed)
- [ ] apply-log.md fully updated

---

## 11. Anti-Patterns

| Anti-Pattern | Why It Fails |
|-------------|-------------|
| Fresh Discriminator every round | Loses accumulated knowledge |
| Generator writes discriminator.md | Pollutes Discriminator's independent knowledge |
| Iterating past 9 just to chase 10 | Diminishing returns |
| Skipping Context Section | Discriminator gives wrong advice |
| Internal files in non-English | LLM token inefficiency |
| User-facing reports in wrong language | User can't read the output |
| Skipping apply, implementing directly | Loses task tracking |
| Attempting Round 4+ after failure | Three Strikes — escalate to user |
| Arbiter every Discriminator round during `/tri new` | Expensive; mandatory only before READY |

---

## Loading Additional Resources

When you need templates, prompts, or reference material, load from:

| Need | File |
|------|------|
| Create generator.md | `templates/generator-template.md` |
| Create discriminator.md | `templates/discriminator-template.md` |
| Create apply-log.md | `templates/apply-log-template.md` |
| Fire Discriminator (first round) | `prompts/discriminator-first.md` |
| Fire Discriminator (continuation) | `prompts/discriminator-continuation.md` |
| Fire Arbiter (design phase) | `prompts/arbiter-design.md` |
| Fire Arbiter (apply phase) | `prompts/arbiter-apply.md` |
| Heartbeat invocation | `reference/heartbeat.md` |
| Discriminator session recovery | `reference/session-recovery.md` |

All paths are relative to this skill's directory.
