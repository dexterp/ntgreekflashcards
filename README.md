# NT Greek flashcards: tag guide

Documentation for the Anki deck **NT Greek (By Freq or Chap)**: one card per Greek New Testament lemma, tagged so you can study by how often a word occurs or by where it occurs.

- **Deck:** [NT Greek (By Freq or Chap) on AnkiWeb](https://ankiweb.net/shared/info/1482865541)
- **Guide:** <https://dexterp.github.io/ntgreekflashcards/> (GitHub Pages, updated by `make release`)

## What the guide covers

The guide is one self-contained page, `index.html`, with three tabs. It opens on the Quickstart.

**Quickstart** takes a new user from the deck to a working filtered deck in five steps, with three copy-ready examples to start with.

**Filtered decks** has copy-and-paste **Name** and **Search** pairs for a filtered deck of every chapter and every frequency tier. Each search takes only cards that are new, due, or in learning. There is a filter box for the chapter table and a Copy button on every cell.

**Tag guide** explains how the deck's tags work and how to search with them:

- **Frequency tags**, `GNT::freq::…`: 11 tiers, from `A:50+` (50 or more occurrences) down to `K:1` (occurs once).
- **Chapter tags**, for example `GNT::Book::04:Jn::03` (John 3): every chapter a lemma appears in is tagged, across all 260 chapters of the 27 books, which are numbered in study order rather than Bible order.
- **Part-of-speech tags**, `GNT::POS::…`.
- Anki search syntax, ready-made search recipes, and tips for studying with filtered decks.

## Repository layout

| File | Purpose |
| --- | --- |
| `index.html` | The documentation site. HTML, CSS and JavaScript in one file, with no build step and no external requests. |
| `VERSION` | The release number (`X.Y.Z`). A release is tagged with exactly this text, for example `1.0.0`. |
| `Makefile` | Tasks to preview, validate, release and publish the site. |
| `RELEASE.md` | Release notes. |
| `.nojekyll` | Tells GitHub Pages to serve the files as they are. |
| `.gitignore` | Ignores `.DS_Store` and editor backup files. |

## Requirements

- `git`
- The [GitHub CLI](https://cli.github.com/) (`gh`), logged in with `gh auth login`
- GNU `make`
- Python 3 (used by `make help`, `make validate` and `make serve`)

## Working on the guide

```sh
make serve      # preview at http://localhost:8000
make validate   # check index.html: doctype, closing tag, working #anchors
```

## Releasing

1. Edit `index.html` and run `make validate`.
2. Set the new number in `VERSION` if you are bumping the release, commit, and push `main`.
3. Run `make release`.

`make release` runs three steps and stops at the first one that fails:

1. It tags the current commit with the `VERSION` number (an annotated tag).
2. It pushes that tag to `origin`.
3. It publishes the site, but only if the tag exists on the remote.

Before it changes anything, `release` checks that:

- `VERSION` holds a semantic version and is committed;
- tracked files have no uncommitted changes;
- `index.html` passes `make validate`;
- `HEAD` is the tip of `main` on `origin`;
- the tag is not already on a different commit. Tags are never moved, so to release again you bump `VERSION`.

Running `make release` again on a commit that is already released just publishes again.

`release` is the only target that changes git. It creates and pushes that one tag, and it never commits or pushes a branch.

## Makefile targets

`make help` lists the documented targets:

| Target | What it does |
| --- | --- |
| `release` | Tag `HEAD` with `VERSION`, push the tag, then publish (only if the tag exists). |
| `publish` | Publish the site. Needs the `VERSION` tag on the remote. |
| `pages` | Enable or update GitHub Pages. Needs the `VERSION` tag on the remote. |
| `rebuild` | Ask GitHub to rebuild the site without a new release. Needs the `VERSION` tag on the remote. |
| `url` | Print the site URL. |
| `serve` | Preview locally on port 8000 (`PORT=…` to change it). |
| `clean` | Remove `.DS_Store` files. |
| `pages-off` | Unpublish the site after asking. The repository is kept. |

There are also helper targets that `help` does not list: `check`, `version-check`, `validate`, `release-check`, `status`, `wait` and `open`.

`publish`, `pages` and `rebuild` share one gate. They refuse to run unless `VERSION` is a semantic version, a tag with that number exists on the remote, and the remote `main` is at that tag's commit, so the live site is exactly the tagged version.

Settings such as `REMOTE`, `BRANCH`, `REPO` and `PORT` can be overridden on the command line, for example `make release REMOTE=upstream`.

## Good to know

GitHub Pages is set to build the `main` branch, so GitHub rebuilds the site every time `main` is pushed, tagged or not. The Makefile's checks control what `make` publishes; they cannot stop that automatic build.
