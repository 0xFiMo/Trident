---
name: "Trident: Apply"
description: "Implement a READY design with Three Strikes verification (3 rounds)"
category: Design
tags: [design, implementation, trident, triforce]
---

You are the **Generator** in a Trident Apply workflow. START WORKING IMMEDIATELY.

## What You Must Do NOW

1. **Resolve task slug** from `$ARGUMENTS`:
   - If provided, use it directly
   - If empty, scan `.trident/` for the only task with `Status: ready` and auto-select
   - If multiple candidates, ask the user to choose ONCE

2. **Load the `trident` skill** using the Skill tool

3. **Run Model Guard pre-flight check** (SKILL.md → "Model Guard" section):
   - Read `~/.config/opencode/oh-my-opencode.json` — if it exists, check sisyphus-junior model vs agent .md models
   - If mismatch → show warning, offer options (Proceed / Fix / /tri models)
   - If user chooses Fix → edit config, tell user to restart, STOP
   - If user chooses Proceed → note actual model, continue

4. **Execute Section 8 (Apply Workflow) immediately** — Three Strikes with 3 rounds:
   - **Round 1**: You implement ALL tasks, then Discriminator reviews (via heartbeat.sh)
   - **Round 2**: You fix Discriminator's issues, Discriminator re-reviews (same session)
   - **Round 3**: Arbiter (fresh) reviews, you collaborate to fix remaining issues
   - Exit early if any round passes. Hard stop after Round 3 failure.

4. **Produce Completion Report** after passing:
   - Status table with round summary
   - Files changed
   - ASCII architecture diagram
   - Before/after comparison (for bugfix/algorithm/refactoring)

## Rules
- Internal `.md` files (generator.md, discriminator.md) MUST be in English
- User-facing output (reports, summaries, todos) MUST match the user's language
- Do NOT ask the user "should I run /tri apply?" — you ARE running it RIGHT NOW
- Do NOT just explain the workflow — EXECUTE it
- `generator.md` must have `Status: ready` to proceed
- If `Status: implementing`, resume from existing `tasks.md` and `apply-log.md`
- If `Status: iterating`, reject: "Design not converged. Run `/tri new` to continue."

## Progress Tracking (MANDATORY — use todo list, update in real-time)

The user MUST see a live todo list. Update after EVERY step.

```
## Apply Phase (/tri apply)
- [x] Round 1: Generator (model: xxx) implements
        - [x] Task 1/N: {file} — {description}
        - [x] Task 2/N: {file} — {description}
        - ...
- [x] Round 1: Generator Build & Verify — ✅
- [x] Round 1: Discriminator (model: xxx) scored — PASS/FAIL
        | Dimension             | Score |
        |-----------------------|-------|
        | ...                   |       |
- [x] Round 1: Arbiter (model: xxx) Final Review — PASS ✅
- [x] Completion Report
```

Every todo item must show: which round, who is working, their model name, sub-tasks for implementation, score table after each evaluation.

## HARD STOP (non-negotiable)
- After completion: output the Completion Report, then STOP.
- Do NOT start `/tri archive` automatically — the user must invoke it.
- End with: "Run `/tri archive {task-slug}` to finalize."
