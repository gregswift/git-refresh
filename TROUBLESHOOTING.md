# Troubleshooting

## Purpose

What to do about the failures this workflow surfaces, as opposed to how the workflow runs. [WORKFLOWS.md](WORKFLOWS.md) is the latter.

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

## `origin dropped this branch`

    origin dropped this branch, and these commits exist only here
    → git push -u origin <branch>   only if it should come back

Origin carried this branch once and does not now. Merging or closing its pull request is what removes it. The commits still here were never sent, or were sent and rewritten since.

`git refresh --all` does not push it back. Recreating a branch the cleanup removed reopens what it closed, and origin holding the branch again stops `--prune` from removing the worktree.

Read the commits before deciding. Where the work still matters, push it back with the command above. Where it does not:

    git worktree remove <worktree> && git branch -D <branch>

## `autostash conflicted`

The rebase completed and the branch moved, but your uncommitted changes did not reapply on top of the new base. The working tree holds the conflict and the stash entry is kept:

    resolve the conflicts in the worktree
    git stash drop

Nothing is unwound automatically, because the conflict is between your own edits and your own new base.

## A squash merged base conflicts on rebase

If a PR is squash-merged its commits do not land on `main`. One new commit lands, holding the same content under a different identity, and every mechanism git has for spotting already-upstream work fails at once. The risk is that none of them tell you: the rebase just starts producing conflicts in code that already shipped.

* **Patch-id** (`git cherry`, and rebase's own duplicate detection) hashes each commit's diff. One squashed commit has one diff covering all of them, so it matches none of them.
* **`git merge-tree`** merges tips, and both tips now contain the same change arrived at by different routes.
* **Ancestry** is broken outright. The squash commit has no parent link to any of the commits it replaced.

So if the changeset on Branch A looks like this:

    Commit 1 - introduce the thing
    Commit 2 - adjust the thing
    Commit 3 - rewrite the comments

It gets squashed to "Commit A" when squash merged to main. Branch B still carries Commits 1-3, so rebasing it onto main attempts to merge the changes from Commits 2-3, which are now part of Commit A, against Commit 1 in Branch B. That is a merge conflict, in code that already shipped.

The correct operation is `git rebase --onto origin/main <old-base-tip> mybranch`, which drops the merged branch's commits and keeps only the ones above it. `<old-base-tip>` is exactly what a squash merge destroys. GitHub deletes the base branch on merge, and merge-base gives the wrong answer: it walks back to where the two branches last agreed, which is further back than you want.

`git refresh` keeps its own copy of `<old-base-tip>` in `branch.<name>.forkPoint`, and runs that `--onto` rebase for you. See **When the base is rewritten** in [WORKFLOWS.md](WORKFLOWS.md). The record does not cover these cases, and each one falls back to a plain rebase that conflicts:

* **A branch with no record.** `git worktree add` does not write one. Run `git refresh` on the branch once before its base merges, and it has one.
* **A branch rebased by hand since its last refresh.** The record then points below where the branch sits. Run `git refresh` after the manual rebase to move it.
* **A merged base that is still on origin.** Until the old base is deleted, a new base reads as a retarget, and a retarget keeps the old base's commits. Delete the merged branch, or turn on automatic branch deletion in repository settings.

For any of these, run the `--onto` rebase above by hand, with the old base's last commit from its pull request.

Rebase merges avoid the problem entirely. In repository settings, enable rebase merges and disable squash merges. Merge commits are not great either, but they do avoid this issue.

Just as a reference because they are good write ups:

* [Mastering Git — Why Rebase is amazing](https://hackernoon.com/mastering-git-why-rebase-is-amazing-a954485b128a)
* [What's the difference between the 3 GitHub Merge Types?](https://rietta.com/blog/github-merge-types)
* [Git Rebase VS Merge VS Squash: How to choose the right one?](https://dev.to/devsatasurion/git-rebase-vs-merge-vs-squash-how-to-choose-the-right-one-3a33)
