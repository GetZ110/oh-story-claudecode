# Style-Profile Generation SOP

> **When to load**: when story-long-analyze Stage 6 runs. Prerequisites: Stage 0-5 done, with `teardown-report.md` + `chapters/*_summary.md` + `chapters/chapter_1-3_deep-dive.md` + `source/source.txt` (or `.md`) all present.
>
> **Output**: `teardown-lib/{Book Title}/style.md` (template in [style-profile-protocol.md](style-profile-protocol.md)).

## The 6-step flow

### Step 1: Read the teardown report's core fields

Read `teardown-lib/{Book Title}/teardown-report.md` and extract:

- **"Writing techniques" section** → fills "Top 5 writing techniques" under "Borrowable techniques" in the style file
- **"Borrowable tropes" section** → fills "Top 3 borrowable tropes" under "Borrowable techniques"
- **"Whole-book emotional rhythm overview / Foreshadowing and conflict network" section** → fills the advanced and adaptation tiers of "Tiered imitation advice"; abstract rhythm and technique only, don't carry over specific scenes
- **Basic info** (title, genre, total chapters) → fills the style title and "Generation record"
- The "Generation record" writes only what the author can understand: which materials were consulted, which chapters were sampled, generation time, whether the style is usable; don't write file timestamps or internal degradation markers — that's implementation jargon

### Step 2: Read the opening-hook-chapters deep dives

Read `chapters/chapter_1_deep-dive.md`, `chapter_2_deep-dive.md`, `chapter_3_deep-dive.md` and extract:

- **Opening hook type + technique**
- **Reaction-layer table** (dialogue subtext samples)
- **Payoff setup/release ratio** (emotional alternation rhythm samples)
- **Borrowable elements** (dedup against Step 1, feed "Top 5 writing techniques")

### Step 3: Extract the per-chapter tone/theme-tag sequence

Read all `chapters/*_summary.md` with Grep:

```bash
grep -hE 'Tone:(tense|light|sad|hot|sweet|warm|horror|oppressive|other)' chapters/*_summary.md
```

**Key format notes**: in `chapters/*_summary.md`, the actual format is `Theme tags{...} | Tone: {Y}` on its own line right after each plot point (10-40 lines per chapter). `Tone` uses an ASCII colon, `Theme tags` takes **no colon**, and neither is **at the start of the line**. The grep pattern must not be anchored like `^Tone:`.

**Chapter-tone aggregation rule** (one chapter tone per chapter, written into the style file's "emotional alternation pattern"):

- Take the mode of the "Tone" field across all plot points in the chapter
- On a tie (e.g., 5 tense vs 5 hot), take the tone that appears **earliest** in the chapter (by line number in `_summary.md`)
- Output format: `Chapter {N}: {chapter tone}`, joined into a whole-book sequence

**In-chapter plot-point tone sequence** (for the "in-chapter tone switching" analysis):

- No aggregation; keep the plot points' tones in their order of appearance in `_summary.md`
- Used to compute switching frequency: number of adjacent plot points with different tones / total plot points

### Step 4: Source sampling

Under `source/` there is **exactly one whole-book file** `source.txt` (or `.md`), **not split by chapter**. Sampling must first locate the chapter separators.

**Correct Grep pattern**:

```bash
grep -nE '^(Chapter|CHAPTER|chapter)[ _-]*[0-9]+' source/source.txt
```

The pattern covers `Chapter 1` / `Chapter 01` / `CHAPTER 1` etc. and matches digit-strings of any length (needed for 1000+ chapter books); it's anchored at the start of the line to avoid matching in-body mentions.

**Relationship to the Stage 0 chapter-boundary substep**: that substep uses the same pattern to produce the authoritative "chapter boundary" table (in `_progress.md`). Stage 6 only reads that table and never slices again; if the table is missing, stop and tell the user to rebuild the Stage 0 progress file.

**If the pattern doesn't match**:

- Read the first 100 lines to see the actual chapter prefix (e.g., `CHAPTER I`, `1.`, `Part One — Chapter 1`), and adjust the regex accordingly
- If chapter separators can't be recognized at all → write `Style usable: no: chapter separators unrecognizable` in the "Generation record", skip Step 4, but Steps 1-3 can still proceed

**Sampling slices**:

- After getting the grep `line:Chapter N` list, pick chapter 1, chapter 10, chapter 20 (if total chapters <20, pick by 1/3, 2/3, tail ratios)
- For each chapter, use `Read offset={chapter start line} limit=50` to cut out roughly 1000 words
- Concatenate the 3 slices into `.story-style-sample.txt` at the project root (append with `>>`, then remove it after Stage 6)

**Deterministic sentence-length/punctuation stats** (replacing subjective eyeballing):

Stage 6 runs on the **main thread**, so the shell is available. Feed the assembled `.story-style-sample.txt` to the script below (heredoc as the Python source; the script opens the sample file itself, to avoid stdin-heredoc vs `< file` double-redirection conflicts). Probe for a working interpreter first — **don't just use `python3`**: on Windows it may trigger the Microsoft Store stub and exit 49:

```bash
for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done
"$PYBIN" <<'PYEOF'
import re
with open('.story-style-sample.txt', 'r', encoding='utf-8') as f:
    text = f.read()
sents = [s for s in re.split(r'[.!?]+', text) if s.strip()]
total = max(len(sents), 1)
short = sum(1 for s in sents if len(s) < 15)
mid   = sum(1 for s in sents if 15 <= len(s) <= 30)
lng   = sum(1 for s in sents if len(s) > 30)
chars = max(sum(1 for c in text if not c.isspace()), 1)
puncts = sum(1 for c in text if c in '.,!?;:…—""\'\'')
avg = sum(len(s) for s in sents) // total
print(f'sentences={total}; short_lt15={100*short//total}%; mid_15to30={100*mid//total}%; long_gt30={100*lng//total}%; avg_len={avg}; punct_density={100*puncts//chars}%')
PYEOF
```

Real output looks like `sentences=6; short_lt15=66%; mid_15to30=33%; long_gt30=0%; avg_len=12; punct_density=15%`.

Fill the `short_lt15 / mid_15to30 / long_gt30 / avg_len / punct_density` numbers straight into the `{...X% / Y% / Z%}` placeholders at line 40 of the `style-profile-protocol.md` template — with `confidence: high`, because it's a deterministic measurement, not a sampling estimate.

**Degradation when Bash is unavailable** (only extreme cases like a subagent context; the main thread never hits this):

- Skip this step; write "Bash unavailable, deterministic stats skipped" in the sentence-length section
- `confidence: low`; the narrative-writer falls back to default Gate D (calibrated by sentence-length standards)

### Step 5: Pick source anchor excerpts (4-6)

From the chapter tones produced in Step 3, pick the 4-6 tone classes with the widest coverage that the project may need (priority coverage: tense / sad or oppressive / light or warm / hot). If a tone class appears in fewer than 3 chapters of the benchmark book, don't force it; note the skip in the style file. Pick 1 chapter per tone class as the anchor chapter.

**Selection rules when several chapters share a tone**:

1. **L1 — strongest payoff-type match**: check that chapter's "key events" + tone sequence in `_summary.md`, pick the chapter with the most prominent payoff
2. **L2 — chapter length closest to the daily-update target**: if Step 4 already sliced the chapter boundaries, estimate word count from the source slice; if the source can't be sliced, approximate complexity only from the `_summary.md` plot-point count — never treat the summary file's length as the source chapter's word count
3. **L3 — smallest chapter number**: the earliest chapters = the author's most canonical voice (not yet affected by serialization drift)

Anchor slices:

- Use the chapter line numbers from the Step 4 grep
- From that chapter's source, pick 1 passage of 300-500 words (prefer passages mixing dialogue and action; skip pure monologue / pure setting exposition)
- Cut with `Read offset limit`, preserving original punctuation and paragraph breaks
- **Anchors must be verbatim contiguous slices — no rewriting, abbreviating, skipping passages, or stitching**: the narrative-writer learns from the anchors as few-shot examples, and the labeled line numbers must be traceable back to the source. Before writing to disk, grep 1-2 sentences per excerpt back into `source/source.txt` with `grep -F`; if they don't hit, the excerpt was rewritten or stitched — re-cut a faithful contiguous slice. When intermediate transition passages genuinely must be skipped, label each part with its true line numbers (e.g., "lines 264-267 + lines 269-270") and mark the break explicitly with "(…omitted…)" inside the quote block; never pretend a gap is contiguous by using one line-range

### Step 6: Write to disk

Fill in `teardown-lib/{Book Title}/style.md` per the [style-profile-protocol.md](style-profile-protocol.md) template:

- **The style file must stay in the teardown library** (`teardown-lib/{Book Title}/style.md`), **never** written into `benchmark/` or a writing-project directory — the teardown library is the analyze data source; the writing project's `benchmark/{Book Title}/` view is synced from the teardown library by story-import
- Mark each section `confidence: high/med/low` (internal signal for the writing agent on how strongly to rely on it; regular users can ignore):
  - `high`: data comes directly from teardown artifacts (e.g., "writing techniques" quoted from the teardown report)
  - `med`: generalized from samples with adequate sample size (e.g., tone sequence tallied from ≥10 chapter summaries)
  - `low`: insufficient samples or failed sampling (e.g., missing anchors, Step 4 sentence-length stats skipped because Bash was unavailable)
- The "Tiered imitation advice" must separate into a base tier / advanced tier / adaptation tier: the base tier only covers vocabulary, sentence patterns, description, and dialogue habits; the advanced tier covers rhythm, foreshadowing, POV, and scene transitions; the adaptation tier says what's usable and what would misalign this project; make explicit that proper nouns, signature lines, unique scenes, and event order are not copied
- Word budget: hard cap ~4000 words. **Description sections ≤ 1800 words + anchors 4-6 × 300-500 words**
- If Step 4 failed (chapter separators unrecognizable) → write `Style usable: no: chapter separators unrecognizable` in the "Generation record"; fill all source anchor sections with the placeholder "Source missing, needs manual completion" and set confidence to low

## Failure modes and degradation

| Scenario | Degradation |
|---|---|
| `source/source.txt` missing | Skip Steps 4-5; the style file contains only description sections; "Generation record" writes `Style usable: no: source missing` |
| `chapters/*_summary.md` count <3 | Skip the Step 3 tone sequence; mark the emotional-alternation section `confidence: low` |
| `chapters/chapter_1-3_deep-dive.md` missing | Skip Step 2; fall back to the teardown report for the dialogue-subtext section; `confidence: low` |
| `teardown-report.md` missing | **Stop Stage 6**, tell the user the teardown isn't finished and to run Stage 5 first |

## Relationship with chapter-extractor

**Do not modify chapter-extractor.** The style profile is assembled directly from existing fields (tone / theme tags / borrowable elements).

Sentence length / punctuation density are computed by the cross-platform Python one-liner in Step 4 on the Stage 6 main thread; they don't depend on chapter-extractor.

## Relationship with the writing side

- analyze Stage 6 writes `teardown-lib/{Book Title}/style.md`
- story-import syncs the whole `teardown-lib/{Book Title}/` to the project's `{project}/benchmark/{Book Title}/` and **automatically includes** the style file (treated the same as the teardown report)
- The writing side (story-long-write) daily-update loop reads `{project}/benchmark/{Book Title}/style.md` (per the benchmark-book path lookup rule, falling back to `teardown-lib/{Book Title}/`)

## Regenerating the style alone

When the current teardown artifacts are only missing `style.md`, you can run the 6 steps of this SOP directly (Stage 6 only) without re-running Stage 0-5; prerequisite: `_progress.md` satisfies the current chapter-boundary contract. Trigger: the user directly says "generate the style profile for benchmark book X" or "regenerate style".
