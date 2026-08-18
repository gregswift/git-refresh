# --please holds the push to where origin stood before this run's fetch. A bare
# --force-with-lease would compare against a ref the run just moved.

fixture_new "$WORK"
d=$(fixture_branch feature)
fixture_pr feature OPEN main 1
fixture_advance_main file-b 'moved'

# Someone else publishes to the branch after our last fetch. Deliberately a
# file main did not touch, so the rebase succeeds and the push is the only
# thing that can fail: this case is about the lease, not about conflicts.
git -C "$UP" fetch -q origin
git -C "$UP" checkout -q -B feature origin/feature
printf 'theirs\n' > "$UP/file-a"
git -C "$UP" commit -qam "a colleague pushes"
git -C "$UP" push -q origin feature

out=$(git -C "$d" refresh --please --no-icons 2>&1) || true
assert_contains "the push is refused" "push refused" "$out"
assert_eq "and their commit is still on origin" \
    "$(git -C "$UP" rev-parse feature)" \
    "$(git ls-remote "$REMOTE" refs/heads/feature | cut -f1)"
