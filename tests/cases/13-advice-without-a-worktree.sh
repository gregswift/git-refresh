# --doctor has to be run inside the worktree it diagnoses. A worktree whose
# directory was deleted has nowhere to stand, so "run git refresh --doctor in
# its worktree" names a directory that is not there. Advice for that branch has
# to arrive in the summary itself.

fixture_new "$WORK"

# Never had a PR, so nothing says it was merged: --prune has to keep the record
# and report it. Its directory is deleted, which is what leaves it unreachable.
kept=$(fixture_branch kept-gone)
busy=$(fixture_branch busy)
fixture_pr busy OPEN main 3
fixture_advance_main file-a moved
git -C "$UP" push -q origin :kept-gone
rm -rf "$kept"

out=$(git -C "$REPO/main" refresh --all --prune --no-icons 2>&1) || true

assert_contains "the branch is still named"       "1 needs you: kept-gone"   "$out"
assert_contains "its remedy arrives in the summary" "git branch -D kept-gone" "$out"
assert_absent   "and nowhere is it sent to a worktree it has not got" \
                "run git refresh --doctor" "$out"

# A branch that does have a directory is still reachable, so the pointer belongs
# to it, and the count in it is that branch alone rather than both.
printf 'edited\n' >> "$busy/file-b"

both=$(git -C "$REPO/main" refresh --all --prune --no-icons 2>&1) || true

assert_contains "both branches are counted"        "2 need you"              "$both"
assert_contains "the unreachable one still gets its remedy" \
                "git branch -D kept-gone" "$both"
assert_contains "and the reachable one gets the pointer" "in its worktree"   "$both"
