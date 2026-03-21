#!/bin/bash
#
# heartbeat.sh — Poll for Trident background agent completion
#
# Watches for .trident/<task-slug>/.done signal file created by the
# Discriminator or Arbiter when they finish their evaluation.
#
# Usage:
#   heartbeat.sh <task-slug> [timeout_seconds] [interval_seconds]
#
# Arguments:
#   task-slug   Task directory name under .trident/
#   timeout     Max wait time in seconds (default: 300 = 5 min)
#   interval    Poll interval in seconds (default: 3)
#
# Exit codes:
#   0  Signal file detected — agent completed
#   1  Timeout — agent did not complete within the time limit
#
# The signal file (.done) contains the agent's verdict summary.
# The full evaluation is in discriminator.md.
#
# Platform-agnostic: works on any system with bash + sleep.

set -euo pipefail

TASK_SLUG="${1:?Usage: heartbeat.sh <task-slug> [timeout] [interval]}"
TIMEOUT="${2:-300}"
INTERVAL="${3:-3}"

SIGNAL=".trident/${TASK_SLUG}/.done"

elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
    if [ -f "$SIGNAL" ]; then
        cat "$SIGNAL"
        exit 0
    fi
    sleep "$INTERVAL"
    elapsed=$((elapsed + INTERVAL))
done

echo "TIMEOUT: no signal after ${TIMEOUT}s"
exit 1
