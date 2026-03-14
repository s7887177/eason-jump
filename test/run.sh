#!/usr/bin/env sh
set -e

PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$PROJ_DIR/dist"
FAILURES=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== eason-jump tests ==="

# Build first
sh "$PROJ_DIR/scripts/build.sh" >/dev/null

# Set up isolated test environment
TEST_DATA_DIR=$(mktemp -d)
TEST_HOME=$(mktemp -d)
mkdir -p "$TEST_DATA_DIR/sessions"

# Helper: run j-core in isolated env (custom data dir + fake HOME so init won't touch real rc files)
jt() {
    EASON_JUMP_DATA_DIR="$TEST_DATA_DIR" HOME="$TEST_HOME" sh "$DIST_DIR/j-core" "$@"
}

# === Usage / Help ===
echo ""
echo "--- usage & help ---"
_out=$(jt --help 2>&1)
if echo "$_out" | grep -q "eason-jump"; then
    pass "j-core --help prints usage"
else
    fail "j-core --help should print usage"
fi

_out=$(jt help jump 2>&1)
if echo "$_out" | grep -q "j jump"; then
    pass "j help jump shows detailed help"
else
    fail "j help jump: $_out"
fi

_out=$(jt help 2>&1)
if echo "$_out" | grep -q "Commands:"; then
    pass "j help shows command list"
else
    fail "j help: $_out"
fi

# === Alias CRUD ===
echo ""
echo "--- alias CRUD ---"
SID="test_alias_$$"

# Save session alias (shortcut form)
_out=$(jt myproject /tmp "$SID" 2>&1)
if echo "$_out" | grep -q "saved: myproject"; then
    pass "alias save (session)"
else
    fail "alias save (session): $_out"
fi

# List alias — should show aligned table with type
_out=$(jt ls "$SID" 2>&1)
if echo "$_out" | grep -q "session" && echo "$_out" | grep -q "myproject" && echo "$_out" | grep -q "/tmp"; then
    pass "alias list (table format)"
else
    fail "alias list: $_out"
fi

# Resolve alias
_out=$(jt _resolve myproject "$SID" 2>&1)
if [ "$_out" = "/tmp" ]; then
    pass "alias resolve (session)"
else
    fail "alias resolve (session): $_out"
fi

# Save global alias
_out=$(jt -g myglobal /var "$SID" 2>&1)
if echo "$_out" | grep -q "saved (global): myglobal"; then
    pass "alias save (global)"
else
    fail "alias save (global): $_out"
fi

# List should show both
_out=$(jt ls "$SID" 2>&1)
if echo "$_out" | grep -q "global" && echo "$_out" | grep -q "session"; then
    pass "alias list shows both types"
else
    fail "alias list both: $_out"
fi

# Session overrides global: create session alias with same name
_out=$(jt create samename /tmp "$SID" 2>&1)
if echo "$_out" | grep -q "saved: samename"; then
    pass "session alias create"
else
    fail "session alias create: $_out"
fi
_out=$(jt -g create samename /var "$SID" 2>&1)
if echo "$_out" | grep -q "saved (global): samename"; then
    pass "global alias replaces session"
else
    fail "global alias replaces session: $_out"
fi
_out=$(jt _resolve samename "$SID" 2>&1)
if [ "$_out" = "/var" ]; then
    pass "resolve after global override"
else
    fail "resolve after global override: $_out"
fi

# Remove alias
_out=$(jt rm myproject "$SID" 2>&1)
if echo "$_out" | grep -q "removed"; then
    pass "alias remove"
else
    fail "alias remove: $_out"
fi

# Resolve after remove should fail
if jt _resolve myproject "$SID" 2>/dev/null; then
    fail "alias resolve after remove should fail"
else
    pass "alias resolve after remove fails"
fi

# Reject reserved name
jt init /tmp 2>/dev/null || true
_out=$(jt _resolve init "$SID" 2>&1) && {
    fail "reserved name 'init' should not be saved as alias"
} || {
    pass "reserved name 'init' not saved as alias"
}

# === Alias promote ===
echo ""
echo "--- alias promote ---"
SID_PROMOTE="test_promote_$$"
jt create promtest /tmp "$SID_PROMOTE" >/dev/null
_out=$(jt _promote promtest "$SID_PROMOTE" 2>&1)
if echo "$_out" | grep -q "promoted to global: promtest"; then
    pass "alias promote session to global"
else
    fail "alias promote: $_out"
fi
# Should be global now
_out=$(jt ls "$SID_PROMOTE" 2>&1)
if echo "$_out" | grep -q "global" && echo "$_out" | grep -q "promtest"; then
    pass "promoted alias is global"
else
    fail "promoted alias in list: $_out"
fi

# === History (graph data structure) ===
echo ""
echo "--- history ---"
SID="test_session_$$"

jt _record /aaa "$SID"
jt _record /bbb "$SID"
jt _record /ccc "$SID"

# Linear history
_out=$(jt history "$SID" 2>&1)
if echo "$_out" | grep -q "/aaa" && echo "$_out" | grep -q "/bbb" && echo "$_out" | grep -q "/ccc"; then
    pass "linear history shows all nodes"
else
    fail "linear history: $_out"
fi

# Back
_out=$(jt b "$SID" 2>&1)
if [ "$_out" = "/bbb" ]; then
    pass "back to /bbb"
else
    fail "back: $_out"
fi

# Back again
_out=$(jt b "$SID" 2>&1)
if [ "$_out" = "/aaa" ]; then
    pass "back to /aaa"
else
    fail "back again: $_out"
fi

# Forward
_out=$(jt f "$SID" 2>&1)
if [ "$_out" = "/bbb" ]; then
    pass "forward to /bbb"
else
    fail "forward: $_out"
fi

# === Branching graph ===
echo ""
echo "--- branching graph ---"
SID_BRANCH="test_branch_$$"

jt _record /home "$SID_BRANCH"
jt _record /home/projects "$SID_BRANCH"
jt _record /home "$SID_BRANCH"
jt _record /home/projects "$SID_BRANCH"
jt _record /tmp/tmp "$SID_BRANCH"

# Back twice (HEAD at /home/projects then /home)
jt b "$SID_BRANCH" >/dev/null
jt b "$SID_BRANCH" >/dev/null
jt b "$SID_BRANCH" >/dev/null

# Now record a new path — this creates a branch
jt _record /home/somewhere "$SID_BRANCH"

# Graph should show branching
_out=$(jt history --graph "$SID_BRANCH" 2>&1)
if echo "$_out" | grep -q '|' && echo "$_out" | grep -q '/home/somewhere'; then
    pass "graph shows branching"
else
    fail "graph branching: $_out"
fi

# Linear should only show main path (through to /home/somewhere)
_out=$(jt history "$SID_BRANCH" 2>&1)
if echo "$_out" | grep -q "/home/somewhere"; then
    pass "linear history shows main path to HEAD"
else
    fail "linear main path: $_out"
fi

# === History truncation via branching ===
echo ""
echo "--- branch + forward ---"
SID_BF="test_bf_$$"

jt _record /one "$SID_BF"
jt _record /two "$SID_BF"
jt _record /three "$SID_BF"

# Go back
_out=$(jt b "$SID_BF" 2>&1)
if [ "$_out" = "/two" ]; then
    pass "back to /two"
else
    fail "bf back: $_out"
fi

# New cd creates branch — /four is child of /two
jt _record /four "$SID_BF"

# Forward should fail (HEAD is at /four, leaf)
_out=$(jt f "$SID_BF" 2>&1) && {
    fail "forward from leaf should fail"
} || {
    pass "forward from leaf fails"
}

# Back to /two
_out=$(jt b "$SID_BF" 2>&1)
if [ "$_out" = "/two" ]; then
    pass "back to /two from branch"
else
    fail "back from branch: $_out"
fi

# Forward should go to /four (last visited child)
_out=$(jt f "$SID_BF" 2>&1)
if [ "$_out" = "/four" ]; then
    pass "forward to /four (last visited)"
else
    fail "forward to last visited: $_out"
fi

# === Clear ===
echo ""
echo "--- clear ---"
_out=$(jt clear 2>&1)
if echo "$_out" | grep -q "history cleared"; then
    pass "history clear"
else
    fail "history clear: $_out"
fi

# Cleanup
rm -rf "$TEST_DATA_DIR" "$TEST_HOME"

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "All tests passed!"
else
    echo "$FAILURES test(s) failed"
    exit 1
fi
