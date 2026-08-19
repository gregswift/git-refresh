# rebase.autoStash decides whether a rebase runs at all in a dirty worktree.
# Off is a refusal, on is a rebase, and a conflicting rebase is still aborted
# with the stashed work put back.

fixture_new "$WORK"
d=$(fixture_branch feature)
fixture_pr feature OPEN main 1
fixture_advance_main file-b 'moved'
printf 'uncommitted\n' >> "$d/file-a"

git -C "$REPO/.git" config rebase.autoStash false
before=$(git -C "$d" rev-parse HEAD)
out=$(git -C "$d" refresh --no-please --no-icons 2>&1) && st=0 || st=$?
assert_contains "off: it refuses" "uncommitted changes" "$out"
assert_status  "off: exit 1" 1 "$st"
assert_eq      "off: the branch did not move" "$before" "$(git -C "$d" rev-parse HEAD)"

git -C "$REPO/.git" config rebase.autoStash true
out=$(git -C "$d" refresh --no-please --no-icons 2>&1) || true
assert_contains "on: it rebases" "rebased" "$out"
assert_contains "on: the edit survives" "uncommitted" "$(cat "$d/file-a")"

# Now a rebase that will conflict, under --all, with the tree still dirty.
fixture_advance_main file-a 'main owns file-a now'
printf 'branch owns it\n' > "$d/file-a"
git -C "$d" commit -qam "feature rewrites file-a"
printf 'and uncommitted on top\n' >> "$d/file-a"
out=$(git -C "$REPO/main" refresh --all --no-please --no-icons 2>&1) || true
assert_contains "--all: the conflicting rebase is reported" "conflict" "$out"
assert_contains "--all: the abort put the uncommitted work back" \
    "and uncommitted on top" "$(cat "$d/file-a")"
assert_eq "--all: no stash entry is orphaned" "" "$(git -C "$d" stash list)"
