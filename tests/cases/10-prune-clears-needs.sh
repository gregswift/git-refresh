# A branch the refresh pass filed as needing attention, and the prune pass then
# removed, is gone: nothing about it is left for you to do, so the run must
# not count it among the branches that need you.

fixture_new "$WORK"

# No recorded base and a merged, closed PR, so the refresh pass has no base to
# rebase onto and files the branch as needing one.
d="$REPO/done"
git -C "$REPO/main" worktree add -q -b done "$d" origin/main
printf 'done\n' > "$d/done.txt"
git -C "$d" add done.txt
git -C "$d" commit -qm "done: its own commit"
git -C "$d" push -q -u origin done

fixture_pr done MERGED main 43
fixture_advance_main file-a moved
git -C "$UP" push -q origin :done

out=$(git -C "$REPO/main" refresh --all --prune --no-icons 2>&1) || true

assert_contains "the worktree is removed"      "removed done"  "$out"
assert_absent   "and no longer needs you"      "need"          "$out"
assert_contains "the summary counts it as removed only"      "2 worktrees: 1 synced, 1 removed" "$out"
