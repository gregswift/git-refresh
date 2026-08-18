# Open PR beats recorded base beats default, the record self-heals from the PR,
# and a merged-away base is followed to where it went.

fixture_new "$WORK"
a=$(fixture_branch feature-a)
b=$(fixture_branch feature-b feature-a)
fixture_pr feature-a OPEN main 1
fixture_pr feature-b OPEN feature-a 2
fixture_advance_main file-b 'moved'

out=$(git -C "$REPO/main" refresh --all --dry-run --no-icons --no-please 2>&1) || true
assert_contains "stacked branch lands on the branch below it" "feature-b" "$out"
assert_contains "and its base is that branch, not main" "origin/feature-a" "$out"

# The recorded base disagrees with the PR; a real run must correct it.
git -C "$b" config branch.feature-b.base main
out=$(git -C "$b" refresh --dry-run --no-please --no-icons 2>&1) || true
assert_eq "a dry run does not write the record" \
    "main" "$(git -C "$b" config --get branch.feature-b.base)"
out=$(git -C "$b" refresh --no-please --no-icons 2>&1) || true
assert_eq "a real run records what the PR says" \
    "feature-a" "$(git -C "$b" config --get branch.feature-b.base)"

# feature-a merges and is deleted; feature-b's recorded base is now gone.
: >"$GH_FIXTURE"
fixture_pr feature-a MERGED main 1
fixture_pr feature-b OPEN feature-a 2
git -C "$UP" push -q origin --delete feature-a
out=$(git -C "$b" refresh --dry-run --no-please --no-icons 2>&1) || true
assert_absent "a base that no longer exists is not reported as the base" \
    "no base" "$out"
