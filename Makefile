# Plain install, and the thing every packaging system builds on top of.
#
#   make install                        into /usr/local
#   make install PREFIX=$HOME/.local    into your home
#   make install DESTDIR=/tmp/stage     into a staging root, for a package
#
# DESTDIR is prepended to every path and is never baked into anything, so a
# package built from a staging root works once unpacked at /.

PREFIX  ?= /usr/local
DESTDIR ?=

BINDIR   = $(DESTDIR)$(PREFIX)/bin
SHAREDIR = $(DESTDIR)$(PREFIX)/share/git-refresh
DOCDIR   = $(DESTDIR)$(PREFIX)/share/doc/git-refresh
MANDIR   = $(DESTDIR)$(PREFIX)/share/man/man1

BINS  = git-refresh git-new-worktree git-clone-for-worktrees
SHARE = shell/gwt.sh git/refresh.gitconfig
DOCS  = README.md WORKFLOWS.md RECOMMENDATIONS.md TROUBLESHOOTING.md LICENSE
MANS  = git-refresh.1 git-new-worktree.1 git-clone-for-worktrees.1

.PHONY: all help setup install uninstall check lint lint-shell lint-man test clean

all: help

help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup: ## Install what check needs; does nothing where it is already there
	@if command -v mandoc >/dev/null 2>&1; then \
		echo "ok  mandoc already present"; \
	elif command -v apt-get >/dev/null 2>&1; then \
		DEBIAN_FRONTEND=noninteractive sudo -E apt-get -o DPkg::Lock::Timeout=60 update -qq \
		&& DEBIAN_FRONTEND=noninteractive sudo -E apt-get -o DPkg::Lock::Timeout=60 install -y -qq mandoc; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install mandoc; \
	else \
		echo "install mandoc, then run make check" >&2; exit 1; \
	fi

install: ## Install into PREFIX, staged through DESTDIR
	install -d $(BINDIR) $(SHAREDIR) $(DOCDIR) $(MANDIR)
	for b in $(BINS); do install -m 0755 bin/$$b $(BINDIR)/$$b; done
	for f in $(SHARE); do install -m 0644 $$f $(SHAREDIR)/$$(basename $$f); done
	for d in $(DOCS); do install -m 0644 $$d $(DOCDIR)/$$d; done
	for m in $(MANS); do install -m 0644 man/$$m $(MANDIR)/$$m; done

uninstall: ## Remove everything install put down
	for b in $(BINS); do rm -f $(BINDIR)/$$b; done
	for m in $(MANS); do rm -f $(MANDIR)/$$m; done
	rm -rf $(SHAREDIR) $(DOCDIR)

# The one target CI calls. Composed of the others rather than repeating what
# they do, so running a piece by hand runs the same thing CI ran.
check: lint test ## Aggregate gate: syntax, man pages, behaviour (CI's entry point)

lint: lint-shell lint-man ## Every static check

lint-shell: ## Parse every shell script without running it
	@for b in $(BINS); do sh -n bin/$$b && echo "ok  bin/$$b"; done
	@sh -n shell/gwt.sh && echo "ok  shell/gwt.sh"
	@for f in tests/run-tests tests/lib.sh tests/stubs/gh tests/cases/*.sh; do \
		sh -n $$f && echo "ok  $$f"; done

lint-man: ## Lint the man pages
	@command -v mandoc >/dev/null 2>&1 || { \
		echo "mandoc not found; run make setup" >&2; exit 1; }
	@mandoc -T lint man/*.1 && echo "ok  man pages"

test: ## Run the behavioural suite
	@tests/run-tests

clean:
	@:
