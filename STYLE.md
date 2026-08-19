# Style

How code in this repository is written. `CONTRIBUTING.md` covers how to build,
test and submit it.

## Comments

Comments say why. The code says what.

Say what is necessary in as few words as it takes. A comment that needs a
paragraph is usually not a comment: it is a commit message, or a section of
WORKFLOWS.md, and it belongs there instead.

- **Delete a comment that adds nothing.** One that names the code below it,
  repeats a nearby `printf`, or points at something already visible.
- **Keep a comment that carries what the code cannot.** A constraint from
  elsewhere, a git command that does not do what it reads like, an approach that
  fails, a measurement that explains an odd bound.
- **Say what the code does, then why.**
- **Cut a closer that names no cost.** "What that costs depends on your
  configuration" does no work.
- **Answer the question the comment raises.** Where it explains a condition, say
  what happens when the condition is false.

Write plainly: one idea per sentence, twenty words or fewer, active voice,
present tense, the same word for the same thing, no figures of speech. If three
sentences are not enough, the explanation belongs somewhere else.

File headers say what the script is for. Function headers give the contract.
Section banners are navigation.

## Shell

`#!/bin/sh` and POSIX only. `make lint-shell` parses every script; it does not
catch a bashism that happens to parse, so do not reach for one.

* No `local`. It is not POSIX. A function names its own variables with a leading
  underscore instead: `_best`, `_dist`, `_cand`.
* `printf`, never `echo`. What `echo` does with a backslash or a leading dash
  varies between shells.
* `set -eu` at the top.
* `die` for anything fatal. It prints to stderr and exits 1.

## Output

**stdout carries data. stderr carries everything a person reads.**
`git-new-worktree` prints one thing to stdout, the worktree path, which is what
lets the `gwt` wrapper `cd` into it. A stray `printf` without `>&2` breaks that
wrapper, and the tests will not always catch it.

Status lines are lowercase with no closing full stop: `rebased onto origin/main,
pushed`. They read as a continuation of the branch name beside them. Longer
prose that explains a refusal is ordinary sentences, because it is not a status
line.

Severity chooses the icon and the colour together, so a line says the same thing
with either switched off. Never carry meaning in colour alone.

## Tests

One case per file in `tests/cases/`, numbered. A case opens with a comment
saying what it is about and why the behaviour matters.

* Build a real repository with the fixture helpers in `lib.sh`. Nothing here
  mocks git; a case makes a bare remote, a clone and worktrees, and runs the
  scripts against them.
* Assertion labels are lowercase and read as prose, because the runner prints
  them and a passing run should read as a description of the behaviour:

      ok   dry run predicts the conflict
      ok   the real run meets the conflict it predicted
      ok   and the prediction did not move the branch

  A follow-on assertion starts with `and`.
* Assert what a user would see, not how it was arrived at.
* Fixtures are invented. Never paste a path, branch name or command output from
  a real repository.
