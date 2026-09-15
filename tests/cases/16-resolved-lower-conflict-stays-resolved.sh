# A conflict resolved by hand on the lower branch of a stack stays resolved. The
# branch above still carries the lower branch's old commits, and a plain rebase
# replays them against the rewritten ones: the same conflict, a second time.

fixture_new "$WORK"
a=$(git -C "$REPO/main" new-worktree feature-a 2>/dev/null)
printf 'from a\n' > "$a/file-a"
git -C "$a" commit -qam "feature-a: change file-a"
git -C "$a" push -q -u origin feature-a
b=$(fixture_branch feature-b feature-a)
fixture_pr feature-a OPEN main 1
fixture_pr feature-b OPEN feature-a 2

# A clean restack first, so the only record of where feature-b sits on
# feature-a is one this run wrote, not the one from its creation.
fixture_advance_main file-b 'moved'
git -C "$REPO/main" refresh --all --please --no-icons >/dev/null 2>&1 || true

fixture_advance_main file-a 'from main'
git -C "$a" fetch -q origin
git -C "$a" rebase origin/main >/dev/null 2>&1 || true
printf 'from a and main\n' > "$a/file-a"
git -C "$a" add file-a
GIT_EDITOR=true git -C "$a" rebase --continue >/dev/null 2>&1
git -C "$a" push -q --force origin feature-a

doc=$(git -C "$b" refresh --doctor --no-icons 2>&1) || true
assert_absent "the doctor predicts no conflict for the upper branch" "conflict" "$doc"

out=$(git -C "$b" refresh --no-icons 2>&1) || true
assert_absent "the upper branch does not meet the conflict again" "conflict" "$out"
assert_eq "it sits on the rewritten lower branch" \
    "$(git -C "$b" rev-parse origin/feature-a)" "$(git -C "$b" merge-base origin/feature-a HEAD)"
assert_eq "and carries only its own commit above it" \
    "1" "$(git -C "$b" rev-list --count origin/feature-a..HEAD)"
