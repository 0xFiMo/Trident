---
name: trident
description: "Trident Design Review — adversarial design with Generator, Discriminator, Arbiter. Multi-dimension scoring (7 core + 2 visual), Three Strikes verification. Use for algorithm changes, architecture decisions, state machines, frontend/UI, or any non-trivial design."
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
| **Discriminator** | Session continuity | `discriminator.md` | Score all applicable dimensions (7 core + 2 visual), accumulate knowledge, verify implementation |
| **Arbiter** | None (fresh each time) | `arbiter.md` (log, never reads) + `.done` signal | Monitor Generator/Discriminator quality, prevent collusion. MANDATORY before READY and before any PASS. |

### Isolation Rules

- Generator MUST NOT write to `discriminator.md`
- Generator MUST record Arbiter's output in `arbiter.md` after each Arbiter review
- Discriminator MUST NOT write to `generator.md` or `arbiter.md`
- Arbiter writes ONLY `.done` signal file — Arbiter NEVER reads `arbiter.md` (always fresh)

### Handoff Protocol (Generator → Discriminator/Arbiter)

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

**Size guideline:** Discriminator/Arbiter prompt should be under 200 lines. If longer, trim old history.

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
task(subagent_type="trident-discriminator", load_skills=["{domain-skill}"],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)

# Discriminator (continuation — reuse session)
task(session_id="{stored_session_id}", load_skills=[],
     description="Trident Discriminator v{N}", prompt="...", run_in_background=true)

# Arbiter (always fresh — NO session_id)
task(subagent_type="trident-arbiter", load_skills=[],
     description="Trident Arbiter review", prompt="...", run_in_background=true)
```

**Claude Code:**
```
@"trident-discriminator (agent)" ...
@"trident-arbiter (agent)" ...
```

**Model configuration:**

Discriminator and Arbiter may use a DIFFERENT model than Generator,
depending on your platform's subagent routing:

- **OpenCode (native):** subagents use platform default model
- **OpenCode + oh-my-opencode:** subagents use `sisyphus-junior` model
  (check `~/.config/opencode/oh-my-opencode.json` → `sisyphus-junior.model`)
- **Claude Code:** uses model from agent definition or platform default

To verify: check `discriminator.md` — Discriminator self-identifies its model there.

### Model Guard (OpenCode + oh-my-opencode)

oh-my-opencode's Zod schema only recognizes 14 predefined agent names.
Custom agents (`trident-discriminator`, `trident-arbiter`) are **silently ignored** —
their `model:` field in `.md` files has NO effect. They fall back to `sisyphus-junior` model.

**Pre-flight check (MANDATORY — run ONCE at the start of any Trident command):**

```
1. Read ~/.config/opencode/oh-my-opencode.json
2. If file does NOT exist → SKIP (no oh-my-opencode, agent .md models work directly)
3. If file exists:
   a. Read agents.sisyphus-junior.model → this is what Discriminator/Arbiter will ACTUALLY use
   b. Read trident-discriminator.md frontmatter → model: field = INTENDED model
   c. Read trident-arbiter.md frontmatter → model: field = INTENDED model
   d. Compare:
      - If sisyphus-junior.model == Discriminator intended model → OK, no action needed
      - If MISMATCH → execute Model Guard Resolution below
```

**Model Guard Resolution (on mismatch):**

```
⚠️ Model mismatch detected:

  Discriminator intended: {Discriminator .md model}
  Arbiter intended:       {Arbiter .md model}
  Actual (sisyphus-junior): {sisyphus-junior model}

  oh-my-opencode ignores custom agent model fields.
  Discriminator and Arbiter will use: {sisyphus-junior model}

Options:
  1. Proceed — use {sisyphus-junior model} for Discriminator/Arbiter (no restart needed)
  2. Fix — update sisyphus-junior model in oh-my-opencode.json
           (⚠️ affects ALL subagents, requires OpenCode restart)
  3. Run /tri models — reconfigure intended models to match
```

- If user chooses **1 (Proceed)**: continue, but mark actual model in all progress tracking
  - Progress shows: `Discriminator (model: {actual}, intended: {intended})`
- If user chooses **2 (Fix)**: edit oh-my-opencode.json → set `sisyphus-junior.model` to Discriminator's intended model,
  then tell user: "Restart OpenCode for changes to take effect. Then re-run this command."
  **STOP — do NOT continue the workflow.**
- If user chooses **3 (/tri models)**: stop and let user reconfigure

**Why this happens:** oh-my-opencode `AgentOverridesSchema` is a strict `z.object({...})`
with only 14 hardcoded keys. Custom agent names are stripped during Zod validation.
The `model:` field in agent `.md` files is overridden by oh-my-opencode's model resolution chain:
`oh-my-opencode.json agents → category model → sisyphus-junior fallback → system default`.

**If Discriminator or Arbiter invocation fails:**

Do NOT fall back to oracle or self-review — that violates Trident's adversarial design.
Stop and report to user:

```
Discriminator/Arbiter invocation failed.
Please check:
1. Agent files installed: ~/.config/opencode/agents/trident-discriminator.md
2. Agent files installed: ~/.claude/agents/trident-discriminator.md
3. Run: ./install.sh to reinstall agents
```

Do NOT retry the same failing call more than once.
Do NOT continue the workflow without Discriminator/Arbiter — the review is invalid without them.

**Skill Stacking — augment all roles with domain expertise:**

Generator SHOULD load relevant domain skills before starting design work.
The same skills SHOULD be passed to Discriminator and Arbiter so all three
roles share the same domain knowledge.

| Role | How to load skills | When |
|------|--------------------|------|
| Generator | Use the Skill tool directly (e.g., `skill("cpp-expert")`) | Before starting `/tri new` |
| Discriminator | Via `load_skills=["{skill}"]` when Generator fires the task | First round only — continuation rounds reuse session |
| Arbiter | Via `load_skills=["{skill}"]` when Generator fires the task | Every invocation (Arbiter has no session) |

Example: task involves React frontend
```python
# Generator loads skill for itself
skill("frontend-patterns")

# Generator passes same skill to Discriminator
task(subagent_type="trident-discriminator", load_skills=["frontend-patterns"], ...)

# Generator passes same skill to Arbiter
task(subagent_type="trident-arbiter", load_skills=["frontend-patterns"], ...)
```

If no relevant domain skill exists, use `load_skills=[]`.

**Session recovery:** If Discriminator's session expires, start fresh with `discriminator.md` content in prompt. See `reference/session-recovery.md`.

---

## 2. Scoring Dimensions

All APPLICABLE dimensions must reach **≥ 9** to pass. No exceptions.

### Core Dimensions (always apply)

| Dimension | Definition |
|-----------|-----------|
| Correctness | Logic correct, no crash, all scenarios, boundaries, cross-component interactions, no unhandled exceptions on any input |
| Safety | Backward compat, null-safe, fail-safe, defensive input validation |
| Testability | Test coverage, edge cases, executable, max verification with available resources |
| Minimality | Minimal change surface, no unnecessary code or patterns |
| Conventions | Matches existing codebase patterns |

### Visual Dimensions (apply when task produces visual output)

| Dimension | Definition | When to apply |
|-----------|-----------|---------------|
| Visual Quality | Aesthetics, polish, animation smoothness, color/palette coherence, typography, visual hierarchy, responsive behavior | HTML, CSS, canvas, WebGL, UI components, animations, any rendered output |
| Creative Impact | Originality, memorability, avoids generic/template patterns, shows design intent beyond "it works", uses creative techniques | Same as Visual Quality |

**Applicability rule:**
- Task produces **visual output** (HTML page, animation, UI component, app screen, CSS styling) → Visual dimensions APPLY, must score ≥ 9
- Task is **non-visual** (backend, CLI, algorithm, library, config) → Visual dimensions = **N/A** (auto-pass, do not score)
- Discriminator determines applicability in first review. If uncertain → apply them (false positive is better than missing visual feedback)

**Visual task scoring guidance:**
- Visual Quality 10 = production-quality visual output, polished transitions, coherent design system
- Visual Quality < 9 = unfinished look, jarring transitions, poor color choices, broken responsive layout
- Creative Impact 10 = distinctively creative, memorable, stands out from generic AI output
- Creative Impact < 9 = generic/template-like, visually boring, no design personality

**Minimality reinterpretation for visual tasks:**
Rich animations, creative CSS, visual effects, and design flourishes are **NOT violations of Minimality** if they serve the design intent. Minimality means no unnecessary *structural* code — not "strip visual richness." Discriminator MUST NOT penalize creative visual code under Minimality.

### MUST FIX Rules (deterministic — no judgment calls)

**Always MUST FIX:**
- Missing input validation on public API parameters
- Unhandled exception paths (crash/assert on any input)
- Missing boundary checks (empty, zero, negative, overflow)
- Race conditions, deadlocks, data corruption
- Security vulnerabilities
- API contract violations

**Visual tasks — also MUST FIX:**
- Broken animations (stuttering, no easing, jumps)
- Inaccessible UI (no contrast, no keyboard nav, no alt text)
- Non-responsive layout (breaks on mobile/resize)
- Generic template output with no creative effort

**Always NICE TO HAVE:**
- Performance optimizations, convenience methods, docs, style

**Golden rule:** If it can crash or produce incorrect behavior on ANY input → MUST FIX.

### Scoring Rules

- Score honestly: if work deserves 10, give 10. Do not deflate.
- If Discriminator lowers a score from previous round, Discriminator MUST explain why.
- Do not iterate just to chase 10 — 9+ is the gate.
- For visual tasks: Discriminator SHOULD render the output (open HTML in browser, take screenshot) before scoring Visual Quality and Creative Impact.

### Task-Type Emphasis

| Task Type | Elevated Dimensions |
|-----------|-------------------|
| Algorithm | Correctness, Testability |
| Refactoring | Minimality, Safety |
| Hotfix | Correctness, Safety |
| New feature | Testability, Correctness |
| Frontend / UI / Animation | Visual Quality, Creative Impact, Correctness |
| Design / Styling | Visual Quality, Creative Impact, Conventions |

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

### Step 1: Auto-Slug, Scan Skills, and Initialize

Convert description to kebab-case. Do NOT ask user to confirm.

**Task Type Detection (MANDATORY — set in generator.md Meta before design):**

Determine whether the task produces visual output:
- HTML, CSS, canvas, WebGL, UI components, animations, app screens → `Visual Task: yes`, `Applicable Dimensions: 5 core + 2 visual`
- Backend, CLI, algorithm, library, config → `Visual Task: no`, `Applicable Dimensions: 5 core`

This decision is recorded in generator.md and Discriminator reads it to know which dimensions to score.

**Skill Discovery (MANDATORY before design):**
1. List all available skills on the platform
2. Identify skills relevant to the task (e.g., web task → load `frontend-patterns`, `dev-browser`)
3. Load matching skills for yourself (Generator)
4. Record which skills to pass to Discriminator and Arbiter in generator.md Meta:
   ```
   - Skills: [frontend-patterns, dev-browser]
   ```

If `.trident/{task-slug}/` exists → continue. If not → create from templates.

Load templates from `templates/generator-template.md`, `templates/discriminator-template.md`, and `templates/arbiter-template.md`.

### Step 2: Submit to Discriminator

Clear `.done`, fire Discriminator with prompt from `prompts/discriminator-first.md`, wait via heartbeat.
See `reference/heartbeat.md` for platform-agnostic invocation.

**Waiting for background agents — use in this priority order:**
1. `bash heartbeat.sh {task-slug} 300` — blocks until `.done` appears (preferred)
2. `background_output(block=true, timeout=300000)` — blocks until agent completes
3. End your response and wait for `<system-reminder>` notification
4. `background_output(block=false)` — last resort ONLY, max 3 attempts with 30s gap between each

Do NOT loop `background_output(block=false)` rapidly. If you tried 3 times and it's still running, end your response and wait.

### Step 3: Process Feedback

Parse Discriminator output. Record scores in generator.md. Check gates.

- All ≥ 9 → proceed to Arbiter Final Review (Step 5)
- NOT all ≥ 9 → **DO NOT STOP. Execute all of the following in ONE response:**
  1. Record Discriminator's scores and feedback in generator.md
  2. Address ALL MUST FIX items — update the design in generator.md (new version)
  3. Clear `.done`
  4. Re-submit to Discriminator with prompt from `prompts/discriminator-continuation.md`
  5. Run: `bash heartbeat.sh {task-slug} 300`

  **CRITICAL: Steps 1-5 above are ONE atomic action. Do NOT end your response between them.
  Do NOT stop after updating the design. Do NOT wait for user input.
  The iterate loop is: receive feedback → fix design → re-submit → wait → repeat.**

**After receiving Discriminator/Arbiter results:**
- Update generator.md `Models:` field with each role's self-identified model name
- Example: `Models: Generator=MiniMax-M2.7, Discriminator=MiniMax-M2.7, Arbiter=MiniMax-M2.7`

**Score History Rules:**
- generator.md MUST have exactly ONE Score History table — never duplicate
- Start with v1 column only. Add columns as new versions are scored.
- Update the SAME table — do NOT create a second table below

### Step 4: Arbiter (conditional mid-iteration)

If triggered by conditions 3-5 above. Use prompt from `prompts/arbiter-design.md`.
Clear `.done`, fire Arbiter, then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`

### Step 5: Arbiter Final Review (MANDATORY before READY)

Clear `.done`, fire Arbiter with prompt from `prompts/arbiter-design.md`. Arbiter MUST create `.done`.
Then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`
Do NOT just end response and wait for system-reminder — heartbeat is MANDATORY.
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

Create todo list immediately. Update in real-time with full score table (all applicable dimensions, full names, no abbreviations) after every Discriminator/Arbiter evaluation.

ALL roles — including Generator — must show their model name in progress tracking.
Generator: ask yourself "What model am I?" and include it in every Generator todo item.
Discriminator/Arbiter: their model is taken from their self-identified output.

```
- [x] v1: Generator (model: {self-identified}) produces design
- [ ] v1: Discriminator (model: {self-identified}) reviewing...
- [x] v1: Discriminator (model: {self-identified}) scored — ITERATE
- [ ] v2: Generator (model: {self-identified}) addresses feedback
- [ ] v2: Arbiter (model: {self-identified}) Final Review...
```

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

Clear `.done`, fire Discriminator with prompt from `prompts/discriminator-first.md` (implementation variant).
Then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`
Do NOT just end response and wait for system-reminder — heartbeat is MANDATORY.
- Discriminator FAIL → Round 2
- Discriminator PASS → Clear `.done`, fire Arbiter for Final Review, then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`. Arbiter PASS → Step 5. Arbiter FAIL → Generator fixes, re-submit.

### Step 3: Round 2 — Generator Fixes + Discriminator Re-reviews

Clear `.done`, fire Discriminator with `prompts/discriminator-continuation.md`.
Then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`
Same Discriminator+Arbiter flow as Round 1.
- Discriminator FAIL → Round 3
- Discriminator PASS → Clear `.done`, fire Arbiter, then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`. Arbiter PASS → Step 5. Arbiter FAIL → Generator fixes, re-submit.

### Step 4: Round 3 — Generator + Arbiter Collaborate

Clear `.done`, fire Arbiter with `prompts/arbiter-apply.md`, then IMMEDIATELY run: `bash heartbeat.sh {task-slug} 300`. Generator fixes Arbiter's issues, re-submit (max 3 attempts).
Exhausted → Human-in-the-Loop Escalation (Generator/Discriminator/Arbiter each submit perspective, human decides).

### Step 5: Resolution

Update Status to `done`. Produce Completion Report (round summary, implementation summary with key-point table, files changed, ASCII diagram, before/after comparison).
**STOP. Do NOT auto-archive.**

### Progress Tracking (MANDATORY)

Todo list with full score table (all applicable dimensions) after every Discriminator/Arbiter evaluation.

---

## 6. Models Workflow — `/tri models`

Show and configure models for Generator, Discriminator, and Arbiter.

### Step 1: Detect CURRENT platform and read current models

Detect which platform you are running on RIGHT NOW — only manage that platform's files:
- **If running on OpenCode:** ONLY read/write `~/.config/opencode/agents/trident-{generator,discriminator,arbiter}.md`
- **If running on Claude Code:** ONLY read/write `~/.claude/agents/trident-{generator,discriminator,arbiter}.md`

Do NOT show or modify the other platform's files. Each platform manages its own config independently.
If no agent files found for the current platform, tell the user to run install.sh first.
Look for `model:` line in the frontmatter. If absent, show "platform default".

### Step 2: Display current configuration

```
Trident Model Configuration:

| Role          | Job                                          | Model                      |
|---------------|----------------------------------------------|----------------------------|
| Generator     | designs and implements code                  | {read from agent .md file} |
| Discriminator | scores and reviews (the critic)              | {read from agent .md file} |
| Arbiter       | independent final check (prevents collusion) | {read from agent .md file} |
```

Read the ACTUAL `model:` value from each file. Do NOT hardcode or guess.

### Step 3: Ask the user if they want to change

Use the question tool to present options:
- "Keep current" → done
- "Same model for all" → go to Step 4, apply chosen model to all three roles
- "Different per role" → go to Step 4 three times, once per role

### Step 4: Present model selection menu

**MANDATORY — do NOT ask user to type model names. Use the question tool with selectable options.**

**OpenCode:** Run `opencode models` to get the full list. Parse the output into selectable options.

If the model list is long (20+ models), group by provider:
```
Anthropic:
  1. anthropic/claude-opus-4-6
  2. anthropic/claude-sonnet-4-6
  3. anthropic/claude-haiku-4-5
OpenAI:
  4. openai/gpt-5.4
  ...
MiniMax:
  7. minimax-coding-plan/MiniMax-M2.7
  ...
```

Use the question tool with all models as selectable options. Add the current model as the first option
with "(current)" suffix so the user can easily keep it.

**Claude Code:** No model list command available — use the question tool with common models
(claude-opus-4-6, claude-sonnet-4-6, claude-haiku-4-5) as options, plus allow custom input.

**Model format** differs per platform. When writing to both, auto-convert:
- OpenCode format: `provider/model-name` (e.g. `minimax/MiniMax-M2.7`)
- Claude Code format: model name without provider prefix (e.g. `claude-opus-4-6`)

Conversion: `anthropic/claude-opus-4-6` → strip provider → `claude-opus-4-6` for Claude Code.
If model has no provider prefix, use as-is for both platforms.

### Step 5: Update agent files

Edit the `model:` line in frontmatter.
If no `model:` line exists, add it after `mode: subagent`.
Update files ONLY for the current platform — do NOT touch the other platform's files.

### Step 6: oh-my-opencode Model Guard (OpenCode only)

After updating agent files, check `~/.config/opencode/oh-my-opencode.json`:

- If file does NOT exist → skip (agent .md models work directly)
- If file exists:
  a. Read `agents.sisyphus-junior.model`
  b. Compare with the Discriminator/Arbiter models just configured
  c. If MATCH → no action needed
  d. If MISMATCH → warn:

```
⚠️ oh-my-opencode detected — model override required

oh-my-opencode ignores custom agent model fields (Zod schema limitation).
Discriminator and Arbiter will actually use: {sisyphus-junior model}
You configured: {Discriminator model}

Fix: Update sisyphus-junior model in oh-my-opencode.json?
(⚠️ This affects ALL subagents — oracle, explore, librarian, etc.)

1. Yes — set sisyphus-junior to {Discriminator model}
2. No — keep current, Discriminator/Arbiter will use {sisyphus-junior model}
```

If user says Yes:
- Edit `~/.config/opencode/oh-my-opencode.json` → `agents.sisyphus-junior.model` = Discriminator's model
- Display updated config
- Warn: "Restart OpenCode for changes to take effect."

### Step 7: Verify and remind

Re-read the files, confirm changes saved, display updated table.
Remind user to restart OpenCode/Claude Code for changes to take effect.

---

## 7. Status Workflow — `/tri status`

Scan `.trident/` (exclude `archive/`). Group by: In Progress vs Completed. List archived from `.trident/archive/`.

---

## 8. Archive Workflow — `/tri archive`

Precondition: Status `done` (warn if `ready`, reject if `iterating`).

1. Move to `.trident/archive/YYYY-MM-DD-{task-slug}/`
2. Produce archive report with final scores
3. Ask user: "Want to extract domain knowledge into a reusable skill?"

---

## 9. File Structure

```
.trident/{task-slug}/
├── generator.md        ← Generator's design + versions + feedback
├── discriminator.md    ← Discriminator's accumulated knowledge
├── arbiter.md          ← Arbiter's review log (read-only, Generator writes, Arbiter never reads)
├── tasks.md            ← Implementation tasks (/tri apply)
├── apply-log.md        ← Round log with scores
└── .done               ← Signal file (transient)
```

---

## 10. Language Rules

- Internal files (generator.md, discriminator.md, etc.) → English ONLY
- User-facing output (reports, summaries, todos) → match user's language

---

## 11. Quick Reference

| Command | Description |
|---------|-------------|
| `/tri new {description}` | Start or continue design review |
| `/tri apply {task-slug}` | Implement with Three Strikes |
| `/tri status` | Show active and completed tasks |
| `/tri archive {task-slug}` | Archive completed task |
| `/tri models` | Show and configure models for all roles |
| `/tri auto {description}` | Full cycle: `/tri new` + `/tri apply` in one go |

### Convergence Checklist

- [ ] All applicable dimensions at ≥ 9
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

## 12. Anti-Patterns

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
| Rapid polling `background_output(block=false)` | Wastes tokens, spams user screen. Max 3 attempts, then end response and wait |

---

## Loading Additional Resources

When you need templates, prompts, or reference material, load from:

| Need | File |
|------|------|
| Create generator.md | `templates/generator-template.md` |
| Create discriminator.md | `templates/discriminator-template.md` |
| Create arbiter.md | `templates/arbiter-template.md` |
| Create apply-log.md | `templates/apply-log-template.md` |
| Fire Discriminator (first round) | `prompts/discriminator-first.md` |
| Fire Discriminator (continuation) | `prompts/discriminator-continuation.md` |
| Fire Arbiter (design phase) | `prompts/arbiter-design.md` |
| Fire Arbiter (apply phase) | `prompts/arbiter-apply.md` |
| Heartbeat invocation | `reference/heartbeat.md` |
| Discriminator session recovery | `reference/session-recovery.md` |

All paths are relative to this skill's directory.
