# Contributing

Thanks for your interest in git-refresh! This is a small set of POSIX shell
scripts — contributions and issues are welcome.

## Development

There is nothing to build. The scripts run from `bin/` as they are, so putting
that directory on your `PATH` is enough to test a change.

```console
$ make check      # syntax + man pages + behaviour (the CI gate)
$ make lint       # every static check
$ make test       # the behavioural suite only
$ make setup      # install what check needs (mandoc)
$ make install    # install into PREFIX, default /usr/local
$ make help       # list all targets
```

`make install PREFIX=$HOME/.local` installs without touching system paths.

## Tests

The suite lives in `tests/`: `run-tests` is the runner, `lib.sh` holds the
fixtures and assertions, `stubs/` fakes `gh`, and each case is one file in
`tests/cases/`. A case builds a real repository — a bare remote, a clone, and
worktrees — and runs the scripts against it.

Cases run with `GIT_CONFIG_GLOBAL` and `GIT_CONFIG_SYSTEM` pointed at
`/dev/null`, so the suite reads none of your own git config. Anything a case
depends on, it sets.

Two rules matter more than coverage:

- **Every behaviour change ships a test that fails without it.** Not "has a
  test" — verified. Stash the change, run the case, watch it go red, restore.
  An assertion that was never exercised passes for the wrong reason: this
  repository has shipped one that read `assert_absent "need you"` against
  output saying `1 needs you`, which never matched and never could.
- **Fixtures are invented.** No real repository paths, branch names, or pasted
  command output, in tests or anywhere else. Build a fixture and read from
  that.

Run one case by number while iterating: `tests/run-tests 08`.

## Documentation

A change to anything a user sees updates every document that quotes it. Before
committing, grep the old text:

```console
$ grep -rn "the old string" README.md WORKFLOWS.md RECOMMENDATIONS.md \
      TROUBLESHOOTING.md man/
```

The surfaces are `README.md` for the short version, `WORKFLOWS.md` for what to
run and when, `RECOMMENDATIONS.md` for settings the tool suggests but does not
set, `TROUBLESHOOTING.md` for failures, and `man/*.1` for the reference. A flag
or a config key that appears in none of them is undiscoverable; a sample output
that no longer matches what the tool prints is worse than none.

`make lint-man` catches malformed roff. It does not catch prose describing
behaviour that changed, so read the rendered page: `mandoc -Tascii man/git-refresh.1`.

## Commits & pull requests

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `chore:`, …). Releases and the changelog are
  generated from them, so the prefix decides the next version number.
- The subject says what changed; the body says why, and what it was doing
  before. A reader with the diff in front of them still cannot see the reason.
- Open PRs against `main`, one issue per PR. CI runs `make check`; keep it green.
- Fix review findings by amending the commit that introduced them. A fixup
  stacked onto your own unmerged branch leaves the history describing a mistake
  nobody ever saw.

## License

By contributing you agree that your contributions are licensed under the
project's [MIT](LICENSE) license.
