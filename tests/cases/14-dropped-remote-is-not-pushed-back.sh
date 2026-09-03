# A branch origin dropped is not a branch waiting to be published. Its pull
# request merged or closed, and the branch went with it. Pushing it back under
# --all recreates what that cleanup removed, and the advice must not read as
# though the branch were simply unpushed. A branch whose change main has taken
# holds nothing of its own, so it has nothing to publish either.

fixture_new "$WORK"

# Pushed once, then dropped from origin, and still carrying its own commit.
dropped=$(fixture_branch dropped-remote)

# Still on origin, but main takes the same change, so the rebase leaves it
# holding nothing of its own.
fixture_branch absorbed >/dev/null
absorbed_was=$(git ls-remote "$REMOTE" refs/heads/absorbed | cut -f1)
( cd "$UP" && git checkout -q main \
  && printf 'absorbed\n' > absorbed.txt \
  && git add absorbed.txt \
  && git commit -qm "main: takes the same change" \
  && git push -q origin main )

git -C "$UP" push -q origin :dropped-remote

# Dropped a while ago, not this second: the stale remote-tracking ref is
# already gone, so the run has no lease to take and a push would create the
# branch rather than be refused.
git -C "$REPO/main" fetch -q --prune origin

out=$(git -C "$REPO/main" refresh --all --please --no-icons 2>&1) || true

assert_eq "the dropped branch is not put back on origin" \
    "" "$(git ls-remote "$REMOTE" refs/heads/dropped-remote | cut -f1)"
assert_eq "the absorbed branch is left where origin had it" \
    "$absorbed_was" "$(git ls-remote "$REMOTE" refs/heads/absorbed | cut -f1)"
assert_contains "the run still names it" "dropped-remote" "$out"

# The row carries a branch name; the reason a human acts on is in the advice.
doc=$(git -C "$dropped" refresh --doctor --no-icons 2>&1) || true
assert_contains "the advice says origin dropped it" \
    "origin dropped this branch" "$doc"
assert_absent "and does not read as merely unpushed" \
    "not on origin; these commits exist only here" "$doc"
