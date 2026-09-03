# --prune skips any branch still on origin, so a run that pushes a dropped
# branch back hides the very worktree it was asked to remove. Pushing and
# pruning happen in one pass over the same branch, and the push goes first.

fixture_new "$WORK"

d=$(fixture_branch merged-and-dropped)
fixture_pr merged-and-dropped MERGED main 11

fixture_advance_main file-a moved
git -C "$UP" push -q origin :merged-and-dropped

# Dropped a while ago, not this second: the stale remote-tracking ref is
# already gone, so the run has no lease to take and a push would create the
# branch rather than be refused.
git -C "$REPO/main" fetch -q --prune origin

out=$(git -C "$REPO/main" refresh --all --please --prune --no-icons 2>&1) || true

assert_contains "the merged worktree is removed" \
    "removed merged-and-dropped" "$out"
assert_eq "and origin does not get the branch back" \
    "" "$(git ls-remote "$REMOTE" refs/heads/merged-and-dropped | cut -f1)"
assert_absent "the worktree record goes with it" \
    "merged-and-dropped" "$(git -C "$REPO/main" worktree list)"
assert_absent "and the directory is gone" "$d" "$(ls "$REPO")"
