# --doctor diagnoses the branch you are standing in, and refuses --all. So an
# --all run that ends with "run again with --doctor" is telling you to do
# something the tool rejects. Name the branches, and say where to run it.

fixture_new "$WORK"

a=$(fixture_branch alpha)
b=$(fixture_branch beta)
fixture_pr alpha OPEN main 1
fixture_pr beta  OPEN main 2
fixture_advance_main file-a moved

# Uncommitted tracked changes, with no rebase.autoStash to hand them to: the
# run has to leave both branches alone and report them.
printf 'edited\n' >> "$a/file-b"
printf 'edited\n' >> "$b/file-b"

out=$(git -C "$REPO/main" refresh --all --no-icons 2>&1) || true

assert_absent   "no advice the tool would refuse" "run again with --doctor" "$out"
assert_contains "the count is still reported"     "2 need you"              "$out"
assert_contains "alpha is named"                  "alpha"                   "$out"
assert_contains "beta is named"                   "beta"                    "$out"
assert_contains "and it says where to run it"     "in one of their worktrees" "$out"

# Standing in one branch, --doctor is a command you can actually run, so the
# original wording belongs there and must survive. A dirty worktree stops the
# run before it reaches any summary, so use a divergence to raise attention.
git -C "$a" checkout -q -- file-b
printf 'more\n' >> "$a/alpha.txt"
git -C "$a" commit -qa --amend --no-edit

one=$(git -C "$a" refresh --no-please --no-icons 2>&1) || true
assert_contains "the single-branch wording is unchanged" "run again with --doctor" "$one"
assert_absent   "and it does not name branches there"    "need you"                 "$one"

printf 'edited\n' >> "$b/file-b"
git -C "$a" checkout -q -- . 2>/dev/null || true
solo=$(git -C "$REPO/main" refresh --all --no-icons 2>&1) || true
assert_contains "a single branch reads singular" "in its worktree" "$solo"
