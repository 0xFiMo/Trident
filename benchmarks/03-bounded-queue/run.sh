#!/bin/bash
# Usage: ./run.sh path/to/solution.py
#
# Runs the BoundedQueue test suite against the provided solution.
# Exit code 0 if all tests pass, 1 if any fail.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <path/to/solution.py>"
    echo ""
    echo "Example:"
    echo "  $0 ./my_solution.py"
    exit 1
fi

SOLUTION_FILE="$1"

if [ ! -f "$SOLUTION_FILE" ]; then
    echo "Error: Solution file not found: $SOLUTION_FILE"
    exit 1
fi

# Create temp working directory
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# Copy solution and test files
cp "$SOLUTION_FILE" "$WORK_DIR/solution.py"
cp "$SCRIPT_DIR/test_queue.py" "$WORK_DIR/test_queue.py"

echo "============================================================"
echo "Bounded Queue Benchmark"
echo "============================================================"
echo "Solution: $SOLUTION_FILE"
echo "Work dir: $WORK_DIR"
echo ""

EXIT_CODE=0

# --- Run with pytest (verbose, short tracebacks) ---
echo "--- pytest run ---"
if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

if $PYTHON -m pytest "$WORK_DIR/test_queue.py" -v --tb=short 2>&1; then
    echo ""
    echo "pytest: ALL PASSED"
else
    EXIT_CODE=1
    echo ""
    echo "pytest: SOME TESTS FAILED"
fi

echo ""

# --- Run standalone for custom summary (unbuffered for stress tests) ---
echo "--- standalone run (with summary) ---"
if $PYTHON -u "$WORK_DIR/test_queue.py" 2>&1; then
    :
else
    EXIT_CODE=1
fi

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "RESULT: ALL TESTS PASSED"
else
    echo "RESULT: SOME TESTS FAILED"
fi

exit $EXIT_CODE
