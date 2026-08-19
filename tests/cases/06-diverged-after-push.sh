# --sync judges divergence before the rebase, and --please can publish the
# branch afterwards. Where the push resolves it, the run must not still report
# a divergence and send you to --doctor for `git pull --rebase`, which would
# undo what it just pushed.

fixture_new "$WORK"
d=$(fixture_branch feature)
fixture_pr feature OPEN main 1

# A local rewrite that is not on origin: exactly what `git commend` leaves.
printf 'amended\n' >> "$d/feature.txt"
git -C "$d" commit -qa --amend --no-edit

out=$(git -C "$d" refresh --please --no-icons 2>&1) || true
assert_contains "the push goes out"           "pushed" "$out"
assert_absent   "and no divergence is claimed" "diverged from origin" "$out"
assert_absent   "so nothing sends you to --doctor" "run again with --doctor" "$out"
assert_eq "origin holds exactly what is here" \
    "$(git -C "$d" rev-parse HEAD)" "$(git -C "$d" rev-parse origin/feature)"

# The same divergence with no push to resolve it is still a real report.
printf 'again\n' >> "$d/feature.txt"
git -C "$d" commit -qa --amend --no-edit
out=$(git -C "$d" refresh --no-please --no-icons 2>&1) || true
assert_contains "unpushed, it is still reported" "diverged from origin" "$out"

out=$(git -C "$d" refresh --no-please --no-icons --doctor 2>&1) || true
assert_contains "and --doctor still advises the fix" "git pull --rebase" "$out"
