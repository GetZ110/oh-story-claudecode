# Style Profile Protocol

> **When to load**: before story-long-analyze Stage 6 runs. Downstream writing skills read `style.md` directly; they don't load this protocol.

## Artifact definition

`teardown-lib/{Book Title}/style.md` is a whole-book writing-technique view that aggregates:

- Sentence length / punctuation / paragraph rhythm (measured from source samples)
- Dialogue subtext patterns + character voice differentiation
- In-chapter and cross-chapter emotional alternation cycles (how each chapter's tone changes)
- The "writing techniques" and "borrowable tropes" already in `teardown-report.md`
- Tiered imitation advice (base tier / advanced tier / adaptation tier; learn the technique, don't copy the scenes)
- 4-6 source anchor excerpts of 300-500 words (example passages)

## File paths

- **Write**: `teardown-lib/{Book Title}/style.md` (analyze's exclusive output)
- **Read**: story-import syncs it to `{project}/benchmark/{Book Title}/style.md`; story-long-write reads the project benchmark view (falling back to the teardown library)

## Word budget

- **Hard cap ~4000 words**
- Description sections (overall voice + dialogue technique + emotional alternation pattern + borrowable techniques + tiered imitation advice) ≤ 1800 words
- Source anchors 4-6 × 300-500 words ≈ 1600-2400 words
- Do-not-imitate + generation record ≤ 100 words

## Template

```markdown
# {Book Title} Style Profile

## Generation record
- Materials consulted: teardown-report.md, opening-hook-chapters deep dives, chapter summaries
- Sampled chapters: {K1}/{K10}/{K20} (about 1000 words each)
- Generated: {date}
- Benchmark path: teardown-lib/{Book Title}/
- Style usable: yes  # if the source is missing or anchors are insufficient, write "no: reason"

## Overall voice
- Sentence-length distribution: {measured deterministically by the cross-platform Python one-liner in `style-profile-generator.md` Step 4 on the 3-chapter concatenated sample — short(<15 words) X%, mid(15-30) Y%, long(>30) Z%, average sentence length N words, punctuation density M%. One sentence summarizing the feel. `confidence: high` (computed by script, not a sampling estimate).}
  - confidence: high | med | low
- Punctuation habits: {high-frequency uses of dashes/ellipses/periods/exclamation marks/semicolons. Include 2-3 short source examples.}
  - confidence: high | med | low
- Paragraph rhythm: {average paragraph length, one-action-per-paragraph vs stacked actions, line-break habits.}
  - confidence: high | med | low

## Dialogue technique
- Subtext patterns: {2-3 typical subtext techniques (answering a different question / tone contrast / withholding information, etc.), each with 1 source example.}
  - confidence: high | med | low
- Dialogue tag habits: {speech-verb variety, how often action replaces speech tags, the mix ratio of dialogue to action.}
- Character voice differentiation: {catchphrases/sentence-pattern differences between the protagonist and 1-2 core supporting characters, with source sample lines.}

## Emotional alternation pattern
- In-chapter tone switching: {statistics of the in-chapter plot-point tone sequence — whether typical chapters switch between tense↔light or hot↔warm, switching frequency (N times per chapter).}
  - confidence: high | med | low
- Cross-chapter tone cycle: {the first 20 chapters' "chapter tone" sequence, recognizing cycles like "3 chapters of misery, 1 chapter of payoff".}
- Comedy↔heavy-beat transition technique: {what technique the benchmark book uses for sharp light→sad transitions, with 1-2 source anchors.}

## Borrowable techniques (quoted from teardown-report.md)
- Top 5 writing techniques:
  1. {technique}: {one-line usage note}
  2. ...
- Top 3 borrowable tropes:
  1. {trope}: {applicable scenario}
  2. ...

## Tiered imitation advice
- Base tier (must-learn): {the 3-5 most transferable items among vocabulary preferences, sentence rhythm, dialogue tags, and description focus; learn expression habits only, don't copy original sentences}
- Advanced tier (structure): {the 3-5 most reusable items among rhythm progression, foreshadowing plant-and-payoff, POV switches, scene transitions; replace characters/scenes/props before using}
- Adaptation tier (make it this book): {which techniques fit the current project and which would misalign its characters/genre; explicitly state not to carry over proper nouns, signature lines, unique scenes, or event order}

## Source anchor excerpts

> Each excerpt is 300-500 words, **used as example passages for the narrative-writer**. Cut from `source/source.txt` by chapter separator. Imitate the technique, don't copy the wording.

### Excerpt A — Tone: tense
**Source**: Chapter {K}, paragraph {N} (lines {L1}-{L2})
**Demonstrates**: {sentence-length rhythm here (how long and short distribute) / punctuation placement / one-stroke-two-uses, etc.}

```
{300-500 words of source}
```

### Excerpt B — Tone: sad/oppressive
**Source**: Chapter {K}, paragraph {N} (lines {L1}-{L2})
**Demonstrates**: {dialogue-subtext technique}

```
{300-500 words of source}
```

### Excerpt C — Tone: light/funny
**Source**: Chapter {K}, paragraph {N} (lines {L1}-{L2})
**Demonstrates**: {sentence rhythm / character voice differentiation}

```
{300-500 words of source}
```

### Excerpt D — Tone: hot/payoff
**Source**: Chapter {K}, paragraph {N} (lines {L1}-{L2})
**Demonstrates**: {payoff setup/release ratio / fight-scene sentence length}

```
{300-500 words of source}
```

> Prioritize covering tones the project may use and that have enough samples in the benchmark book: tense, sad/oppressive, light/warm, hot. Pick 4-6 excerpts by the actual distribution in the teardown; whichever tone is short on samples, write "this tone has too few samples in this book, skipping" — don't fabricate.

## Do not imitate
- {the benchmark book's clear weaknesses or techniques that don't fit the current project. Optional section; may be empty.}
```

## confidence field semantics

| Value | Trigger condition | Downstream handling |
|---|---|---|
| `high` | Data directly readable (e.g., tone sequence grepped from summaries) | narrative-writer adopts it first, overriding default Gates |
| `med` | Generalized from samples with adequate sample size (e.g., reading chapter-tone trends, organizing dialogue subtext) | narrative-writer consults it, negotiates with default Gates |
| `low` | Insufficient samples / source missing | narrative-writer falls back to default Gates (doesn't force adoption) |

## Usability semantics

- `Style usable: yes` → the style can be used for writing; narrative-writer uses it by confidence tier.
- `Style usable: no: {reason}` → the style is too low quality (e.g., source missing, anchors all placeholders). story-explorer returns `gaps.profile_degenerate: true` when reading it; narrative-writer skips the style and writes by default Gates to avoid being misled.

## Override and do-not-imitate principles

- **Override**: the style outranks Gate D (rhythm adjustment), Gate B (sentence-pattern de-templating), and default punctuation habits — those Gates are the de-AI-flavor **defaults**; when the style gives more specific instructions, the style wins.
- **Cannot override (hard constraints)**: banned-words / Gate F no-end-of-chapter-elevation / no universal or stacked metaphors / no chapter-end previews / word-count floors — these hard constraints always win, even if the style demonstrates the opposite.

The precise resolution table lives in the "called-protocol" section of `.claude/agents/narrative-writer.md`.
