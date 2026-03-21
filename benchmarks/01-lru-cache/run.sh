#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <path/to/solution.py>"
    exit 2
fi

SOLUTION_PATH="$1"
if [[ ! -f "$SOLUTION_PATH" ]]; then
    echo "Error: solution file not found: $SOLUTION_PATH"
    exit 2
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

cp "$SOLUTION_PATH" "$WORKDIR/solution.py"
cp "$SCRIPT_DIR/test_lru.py" "$WORKDIR/test_lru.py"

echo "========================================"
echo "LRU Cache Benchmark"
echo "========================================"
echo "Solution: $SOLUTION_PATH"
echo "Work dir: $WORKDIR"
echo ""

EXIT_CODE=0

echo "--- pytest (verbose) ---"
if python3 -m pytest "$WORKDIR/test_lru.py" -v --tb=short 2>&1; then
    echo ""
    echo "pytest: ALL PASSED"
else
    EXIT_CODE=1
    echo ""
    echo "pytest: FAILURES DETECTED"
fi

echo ""
echo "--- Category summary ---"
if python3 "$WORKDIR/test_lru.py" 2>&1; then
    :
else
    EXIT_CODE=1
fi

exit $EXIT_CODE
