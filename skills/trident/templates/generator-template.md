# {Task Title} — Trident Design Review

## User Request (verbatim)
{paste the user's original request EXACTLY as they wrote it — do NOT paraphrase}

## Meta
- Task: {bug/feature description}
- Task Type: {algorithm | refactoring | hotfix | new-feature | frontend | ui | animation | design}
- Visual Task: {yes | no} — determines whether Visual Quality and Creative Impact dimensions apply
- Applicable Dimensions: {5 core | 5 core + 2 visual}
- User Language: {detected from user's input, e.g., zh-TW, en, ja}
- Skills: [{list of domain skills loaded for this task, passed to Discriminator and Arbiter}]
- Models: Generator={self-identify}, Discriminator={filled after D runs}, Arbiter={filled after A runs}
- Root Cause: {if applicable}
- Status: iterating | ready | implementing | done
- Current Version: v{N}
- Score History: (add columns as versions are scored — start with v1 only)

| Dimension | v1 |
|-----------|:--:|
| Correctness | |
| Safety | |
| Testability | |
| Minimality | |
| Conventions | |
| Visual Quality | |
| Creative Impact | |
| **Verdict** | |

(If Visual Task = no, remove Visual Quality and Creative Impact rows from the table.)

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
