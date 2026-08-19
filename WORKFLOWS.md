# Workflows

## Purpose

These workflows are focused on:

* the worktree layout from Christopher Allen's [Git Worktree Best Practices and Tools](https://gist.github.com/ChristopherA/4643b2f5e024578606b9cd5d2e6815cc)
* keeping branches current based on their parent (regular or stacked)
* trying to keep your checked out branches/worktrees cleaned up

There are two terms used throughout and that are not standard git vocabulary:

* **Worktree layout** \- a repository checked out as one directory per branch, sharing a single object store, rather than one working directory that moves between branches or any other checkout structure.
* **Base** \- the **direct parent** of a branch, meaning the one branch it should be rebased onto. For a branch with an open pull request this is that PR's target. In a stack it is the branch immediately below, never the bottom of the stack, and it is frequently not `main`. The word is git's and GitHub's (`merge-base`, `rebase --onto <newbase>`, `baseRefName`), which is why it is used here rather than "parent", but the relationship it names is the direct one.

## What this isn't trying to provide

One workflow to rule them all. These are the defaults that hold up across the repositories where a rebase-based workflow is the standard. Each workflow can be treated as optional or overrideable and for the most part you should be able to perform all the commands manually with no conflicting behaviors.

These workflows will either run into issues or completely break if your repository merges by squash or forbids force-pushing to PR branches. This is called out in those sections.

The one thing you lose by running the native commands instead is the recorded base: `git worktree add` does not write `branch.<name>.base`, so until that branch has an open pull request `git refresh` has to fall back on inference. See **Where the base comes from**.

# The worktree layout

## Why one directory per branch

`git checkout` has one working copy and moves it between branches. Everything expensive to rebuild gets rebuilt on every switch: the stash dance, `node_modules`, the build cache, the editor index, the language server. Only one branch can be looked at.

`git worktree` gives each branch its own directory against one shared object store. Switching branches becomes `cd ../<other branch>` or `gwt <other branch>`. Two branches can be open in two editor windows, and a test suite can run against one while you type in another.

Plain `git worktree` leaves the placement of those directories to you, and the common answer (scattering them beside the original clone) gets ugly quickly. `git clone-for-worktrees` picks a layout:

    myrepo/
      .git/          the bare repository: history, objects, config
      main/          a worktree
      add-ci/        a worktree
      spike/         a worktree

The repository becomes a directory of branches. Nothing is nested inside anything else, and each directory is named for the branch in it.


What is added here is everything about *where a branch should land*, and what to do when it cannot:

* resolving a base from the branch's open pull request, and recording it
* ordering a stack so one pass restacks the whole chain
* pushing under a lease taken before the fetch
* `--doctor`, and the triage table that feeds it
* adopting a remote that was rewritten elsewhere (`--sync`)
* removing worktrees only where there is evidence the branch merged (`--prune`)
* converting an existing plain clone into the layout

## Creating the layout

* `git clone-for-worktrees owner/name` clones as `<name>/.git` and checks out the default branch beside it.
    * A bare `owner/name` becomes an ssh URL. Anything with a scheme, an scp-style host, or a path is passed to git untouched.
    * Only the default branch is checked out. Every other branch should be a worktree you ask for, rather than one directory per branch the remote happens to have.
* `--upstream owner/name` adds an `upstream` remote. When `gh` is installed and the clone is a fork, its parent is detected and this is only needed to override.

## Adding branches

As with all scripts in this project, the `git-new-worktree` script can be run via `git new-worktree`. However, the shell function `gwt` provides an improved interface that will also change the directory after it calls `git-new-worktree`. This works whether the branch needs to be created, only exists on `origin`, or is already checked out locally.

That split exists because a script cannot change its caller's directory: `git new-worktree` prints the worktree path on stdout and every message on stderr, so the wrapper has a clean path to `cd` to.

* `gwt my-feature` creates the branch off the default branch and cd's into it.
* `gwt my-feature other-base` creates it off `origin/other-base`. A bare name is looked up under `origin` first.
* `gwt existing-branch` checks it out, tracking `origin` if the branch is there.
* `gwt already-open` takes you to a worktree that is already laid down. There is nothing to create and nothing to look up, so the path comes straight back without even a fetch.

Creating a branch this way records what it was branched from:

    git config branch.my-feature.base main

That line is what lets `git refresh` do the right thing before a pull request exists. See **Where the base comes from**. `man git-new-worktree` covers the rest.

New branches are created with `--no-track`, deliberately. Branching from `origin/main` would otherwise leave `origin/main` as the new branch's upstream, and every branch here wants `origin/<its own name>`. What a wrong upstream costs depends on `push.default`, so none is left behind.

## Converting a clone you already have

Running `git new-worktree` inside a plain clone offers to convert it: `.git` becomes bare and the checkout moves to `<repo>/<current-branch>/`.

* The conversion **must** start from a pristine checkout. It removes the old working directory and lets `git worktree add` lay it down again, so anything git is not tracking would not come back.
* It refuses when `git status --porcelain --ignored` returns anything, and tells you to run `git clean -ndx` to review.
* `-f` skips the prompt. It does not skip the check.

# Staying current

## The rule

Keep a branch rebased onto its base continuously, rather than merging the base into it now and then.

A branch that is always one rebase from its base is reviewable, cherry-pickable, and does not produce a surprise conflict at merge time. A branch carrying six "Merge branch 'main' into feature" commits is none of those, and the reviewer has to read around them.

`git refresh` automates that. One line back, naming what it rebased onto and what is still true afterwards:

    $ git refresh
    ✅ rebased onto origin/main, pushed

## The everyday loop

    git refresh              # land on the current base, and publish what moved
    # edit something
    git commend -a           # fold it into the commit that was wrong
    git please               # republish, refusing if origin moved

`git refresh` is the one that works out what to rebase onto. After that, a change to work already in review is an amend and a republish, not a new commit apologising for the last one, so `commend` and `please` carry the rest of the loop.

## Where the base comes from

In order. First hit wins:

1. **The base of the branch's open pull request**, via `gh`. Once a PR exists this is the authority, because it names the branch the change will actually merge into.
2. **`branch.<name>.base`**, recorded by `git new-worktree` at creation. This covers the gap before a PR exists.
    * When that base branch is gone (merged and deleted while you were working), it is followed to whatever it merged into rather than reported as a base that no longer exists.
3. **The default branch**, but only where the shape of the history agrees.
    * On a single branch it is assumed outright.
    * Under `--all` it is assumed only when nothing in the history points at a different parent. Guessing wrong there flattens an entire unopened stack onto `main`.

A branch none of those answer is reported as `no base` and left alone. `--doctor` will say which of the three is missing and offer the `git config branch.<name>.base <guess>` that fixes it.

Every rebase targets `origin/<base>`, **never** a local branch of the same name. That is deliberate, and it is why a stack needs its lower branches pushed before the ones above them land on anything new.

## Forks

Where an `upstream` remote exists, every run starts by fast-forwarding origin's default branch from upstream's:

    ⬆️  origin/main fast-forwarded from upstream

Everything after that is a plain `origin` workflow, and a branch rebasing onto `origin/main` is rebasing onto current upstream. Where the two have genuinely diverged it says so and uses origin as-is.

## Pushing a rebased branch

A rebase rewrites every commit, so publishing one means force-pushing. The obvious safe version does not work here:

* `git push --force-with-lease` with no value checks against your remote-tracking ref, which `git refresh` just updated at the top of the run. Not a common occurrence when on a single contributor branch, but it could approve overwriting a colleague's commit that arrived in that very fetch.
* `--force-if-includes` reads the branch's reflog. A bare repository keeps no branch reflogs at all, because `core.logAllRefUpdates` defaults to false when `core.bare` is true.

So `--please` snapshots where each branch stood on origin **before** the fetch, and pushes holding that value:

    git push --force-with-lease=<branch>:<sha-from-before-the-fetch> origin <branch>

If someone pushed in between, the lease fails, the push is refused, and the run says so.

The point is not that the window is large. On a branch only you touch, fetch to push is a second or two. The point is that a script already knows where origin stood before its own fetch, so passing that value costs nothing, while an alias like `git please` has nowhere to get it from. Correctness here is free, so it is taken.

Under `--all`, only branches that moved, or that hold commits origin does not have, are pushed. A run over twenty worktrees should not fire off twenty pushes.

This is on by default. `--no-please` turns it off for one run, `git config refresh.pushWithLease false` for good.

## When the branch was rewritten somewhere else

Rebase a branch on a laptop, force-push, then run `git refresh` on a desktop. The desktop copy holds the same work under different hashes, so a plain rebase replays commits that already landed, against a base that already contains them. That is a conflict per file, for nothing.

`--sync` handles it:

* Where the local branch has nothing origin lacks (judged by patch identity, bounded by the base) origin's version is adopted first, then rebased.
* It is replayed onto the remote rather than reset onto it, so where that judgement is wrong the work ends up on top instead of gone. A bare repository has no branch reflog to have recovered it from.
* A branch that does have commits of its own under a rewritten remote is a question about intent, not a mechanical problem. It is reported as `diverged from origin` and left alone.

This is on by default too. `--no-sync` for one run, `git config refresh.syncStale false` for good.

## Uncommitted changes

By default `rebase.autoStash` is disabled which causes `git refresh` to see a dirty worktree and leave it alone, reporting that it is dirty and needs to be addressed.

On a single branch that is a refusal, on stderr, exit 1, before the fetch even runs:

    $ git refresh
    ❌ you have uncommitted changes; commit or stash them, or set rebase.autoStash

Under `--all` it is a row, and the rest of the worktrees carry on:

    add-billing-writes  origin/main  ⏭️  dirty

When `rebase.autoStash` is enabled `git-refresh` will honour it and rebases will run after stashing the changes for the duration. If the stash does not reapply afterwards the branch has still moved and the working tree is left conflicted, reported as `autostash conflicted` with the stash kept. See [RECOMMENDATIONS.md](RECOMMENDATIONS.md).

A rebase that runs because of this and then conflicts is still aborted under `--all` and `--stack`, and the abort restores the stashed changes. See **Conflicts behave differently under --all**.

# Stacks

## What a stack is

A chain of pull requests where each targets the one below it instead of `main`:

    main
     └── add-billing-writes      PR #1 → main
          └── add-billing-ui     PR #2 → add-billing-writes
               └── add-billing-docs  PR #3 → add-billing-ui

You do this when a change is too big to review in one piece and the pieces depend on each other. The cost is that keeping it current by hand is miserable: `main` moves, so #1 gets rebased, which rewrites its commits, so #2 is now based on commits that no longer exist, and so on up the chain.

## One pass, bottom-up

`git refresh --stack` does the whole chain in one run. It starts from the branch you are standing in and walks pull request bases in both directions: the branches below, because it has to land on them, and the branches above, because those are the ones a rebase here would strand.

    cd add-billing-writes
    git refresh --stack

* Branches are sorted topologically by their base, so `add-billing-writes` is processed before `add-billing-ui`, which is processed before `add-billing-docs`.
* Each branch is pushed as soon as it is rebased. Because every rebase targets `origin/<base>`, pushing #1 moves the exact ref #2 is about to land on. One pass, correct order, no second run.

`--all` does the same across every worktree rather than one chain, and behaves identically in every other respect. It belongs to housekeeping rather than to stacks; see **The table is the triage**.

## Squash merges break this

Squash merging the bottom of a stack destroys the commit identity every later rebase depends on, so the branch above replays work that is already in `main` and conflicts with it. `git refresh` cannot repair that, because the information needed to repair it is what the squash threw away.

If your repository squash merges, read [TROUBLESHOOTING.md](TROUBLESHOOTING.md#a-squash-merged-base-conflicts-on-rebase) before you build a stack on it. The short version: enable rebase merges and disable squash merges in repository settings. Merge commits are not great either, but they do avoid this issue.

# Housekeeping

## The table is the triage

`--all` is `--stack` widened to every worktree in the repository, in the same topological order. With `--dry-run`, or through `git check-trees`, it changes nothing and reports the state of all of them:

    $ git check-trees
    🔎 dry run: fetched, and changed nothing else. what follows is a prediction.
    BRANCH              BASE                       STATUS
    main                origin/main                ✅ synced
    old-spike           origin/main                ❌ conflict, 1 file
    add-billing-writes  origin/main                ➖ current
    add-billing-ui      origin/add-billing-writes  ✅ pushed

    4 worktrees: 1 synced, 1 pushed, 1 current, 1 conflicted

    1 needs you; run again with --doctor to see what to do

An empty status means nothing to report: the branch will rebase and it will be fine. Each branch lands in exactly one bucket in the summary, so the counts add up to the number in front of them.

That first line is there because the rows read identically whether or not anything was done, which is deliberate: one format to learn. A dry run does fetch, and that is the only thing it changes. With stale remote-tracking refs it would be predicting against last week's origin, and reporting a branch clean that conflicts a second later. Nothing of yours is a remote-tracking ref. It moves nothing else: no rebase, no push, no worktree removed, and origin's default branch is not fast-forwarded from upstream.

## When to use --doctor

The table says which branches need you. `--doctor` says what to do about the one you are standing in: the conflicting files by name, the unpushed commits by subject, and the command that fixes it.

    $ git refresh --doctor
    ⚠️  conflict, 3 files, 2 unpushed

    🩺 add-billing-ui

      would conflict in 3 files against origin/add-billing-writes
          src/billing/invoice.go
          src/billing/invoice_test.go
          src/billing/proration.go
      → git rebase origin/add-billing-writes   to do it now and resolve them

      2 commits here that origin has not got
          a1b2c3d4e  Add invoice line items
          f5e6d7c8b  Cover the proration case
      → git push   (or: git refresh --please)

## When not to use --doctor

It refuses `--all` and `--stack`, on purpose. Advice this specific does not scale to twenty branches, and the table is already the triage across them.

## Removing worktrees that are finished

`--prune` removes a worktree when its branch is gone from origin **and** there is evidence it was merged.

* It **never** touches a worktree with uncommitted changes, one you are standing in, or one with no sign of having been merged. Those are reported and left for you.
* A branch that was never pushed is never pruned. Never pushed means never merged, so there is nothing to clean up, and it may be the only copy.
* This is a different operation from `fetch.prune`, despite the name. That one deletes remote-tracking refs; this one removes the worktree directory and deletes the local branch.
* Unlike `fetch.prune`, which only deletes remote-tracking refs, this removes the worktree directory and deletes the local branch.


    git check-trees        # --all --prune --dry-run: what would go
    git prune-trees        # --all --prune: actually go

## Conflicts behave differently under --all

* Under `--all` and `--stack`, a conflicting rebase is aborted. Twenty speculative rebases cannot be allowed to leave six worktrees wedged mid-rebase. The conflict is reported and handed back as a command to run.
* On a single branch the conflict is left in place. You asked for that rebase while standing in that worktree, and aborting would only mean running the identical rebase by hand to reach the identical conflict.

This is a separate question from **Uncommitted changes** above, and the two compose rather than disagree. `rebase.autoStash` decides whether a rebase runs at all in a dirty worktree; this decides what happens to a rebase that ran and then conflicted. Where both apply, the abort restores the autostash: the uncommitted work comes back, the branch is left where it started, and no stash entry is orphaned.

This is also why `--all` and `--stack` force `rerere.enabled=false`. See [RECOMMENDATIONS.md](RECOMMENDATIONS.md).

## When something goes wrong

[TROUBLESHOOTING.md](TROUBLESHOOTING.md) covers the failures this workflow surfaces: a squash merged base, a refused push, `no base`, `autostash conflicted`, and a refusal to run in a dirty worktree.

## Exit status

* `0` where nothing conflicted and nothing was refused.
* `1` where a rebase conflicted, a push was refused, or the run could not proceed (no branch here, an unreadable config value, a base that does not exist).
* `2` where the command line was wrong: an unknown option, or a required argument missing.
