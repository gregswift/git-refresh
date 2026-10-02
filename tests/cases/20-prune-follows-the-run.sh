# --prune removes only what the run covers. With refresh.pruneWorktrees on,
# every refresh prunes, so a run on one stack must not remove or count a
# worktree in another.

fixture_new "$WORK"

outside=$(fixture_branch outside)
fixture_pr outside MERGED main 31
git -C "$UP" push -q origin :outside

fixture_branch lower >/dev/null
fixture_pr lower OPEN main 32
upper=$(fixture_branch upper lower)
fixture_pr upper OPEN lower 33

fixture_advance_main file-a moved
git -C "$REPO/main" fetch -q --prune origin

out=$(git -C "$upper" refresh --stack --prune --dry-run --no-icons 2>&1) || true

assert_absent "a stack run does not offer to remove another stack's worktree" \
    "outside" "$out"
assert_absent "and does not count it" "to remove" "$out"

out=$(git -C "$REPO/main" refresh --all --prune --dry-run --no-icons 2>&1) || true

assert_contains "an --all run still offers to remove it" \
    "would remove worktree outside" "$out"

git -C "$upper" refresh --prune --no-please --no-icons >/dev/null 2>&1 || true

assert_contains "a single-branch run leaves it in place" \
    "$outside" "$(git -C "$REPO/main" worktree list)"
