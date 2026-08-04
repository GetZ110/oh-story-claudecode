# Genre Prose Card Index

> This file is only the **index and recall rules**; each genre's prose card lives in the same directory under `genre-prose-cards/`.

---

## Usage principles

Prose writing uses the three-piece set: **generic prose requirements + single-genre prose card + this book's style**.

- Generic prose requirements are maintained once: strictly consume the chapter outline, write per plot-point budgets, advance slowly, no early later-plot writing, and after writing run word-count, hook, banned-word, and degeneration validation.
- The genre card governs the genre layer's stable core: worldview/life logic, reader expectations, core payoff/emotion, common scenes, common hooks, and drift bans.
- This book's style governs sentence length, punctuation, subtext, anchor excerpts, and tone; it does not override the genre card or `plot/emotional-beats.md` / `plot/pacing.md`.
- On conflict between the three: chapter outline & continuity > emotion/rhythm authoritative recall > genre card > this book's style > generic techniques.

## Recall rules

1. First read `setting/genre-positioning.md`; confirm the primary genre, target platform, audience channel, primary benchmark book, and core hook.
2. First match the genre against this index, then read only that one card `genre-prose-cards/{genre}.md` in the same directory; never load the whole card set into the prompt.
3. Cross-genre: read 1 full card of the primary genre; for the secondary genre, read 1 card and extract only 1-2 items of "common scenes / drift bans"; never run two rhythm sets in parallel.
4. High-confidence cards may be used directly for the Phase 2 `setting/genre-prose-card.md`; medium-confidence cards need cross-checking against this book's benchmark/outlines; low-confidence cards are fallback only — must be flagged low-confidence and supplemented with a same-genre benchmark first.
5. Per chapter, the `genre_prose_card` passed to narrative-writer keeps only this-chapter-relevant items, recommended 120-300 words: genre limits, core logic, reader expectations, core payoff/emotion, prose landing points, early/mid/late play, scene granularity, drift bans, this-chapter tradeoffs, card confidence.
6. **The genre card only calibrates genre flavor inside the writer's head; it never appears in the prose**: prose must not write the card name, genre labels, confidence, item numbers, or "evidence summary" data, and must not write compliance self-assessments like "per the genre card / word count met / zero violations" or writing-process notes — output the story only.

## Genre card writing principles

Every genre card must answer nine things: genre core, main-line goal, conflict engine, payoff positioning, common emotion conversions, scene granularity, prose landing points, early/mid/late play, and drift bans. Follow the "contemporary-romance"-style approach: first give a clear life/relationship goal, then explain how low-intensity conflicts produce real results, then land the opening/conflict/ending on concrete objects and scenes, and finally state which payoffs are small-but-visible changes. Don't force generic methodology onto every genre.

## Don't turn these into hard rules

Local long-form samples do not support fixed 50-60 character line widths, fixed 50%-60% dialogue shares, global function-word replacements, random inversions, or mechanical template stacks. Genre cards only give "the scenes and emotion landings this genre uses more often"; concrete paragraphs still follow the chapter outline, the style, and the current scene.

---

## High-confidence genre cards

| Card | Common aliases / match words | Confidence |
|---|---|---|
| [contemporary-romance](genre-prose-cards/contemporary-romance.md) | billionaire-romance / marriage-first / second-chance-romance / sports-romance | high |
| [progression-fantasy](genre-prose-cards/progression-fantasy.md) | power-fantasy / cultivation-adjacent / wuxia-adjacent | high |
| [litrpg](genre-prose-cards/litrpg.md) | system-apocalypse / game-lit / rpg-isekai | medium |
| [cultivation](genre-prose-cards/cultivation.md) | xianxia / daoist-fantasy / eastern-fantasy | high |
| [urban-fantasy](genre-prose-cards/urban-fantasy.md) | modern-fantasy / urban-supernatural / hidden-world | medium |
| [epic-fantasy](genre-prose-cards/epic-fantasy.md) | high-fantasy / secondary-world / quest-fantasy | medium |
| [paranormal-romance](genre-prose-cards/paranormal-romance.md) | shifter-romance / vampire-romance / witch-romance / monster-romance | medium |
| [dark-romance](genre-prose-cards/dark-romance.md) | possessive-romance / forbidden-love / morally-gray-lead | medium |
| [mafia-romance](genre-prose-cards/mafia-romance.md) | organized-crime-romance / arranged-marriage-crime | medium |
| [thriller](genre-prose-cards/thriller.md) | suspense / crime-thriller / psychological-thriller / espionage | high |
| [horror](genre-prose-cards/horror.md) | cosmic-horror / weird-fiction / folk-horror / survival-horror | medium |
| [cozy-mystery](genre-prose-cards/cozy-mystery.md) | small-town-mystery / amateur-sleuth / culinary-mystery | medium |

## Low-confidence cards

No low-confidence single cards currently exist. When adding a new low-confidence card, treat it as a first-draft direction only; before writing, must first read the same-genre benchmark book, the user's setting, and the latest scan results.

---

## Low-confidence card usage notes

A low-confidence card cannot decide the prose alone. Before writing, supplement three things:

1. The same-genre benchmark book's `plot/emotional-beats.md` and `plot/pacing.md`.
2. `setting/style.md` or the benchmark `style.md`, confirming sentence length, voice, and paragraph rhythm.
3. This chapter's outline: target emotion, appearance order, info gaps, and chapter-end hook.

If two of the three are missing, only generate a temporary `genre_prose_card` flagged "low-confidence" — never let the genre card override the chapter outline.
