# Makefile - automate GitHub Pages for the NT Greek flashcards tag guide
#
#   One time:              git init -b main, then make create
#   After editing docs:    make publish
#   Watch the build:       make wait
#   See where things are:  make status
#
# Requires: git and the GitHub CLI (gh), logged in via `gh auth login`.
# Works with the macOS default GNU Make 3.81.

SHELL := /bin/bash
.DEFAULT_GOAL := help
.NOTPARALLEL:

# Python
PYTHON ?= $(shell command -v python3 python|head -n1)

# ---- Settings (override on the command line, e.g. make publish MSG="Fix typo") ----
REPO        ?= ntgreekflashcards
BRANCH      ?= main
PAGES_PATH  ?= /
VISIBILITY  ?= public
DESCRIPTION ?= Tag guide for the NT Greek (By Freq or Chap) Anki deck
MSG         ?= Update documentation
PORT        ?= 8000
DOCS        := index.html

export MSG

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

.PHONY: check repo pages create validate commit push publish \
        status wait rebuild url open serve clean pages-off

# ---------------------------------------------------------------- setup

check: # Verify git, gh, your GitHub login, the git repo and index.html
	@command -v git >/dev/null || { echo "git not found"; exit 1; }
	@command -v gh >/dev/null || { echo "GitHub CLI not found: brew install gh"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "Not logged in to GitHub: run 'gh auth login'"; exit 1; }
	@test -d .git || { echo "Not a git repo yet: run 'git init -b $(BRANCH)' first"; exit 1; }
	@test -n "$(OWNER)" || { echo "Could not determine your GitHub username (try OWNER=yourname)"; exit 1; }
	@test -f $(DOCS) || { echo "$(DOCS) is missing"; exit 1; }
	@echo "OK: $(SLUG) -> $(PAGES_URL)"

.gitignore:
	@printf '.DS_Store\n*.swp\n*~\n' > $@
	@echo "Created .gitignore"

# An empty .nojekyll tells GitHub Pages to serve the files as-is (no Jekyll processing).
.nojekyll:
	@touch $@
	@echo "Created .nojekyll"

repo: check # Create the GitHub repo and add the origin remote (skips what exists)
	@if gh repo view $(SLUG) >/dev/null 2>&1; then \
		echo "GitHub repo $(SLUG) already exists"; \
	else \
		gh repo create $(SLUG) --$(VISIBILITY) --description '$(DESCRIPTION)' && echo "Created $(SLUG)"; \
	fi
	@if git remote get-url origin >/dev/null 2>&1; then \
		echo "Remote 'origin' already set"; \
	else \
		if [ "$$(gh config get git_protocol 2>/dev/null)" = ssh ]; then \
			git remote add origin git@github.com:$(SLUG).git; \
		else \
			git remote add origin https://github.com/$(SLUG).git; \
		fi; \
		echo "Added remote 'origin'"; \
	fi

pages: check ## Enable (or update) GitHub Pages for the branch
	@if gh api repos/$(SLUG)/pages >/dev/null 2>&1; then \
		gh api -X PUT repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' \
			&& echo "Pages source set to $(BRANCH):$(PAGES_PATH)"; \
	else \
		gh api -X POST repos/$(SLUG)/pages -f 'source[branch]=$(BRANCH)' -f 'source[path]=$(PAGES_PATH)' >/dev/null \
			&& echo "Pages enabled ($(BRANCH):$(PAGES_PATH))"; \
	fi

create: check .gitignore .nojekyll validate repo commit # One-time setup: repo, first push, enable Pages
	@git push -u origin $(BRANCH)
	@$(MAKE) --no-print-directory pages
	@echo ""
	@echo "Done. The first build takes a minute or two. Follow it with: make wait"
	@echo "  $(PAGES_URL)"

# ---------------------------------------------------------------- day to day

validate: # Sanity-check index.html (exists, doctype, closing tag, working #anchors)
	@test -s $(DOCS) || { echo "$(DOCS) is missing or empty"; exit 1; }
	@grep -qi '<!doctype html>' $(DOCS) || { echo "$(DOCS): missing <!doctype html>"; exit 1; }
	@grep -qi '</html>' $(DOCS) || { echo "$(DOCS): missing </html>"; exit 1; }
	@python3 -c "import re,sys; t=open('$(DOCS)',encoding='utf-8').read(); ids=set(re.findall(r'id=\"([^\"]+)\"',t)); bad=[h for h in re.findall(r'href=\"#([^\"]+)\"',t) if h not in ids]; sys.exit('broken #anchors: %s' % bad) if bad else None"
	@echo "$(DOCS) looks OK"

commit: # Commit all local changes (skips if nothing changed); MSG="..." sets the message
	@git add -A
	@if git diff --cached --quiet; then \
		echo "Nothing to commit"; \
	else \
		git commit -m "$$MSG"; \
	fi

push: check # Push the current commits to GitHub
	@git push -u origin $(BRANCH)

publish: check validate commit ## Validate, commit and push; GitHub Pages then rebuilds
	@git push -u origin $(BRANCH)
	@echo ""
	@echo "Pushed. Follow the build with: make wait"
	@echo "  $(PAGES_URL)"

# ---------------------------------------------------------------- maintenance

status: check # Show git status and the GitHub Pages build state
	@echo "== Local =="
	@git status -sb
	@echo ""
	@echo "== GitHub Pages =="
	@gh api repos/$(SLUG)/pages --jq '"URL:    \(.html_url)\nStatus: \(.status // "n/a")\nSource: \(.source.branch):\(.source.path)"' 2>/dev/null \
		|| echo "Pages is not enabled (run: make pages)"
	@gh api repos/$(SLUG)/pages/builds/latest --jq '"Latest build: \(.status) at \(.updated_at)"' 2>/dev/null || true

wait: check # Wait for the Pages build of your latest commit to finish (about 3 min max)
	@head=$$(git rev-parse HEAD); \
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

rebuild: check ## Ask GitHub to rebuild the site without a new commit
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
