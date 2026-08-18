# One pass, bottom-up. Pushing the lower branch is what gives the upper one
# something new to land on, so the order is the whole trick.

fixture_new "$WORK"
a=$(fixture_branch feature-a)
b=$(fixture_branch feature-b feature-a)
fixture_pr feature-a OPEN main 1
fixture_pr feature-b OPEN feature-a 2
fixture_advance_main file-b 'moved'

out=$(git -C "$REPO/main" refresh --all --no-icons 2>&1) || true

lower=$(printf '%s\n' "$out" | grep -n '^feature-a' | cut -d: -f1)
upper=$(printf '%s\n' "$out" | grep -n '^feature-b' | cut -d: -f1)
if [ -n "$lower" ] && [ -n "$upper" ] && [ "$lower" -lt "$upper" ]; then
    ok "the lower branch is processed first"
else
    bad "the lower branch is processed first (a=$lower b=$upper)" "$out"
fi

# One pass is enough: nothing is left to do.
out=$(git -C "$REPO/main" refresh --all --dry-run --no-icons 2>&1) || true
assert_absent "a second pass finds no conflicts" "conflict" "$out"

mb=$(git -C "$b" merge-base origin/feature-a HEAD)
assert_eq "the upper branch sits on the pushed lower branch" \
    "$(git -C "$b" rev-parse origin/feature-a)" "$mb"
