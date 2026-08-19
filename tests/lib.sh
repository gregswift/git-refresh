# Shared by every case. Sourced, never executed.

TAB=$(printf '\t')

# --------------------------------------------------------------------------
# Isolation. Without this the suite reads the config of whoever runs it, and
# two settings in particular decide the outcome of tests here: commit.gpgsign
# sends every fixture commit through a signing agent, and rebase.autoStash is
# the subject of several cases. A green run on one machine would mean nothing
# on another.
# --------------------------------------------------------------------------
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null
export GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
export GIT_AUTHOR_DATE='2026-01-01T00:00:00Z'
export GIT_COMMITTER_DATE='2026-01-01T00:00:00Z'
# Colour and icons are what a human wants and what an assertion cannot read.
export NO_COLOR=1

# Cases run in a subshell so that one exiting early cannot take the run with it.
# That means a counter incremented in a case never reaches the runner, so
# verdicts go to a file and the runner tallies from that.
RESULTS=${RESULTS:-/dev/null}

# --------------------------------------------------------------------------
# Fixtures
# --------------------------------------------------------------------------

# A bare "remote", a scratch clone to push from, and the worktree layout.
# $1 = directory to build in. Leaves $REMOTE, $UP and $REPO set.
fixture_new() {
    REMOTE="$1/remote.git"; UP="$1/up"; REPO="$1/repo"
    mkdir -p "$1"
    git init -q --bare "$REMOTE"
    # A bare repo's HEAD points at whatever init.defaultBranch said, and this
    # suite runs with no global config at all, so that is master and no such
    # branch is ever created. Everything downstream resolves origin/HEAD, so
    # say it here rather than depending on the runner's git version.
    git -C "$REMOTE" symbolic-ref HEAD refs/heads/main
    git init -q "$UP"
    ( cd "$UP"
      printf 'base\n' > file-a
      printf 'base\n' > file-b
      git add file-a file-b
      git commit -qm "base"
      git branch -M main
      git remote add origin "$REMOTE"
      git push -qu origin main )
    git clone -q --bare "$REMOTE" "$REPO/.git"
    git -C "$REPO/.git" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
    git -C "$REPO/.git" fetch -q --prune origin
    git -C "$REPO/.git" remote set-head origin --auto >/dev/null
    git -C "$REPO/.git" worktree add -q "$REPO/main" main
    git -C "$REPO/main" branch --set-upstream-to origin/main >/dev/null
    : >"$1/prs"
    export GH_FIXTURE="$1/prs"
}

# Add a pull request the gh stub will report. $1 head, $2 state, $3 base, $4 number.
fixture_pr() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >>"$GH_FIXTURE"; }

# A branch with one commit of its own, pushed. $1 = name, $2 = base (optional).
fixture_branch() {
    _d=$(git -C "$REPO/main" new-worktree "$1" ${2:+"$2"} 2>/dev/null)
    printf '%s\n' "$1" > "$_d/$1.txt"
    git -C "$_d" add "$1.txt"
    git -C "$_d" commit -qm "$1: its own commit"
    git -C "$_d" push -q -u origin "$1"
    printf '%s' "$_d"
}

# Move origin/main on, so branches have something to rebase onto.
# $1 = file to touch, $2 = contents.
fixture_advance_main() {
    ( cd "$UP" && git checkout -q main \
      && printf '%s\n' "$2" > "$1" && git add "$1" \
      && git commit -qm "main: change $1" && git push -q origin main )
}

# --------------------------------------------------------------------------
# Assertions. Each prints its own verdict, so a failing run says which line of
# which case failed and what it saw.
# --------------------------------------------------------------------------

ok()  {
    printf 'ok\t%s\t%s\n' "$CASE" "$1" >>"$RESULTS"
    printf '    ok   %s\n' "$1"
}
bad() {
    printf 'FAIL\t%s\t%s\n' "$CASE" "$1" >>"$RESULTS"
    printf '    FAIL %s\n' "$1"
    [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/         | /'
}

assert_contains() {  # $1 = label, $2 = needle, $3 = haystack
    case "$3" in
        *"$2"*) ok "$1" ;;
        *)      bad "$1 (expected to find: $2)" "$3" ;;
    esac
}

assert_absent() {  # $1 = label, $2 = needle, $3 = haystack
    case "$3" in
        *"$2"*) bad "$1 (did not expect: $2)" "$3" ;;
        *)      ok "$1" ;;
    esac
}

assert_eq() {  # $1 = label, $2 = expected, $3 = actual
    if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected [$2], got [$3])"; fi
}

assert_status() {  # $1 = label, $2 = expected status, $3 = actual status
    if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi
}
