# {Task Title} — Trident Design Review

## User Request (verbatim)
{paste the user's original request EXACTLY as they wrote it — do NOT paraphrase}

## Meta
- Task: {bug/feature description}
- Task Type: {algorithm | refactoring | hotfix | new-feature}
- User Language: {detected from user's input, e.g., zh-TW, en, ja}
- Skills: [{list of domain skills loaded for this task, passed to Discriminator and Arbiter}]
- Root Cause: {if applicable}
- Status: iterating | ready | implementing | done
- Current Version: v{N}
- Score History: (add columns as versions are scored — start with v1 only)

| Dimension | v1 |
|-----------|:--:|
| Correctness | |
| Algorithmic Soundness | |
| Safety | |
| Measurability | |
| Minimality | |
| Testability | |
| Conventions | |
| **Verdict** | |

## Context for Review

### Modified Code (before)
{code snippets of functions being changed — BEFORE modification}

### Related Code (not modified)
{code that constrains or interacts with the change}

### Pattern Reference
{similar patterns in codebase that this change should follow}

### Verification Checklist
- [ ] {specific question Discriminator must answer}
- [ ] {specific question Discriminator must answer}

## Version History

### v1 — {title}
#### Design
{complete design description}

#### Discriminator Feedback (v1)
| Dimension | Score | MUST FIX | NICE TO HAVE |
|-----------|-------|----------|--------------|

#### Arbiter Evaluation
{arbiter output — MANDATORY before READY, optional during iteration}
