# Structure Migration Mapping Rules (Long-Form)

The detailed mapping rules and templates for Phase 3-L long-form structure migration: converting `teardown-lib/{Book Title}/`'s analysis results into the `{Book Title}/` long-form project structure.

> Short-form migration rules: `structure-mapping-short.md`.

---

## Mapping overview

| Teardown-library path | Project path | Conversion |
|------------------------|--------------|------------|
| `source/` | `prose/chapter_NNN_Title.md` | split by chapter and standardize names |
| `quick-preview.md` | — | reference for volume-split candidates and plot direction; not migrated directly |
| `characters/{Character Name}.md` | `setting/characters/{Character Name}.md` | add character-template fields |
| `characters/relationships.md` | `setting/relationships.md` | format conversion |
| `setting/worldview/*.md` | `setting/worldview/*.md` | sync as-is by topic |
| `setting/factions/*.md` | `setting/factions/*.md` | sync as-is by faction |
| `plot/storylines.md` | `outline/outline.md` | back-derive the volume-level structure (volume split needs user confirmation, below) |
| `plot/{title}.md` | `outline/volume_outline_{X}.md` | aggregate into volume outlines |
| `plot/pacing.md` | `benchmark/{Book Title}/plot/pacing.md` | direct sync as the writing-side authoritative rhythm index (key-info progression / emotional touchpoints / burst rhythm) |
| `plot/emotional-beats.md` | `benchmark/{Book Title}/plot/emotional-beats.md` | direct sync as the writing-side authoritative module index (reader needs / emotional engine / reproducible modules) |
| `chapters/chapter_N_summary.md` | `outline/outline_chapter_NNN.md` | back-derive chapter outlines |
| — | `setting/genre-positioning.md` | generated from the teardown report |
| — | `tracking/foreshadowing.md` | extracted from plot points (generated before character state) |
| — | `tracking/timeline.md` | extracted from time markers (generated before character state) |
| — | `tracking/character-state.md` | back-derived per `character-state-reverse.md` (generation order: [Step 7: generate the tracking files](../SKILL.md#step-7-generate-the-tracking-files)) |
| `plot/loose-threads.md` | appendix of `outline/outline.md` or the matching volume outline | merge into the relevant volume's outline |
| — | `tracking/context.md` | generate the progress summary (generated last; depends on character state) |

---

## Prose standardization rules

### Naming format

Source filename → standard format: `chapter_{zero-padded 3 digits}_{Title}.md`

| Source filename | Standardized |
|-----------------|--------------|
| Chapter 1_Entering the Jianghu.txt | chapter_001_Entering-the-Jianghu.md |
| Chapter 1.md | chapter_001_Untitled.md |
| chapter01.md | chapter_001_Untitled.md |
| 01_Awakening.md | chapter_001_Awakening.md |

### Chapter-separator recognition

When the source is one big file, split by the following separators (same recognition table as `length-routing.md` priority 2):

| Separator pattern | Example |
|-------------------|---------|
| `Chapter X` / `Chapter X ` / `Chapter X:` / `Chapter X XXX` | Chapter 1 Entering the Jianghu |
| Plain numbered + title | 1. Awakening |

### Content handling

- Keep the original content unchanged; no modifications
- Encode uniformly as UTF-8
- Strip irrelevant header/footer info (ads, disclaimers, etc.)

---

## Character-file migration template

```markdown
---
name: {Character Name}
---

# {Character Name}

## Basic info
- Identity: {extracted from the teardown-library character file}
- Core traits: {}
- Current ability: {}
- Core motive: {}
- Weakness/flaw: {}

## External presentation
{identity/speech-and-deeds/appearance}

## Inner analysis
{personality/goals/secrets}

## Appearance log
| Chapter | Key event | State change |
|---------|-----------|--------------|
| Chapter {N} | {event} | {change} |

## Aliases
{list aliases if any}
```

---

## Relationship-file conversion rules

Teardown-library format (relationships.md) → project format (setting/relationships.md):

```
Teardown-library format:
A<->B: relationship type | emotion | description (50-200 words) | evolution trajectory

Project format:
| Character A | Character B | Relationship type | Emotional valence | Current state | Starting chapter | Change nodes |
```

Conversion rules:
- Relationship-type mapping: family → kinship, lovers → romance, friends → friendship, etc.
- Emotional valence reused directly: positive/negative/neutral/complex
- The evolution trajectory goes into the "change nodes" column

### Target-format template (setting/relationships.md)

```markdown
# Character Relationship Map

## Relationship overview

| Character A | Character B | Relationship type{kinship/romance/friendship/emnity/mentor-student/master-servant/interest} | Emotional valence{positive/negative/neutral/complex} | Current state | Starting chapter | Change nodes |
|-------------|-------------|--------------------------------------------------------------------------------------------|---------------------------------------------------|---------------|------------------|--------------|
| {name} | {name} | {type} | {valence} | {description} | Chapter {N} | {event} |

## Relationship evolution

{Character A}<->{Character B}:
- Start: {initial relationship}
- Turns: {chapter · event · change}
- Current: {present state}

## Core conflict relationships

{list the 2-3 core opposing/cooperative pairs driving the plot}
```

---

## Worldview sync rules

The current `story-long-analyze` already outputs topic-split directories; the import phase only does pass-through — no parsing or splitting of flat `worldview.md` files.

| Source path | Target path | Current contract |
|-------------|-------------|------------------|
| `teardown-lib/{Book Title}/setting/worldview/*.md` | `{project}/setting/worldview/*.md` | sync as-is; `background.md` must exist |
| `teardown-lib/{Book Title}/setting/factions/*.md` | `{project}/setting/factions/*.md` | sync the already-standalone faction files as-is |

When `power-system.md`, `geography.md`, or small-faction material is under 200 words, the upstream merges it into `background.md`, so those standalone files may be omitted. If `background.md` is missing, or the current content implies an independent power system without the corresponding file, stop the import and tell the user to re-run `story-long-analyze` Stage 4.

---

## Outline back-derivation rules

### outline.md (volume-level structure) and the volume-split rules

Back-derived from `plot/storylines.md`, `plot/*.md`, and `quick-preview.md`; **the volume split must follow these decision rules**:

**Case A: the source has explicit volume boundaries**

The source contains explicit volume-level markers (e.g., "Volume 1 XXX", "Book One" chapter-level titles) → split by the source's own volume boundaries directly; no asking the user.

**Case B: the source has no explicit volume boundaries**

No mechanical volume-splitting. Execution flow:

1. Detect candidate volume boundaries from storylines/scene switches/large time jumps (see the "candidate-boundary detection reference" below);
2. Present the candidate split to the user, format example:

   ```
   Candidate volume split (for reference, not final):
   - Candidate volume 1: Chapters 1-18 (worldview establishment + initial growth, setting: the academy outside town)
   - Candidate volume 2: Chapters 19-45 (main-line conflict erupts, setting: the council chamber in the capital)
   - Candidate volume 3: Chapters 46-XX (final showdown, setting switch: the ancient ruins)
   The above is the auto-detection result from storylines/scene switches; confirm or adjust.
   ```

3. **Wait for user confirmation of the volume split** before generating the volume-level structure in `outline/outline.md` and the matching `outline/volume_outline_{X}.md`;
4. Before confirmation, `outline/outline.md` only records the candidates; no finalized volume outlines.

> **Not allowed**: mechanically splitting a source without volume boundaries at a default "20-40 chapters per volume". Candidates are only reference; the user decides.

### Candidate-boundary detection reference

| Signal type | Example | Volume-boundary likelihood |
|-------------|---------|---------------------------|
| Consecutive chapters + one storyline | same city/same faction viewpoint | same volume |
| Major scene switch (new map/new faction) | from the town outskirts into the capital | candidate new-volume start |
| Large time jump (months/years) | "Three years later…" | candidate new-volume start |
| Major phase goal completed + new goal opens | beat the phase boss → a new crisis appears | candidate new-volume start |
| Storyline summary already has phases | the internal phases in `plot/storylines.md` | reference first |

### Volume-outline back-derivation

#### Target-format template (outline/volume_outline_{X}.md)

The volume outline is the expansion of the master outline — the master decides direction, the volume outline decides rhythm. It contains all the volume's creation planning.

```markdown
# {volume name} Volume Outline

## Core info
- Chapter range: Chapters {X}-{Y}
- Target words: {W}K words
- Volume positioning: {setup/development/climax/turn/wrap-up}

## Core contradiction
{one sentence: what problem this volume solves or what goal it reaches}

## Emotional arc
- Template: {V-shape/inverted-V/W-shape/progressive/delayed-gratification/sharp-turn}
- Rationale: {by genre and this volume's positioning}

| Chapter | Emotional tone{tense/light/sad/hot/warm/shock} | Intensity{1-10} | Triggering event |
|---------|--------------------------------------------------|-----------------|------------------|
| Chapter {N} | {tone} | {N} | {event} |

## Volume contract & endgame reserve (back-derived)
- Volume contract: {the reader expectation and protagonist highlight generalized from this volume's plots; insufficient evidence → `[TBD]`}
- Primary pushed line this volume: {the line carrying this volume's biggest climax, generalized from plot points}
- Volume gains: {the other lines cashed in along the way; insufficient evidence → `[TBD]`}
- Endgame milestones unlocked this volume: `[TBD]`
- Endgame trump cards untouched this volume: `[TBD]`
- Contract risk: {safe / needs reinforcement / broken; unknown → `[TBD]`}

## Story units (back-derived)
| Unit ID | Chapter range | Unit beats (setup→release→reaction layer→handoff) | Primary line/gains | Next-unit causal hook |
|---------|---------------|----------------------------------------------------|--------------------|-----------------------|
| L{volume}-1 | {Chapters X-Y} | {generalized from payoff/plot-point distribution} | {line} | {method} |

(Import back-derivation only fills evidence-based fields; unknown → `[TBD]`, never invented; later outline completion/revision upgrades to the full "story-unit card" field template in the story-long-write skill.)

## Character arcs
| Character | Volume start | Volume end | Key turn |
|-----------|--------------|------------|----------|
| {name} | {state} | {state} | {event} |

## Volume reversals (if any)
| Type{identity/motive/faction/info/fate} | Characters involved | Misdirection path | Reveal chapter | Scope of impact |
|------|--------------------|-------------------|-----------------|------------------|
| {type} | {name} | {how the reader was misled} | Chapter {N} | {which lines it affects} |

## Volume foreshadowing
| Foreshadowing | Planted in | Expected recovery | Type{short/medium/long} |
|---------------|------------|-------------------|--------------------------|
```

#### Field mapping

From the plot files, extract per volume:
- Core contradiction → the core-contradiction field
- Plot-point distribution → emotional arc + story units (back-derived)
- Character appearances → character arcs
- Setup-type plot points → foreshadowing

### Chapter-outline back-derivation

From each chapter summary (`chapters/chapter_N_summary.md`):

| Summary field | Chapter-outline field | Conversion |
|---------------|-----------------------|------------|
| Key events | Core event | reuse directly |
| Chapter word count | Target words | counted from the source |
| Chapter tone / emotion curve | Target emotion | extracted from the summary; missing → `[TBD]` |
| First plot point | Opening hook | evidence only; the design goal marked `[TBD]` |
| Payoff-type plot points | Payoff | inferred from plot-point types; none → "no visible payoff / [TBD]" |
| Plot points' setup-development-turn-climax | Content summary (Cause/Development/Turn/Climax/Ending) | generalized in plot-point order; insufficient evidence → `[TBD]` |
| Main/sub/event/task thread clues | Plot arrangement (Main line / Sub-line / Event & task line / Relationship line / Logic line) | back-derived from the story-unit index and summary; evidence-free sub-lines/relationship lines → "none" or `[TBD]`, never invented |
| Appearing characters / key objects | Characters and appearance order | listed in summary appearance order; relationship changes only with evidence ("before → after"); missing → `[TBD]` |
| All plot points | Plot detail / plot-point sequence | "who did what + function tag" per point; unclear function → `[TBD]` |
| Win/loss, reversal, gains/losses | Action cost (optional)/benefit attribution | only with clear evidence; the action cost may be absent — don't invent; else `[TBD]` |
| Last plot point / suspense-type plot points | Ending and hook | the closing state can be generalized; the chapter-end hook design goal marked `[TBD]` |

---

## Character-state back-derivation

Back-derived per character-state-reverse.md; see that file.

---

## Foreshadowing extraction rules

Identify candidate foreshadowing from plot points:

### Recognition patterns

| Plot-point type | Foreshadowing likelihood | Extraction method |
|-----------------|--------------------------|-------------------|
| Setup | high | extract directly as foreshadowing |
| Info reveal (partial) | medium | check for later echoes |
| Object first appearance | medium | check for later use |
| Character secret | high | mark as character foreshadowing |
| Unresolved suspense | high | extracted from chapter-end markers |

### State inference

- A setup point followed by a "reveal" or "resolution" plot point in later chapters → mark "recovered"
- A setup point with no later echo → mark "planted"
- Setup points in the final chapters of a partial book → mark "planted", note "near the cutoff"

---

## Timeline extraction rules

### Time-marker recognition

Extracted from plot points and time markers:

| Marker pattern | Example | Extraction method |
|----------------|---------|-------------------|
| Explicit date | "Spring of year three of the Tianyuan era" | record directly |
| Relative time | "three days later", "half a month later" | calculate the absolute time |
| Event interval | "the next day", "the following morning" | continuous markers |
| Season marker | "winter set in", "when spring bloomed" | season inference |

### Sorting rules

Order by chapter; within a chapter, by plot-point index. Missing time markers are labeled `[inferred]`.

---

## Genre-positioning generation

Extract core findings from the teardown report and generate `setting/genre-positioning.md`.

### Target-format template (setting/genre-positioning.md)

```markdown
# Genre Positioning

## Basic info
- Genre: {fantasy/urban/system/...}
- Target platform: {the platform collected from the user in Phase 1; if none, extract from the teardown report, and if still none fill [TBD]. story-review picks the platform rubric from this}
- Core hook: {one-sentence selling point}
- Micro-innovation points: {differences from the same-genre pack}

## Core-hook three-way split
- Surface sell: {the attraction readers see at a glance}
- Deep gratification: {the emotional driver of sustained following}
- Long-line hook: {the suspense/goal supporting the whole book}

## Reader needs / emotional engine
> Detailed modules in `benchmark/{Book Title}/plot/emotional-beats.md`; this section only keeps the quick positioning for opening/continuing.

| Reader need | Emotional gap | How satisfied | Reproducible module | Source |
|-------------|---------------|---------------|---------------------|--------|
| {safety/superiority/anticipation/emotional compensation/cognitive reversal/companionship} | {the lack} | {how it's satisfied} | {EM-001 etc.} | `benchmark/{Book Title}/plot/emotional-beats.md` |

## Rhythm and trigger reference
> Detailed rhythm in `benchmark/{Book Title}/plot/pacing.md`; that file is the rhythm authority when writing.

| Rhythm module | Key-info progression | Emotional touchpoints | Burst rhythm | Source |
|---------------|----------------------|------------------------|--------------|--------|
| {RH/TR IDs} | {how the info is expanded} | {what feeling is triggered} | {setup→eruption→cool-down} | `benchmark/{Book Title}/plot/pacing.md` |

## Benchmark-book list (canonical registry)
primary benchmark book: {Book Title}  # at most 1; the daily update only reads this one's style.md and source anchors
benchmark book list:
  - title: {Book Title A}
    reference strength: primary  # primary / secondary / reference
    genre: {fantasy/urban/system/...}
    relevance: same-genre
    use: style + core structure
  - title: {Book Title B}
    reference strength: secondary
    genre: {genre}
    relevance: same-genre/weakly-related
    use: {supplement settings/outline/modules, not style}
  - title: {Book Title C}
    reference strength: reference
    genre: {genre}
    relevance: same-genre/weakly-related
    use: {recall summaries by budget only}

## Benchmark analysis (derived summary)
> Full benchmark data in the `benchmark/` directory; the registry above is the authoritative list. This table is only a quick overview; it can't replace `primary benchmark book` + `benchmark book list`.

| Benchmark book | Similarities | Differences | Borrowable |
|----------------|--------------|-------------|------------|
| {title} | {points} | {points} | {points} |

## Genre framework
- Eight-node position: {which node the current book is at}
- Key turning nodes: {list}
```

### Field mapping

- Genre, core hook, micro-innovation points → extracted from the basic-info and core-findings sections of `teardown-report.md`
- Core-hook three-way split → extracted from the surface-attraction, payoff-design, and long-line-suspense sections of `teardown-report.md`
- Reader needs / emotional engine → extracted from `plot/emotional-beats.md`; when missing, stop the import and give the fix action to re-run Stage 3+
- Rhythm and trigger reference → extracted from `plot/pacing.md`; when missing, stop the import — never substitute `teardown-report.md`, chapter summaries, or `plot/storylines.md`
- Benchmark-book list → when importing the current book, at least register itself as `primary`; when the user provides multiple books, all enter the `benchmark book list`; secondary/reference benchmarks are unlimited
- Benchmark analysis (derived summary) and genre framework → may be summarized by the import scenario; must not replace the canonical registry

---

## Benchmark reference-view sync rules

Long-form migration must sync the teardown library's key analysis assets to the project-side `benchmark/{Book Title}/` so story-long-write reads the project reference view first. Before the project view exists, the import flow may read the canonical source at the root `teardown-lib/{Book Title}/` and sync immediately; this is not a second artifact format.

| Source path | Target path | Sync semantics |
|-------------|-------------|----------------|
| `teardown-lib/{Book Title}/plot/pacing.md` | `{project}/benchmark/{Book Title}/plot/pacing.md` | the required authoritative file for the daily update's `rhythm_reference`; fix if missing |
| `teardown-lib/{Book Title}/plot/emotional-beats.md` | `{project}/benchmark/{Book Title}/plot/emotional-beats.md` | the required authoritative file for the daily update's `selected_emotion_module`; fix if missing |
| `teardown-lib/{Book Title}/plot/*.md` | `{project}/benchmark/{Book Title}/plot/*.md` | plot assets (story units, storylines, loose threads); on conflict with the authoritative rhythm/emotion files, the latter win |
| `teardown-lib/{Book Title}/chapters/*.md` (chapter_N_summary.md + opening chapters chapter_1-3_deep-dive.md) | `{project}/benchmark/{Book Title}/chapters/*.md` | matching-chapter evidence, incl. "key info and expansion techniques" |
| `teardown-lib/{Book Title}/characters/*.md` | `{project}/benchmark/{Book Title}/characters/*.md` | character functional slots, relationships, reaction-layer reference |
| `teardown-lib/{Book Title}/setting/` | `{project}/benchmark/{Book Title}/setting/` | worldview, factions, cheat setting-constraint reference |
| `teardown-lib/{Book Title}/teardown-report.md` | `{project}/benchmark/{Book Title}/teardown-report.md` | human-readable summary projection |
| `teardown-lib/{Book Title}/style.md` | `{project}/benchmark/{Book Title}/style.md` | must-read for daily-update style recall |

Conflict rule: `benchmark/{Book Title}/plot/emotional-beats.md` and `benchmark/{Book Title}/plot/pacing.md` are the writing-side emotion/rhythm authorities; `teardown-report.md` and `plot/storylines.md` are only summary projections. If a summary conflicts, keep the conflict note and follow the authoritative files; when either authoritative file is missing, re-run or fix the teardown artifacts first.

---

## Quality-check checklist

Run after Phase 3-L migration completes:

- [ ] Prose file count = source chapter count
- [ ] Major characters (protagonist + core supporting) files created
- [ ] relationships.md non-empty
- [ ] outline.md has volume-level structure
- [ ] Every chapter outline generated
- [ ] tracking/foreshadowing.md has content (when setup-type plot points exist)
- [ ] tracking/timeline.md has content (when time markers exist)
- [ ] tracking/character-state.md generated and aligned with the `character-state-reverse.md` standard template
- [ ] tracking/context.md progress summary filled
- [ ] Loose threads merged into the relevant volume outlines or the master-outline appendix
- [ ] Volume split user-confirmed (mandatory when the source has no explicit volume boundaries)
- [ ] `plot/pacing.md` synced to `benchmark/{Book Title}/plot/pacing.md`; when missing, migration fails with a fix action
- [ ] `plot/emotional-beats.md` synced to `benchmark/{Book Title}/plot/emotional-beats.md`; when missing, migration fails with a fix action
