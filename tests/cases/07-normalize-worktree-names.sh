# The layout is one directory per branch directly under the repository. A
# branch name with a `/` would nest instead, so the directory name can be
# flattened while the branch keeps its own name.

fixture_new "$WORK"

# Off by default: today's behaviour, which nests.
d=$(git -C "$REPO/main" new-worktree abc/one 2>/dev/null)
assert_eq "off by default, the name nests" "$REPO/abc/one" "$d"

git -C "$REPO/.git" config refresh.normalizeWorktreeNames true
d=$(git -C "$REPO/main" new-worktree abc/two 2>/dev/null)
assert_eq "on, the directory is flattened" "$REPO/abc_two" "$d"
assert_eq "and the branch keeps its own name" \
    "abc/two" "$(git -C "$d" branch --show-current)"

d=$(git -C "$REPO/main" new-worktree abc/two 2>/dev/null)
assert_eq "going back to it finds the flattened directory" "$REPO/abc_two" "$d"

git -C "$REPO/.git" config refresh.normalizeReplacement -
d=$(git -C "$REPO/main" new-worktree abc/three 2>/dev/null)
assert_eq "the replacement is tunable" "$REPO/abc-three" "$d"
git -C "$REPO/.git" config refresh.normalizeReplacement _

d=$(git -C "$REPO/main" new-worktree --no-normalize xyz/four 2>/dev/null)
assert_eq "--no-normalize overrides the config" "$REPO/xyz/four" "$d"

# Two branches, one directory. Handing back the other one's worktree would put
# you on the wrong branch, so it refuses either way round.
out=$(git -C "$REPO/main" new-worktree abc_two 2>&1) && st=0 || st=$?
assert_status   "a collision refuses" 1 "$st"
assert_contains "and says whose directory it is" "holds abc/two" "$out"
assert_contains "and why they collide" "collide once flattened" "$out"

# A directory that is not a worktree at all must not be mistaken for one: git
# answers about the nearest ancestor worktree if you let it.
mkdir -p "$REPO/plain"
out=$(git -C "$REPO/main" new-worktree plain 2>&1) && st=0 || st=$?
assert_status   "a plain directory refuses" 1 "$st"
assert_contains "without claiming a branch holds it" "is not a worktree" "$out"

# A bad replacement is an error, not a silently ignored setting.
git -C "$REPO/.git" config refresh.normalizeReplacement "__"
out=$(git -C "$REPO/main" new-worktree abc/five 2>&1) && st=0 || st=$?
assert_status   "a multi-character replacement refuses" 1 "$st"
assert_contains "and says why" "single character" "$out"
