# Discriminator Prompt — Continuation Round

Use this prompt when firing the Discriminator with an existing session_id.

```
Generator has submitted v{N} addressing your previous feedback.

## Response Language
The user's language is: {from generator.md Meta → User Language}
All user-facing output MUST be in this language.

## Changes from v{N-1}
{diff table from generator.md}

## Your Previous Issues
{list from previous round}

## Task
1. Re-read the user's original request in generator.md — does the design still address it?
2. Read the actual source files — verify Generator's fixes match what is claimed
3. Verify each previous MUST FIX is resolved in the actual code
3. Re-score all 7 dimensions
4. Identify any NEW issues introduced by the fixes
5. Do NOT re-verify issues you already confirmed in previous rounds
6. If you LOWER a score from previous round, explain why

## Signal Completion
After completing your evaluation, you MUST create the signal file:
  echo "VERDICT: <READY or ITERATE>" > .trident/{task-slug}/.done
```
