---
name: "Trident: Auto"
description: "Run full Trident cycle — design + implement in one go"
category: Design
tags: [trident, auto, full-cycle]
---

Run `/tri new` then `/tri apply` automatically. User explicitly authorizes skipping the hard stop between phases.

---

**Input**: `$ARGUMENTS` — task description (same as `/tri new`)

**Steps**

1. **Execute `/tri new` workflow** (Section 4 of SKILL.md)
   - Auto-slugify the description
   - Full design iteration: Generator ↔ Discriminator ↔ Arbiter
   - Continue until all 7 dimensions ≥ 9 AND Arbiter approves
   - Produce Convergence Report
   - Status → `ready`

2. **Immediately execute `/tri apply` workflow** (Section 5 of SKILL.md)
   - Do NOT wait for user to invoke `/tri apply` — this is the purpose of `/tri auto`
   - Generate tasks.md + apply-log.md
   - Three Strikes: Round 1 → Round 2 → Round 3
   - Build & Verify
   - Produce Completion Report
   - Status → `done`

3. **STOP and report** — wait for user to invoke `/tri archive`

**Progress Tracking (MANDATORY — use todo list, update in real-time):**

The user MUST see a live todo list throughout the entire process.
Update it after EVERY step — mark `in_progress` when starting, `completed` when done.

```
# /tri auto — {task-slug}

## Design Phase (/tri new)
- [x] Skill Discovery: loaded [frontend-patterns]
- [x] v1: Generator produces design
- [x] v1: Discriminator (model: xxx) scored — ITERATE
        | Dimension             | Score |
        |-----------------------|-------|
        | Correctness           |   7   | ← MUST FIX: ...
        | ...                   |       |
- [x] v2: Generator addresses Discriminator feedback
- [x] v2: Discriminator (model: xxx) scored — all ≥ 9
- [x] v2: Arbiter (model: xxx) Final Review — READY ✅
- [x] Convergence Report produced

## Apply Phase (/tri apply)
- [x] Round 1: Generator implements
        - [x] Task 1/4: {file} — {description}
        - [x] Task 2/4: {file} — {description}
        - [x] Task 3/4: {file} — {description}
        - [x] Task 4/4: {file} — {description}
- [x] Round 1: Generator Build & Verify — ✅
- [x] Round 1: Discriminator (model: xxx) reviewing...
- [x] Round 1: Discriminator scored — PASS
- [x] Round 1: Arbiter (model: xxx) Final Review — PASS ✅
- [ ] Completion Report

## Done — waiting for /tri archive
```

Every todo item must show:
- Which round (Round 1/2/3)
- Who is working (Generator/Discriminator/Arbiter)
- Their model name (self-identified)
- Score table after every Discriminator/Arbiter evaluation
- Sub-tasks for implementation (each file = one sub-task)

Do NOT summarize or skip steps. The user wants to see every step happening.

**Rules:**
- Internal `.md` files MUST be in English
- User-facing output MUST match the user's language
- All SKILL.md rules apply (scoring, verification, isolation, etc.)
- The ONLY difference from running `/tri new` + `/tri apply` separately is: no pause between them
- If `/tri new` fails to converge → stop and report, do NOT proceed to apply
- If `/tri apply` fails (Round 3 exhausted) → Human-in-the-Loop Escalation as normal
