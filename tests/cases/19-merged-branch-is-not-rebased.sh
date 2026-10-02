# A finished branch is not rebased, with or without --prune, and the run does
# not report it as work for you.

fixture_new "$WORK"

d=$(git -C "$REPO/main" new-worktree finished 2>/dev/null)
printf 'finished\n' > "$d/file-a"
git -C "$d" commit -qam "finished: change file-a"
git -C "$d" push -q -u origin finished
finished_was=$(git -C "$d" rev-parse HEAD)

fixture_pr finished MERGED main 21
fixture_advance_main file-a finished
fixture_advance_main file-a "moved on"
git -C "$UP" push -q origin :finished
git -C "$REPO/main" fetch -q --prune origin

out=$(git -C "$REPO/main" refresh --all --prune --dry-run --no-icons 2>&1) || true

assert_contains "a dry run with --prune would remove the merged worktree" \
    "would remove worktree finished" "$out"
assert_absent "and predicts no conflict for it" "conflict" "$out"
assert_absent "and does not say it needs you" "need" "$out"

out=$(git -C "$REPO/main" refresh --all --no-please --no-icons 2>&1) || true

assert_contains "without --prune the row says it merged" \
    "merged, --prune removes it" "$out"
assert_absent "and meets no conflict" "conflict" "$out"
assert_absent "and does not say it needs you" "need" "$out"
assert_eq "and the branch is not rebased" \
    "$finished_was" "$(git -C "$d" rev-parse HEAD)"

printf 'scratch\n' > "$d/notes.txt"
out=$(git -C "$REPO/main" refresh --all --no-please --no-icons 2>&1) || true

assert_contains "with uncommitted work the row says so instead" \
    "merged, uncommitted work here" "$out"
assert_absent "and does not promise --prune removes it" "--prune removes it" "$out"
