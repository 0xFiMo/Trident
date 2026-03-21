# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-03-22

### Fixed
- `install.sh` had wrong GitHub URL (pointed to anthropic-community instead of 0xFiMo)

## [1.0.0] - 2026-03-22

### Summary

First public release. Trident is ready for open-source.

---

## [0.0.5] - 2026-03-22

### Added
- `scripts/heartbeat.ps1` — PowerShell heartbeat for Windows native support
- `.gitignore` for open-source project
- `trident-generator.md` agent definition — Triforce now has all 3 roles as independent agents
- Discriminator session recovery mechanism — recovers from session expiry using discriminator.md
- Heartbeat timeout recovery guidance — 4-step recovery when background agent doesn't respond
- Domain skill selection guidance for Discriminator invocation
- MUST FIX classification rules inlined into all D and A prompt templates (agents can't see SKILL.md sections)
- Score regression rule — D must explain if lowering a score from previous round
- Windows support in README platforms table, docs/installation.md, and install.sh

### Changed
- Heartbeat invocation is now platform-agnostic — auto-detects bash vs PowerShell, no Python dependency
- All hardcoded `.opencode/` heartbeat paths replaced with `{heartbeat}` placeholder pattern
- Verdict terms unified: Arbiter uses ITERATE (not CONTINUE) to match Discriminator
- Arbiter agent can write `.done` signal file (exception to "no file writes" rule)
- Arbiter agent scope clarified: process review in `/tri new`, process + implementation in `/tri apply`
- "Step 6: Ship" renamed to "Step 6: Finalize Design"
- All remaining "ship" terminology replaced with "READY"

### Fixed
- SKILL.md said "Arbiter MUST NOT write to any file" but Arbiter needs to create `.done` — rule updated
- D agent had vague `.done` signal (`<your verdict>`) — now explicit per phase (READY/ITERATE or PASS/FAIL)
- Round 2 Arbiter reference was too vague — added explicit `.done` reminder
- install.sh final message said `/tri list` instead of `/tri status`
- 23 issues found and fixed across 4 rounds of systematic review

## [0.0.4] - 2026-03-21

### Changed
- `/tri list` renamed to `/tri status` — dashboard view grouped by In Progress / Completed / Archived
- Status output now shows progress context per task (design phase, ready for apply, round N)
- Completed tasks show one-line summary and iteration count
- Discriminator scoring rules strengthened:
  - Safety dimension now explicitly requires "defensive input validation, graceful handling of invalid/edge-case inputs"
  - Correctness dimension now explicitly requires "no unhandled exceptions on any input"
  - MUST FIX vs NICE TO HAVE classification rules are now deterministic (no judgment calls)
  - Missing input validation on public API = always MUST FIX, never NICE TO HAVE
  - "The spec doesn't mention it" is NOT a valid reason to skip input validation

### Fixed
- Discriminator could classify missing input validation as NICE TO HAVE, allowing bugs to ship (caught by LRU Cache benchmark — capacity=0 caused AssertionError crash)

## [0.0.3] - 2026-03-21

### Added
- Benchmark suite: 3 tasks (LRU Cache, Traffic Light, Bounded Queue) with test suites, prompts, and run scripts
- Benchmark protocol (PROTOCOL.md): environment isolation, execution order, prohibited actions
- First benchmark results: Kimi K2.5 with detailed code quality analysis

### Changed
- All 7 dimension gate thresholds unified to ≥ 9 (previously varied 6-9)
- Score tables now use 7-row vertical format with full dimension names (no abbreviations)
- Arbiter is now MANDATORY before SHIP IT in both `/tri new` and `/tri apply`
  - `/tri new`: Arbiter Final Review required before design convergence
  - `/tri apply`: Arbiter Final Review required after any round D PASS, before completion
- Arbiter FAIL does NOT consume a round — Generator fixes and re-submits D+A within same round
  - Only Discriminator FAIL consumes a round and advances to next
  - Round 3 allows up to 3 fix attempts before hard stop
- Discriminator must score honestly — if work deserves 10, give 10 (no deflation)

### Added
- Human-in-the-Loop Escalation: when Round 3 exhausted, structured report with G/D/A perspectives for human judgment (5 decision options)
- Language rules: internal files in English, all user-facing output matches user's language
  - Language rule added to all command files (new, apply, list, archive)
  - Language rule added to Discriminator and Arbiter agent definitions
- Design Summary and Implementation Summary now include key-point tables
  - Problem/Root Cause/Fix/Scope/Risk table for all tasks
  - Before/After table for modification tasks (bugfix, refactoring)
- `/tri archive` now suggests extracting domain knowledge into reusable agent skills
- Command files rewritten to be action-oriented — agent auto-executes instead of asking user
- Auto-slug generation from user description (no confirmation needed)
- Progress tracking (MANDATORY) for both `/tri new` and `/tri apply`
- `/tri new` Convergence Report (MANDATORY): score history table, design summary, ASCII diagram, change surface
- `install.sh` detects existing installations (shows "Updating" vs "Installing")
- `install.sh` copies `scripts/heartbeat.sh` to all platforms

## [0.0.2] - 2026-03-21

### Changed
- `/tri apply` redesigned: Pass 1/2/3 replaced with Round 1/2/3
  - Round 1: Generator implements + Discriminator reviews (session continuity)
  - Round 2: Generator fixes + Discriminator re-reviews (same session)
  - Round 3: Arbiter (fresh) + Generator collaborative review
  - Early exit: passes at any round skip remaining rounds
- Completion Report now mandatory: includes ASCII architecture diagrams and before/after comparison for bugfix/algorithm/refactoring tasks

### Added
- `scripts/heartbeat.sh` — platform-agnostic background agent completion detection via `.done` signal file polling (zero token cost)
- Signal file protocol: background agents create `.trident/{slug}/.done` on completion
- Discriminator prompt templates updated with signal file instructions

## [0.0.1] - 2026-03-21

### Added
- Trident Design Review methodology with Triforce (Generator, Discriminator, Arbiter)
- Seven-dimension scoring framework with configurable gate thresholds
- Three Strikes implementation verification (implement, self-audit, independent verify)
- Arbiter role for detecting collusion and score inflation
- Multi-platform support: Claude Code, OpenCode
- Interactive installer (`install.sh`) with platform auto-detection
- Slash commands: `/tri new`, `/tri apply`, `/tri list`, `/tri archive`
- Smart `/tri new` — creates new or continues existing review based on directory state
- `apply-log.md` template for tracking Three Strikes passes
- Task-type weight adjustment (algorithm, refactoring, hotfix, new-feature)
