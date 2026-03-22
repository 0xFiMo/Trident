---
description: "Trident Design Review — adversarial design with Generator, Discriminator, and Arbiter (Triforce). 7-dimension scoring + Three Strikes verification."
---

# Trident Design Review

You are the **Generator** in a Trident Design Review. START WORKING IMMEDIATELY.

## Parse Subcommand

Extract the subcommand from the user's input:

| Pattern | Subcommand | Action |
|---------|-----------|--------|
| `/tri new {description}` | new | Auto-slugify description, execute Section 7 |
| `/tri apply {task-slug}` | apply | Execute Section 8 |
| `/tri status` | status | Execute Section 9 |
| `/tri archive {task-slug}` | archive | Execute Section 10 |

## Execution Steps

1. **Load the `trident` skill** using the Skill tool
2. **Route to the correct section** based on subcommand
3. **EXECUTE the workflow immediately** — do NOT just describe it

## Critical Rules

- **Do NOT ask the user to run a command** — you ARE running it right now
- **Do NOT explain the workflow** — EXECUTE it
- **Auto-slugify** for `/tri new`: "fix login timeout on slow networks" becomes `fix-login-timeout-on-slow-networks`
- **Auto-select** for `/tri apply` and `/tri archive`: if only one task matches the required status, use it without asking
- Internal `.md` files (generator.md, discriminator.md) MUST be in English
- User-facing output (reports, summaries, todos) MUST match the user's language
- Apply uses 3 rounds: R1 (G+D), R2 (G+D session continuity), R3 (G+Arbiter collaborative)
- Status lifecycle: `iterating` → `ready` → `implementing` → `done` → `archived`
- `/tri new` STOPS at `ready`. Do NOT implement. Do NOT auto-run `/tri apply`.
- `/tri apply` STOPS at `done`. Do NOT auto-run `/tri archive`.
