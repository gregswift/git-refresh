# Troubleshooting

## Purpose

What to do about the failures this workflow surfaces, as opposed to how the workflow runs. [WORKFLOWS.md](WORKFLOWS.md) is the latter.

## A squash merged base conflicts on rebase

When PR #1 is squash-merged its commits do not land on `main`. One new commit lands, holding the same content under a different identity, and every mechanism git has for recognising "this work is already upstream" fails at once.

* **Patch-id** (`git cherry`, and rebase's own duplicate detection) hashes each commit's diff. One squashed commit has one diff covering all of them, so it matches none of them.
* **`git merge-tree`** merges tips, and both tips now contain the same change arrived at by different routes.
* **Ancestry** is broken outright. The squash commit has no parent link to any of the commits it replaced.

So if the changeset on Branch A looks like this:

    Commit 1 - introduce the thing
    Commit 2 - adjust the thing
    Commit 3 - rewrite the comments

It gets squashed to "Commit A" when squash merged to main. Branch B still carries Commits 1-3, so rebasing it onto main attempts to merge the changes from Commits 2-3, which are now part of Commit A, against Commit 1 in Branch B. That is a merge conflict, in code that already shipped.

The correct operation is `git rebase --onto origin/main <old-base-tip> mybranch`, which drops #1's commits and keeps only #2's. `git refresh` **cannot** do this for you: `<old-base-tip>` is exactly what a squash merge destroys. GitHub deletes the base branch on merge, and once that ref is gone there is no record of where the branch started (merge-base gives the wrong answer, it walks back to where the two branches last agreed, which is now further back than you want).

The fix is upstream of the tooling. In repository settings, enable rebase merges and disable squash merges. Merge commits are not great either, but they do avoid this issue.

Where that is not your call, expect to fix stacked branches by hand with `--onto`, and expect `--doctor` to be wrong about them. It merges tips, so a squashed base looks clean right up until the rebase replays.

Just as a reference because they are good write ups:

* [Mastering Git — Why Rebase is amazing](https://hackernoon.com/mastering-git-why-rebase-is-amazing-a954485b128a)
* [What's the difference between the 3 GitHub Merge Types?](https://rietta.com/blog/github-merge-types)
* [Git Rebase VS Merge VS Squash: How to choose the right one?](https://dev.to/devsatasurion/git-rebase-vs-merge-vs-squash-how-to-choose-the-right-one-3a33)

## `git refresh` refuses: you have uncommitted changes

    ❌ you have uncommitted changes; commit or stash them, or set rebase.autoStash

Commit them, stash them, or set `rebase.autoStash` and let the rebase handle it. See [RECOMMENDATIONS.md](RECOMMENDATIONS.md).

## A branch is reported as `no base`

Nothing answered the question of what this branch should rebase onto: it has no open pull request, nothing was recorded when it was created, and the shape of the history did not clearly point at a parent.

`git refresh --doctor`, standing in that worktree, will say which of the three is missing and offer the fix, which is usually one of:

* open its pull request, and the base comes from there
* `git config branch.<name>.base <parent>`, if the branch is not ready for review yet
* remove the worktree, if the branch is finished with

## A push was refused

    ❌ current with origin/main, push refused

Origin moved after this run's fetch snapshot, so the lease failed and nothing was overwritten. Someone else pushed to your branch, or you pushed from another machine.

    cd <worktree> && git pull --rebase origin <branch>

then run `git refresh --please` again.

## `autostash conflicted`

The rebase completed and the branch moved, but your uncommitted changes did not reapply on top of the new base. The working tree holds the conflict and the stash entry is kept:

    resolve the conflicts in the worktree
    git stash drop

Nothing is unwound automatically, because the conflict is between your own edits and your own new base.
