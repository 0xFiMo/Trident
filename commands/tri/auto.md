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

**Rules:**
- Internal `.md` files MUST be in English
- User-facing output MUST match the user's language
- All SKILL.md rules apply (scoring, verification, isolation, etc.)
- The ONLY difference from running `/tri new` + `/tri apply` separately is: no pause between them
- If `/tri new` fails to converge → stop and report, do NOT proceed to apply
- If `/tri apply` fails (Round 3 exhausted) → Human-in-the-Loop Escalation as normal
