# A dry run must answer about origin as it is now, not as it was at the last
# real fetch. It fetches for exactly this reason; with --dry-run on the fetch it
# reported a branch clean that conflicted a second later.

fixture_new "$WORK"
d=$(fixture_branch feature)
fixture_pr feature OPEN main 1

# feature owns file-a; main rewrites it after feature's last fetch.
printf 'from the branch\n' > "$d/file-a"
git -C "$d" commit -qam "feature rewrites file-a"
git -C "$d" push -qf origin feature
fixture_advance_main file-a 'from main'

out=$(git -C "$d" refresh --dry-run --no-icons 2>&1) || true
assert_contains "dry run announces itself" "dry run: fetched, and changed nothing else" "$out"
assert_contains "dry run predicts the conflict"  "conflict, 1 file" "$out"

before=$(git -C "$d" rev-parse HEAD)
out=$(git -C "$d" refresh --no-please --no-icons 2>&1) || true
assert_contains "the real run meets the conflict it predicted" "conflict, 1 file" "$out"
assert_eq "and the prediction did not move the branch" \
    "$before" "$(git -C "$d" rev-parse ORIG_HEAD 2>/dev/null || echo "$before")"
git -C "$d" rebase --abort 2>/dev/null || true
