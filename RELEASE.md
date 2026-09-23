# Release notes

## 1.5.0

Adds Article to the part-of-speech table, adds lemma counts to the frequency table, and retitles the intro.

### Changes

- The part-of-speech table in the Tag guide now lists `GNT::POS::Article` alongside the other nine tags.
- The Tag guide's part-of-speech section now says every note has one part-of-speech tag, since the three notes that lacked one (the article, Ῥήσσω, and ἐλάχιστος) have since been tagged.
- The frequency table in the Tag guide has a new **Lemmas** column showing how many lemmas fall in each tier, from 311 in the 50+ tier to 1,914 hapax legomena, with a total of 5,385 across all eleven tiers.
- The page's opening line now reads "A guide to using this Anki deck" instead of "A guide to the tags in this Anki deck".

## 1.4.0

Adds a study-order note to the Filtered decks tab.

### Changes

- A new note near the top of the Filtered decks tab, above the numbered steps: start with a frequency tier such as 50+, then switch to studying chapter by chapter while reading through the Greek New Testament, since reading reinforces the vocabulary already drilled and improves retention.
- The note explains that the books are ordered from easiest to hardest, a variation on Daniel Wallace's reading order, and links to his article.

## 1.3.0

Changes the Limit advice in the Quickstart.

### Changes

- Quickstart step 3 now tells readers to review the Limit and change it as desired, instead of telling them to set it to 9999. It still mentions that Anki's default of 100 cards would cut the deck short.

## 1.2.0

Changes the colour scheme.

### Changes

- The site now has a white background with a pastel blue scheme: pale blue panels, table headers and code boxes, blue links and buttons, and a pastel highlight on the active tab. Rows in the Filtered decks tables get a faint tint when you hover over them.
- The tag breakdown examples in the Tag guide use blue, teal and violet.
- All text and background pairs meet the WCAG AA contrast ratio of 4.5:1.
- Dark mode is removed. The page is always light, even when the visitor's device is set to dark.

## 1.1.1

Reorders the tabs.

### Changes

- The tabs now run **Quickstart**, **Filtered decks**, **Tag guide**. The page still opens on the Quickstart.
- The sections in the page follow the same order, so the content reads the same way if JavaScript is off.
- Links are unchanged: `#quickstart`, `#deck-names` and `#guide` still open their tabs, and section links such as `#frequency` still open the Tag guide.
- `README.md` lists the tabs in the new order.

## 1.1.0

Adds a Quickstart tab to the tag guide.

### Quickstart tab

- A new first tab, **Quickstart**, takes a new user from the deck to a working filtered deck in five steps: get the deck from AnkiWeb, pick a row on the Filtered decks tab, create the filtered deck in Anki (Tools → Create Filtered Deck…, paste the Name and Search, set the Limit to 9999, Build), study, then empty it and move on.
- Three copy-ready Name and Search pairs to start with: the most common words (`NT Greek: Instances 50+`), John 1 (`NT Greek 04: John::John 01`) and 1 John 1 (`NT Greek 01: 1 John::1 John 1`). They use the same searches as the Filtered decks tab, with a Copy button on every cell.
- Explains the two things that most often surprise people: a filtered deck can build small or even empty, because each search takes only new, due and learning cards, and a card can sit in only one filtered deck at a time.
- Links on to the Filtered decks tab and the Tag guide, and the Filtered decks tab now links back to the Quickstart.

### Changes

- The site now opens on the Quickstart tab instead of the Tag guide. Existing links still work: `#deck-names` opens the Filtered decks tab, and section links such as `#frequency` open the Tag guide. `#quickstart` opens the Quickstart tab.
- The tab script now handles three panels instead of two.

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
