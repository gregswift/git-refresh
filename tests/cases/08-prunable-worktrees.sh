# A worktree directory deleted by hand leaves git calling that worktree
# prunable. Clearing the record is exactly what --prune is for, so the run has
# to do it quietly: no fatal from asking a directory that is not there for its
# base, and no claim that anything needs attention once it is gone.

fixture_new "$WORK"

# Plain `git worktree add`, not git-new-worktree, so the branch never gets a
# recorded base. That is what sends base resolution on to infer_base, which is
# the call that used to reach into the missing directory.
d="$REPO/orphan"
git -C "$REPO/main" worktree add -q -b orphan "$d" origin/main
printf 'orphan\n' > "$d/orphan.txt"
git -C "$d" add orphan.txt
git -C "$d" commit -qm "orphan: its own commit"
git -C "$d" push -q -u origin orphan

# Merged and closed, so there is no open PR to name a base either.
fixture_pr orphan MERGED main 42
fixture_advance_main file-a moved
git -C "$UP" push -q origin :orphan

rm -rf "$d"

out=$(git -C "$REPO/main" refresh --all --prune --no-icons 2>&1) || true

assert_absent   "no fatal from the missing directory" "cannot change to" "$out"
assert_contains "the stale record is cleared"         "removed orphan"   "$out"
# Both "1 needs you" and "2 need you" are the same claim, so match the tail of
# the line rather than either verb.
assert_absent   "and nothing is left needing you"     "run again with"   "$out"
assert_contains "the summary counts the removal"      "1 removed"        "$out"

left=$(git -C "$REPO/main" worktree list | grep -c orphan || true)
assert_eq "git no longer lists the worktree" "0" "$left"
