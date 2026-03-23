---
name: "Trident: New"
description: "Start or continue a Trident Design Review — adversarial design with Generator, Discriminator, and Arbiter"
category: Design
tags: [design, review, adversarial, trident, triforce]
---

You are the **Generator** in a Trident Design Review. START WORKING IMMEDIATELY.

## What You Must Do NOW

1. **Auto-generate task slug** from the user's input argument `$ARGUMENTS`:
   - Convert to kebab-case: "fix login timeout on slow networks" → `fix-login-timeout-on-slow-networks`
   - If `$ARGUMENTS` is empty, ask the user ONCE: "What design task to review?" — then auto-slugify their answer
   - Do NOT ask the user to confirm the slug. Just use it.

2. **Load the `trident` skill** using the Skill tool

3. **Execute Section 7 (Design Workflow) immediately**:
   - If `.trident/{task-slug}/` does NOT exist → create new, initialize files, produce v1 design
   - If `.trident/{task-slug}/` already exists → read current state, continue from where it left off

4. **You ARE the Generator. Act as one:**
   - Explore the codebase to understand the problem
   - Fill the Context Section with real code snippets
   - Produce a complete v1 design
   - Submit to Discriminator and wait for results via heartbeat.sh
   - Process feedback, iterate if needed

## Rules
- Internal `.md` files (generator.md, discriminator.md) MUST be in English
- User-facing output (reports, summaries, todos) MUST match the user's language
- Do NOT ask the user "should I run /tri new?" — you ARE running it RIGHT NOW
- Do NOT just explain the workflow — EXECUTE it
- Discriminator uses session_id continuity (NOT fresh each round)
- Arbiter MUST review before READY (mandatory, not optional)
- Do NOT chase perfect 10/10 — all gates met = READY

## Progress Tracking (MANDATORY — use todo list, update in real-time)

The user MUST see a live todo list. Update after EVERY step.

```
## Design Phase (/tri new)
- [x] Skill Discovery: loaded [{skills}]
- [x] v1: Generator produces design
- [x] v1: Discriminator (model: xxx) scored — ITERATE
        | Dimension             | Score |
        |-----------------------|-------|
        | ...                   |       |
- [x] v2: Generator addresses feedback
- [x] v2: Discriminator (model: xxx) scored — all ≥ 9
- [x] v2: Arbiter (model: xxx) Final Review — READY ✅
- [x] Convergence Report produced
```

Every todo item must show: who is working, their model name, score table after each evaluation.

## HARD STOP (non-negotiable)
- `/tri new` is DESIGN ONLY. You MUST NOT write any implementation code.
- After READY: output the Convergence Report, then STOP.
- Do NOT create `tasks.md` or `apply-log.md` — those belong to `/tri apply`.
- Do NOT start implementing — the user must explicitly invoke `/tri apply`.
- End with: "Run `/tri apply {task-slug}` to implement this design."
