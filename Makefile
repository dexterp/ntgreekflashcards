# Makefile - release and publish the NT Greek flashcards docs on GitHub Pages
#
# The release number lives in the VERSION file (X.Y.Z). To ship it:
#
#   1. Set VERSION, commit it, and push your branch yourself (git commit; git push origin main).
#   2. make release
#
# make release runs these steps and stops at the first one that fails:
#   1. tags the current commit with the VERSION number (annotated tag),
#   2. pushes that tag to the remote,
#   3. publishes the website, but only if the tag exists on the remote.
# It is the only target that changes git, and it only ever creates and pushes that one tag
# (it never commits, moves a tag, or pushes a branch).
#
# make publish (and pages, rebuild) all use the same gate. They refuse to run unless
#   1. VERSION is a semantic version,
#   2. the tag with that number exists on the remote, and
#   3. the remote branch that GitHub Pages serves is at that tag's commit,
#      so the live site is exactly the tagged version.
#
# Requires: git and the GitHub CLI (gh), logged in via `gh auth login`.
# Works with the macOS default GNU Make 3.81.

SHELL := /bin/bash
.DEFAULT_GOAL := help
.NOTPARALLEL:

# Python
PYTHON ?= $(shell command -v python3 python|head -n1)

# ---- Settings (override on the command line, e.g. make release REMOTE=upstream) ----
REPO        ?= ntgreekflashcards
REMOTE      ?= origin
BRANCH      ?= main
PAGES_PATH  ?= /
PORT        ?= 8000
DOCS        := index.html

# Release number from the VERSION file; the git tag is named exactly this (e.g. 1.0.0).
VERSION := $(shell tr -d '[:space:]' < VERSION 2>/dev/null)
TAG      = $(VERSION)

# Semantic Versioning 2.0.0 (semver.org) with an optional leading "v", as an extended regex.
SEMVER_RE := ^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*)?(\+[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)?$$

# GitHub username, looked up once and only when a target needs it (so `make help` stays offline).
# Override with: make OWNER=yourname ...
ifeq ($(origin OWNER),undefined)
OWNER = $(eval OWNER := $(shell gh api user --jq .login 2>/dev/null))$(OWNER)
endif
SLUG      = $(OWNER)/$(REPO)
PAGES_URL = https://$(shell echo '$(OWNER)' | tr '[:upper:]' '[:lower:]').github.io/$(REPO)/

#
# Help Script
#
define PRINT_HELP_PYSCRIPT
import re, sys

print("Usage: make <target>\n")
cmds = []
for line in sys.stdin:
    match = re.match(r'^_?([a-zA-Z0-9_-]+):.*?## (.*)$$', line)
    if match:
      target, help = match.groups()
      cmds.append([target, help])
for cmd, help in cmds:
        print("  %s%s%s - %s" % ("\x1b[0001m", cmd, "\x1b[0000m", help))
print("")
endef
export PRINT_HELP_PYSCRIPT

.PHONY: help
help: # Print help for the documented targets
	@$(PYTHON) -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

.PHONY: check version-check release-check pages validate release publish status wait rebuild url open serve clean pages-off

# ---------------------------------------------------------------- checks

check: # Verify git, gh, your GitHub login, the git repo and index.html
	@command -v git >/dev/null || { echo "git not found"; exit 1; }
	@command -v gh >/dev/null || { echo "GitHub CLI not found: brew install gh"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "Not logged in to GitHub: run 'gh auth login'"; exit 1; }
	@test -d .git || { echo "Not a git repo: set one up yourself (git init, remote, first commit)"; exit 1; }
	@test -n "$(OWNER)" || { echo "Could not determine your GitHub username (try OWNER=yourname)"; exit 1; }
	@test -f $(DOCS) || { echo "$(DOCS) is missing"; exit 1; }
	@echo "OK: $(SLUG) -> $(PAGES_URL)"

version-check: # Verify the VERSION file holds a semantic version
	@test -f VERSION || { echo "VERSION file is missing"; exit 1; }
	@tr -d '[:space:]' < VERSION | grep -Eq '$(SEMVER_RE)' || { echo "VERSION must hold a semantic version such as 1.0.0"; exit 1; }

validate: # Sanity-check index.html (exists, doctype, closing tag, working #anchors)
	@test -s $(DOCS) || { echo "$(DOCS) is missing or empty"; exit 1; }
	@grep -qi '<!doctype html>' $(DOCS) || { echo "$(DOCS): missing <!doctype html>"; exit 1; }
	@grep -qi '</html>' $(DOCS) || { echo "$(DOCS): missing </html>"; exit 1; }
	@python3 -c "import re,sys; t=open('$(DOCS)',encoding='utf-8').read(); ids=set(re.findall(r'id=\"([^\"]+)\"',t)); bad=[h for h in re.findall(r'href=\"#([^\"]+)\"',t) if h not in ids]; sys.exit('broken #anchors: %s' % bad) if bad else None"
	@echo "$(DOCS) looks OK"

# Publishing gate. Read-only: it only inspects the remote and never changes anything.
release-check: check version-check
	@git ls-remote --heads $(REMOTE) >/dev/null 2>&1 || { echo "Cannot read remote '$(REMOTE)' (does it exist, and do you have access?)"; exit 1; }
	@tag='$(TAG)'; \
	tagsha=$$(git ls-remote --tags $(REMOTE) "refs/tags/$$tag" "refs/tags/$$tag^{}" 2>/dev/null \
		| awk '{ if (index($$2, "^") > 0) peeled = $$1; else plain = $$1 } END { print (peeled != "" ? peeled : plain) }'); \
	if [ -z "$$tagsha" ]; then \
		echo "Refusing to publish: tag $$tag does not exist on '$(REMOTE)'."; \
		echo "Run: make release"; \
		exit 1; \
	fi; \
	tip=$$(git ls-remote $(REMOTE) "refs/heads/$(BRANCH)" | cut -f1); \
	if [ "$$tip" != "$$tagsha" ]; then \
		echo "Refusing to publish: '$(BRANCH)' on $(REMOTE) is not at tag $$tag, and GitHub Pages builds that branch."; \
		echo "Bump VERSION, push your commits, and run: make release"; \
		exit 1; \
	fi; \
	echo "Release gate passed: $$tag ($$tagsha)"

# ---------------------------------------------------------------- release and publish

pages: release-check ## Enable (or update) GitHub Pages (needs the VERSION tag on the remote)
	@if gh api repos/$(SLUG)/pages >/dev/null 2>&1; then \
		gh api -X PUT repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' \
			&& echo "Pages source set to $(BRANCH):$(PAGES_PATH)"; \
	else \
		gh api -X POST repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' >/dev/null \
			&& echo "Pages enabled ($(BRANCH):$(PAGES_PATH))"; \
	fi

release: check version-check validate ## Tag HEAD with VERSION, push the tag, then publish (only if the tag exists)
	@set -e; \
	tag='$(TAG)'; head=$$(git rev-parse HEAD); \
	git ls-remote --heads $(REMOTE) >/dev/null 2>&1 || { echo "Cannot read remote '$(REMOTE)' (does it exist, and do you have access?)"; exit 1; }; \
	git ls-files --error-unmatch VERSION >/dev/null 2>&1 || { echo "Refusing to release: VERSION is not committed. Commit it first."; exit 1; }; \
	if ! git diff --quiet HEAD; then \
		echo "Refusing to release: tracked files have uncommitted changes. Commit or stash them first."; \
		exit 1; \
	fi; \
	tip=$$(git ls-remote $(REMOTE) "refs/heads/$(BRANCH)" | cut -f1); \
	if [ "$$tip" != "$$head" ]; then \
		echo "Refusing to release: HEAD is not the tip of '$(BRANCH)' on $(REMOTE). Push (or pull) so they match first."; \
		exit 1; \
	fi; \
	localsha=$$(git rev-parse -q --verify "refs/tags/$$tag^{commit}" || true); \
	remotesha=$$(git ls-remote --tags $(REMOTE) "refs/tags/$$tag" "refs/tags/$$tag^{}" 2>/dev/null \
		| awk '{ if (index($$2, "^") > 0) peeled = $$1; else plain = $$1 } END { print (peeled != "" ? peeled : plain) }'); \
	if [ -n "$$localsha" ] && [ "$$localsha" != "$$head" ]; then \
		echo "Refusing to release: tag $$tag already exists locally at a different commit. Tags are never moved; bump VERSION."; \
		exit 1; \
	fi; \
	if [ -n "$$remotesha" ] && [ "$$remotesha" != "$$head" ]; then \
		echo "Refusing to release: tag $$tag already exists on '$(REMOTE)' at a different commit. Tags are never moved; bump VERSION."; \
		exit 1; \
	fi; \
	if [ -z "$$localsha" ] && [ -z "$$remotesha" ]; then \
		git tag -a "$$tag" -m "Release $$tag"; \
		echo "Tagged $$head as $$tag"; \
	else \
		echo "Tag $$tag already exists at this commit; not re-tagging"; \
	fi; \
	if [ -z "$$remotesha" ]; then \
		git push $(REMOTE) "refs/tags/$$tag:refs/tags/$$tag"; \
	else \
		echo "Tag $$tag is already on '$(REMOTE)'"; \
	fi
	@$(MAKE) --no-print-directory publish

publish: release-check ## Publish the site (only if the VERSION tag exists on the remote)
	@if gh api repos/$(SLUG)/pages >/dev/null 2>&1; then \
		gh api -X PUT repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' \
			&& gh api -X POST repos/$(SLUG)/pages/builds >/dev/null \
			&& echo "Pages updated; rebuild requested"; \
	else \
		gh api -X POST repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' >/dev/null \
			&& echo "Pages enabled ($(BRANCH):$(PAGES_PATH))"; \
	fi
	@echo ""
	@echo "Follow the build with: make wait"
	@echo "  $(PAGES_URL)"

# ---------------------------------------------------------------- maintenance

status: check # Show git status and the GitHub Pages build state
	@echo "== Local =="
	@git status -sb
	@echo ""
	@echo "== GitHub Pages =="
	@gh api repos/$(SLUG)/pages --jq '"URL:    \(.html_url)\nStatus: \(.status // "n/a")\nSource: \(.source.branch):\(.source.path)"' 2>/dev/null \
		|| echo "Pages is not enabled (run: make publish)"
	@gh api repos/$(SLUG)/pages/builds/latest --jq '"Latest build: \(.status) at \(.updated_at)"' 2>/dev/null || true

wait: check # Wait for the Pages build of the remote branch tip to finish (about 3 min max)
	@head=$$(git ls-remote $(REMOTE) "refs/heads/$(BRANCH)" | cut -f1); \
	for i in $$(seq 1 36); do \
		out=$$(gh api repos/$(SLUG)/pages/builds/latest --jq '.status + " " + .commit' 2>/dev/null); \
		st=$${out%% *}; sha=$${out##* }; \
		echo "build: $${st:-waiting}"; \
		if [ "$$sha" = "$$head" ]; then \
			case "$$st" in \
				built) echo "Live: $(PAGES_URL)"; exit 0;; \
				errored) echo "Build failed; see: make status"; exit 1;; \
			esac; \
		fi; \
		sleep 5; \
	done; \
	echo "Timed out; check again with: make status"; exit 1

rebuild: release-check ## Rebuild the site without a new release (needs the VERSION tag on the remote)
	@gh api -X POST repos/$(SLUG)/pages/builds >/dev/null && echo "Rebuild requested; follow it with: make wait"

url: check ## Print the site URL
	@echo $(PAGES_URL)

open: check # Open the live site in your browser
	@open $(PAGES_URL)

serve: ## Preview locally on port 8000 (override with PORT=...)
	@echo "Serving on http://localhost:$(PORT)  (Ctrl-C to stop)"
	@python3 -m http.server $(PORT)

clean: ## Remove .DS_Store files
	@find . -name .DS_Store -not -path './.git/*' -delete
	@echo "Cleaned"

pages-off: check ## Unpublish the site (asks first; the repo is kept)
	@read -r -p "Turn off GitHub Pages for $(SLUG)? [y/N] " a; \
	if [ "$$a" = y ] || [ "$$a" = Y ]; then \
		gh api -X DELETE repos/$(SLUG)/pages && echo "Pages disabled"; \
	else \
		echo "Cancelled"; \
	fi
