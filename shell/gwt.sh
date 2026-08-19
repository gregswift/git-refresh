# gwt -- add or check out a worktree, and cd into it.
#
# git-new-worktree prints the worktree path and nothing else, because a script
# cannot change its caller's directory. This wrapper is what makes it feel like
# one command. Source it from your shell rc:
#
#     . /path/to/git-refresh/shell/gwt.sh
#
# Works in bash and zsh. `local` is not POSIX, so plain sh users want the
# function body without it.

gwt() {
    local d
    d=$(git new-worktree "$@") || return
    cd "$d"
}
