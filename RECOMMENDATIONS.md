# Recommended git settings

## Purpose

Settings that make this workflow smoother, and one that `git-refresh` overrides no matter what you set. Nothing here is installed by anything in this repository, and none of it is required to run the tools.

Read **rerere** even if you skip the rest.

## Out of Scope

A gitconfig you should copy wholesale. Every setting below changes what a core git command already does, so each one is listed with what it costs as well as what it buys.

# rerere

`git-refresh --all` and `git-refresh --stack` force `rerere.enabled=false`, whatever your config says. If rerere is on globally and has never fired during an `--all` run, that is why.

`git rerere` ("reuse recorded resolution") watches a merge conflict get resolved, records the resolution, and replays it the next time the same conflict shows up. For a workflow that rebases constantly that sounds ideal, and on a single branch it is.

Under `--all` it is wrong for two reasons:

1. **Those rebases are speculative and get thrown away.** An `--all` run attempts a rebase on every worktree and aborts any that conflicts, because twenty attempts cannot leave six worktrees wedged. Recording from a rebase that was then discarded teaches rerere a resolution nobody reviewed and nobody kept.
2. **It would replay resolutions unattended, across branches.** One recorded resolution applied to twenty branches in a batch, with nobody looking at any of them, is twenty silent decisions rather than a time-saver.

On a single branch rerere is left exactly as configured. You asked for that rebase, you are standing in that worktree, and the conflict is left in place. Where rerere resolves it, the run says so:

    ⚠️  conflict resolved by rerere, rebase paused

which means every conflict matched something rerere had already seen, and the rebase is waiting on you to check the result and `git rebase --continue`.

If you want rerere, turn it on and get the benefit where it belongs:

    [rerere]
        enabled = true
        autoUpdate = false     # stage the resolution yourself, so you see what it did

Leaving it off costs nothing here.

# Settings

## push.autoSetupRemote

    [push]
        autoSetupRemote = true

The strongest recommendation on this page, and the only one tied directly to how `git new-worktree` behaves.

New branches are created with `--no-track`, because branching from `origin/main` would otherwise leave `origin/main` as the new branch's upstream. Every branch here wants `origin/<its own name>`, which is set by the first push.

* Without this setting, that first push **must** be `git push -u origin <branch>`, and a plain `git push` fails.
* With it, `git push` does the right thing on a branch that has never been pushed.

Requires git 2.37.

## pull.rebase and branch.autosetuprebase

    [pull]
        rebase = true

    [branch]
        # autosetuprebase controls whether new branches should be set up to be
        # rebased upon git pull. Existing branches retain their configuration
        # when you change this option.
        autosetuprebase = always

The premise of this tooling, as a default: `git pull` updates a branch by rebasing onto its upstream rather than merging into it, so "Merge branch 'main' into feature" commits never accumulate and never have to be explained in review.

The per branch setting records and enforces the behavior directly into each branch's configuration, which persists the behavior on each branch you are already working on even if the global changes.

Since the rebase behavior is the preference here, the point is to make sure it is there, and to accept the change cost later if that shifts, rather than a global change impacting existing work.

This also lines `git pull` up with what `--doctor` recommends, which is `git pull --rebase` in several places.

## fetch.prune

    [fetch]
        prune = true

Deletes remote-tracking refs for branches that no longer exist on the remote.

Because `git-refresh` supports `--prune` via either the switch or the gitconfig setting, it never depends on the global `fetch.prune` state. What this setting provides is ensuring any other fetch or pull behave the same as `git refresh --prune`, or `git refresh` when `refresh.pruneWorktrees` is enabled.

The two prunes are near-homonyms for different things:

* `fetch.prune` deletes remote-tracking refs, and nothing else.
* `git refresh --prune` removes the worktree directory with `git worktree remove` and deletes the local branch with `git branch -D`.

## fetch.pruneTags

    [fetch]
        pruneTags = true

The same for tags. Nothing in this workflow is load-bearing on it.

> **Warning**
> This deletes local tags that do not exist on the remote. If you make local tags and do not push them, do not set this.

## rebase.autoStash

    [rebase]
        autoStash = true

Stashes a dirty working tree before a rebase and reapplies it after. `git-refresh` honours it:

* **Inside a single branch or worktree**, the rebase runs and git stashes the uncommitted changes for the duration. Without this set, `git refresh` refuses and says to commit or stash first.
* **Across multiple worktrees** (`--all`, `--stack`), a dirty worktree is rebased rather than marked skipped and reported.

Where the stash does not reapply cleanly the rebase has still completed, and the working tree is left conflicted. That is reported on the branch's row, the stash entry is kept, and the run says where:

    ⚠️  rebased onto origin/main, autostash conflicted
       your uncommitted changes are left conflicted in /path/to/worktree
       resolve them, then: git stash drop   (they are still in the stash)

Nothing is unwound for you, because the conflict is between your own edits and your own new base.

Where the rebase itself conflicts rather than the stash, `--all` and `--stack` abort it as they would any other conflicting rebase, and the abort puts the stashed changes back. The worktree ends up exactly as it started.

## merge.conflictstyle

    [merge]
        conflictstyle = zdiff3

Puts the common ancestor's version into the conflict markers alongside both sides, so what each side changed is visible rather than inferred from two final states.

This workflow surfaces conflicts earlier and more often, on purpose, because finding them at rebase time is cheaper than finding them at merge time. This is the setting that makes each of those conflicts cheaper to resolve. Requires git 2.35.

# Settings git-refresh reads

Unlike everything above, these only affect `git-refresh`.

| key | default | effect |
|---|---|---|
| `refresh.pushWithLease` | **on** | Push what the run rebased, holding the push to where origin stood before the fetch. Same as `--please`; `--no-please` for one run. |
| `refresh.syncStale` | **on** | Adopt `origin/<branch>` where this copy was rewritten elsewhere and holds nothing origin lacks. Same as `--sync`; `--no-sync` for one run. |
| `refresh.pruneWorktrees` | **off** | Remove worktrees whose branch is gone from origin and was merged. Same as `--prune`. Opt-in, because it deletes things. |
| `refresh.icons` | **on** | Emoji in the status column and the messages. `--icons` / `--no-icons` for one run. |
| `refresh.normalizeWorktreeNames` | **off** | Flatten a `/` out of the directory name a worktree gets, so a branch like `abc/feature` does not nest. Read by `git new-worktree`. `--normalize` / `--no-normalize` for one run. |
| `refresh.normalizeReplacement` | `_` | The single character a flattened name uses in place of `/`. |
| `color.refresh` | `auto` | `auto`, `always` or `never`. `auto` means a terminal, with no `NO_COLOR` set. |

Three more it reads but does not own:

| key | effect |
|---|---|
| `rebase.autoStash` | git's own. Honoured, as above: a dirty worktree is rebased rather than refused or skipped. |
| `branch.<name>.base` | Written by `git new-worktree`, read where the branch has no open pull request. Safe to set by hand. |
| `branch.<name>.remote` | git's own. Read by `--prune` as the evidence a branch was ever pushed. Never pushed means never merged, so such a branch is never removed. |

A key set to something that is not a boolean is an error, not a silent "off". That is deliberate for `refresh.pruneWorktrees`, where a typo would otherwise quietly change what a setting that removes worktrees does.
