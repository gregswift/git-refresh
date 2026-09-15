# A squash merge lands the lower branch's commits on main as one new commit.
# Patch-id matches none of them, so a plain rebase of the branch above replays
# each one against the squash and conflicts in code that already shipped.

fixture_new "$WORK"
a=$(git -C "$REPO/main" new-worktree feature-a 2>/dev/null)
printf 'one\n' > "$a/file-a"
git -C "$a" commit -qam "feature-a: first pass"
printf 'two\n' > "$a/file-a"
git -C "$a" commit -qam "feature-a: second pass"
git -C "$a" push -q -u origin feature-a
b=$(fixture_branch feature-b feature-a)

# GitHub retargets the open PR above when the branch below merges and goes.
fixture_pr feature-a MERGED main 1
fixture_pr feature-b OPEN main 2
( cd "$UP" && git checkout -q main && git pull -q origin main \
  && printf 'two\n' > file-a && git commit -qam "feature-a (#1)" \
  && git push -q origin main && git push -q origin :feature-a )

doc=$(git -C "$b" refresh --doctor --no-icons 2>&1) || true
assert_absent "the doctor predicts no conflict above a squash" "conflict" "$doc"

out=$(git -C "$b" refresh --no-icons 2>&1) || true
assert_absent "the branch above does not conflict with the squash" "conflict" "$out"
assert_eq "it carries only its own commit above main" \
    "1" "$(git -C "$b" rev-list --count origin/main..HEAD)"
assert_eq "and keeps the squashed content" "two" "$(cat "$b/file-a")"
