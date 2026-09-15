# A pull request moved off a base that is still open has not had that base
# merged. The branch still needs the commits it took from the old base, so the
# rebase keeps them rather than skipping from where the old base ended.

fixture_new "$WORK"
fixture_branch feature-a >/dev/null
b=$(fixture_branch feature-b feature-a)
fixture_pr feature-a OPEN main 1
fixture_pr feature-b OPEN main 2
fixture_advance_main file-b 'moved'

out=$(git -C "$b" refresh --no-icons 2>&1) || true
assert_contains "the retargeted branch rebases onto main" "rebased onto origin/main" "$out"
assert_eq "and still carries the old base's commit under its own" \
    "2" "$(git -C "$b" rev-list --count origin/main..HEAD)"
