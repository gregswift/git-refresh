# Removing one stale worktree record must not take the others with it.
# `git worktree prune` is repository-wide, so using it to clear one prunable
# worktree also cleared the ones this run had decided to leave alone — and the
# `git worktree remove` it then suggests for them has nothing left to act on.

fixture_new "$WORK"

# Merged upstream, so --prune is entitled to remove it.
gone=$(fixture_branch merged-gone)
fixture_pr merged-gone MERGED main 7

# Never had a PR, so nothing says it was merged. --prune must leave this one
# alone and tell the human to look at it.
kept=$(fixture_branch kept-gone)

fixture_advance_main file-a moved
git -C "$UP" push -q origin :merged-gone
git -C "$UP" push -q origin :kept-gone

# Both directories deleted by hand: git calls both worktrees prunable.
rm -rf "$gone" "$kept"

out=$(git -C "$REPO/main" refresh --all --prune --no-icons 2>&1) || true

assert_contains "the merged one is removed"     "removed merged-gone"    "$out"
assert_contains "the other one is flagged"      "no sign it was merged"  "$out"
assert_absent   "and not removed"               "removed kept-gone"      "$out"

# The point of the case: its record has to survive, or the suggested command
# cannot work when the human runs it.
list=$(git -C "$REPO/main" worktree list)
assert_contains "the kept record survives"  "kept-gone"    "$list"
assert_absent   "the removed one is gone"   "merged-gone"  "$list"
