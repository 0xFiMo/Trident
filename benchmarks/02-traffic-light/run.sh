#!/bin/bash
set -euo pipefail

# Traffic Light Benchmark Runner
# Usage: ./run.sh [path/to/traffic_light.html]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_FILE="$SCRIPT_DIR/test_traffic.html"
SOLUTION="${1:-}"
PORT=8742

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BOLD}========================================${NC}"
    echo -e "${BOLD}  Traffic Light Benchmark${NC}"
    echo -e "${BOLD}========================================${NC}"
    echo ""
}

print_checklist() {
    echo -e "${CYAN}Visual Verification Checklist:${NC}"
    echo ""
    echo -e "  ${BOLD}1. Initial State${NC}"
    echo "     [ ] NS shows GREEN, EW shows RED"
    echo "     [ ] Both pedestrian signals show STOP"
    echo "     [ ] Mode displays 'Normal', cycle count is 0"
    echo ""
    echo -e "  ${BOLD}2. Normal Cycle${NC}"
    echo "     [ ] NS Green lasts ~10s, then Yellow ~3s"
    echo "     [ ] All-Red buffer ~2s between direction changes"
    echo "     [ ] EW Green lasts ~10s, then Yellow ~3s"
    echo "     [ ] Cycle count increments after full 30s cycle"
    echo "     [ ] Elapsed timer counts up within each phase"
    echo ""
    echo -e "  ${BOLD}3. Pedestrian Walk${NC}"
    echo "     [ ] Click NS 'Request Walk' during any phase"
    echo "     [ ] Walk activates at NEXT NS green (not current)"
    echo "     [ ] During walk: NS vehicle = RED, NS ped = WALK"
    echo "     [ ] Walk lasts 8s, then NS turns GREEN"
    echo "     [ ] Without button press, no walk phase occurs"
    echo ""
    echo -e "  ${BOLD}4. Emergency Mode${NC}"
    echo "     [ ] Toggle Emergency: all lights flash RED"
    echo "     [ ] Flash rate: 1s on / 1s off"
    echo "     [ ] Pedestrian buttons ignored"
    echo "     [ ] Toggle off: resumes Normal from Phase 1"
    echo ""
    echo -e "  ${BOLD}5. Night Mode${NC}"
    echo "     [ ] Toggle Night: all lights flash YELLOW"
    echo "     [ ] Flash rate: 1s on / 1s off"
    echo "     [ ] Pedestrian buttons ignored"
    echo "     [ ] Toggle off: resumes Normal from Phase 1"
    echo ""
    echo -e "  ${BOLD}6. Code Quality${NC}"
    echo "     [ ] State machine exposed on window.TrafficLight"
    echo "     [ ] getState() returns correct shape"
    echo "     [ ] tick(), requestWalk(), setMode(), reset() work"
    echo "     [ ] No console errors"
    echo ""
}

print_header

# Validate test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}ERROR: Test file not found: $TEST_FILE${NC}"
    exit 1
fi

# Check solution argument
if [ -z "$SOLUTION" ]; then
    echo -e "${YELLOW}No solution file provided.${NC}"
    echo ""
    echo "Usage: ./run.sh path/to/traffic_light.html"
    echo ""
    echo "Files in this benchmark:"
    echo "  prompt.md          - Task prompt for the model"
    echo "  test_traffic.html  - Automated state machine tests (18 cases)"
    echo "  run.sh             - This runner script"
    echo ""
    echo -e "${CYAN}The test file can be opened standalone to verify the reference${NC}"
    echo -e "${CYAN}state machine implementation passes all 18 tests.${NC}"
    echo ""

    # Offer to open test file
    if command -v xdg-open &>/dev/null; then
        echo -e "Open test file in browser? ${BOLD}xdg-open $TEST_FILE${NC}"
    elif command -v open &>/dev/null; then
        echo -e "Open test file in browser? ${BOLD}open $TEST_FILE${NC}"
    fi
    exit 0
fi

# Validate solution file
if [ ! -f "$SOLUTION" ]; then
    echo -e "${RED}ERROR: Solution file not found: $SOLUTION${NC}"
    exit 1
fi

SOLUTION="$(cd "$(dirname "$SOLUTION")" && pwd)/$(basename "$SOLUTION")"

echo -e "${GREEN}Solution:${NC}  $SOLUTION"
echo -e "${GREEN}Tests:${NC}     $TEST_FILE"
echo ""

# Try to serve files if npx is available
if command -v npx &>/dev/null; then
    echo -e "${CYAN}Starting local server on port $PORT...${NC}"
    echo ""

    # Create a temporary directory with both files
    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    cp "$SOLUTION" "$TMPDIR/traffic_light.html"
    cp "$TEST_FILE" "$TMPDIR/test_traffic.html"

    echo -e "  Solution:  ${BOLD}http://localhost:$PORT/traffic_light.html${NC}"
    echo -e "  Tests:     ${BOLD}http://localhost:$PORT/test_traffic.html${NC}"
    echo ""
    print_checklist
    echo -e "${YELLOW}Press Ctrl+C to stop the server.${NC}"
    echo ""

    # Try npx serve, fall back to python
    npx -y serve "$TMPDIR" -p "$PORT" -s 2>/dev/null || {
        echo -e "${YELLOW}npx serve failed, trying Python...${NC}"
        python3 -m http.server "$PORT" --directory "$TMPDIR" 2>/dev/null || {
            echo -e "${RED}Could not start server. Open files manually:${NC}"
            echo "  $SOLUTION"
            echo "  $TEST_FILE"
        }
    }
elif command -v python3 &>/dev/null; then
    echo -e "${CYAN}Starting Python server on port $PORT...${NC}"
    echo ""

    TMPDIR=$(mktemp -d)
    trap 'rm -rf "$TMPDIR"' EXIT

    cp "$SOLUTION" "$TMPDIR/traffic_light.html"
    cp "$TEST_FILE" "$TMPDIR/test_traffic.html"

    echo -e "  Solution:  ${BOLD}http://localhost:$PORT/traffic_light.html${NC}"
    echo -e "  Tests:     ${BOLD}http://localhost:$PORT/test_traffic.html${NC}"
    echo ""
    print_checklist
    echo -e "${YELLOW}Press Ctrl+C to stop the server.${NC}"
    echo ""

    python3 -m http.server "$PORT" --directory "$TMPDIR"
else
    echo -e "${YELLOW}No server available (npx/python3 not found).${NC}"
    echo "Open these files directly in your browser:"
    echo ""
    echo -e "  Solution:  ${BOLD}file://$SOLUTION${NC}"
    echo -e "  Tests:     ${BOLD}file://$TEST_FILE${NC}"
    echo ""
    print_checklist
fi
