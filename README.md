# git-refresh

Git tooling for keeping branches rebased onto the right thing without doing it by hand, and for the worktree-per-branch layout that makes working on several of them at once bearable.

Three commands:

* `git clone-for-worktrees` \- clone a repository as `<name>/.git` plus one worktree per branch.
* `git new-worktree` \- add a branch to that layout, and record what it was branched from.
* `git refresh` \- rebase every branch onto its base, push what moved, remove what is finished.

`git refresh` is the one you run all day. It rebases onto the base branch of the branch's open pull request rather than onto `origin/main`, so a stacked branch lands on the one below it, and `--all` walks the stack bottom-up so one pass restacks the whole chain.

    $ git refresh
    ✅ rebased onto origin/main, pushed

    $ git refresh --all
    BRANCH              BASE                       STATUS
    main                origin/main                ✅ synced
    old-spike           origin/main                ❌ conflict, 1 file
    add-billing-writes  origin/main                ➖ current
    add-billing-ui      origin/add-billing-writes  ✅ pushed

    4 worktrees: 1 synced, 1 pushed, 1 current, 1 conflicted

    1 needs you; run again with --doctor to see what to do

`git refresh` works in an ordinary clone too. Single-branch mode never looks at the worktree layout.

## Install

### Homebrew

    brew tap gregswift/tap
    brew install git-refresh

### From source

    git clone https://github.com/gregswift/git-refresh
    cd git-refresh
    make install PREFIX=$HOME/.local

`PREFIX` defaults to `/usr/local`. `DESTDIR` stages into a build root for packaging. Nothing is compiled; these are POSIX shell scripts.

Man pages install alongside them: `man git-refresh`, `man git-new-worktree`, `man git-clone-for-worktrees`.

## Wiring up the two optional pieces

`gwt` is a shell function that enhances regular use of `git new-worktree` by also changing into the new worktree directory after it is created, which a script can't do for us. It also takes you to a worktree that already exists.

    # ~/.bashrc or ~/.zshrc
    . $(brew --prefix)/share/git-refresh/gwt.sh

The aliases are a gitconfig you can include directly, which allows changes to be sync'd in when the installation updates, rather than drifting from a local copy or copy paste:

    git config --global include.path "$(brew --prefix)/share/git-refresh/refresh.gitconfig"

That adds:

| alias | |
|---|---|
| `git check-trees` | `git-refresh --all --prune --dry-run`, so what every worktree needs, changing nothing |
| `git prune-trees` | `git-refresh --all --prune`, the same run for real |
| `git commend` | `commit --amend --no-edit` |
| `git please` | `push --force-with-lease` |

Nothing in it changes what an existing git command already does. For the settings that do, see [RECOMMENDATIONS.md](RECOMMENDATIONS.md).

## Try it

    git clone-for-worktrees gregswift/git-refresh
    cd git-refresh/main
    gwt my-feature            # new branch, new worktree, cd'd into it
                              # ... work, commit ...
    git refresh               # rebase onto its base and push, safely
    git check-trees           # what every other worktree needs, changing nothing

Already have a plain clone? `git new-worktree <branch>` inside it offers to convert it to the layout.

## Defaults worth knowing

`git refresh` pushes what it rebased, and adopts `origin/<branch>` where your copy was rewritten elsewhere. Both can be turned off for one run (`--no-please`, `--no-sync`) or for good (`refresh.pushWithLease`, `refresh.syncStale`).

It does not remove worktrees unless asked. `--prune` should stay opt-in: it is the one that runs `git worktree remove` and deletes the branch.

A branch name with a `/` in it nests, because the directory is named for the branch. If your team names branches `initials/feature` or `TICKET/feature` and you don't want the nested directories, you can flatten them:

    git config refresh.normalizeWorktreeNames true

    gwt abc/add-search-filter    ->  myrepo/abc_add-search-filter/

The branch keeps its own name. Off by default, because turning it on does not move worktrees that already exist.

## Requirements

* git 2.23 or newer, for `git branch --show-current`.
* A POSIX shell.
* `gh` is optional. Without it, base resolution falls back to what `git new-worktree` recorded and nothing else changes.

## Read next

* [WORKFLOWS.md](WORKFLOWS.md) \- the four workflows these implement: the layout, staying current, stacked pull requests, and housekeeping.
* [TROUBLESHOOTING.md](TROUBLESHOOTING.md) \- what to do when a rebase conflicts, a push is refused, or a branch has no base.
* [RECOMMENDATIONS.md](RECOMMENDATIONS.md) \- git settings that help, each with what it costs as well as what it buys. Start with the rerere section: `--all` and `--stack` disable rerere on purpose.

## Credit

The worktree layout comes from Christopher Allen's [Git Worktree Best Practices and Tools](https://gist.github.com/ChristopherA/4643b2f5e024578606b9cd5d2e6815cc). My own `git-refresh` and `git-rebase` aliases I had used for years met his structure there, and the heavier scripts grew out of that.

`commend` and `please` are Raphaël Pinson's, from [a post on the two of them](https://www.linkedin.com/posts/raphink_2-%F0%9D%90%86%F0%9D%90%A2%F0%9D%90%AD-%F0%9D%90%9A%F0%9D%90%A5%F0%9D%90%A2%F0%9D%90%9A%F0%9D%90%AC%F0%9D%90%9E%F0%9D%90%AC-%F0%9D%90%AD%F0%9D%90%A1%F0%9D%90%9A%F0%9D%90%AD-%F0%9D%90%AC%F0%9D%90%A2%F0%9D%90%A6%F0%9D%90%A9%F0%9D%90%A5%F0%9D%90%A2%F0%9D%90%9F%F0%9D%90%A2%F0%9D%90%9E%F0%9D%90%9D-activity-7297910317274050560-JwIM). `git refresh --please` is named after the second one and does the same job per branch.
