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

.PHONY: all install uninstall check clean

all:
	@echo "nothing to build; these are shell scripts. try: make install"

install:
	install -d $(BINDIR) $(SHAREDIR) $(DOCDIR) $(MANDIR)
	for b in $(BINS); do install -m 0755 bin/$$b $(BINDIR)/$$b; done
	for f in $(SHARE); do install -m 0644 $$f $(SHAREDIR)/$$(basename $$f); done
	for d in $(DOCS); do install -m 0644 $$d $(DOCDIR)/$$d; done
	for m in $(MANS); do install -m 0644 man/$$m $(MANDIR)/$$m; done

uninstall:
	for b in $(BINS); do rm -f $(BINDIR)/$$b; done
	for m in $(MANS); do rm -f $(MANDIR)/$$m; done
	rm -rf $(SHAREDIR) $(DOCDIR)

# Syntax only. The behavioural suite is tests/run-tests.
check:
	@for b in $(BINS); do sh -n bin/$$b && echo "ok  bin/$$b"; done
	@sh -n shell/gwt.sh && echo "ok  shell/gwt.sh"
	@test -x tests/run-tests && tests/run-tests || echo "no tests/run-tests yet"

clean:
	@:
