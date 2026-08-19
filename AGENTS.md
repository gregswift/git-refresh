# AGENTS.md

Read [CONTRIBUTING.md](CONTRIBUTING.md) for how to build, test and submit, and
[STYLE.md](STYLE.md) for how the code is written. This file lists only what an
agent gets wrong.

## Before proposing a change

* Run `make check`. It is what CI runs.
* Prove a new test fails without the change. Stash the change, run the case,
  watch it go red, restore. An assertion that never matched anything passes for
  the wrong reason, and one has shipped here already.
* A change to anything a user sees updates every document quoting it. Grep
  `README.md WORKFLOWS.md RECOMMENDATIONS.md TROUBLESHOOTING.md man/` for the
  old text first.
* Fixtures are invented. Never paste a path, branch name or command output from
  a real repository into this one.

## Comments

A comment should be as short as it can be and still say what is necessary.
Going past that point is the failure: the reasoning survives and the thing
being reasoned about is lost. Where a comment adds nothing, delete it rather
than trim it. [STYLE.md](STYLE.md) has the rules.

## These scripts are destructive

`bin/` removes worktrees, deletes branches and force-pushes. Never run
`git refresh --all --prune`, `git prune-trees`, or anything with `--please`
against a real repository to see what it does.

`tests/lib.sh` builds throwaway repositories with a bare remote, a clone and
worktrees. Use `tests/run-tests`, or a scratch fixture built the same way.
`--dry-run` is the read-only view when you need one against real state.
