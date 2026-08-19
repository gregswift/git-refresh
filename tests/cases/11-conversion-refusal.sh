# Converting a plain clone rebuilds the working copy from HEAD, so the run
# refuses while anything untracked, ignored or modified is present. Ignored
# paths are the half that surprises people: plain `git status` does not show
# them, so the checkout reads as clean while the conversion refuses. Say so
# there — but only there, or the explanation is in front of everyone whose
# problem is an uncommitted edit, and gets skimmed when it matters.

# A plain clone, which is what the conversion path needs. The shared fixture
# builds the bare layout, which is already converted.
plain_clone() {  # $1 = name; prints the clone path
    git init -q --bare "$WORK/$1-remote.git"
    git -C "$WORK/$1-remote.git" symbolic-ref HEAD refs/heads/main
    git init -q "$WORK/$1-up"
    ( cd "$WORK/$1-up"
      printf 'base\n' > f
      git add f && git commit -qm base && git branch -M main
      git remote add origin "$WORK/$1-remote.git" && git push -qu origin main ) >/dev/null 2>&1
    git clone -q "$WORK/$1-remote.git" "$WORK/$1"
    git -C "$WORK/$1" remote set-head origin --auto >/dev/null
    printf '%s' "$WORK/$1"
}

# --- an ignored path triggers it ------------------------------------------
c=$(plain_clone ign)
printf 'cache/\n' > "$c/.gitignore"
git -C "$c" add .gitignore && git -C "$c" commit -qm ignore
mkdir "$c/cache" && touch "$c/cache/x"

out=$(cd "$c" && git new-worktree --force topic 2>&1) || true
assert_contains "it names what it counted"    "!! cache/"                     "$out"
assert_contains "it shows the command"        "git status --porcelain --ignored" "$out"
assert_contains "it explains the trap"        "not shown by plain git status" "$out"
assert_contains "and offers git clean"        "git clean -fdx"                "$out"

# --- untracked, nothing ignored -------------------------------------------
c=$(plain_clone untr)
touch "$c/notes.txt"

out=$(cd "$c" && git new-worktree --force topic 2>&1) || true
assert_contains "it names the untracked file" "?? notes.txt"                  "$out"
assert_absent   "no ignored-path explanation" "not shown by plain git status" "$out"
assert_contains "git clean still applies"     "git clean -fdx"                "$out"
assert_contains "and it counts one path"      "1 untracked, ignored or modified path in" "$out"

# --- a tracked modification, which git clean cannot help with -------------
c=$(plain_clone mod)
printf 'changed\n' >> "$c/f"

out=$(cd "$c" && git new-worktree --force topic 2>&1) || true
assert_contains "it names the modified file"  "M f"                           "$out"
assert_absent   "no ignored-path explanation" "not shown by plain git status" "$out"
assert_absent   "and no git clean advice"     "git clean"                     "$out"
assert_contains "commit or stash instead"     "Commit or stash them"          "$out"
