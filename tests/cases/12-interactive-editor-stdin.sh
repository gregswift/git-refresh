# -i hands the terminal to git rebase, which hands it to the editor. The plan
# the run walks is a file, and reading it on stdin used to leave the editor
# reading that file instead of the terminal, so every editor refused to start.
# The suite has no terminal, so stand a known file in for one and check the
# editor is the thing that reads it.

fixture_new "$WORK"
d=$(fixture_branch feature)
fixture_pr feature OPEN main 1
fixture_advance_main file-b 'moved'

printf 'from the terminal\n' > "$WORK/stdin"
cat > "$WORK/editor" <<'EOF'
#!/bin/sh
head -n 1 > "$SEEN"
exit 0
EOF
chmod +x "$WORK/editor"
SEEN="$WORK/seen"; : >"$SEEN"
export SEEN
GIT_SEQUENCE_EDITOR="$WORK/editor"; export GIT_SEQUENCE_EDITOR

out=$(git -C "$d" refresh -i --no-please --no-icons < "$WORK/stdin" 2>&1) || true
assert_contains "it announces the interactive rebase" "Interactive rebase from" "$out"
assert_eq "the editor reads the caller's stdin" "from the terminal" "$(cat "$SEEN")"
assert_eq "and the rebase finished" "" "$(git -C "$d" rev-parse -q --verify REBASE_HEAD 2>/dev/null || true)"
