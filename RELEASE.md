# Release notes

## 1.0.0

First release of the tag guide for the Anki deck **NT Greek (By Freq or Chap)**, together with the tooling that publishes it to GitHub Pages.

### The documentation site

- **Tag guide tab.** Explains the deck's three tag families and how to search with them:
  - frequency tags `GNT::freq::…` in 11 tiers, `A:50+` down to `K:1`;
  - chapter tags such as `GNT::Book::04:Jn::03`, covering all 260 chapters of the 27 books, numbered in study order;
  - part-of-speech tags `GNT::POS::…`.

  It also covers Anki search syntax, ready-made search recipes, filtered-deck steps and tips.
- **Filtered decks tab.** Copy-and-paste **Name** and **Search** tables for 11 frequency tiers and 260 chapters. Every search follows `"deck:NT Greek (By Freq or Chap)" (is:new OR is:due OR is:learn) tag:…`, so only new, due and learning cards are pulled in. Names follow the deck's own pattern, for example `NT Greek 01: 1 John::1 John 1` and `NT Greek: Instances 12-10`. Includes a chapter filter box and a Copy button on every cell.
- The tabs can be linked directly (`#deck-names` opens the Filtered decks tab).
- The intro links to the deck on [AnkiWeb](https://ankiweb.net/shared/info/1482865541).
- One self-contained page: light and dark themes, responsive layout, no external requests.

### Release tooling

- `VERSION` holds the release number, and the git tag is named exactly that (`1.0.0`).
- `make release` tags `HEAD` with the `VERSION` number, pushes only that tag, then publishes the site if the tag exists on the remote. It first checks that `VERSION` is a valid and committed semantic version, tracked files are clean, `index.html` validates, `HEAD` is the tip of `main` on the remote, and the tag is not already on a different commit. Tags are never moved, and re-running on a released commit just publishes again.
- `make publish`, `make pages` and `make rebuild` share one gate: the `VERSION` tag must exist on the remote and the remote `main` must be at that tag's commit.
- Other targets: `serve`, `validate`, `url`, `open`, `status`, `wait`, `clean`, `pages-off`. `make help` lists the documented ones.
- `README.md` describes the project and the release workflow.

### Known limitation

GitHub Pages builds the `main` branch, so GitHub rebuilds the site whenever `main` is pushed, tagged or not. The Makefile's checks control what `make` publishes but cannot stop that automatic build.
