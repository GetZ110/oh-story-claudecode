---
name: story-import
version: 1.0.0
description: "Reverse import of an existing novel. Reverse-parses an already-written novel (partial or complete) into the standard project directory structure, compatible with the story-long-write / story-short-write flows that follow; internally reuses the story-long-analyze / story-short-analyze teardown pipelines, routing automatically by length. Triggers: /story-import, \"import this novel\", \"reverse parse\", \"import\", \"import my book\"."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-import: Reverse Import of an Existing Novel

### Agent bundle preflight

The current deployment contract is `agents_version: 23`. A version mismatch does not block spawning: continue checking the deployed files and emit `Notice: agents bundle version mismatch`. If the deployed version is greater than 23, tell the user to update oh-story-claudecode first. only missing or unavailable custom agents trigger solo/direct fallback.

You are a novel-project reverse engineer. Import routes by length: long-form takes Phase 3-L, short-form takes Phase 3-S.

**The deliverable is a writing project**: rebuild the author's existing book into a **continuable writing project** (project structure + teardown-library analysis assets). `teardown-lib/` is part of the project (feeding the project's `benchmark/`), not a throwaway intermediate; it can't replace the deliverable itself — the deliverable must let the author keep writing directly. Execute with "building the project" as the visible goal; don't treat "the teardown" as the endpoint or as an external label.

For the English tracking layout and transaction schema, load `references/tracking-transaction.md` before creating or validating `tracking/`.

---

> Agent compatibility: when checking whether professional agents are available, look them up in the order `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml`. Codex native subagent calls prefer the same-named `agent_type`; if the current Codex runtime returns `unknown agent_type` or does not expose a custom-agent registry, you must degrade to solo/direct. When `.zcode/` is detected, also go straight to solo/direct, because ZCode 3.3.4 does not execute project custom agents; report `Fallback: project custom agents unavailable -> solo`. The Claude/OpenCode compatibility surface keeps `subagent_type`.

## Core principles

### Principle 1: analyze first, then migrate

First run the complete teardown pipeline on the novel (output to `teardown-lib/`), then migrate the analysis into the project structure. **`teardown-lib/` is part of the writing project** (analysis assets, feeding the project's `benchmark/`) — keep it, don't discard it; it's not a throwaway intermediate.

### Principle 2: reuse, don't reinvent

The deep-analysis phase calls the existing teardown pipelines; it doesn't reinvent them: long-form runs `/story-long-analyze`'s full teardown pipeline, short-form runs `/story-short-analyze`'s teardown pipeline. The teardown methodology and output templates live in the corresponding analyze skill; story-import doesn't execute teardown methodology and doesn't maintain those files.

---

## Phase 1: Confirm the import source

### Step 1: import-and-continue entry order (answer the user's flow question first)

When the user asks flow questions like "for import-and-continue, do I run story-setup or story-import first", "how do I continue an existing novel", "what's the import flow", answer with the conclusion directly, then continue collecting the source:

1. **Recommended order**: run `/story-setup` first (deploys hooks/agents/AGENTS), then start/refresh a session and run `/story-import`, finally continue writing with `/story-long-write daily / write chapter N`.
2. **Or run `/story-import` directly**: this skill detects `.story-deployed` and the professional agents before entering deep analysis; when not deployed, it offers two choices: "run setup first" or "continue importing (serial degradation)".
3. **Already-imported projects**: don't re-run the full import; go into the book directory, confirm `.active-book` / `tracking/context.md` point at the right book, then use `/story-long-write daily` or `/story-long-write write chapter N`.

This conclusion must come before any import-source follow-up questions, so users who only want to confirm the flow aren't asked to paste the source text first.

Ask the user: **"Which book do you want to import? Provide the file path or paste the text directly."**

### Step 2: confirm the intent (writing project vs teardown-library only)

The default goal is a **complete writing project** (continuable). If the intent is unclear — whether they want a continuable project or just a teardown-library analysis — **ask proactively**, don't assume:

> "Do you want this book turned into a continuable writing project (setting/outline/prose/tracking, so you can write chapter N+1), or do you just want a teardown-library analysis?"

- Continuable project → full story-import (Phase 2 teardown + Phase 3 migration).
- Analysis / teardown-library only → use `/story-long-analyze` directly (short-form: `/story-short-analyze`), stop at the teardown library; no Phase 3 migration.

### Step 3: input-method recognition

```
User provides a path?
├─ single file path (.txt/.md)
│   └─ split automatically by chapter separators
├─ directory path
│   └─ sort by filename, merge-process
└─ no path → user pastes text directly?
              ├─ yes → save to a temp file, then process
              └─ no → ask the user to provide the source file
```

### Step 4: basic-info confirmation

1. **Auto-detect**: recognize the title (if present), total chapter count, total word count, and chapter format from the text
2. **User confirmation**:
   - Title: {auto-detected or user input}
   - Genre: {user provided}
   - Target platform: {Royal Road / Webnovel / Wattpad / Amazon Kindle / Other}
   - Market / English variant: {US/en-US | UK/en-GB | global English}
   - Content rating / warnings: {general | teen | mature} / {none or list}
   - Serialization: {serial episode | web chapter | ebook manuscript | one-shot}
   - Completed or not: {yes / no (partial, written through chapter N)}
   - **Length type**: long-form / short-form — auto-detected per [references/length-routing.md](references/length-routing.md) (user explicit declaration > structural signals > word-count fallback), and repeated back to the user for confirmation. The verdict decides whether Phase 3 takes the long-form or short-form path.
   - **Whether the last chapter is complete**: complete / draft (half-written). If it's a draft, tell the user and record "draft through chapter N" in the context, and let the user decide between "continue from the draft chapter" and "finish it before importing". story-import only records the user's decision; it doesn't choose for them.
3. **Output confirmation**: show the user the detected chapter range, word count, length verdict, and last-chapter status; after confirmation, start the analysis

4. **Language-contract confirmation**: load the deployed English book contract, detect the source prose language, and record the language profile before generating analysis or writing-project files. An English source defaults to `en-US` with English records. If the source is not English, preserve that source language only when it is explicitly recorded; never choose the output language from the language of the user's request.

### Step 5: environment detection (pre-flight)

Before entering Phase 2, check whether the project has story-setup infrastructure deployed:

- Check whether `.story-deployed` exists;
- Prefer checking `.claude/agents/` for `chapter-extractor.md`; if absent, check `.opencode/agents/`, then `.codex/agents/` (the parallel agent for Phase 2 long-form deep analysis).
- If `.story-deployed`'s `target_cli` includes `zcode`, missing project agents are the expected state for ZCode 3.3.4: don't prompt to re-deploy; enter the analysis in serial solo/direct and report the fallback.

**When not deployed and not an already-deployed ZCode project**, tell the user:

> "This project doesn't have the writing infrastructure deployed yet. I recommend running `/story-setup` first and coming back to import — otherwise the deep-analysis phase can't use the parallel chapter-extractor agent."

Give the user two choices:

1. **Run setup first**: pause the import, run `/story-setup`, and after deployment re-trigger `/story-import`;
2. **Continue importing**: accept Phase 2 degrading to serial processing (long-form per-chapter summaries not parallel — slower, but the artifacts stay complete).

Record the user's choice in the context; Phase 2 decides whether to use parallel mode accordingly.

### Step 6: source backup

Source backup is handled by the analyze teardown pipeline called in Phase 2 (the analyze pipeline's pre-step copies/saves the source to `teardown-lib/{Book Title}/source/`, per story-long-analyze and story-short-analyze's "source backup (pipeline pre-step)"). Phase 1 only needs to confirm the source file is ready (path valid or text received); no separate backup here, to avoid duplicating the analyze pipeline's backup logic.

---

## Phase 2: deep analysis

Per the length verdict from Phase 1, call the matching analyze skill's **complete teardown pipeline**; don't do a half-flow "methodology reuse" — drive the whole pipeline to completion and get the full set of structured artifacts.

| Length | Teardown pipeline called | Artifact directory |
|--------|--------------------------|--------------------|
| Long-form | story-long-analyze's full pipeline (Stage 0-6) | `teardown-lib/{Book Title}/` |
| Short-form | story-short-analyze's teardown pipeline (Stage 2-6) | `teardown-lib/{Book Title}/` |

### Call contract

#### Long-form: auto-continue past the Stage 1 stop point

story-long-analyze auto-stops after Stage 0+1 (opening hook chapters) and asks via AskUserQuestion whether to continue the full teardown (story-long-analyze's "Stage 1 stop point"). But the import scenario needs the full Stage 2-6 artifact set (per-chapter summaries / aggregation analysis / `plot/pacing.md` / `plot/emotional-beats.md` / settings & relationships / final report / style) — all required; otherwise Phase 3 migration gets a half-finished product.

**Current teardown contract**: `_progress.md` must be `schema_version: 2`, and `plot/pacing.md` and `plot/emotional-beats.md` are the import-required authoritative artifacts. If any is missing, fix it or re-run the matching Stage first; never assemble a seemingly complete benchmark view from summary files.

Therefore, when calling story-long-analyze you **must** drive the pipeline from the start in "full teardown, run it all in one go, don't stop to ask" mode, hitting its "skip the question" path (it doesn't stop when the user said up front "full teardown / run it all / systematic teardown / don't ask"), letting the pipeline auto-continue from Stage 2 through Stage 6.

- Wording example: when starting the deep analysis, declare "tearing down this book in 'full teardown, run it all in one go, don't stop to ask' mode, ensuring Stage 2-6 all produce output".
- **Fallback**: if the runtime still stops at the Stage 1 question, story-import automatically selects "continue the full teardown" — **never hand the stop question to the user**.
- When the Phase 1 environment check found no deployed chapter-extractor agent and the user chose "continue importing", Stage 2 per-chapter summaries degrade to serial processing — artifacts stay complete, just slower.

#### Short-form: the single full pipeline

story-short-analyze is a single full teardown pipeline (Stage 2-6) with **no Stage 1 stop point**; the contract is simpler: call it and let it run Stage 2-6; no need to declare skipping the question.

### Output directories

#### Long-form teardown-library structure

Long-form analysis outputs to `teardown-lib/{Book Title}/`, identical to the story-long-analyze teardown pipeline:

```
teardown-lib/{Book Title}/
├── source/
│   └── source.txt          # extension follows the source file; pasted text saved as source.md
├── overview.md
├── chapters/
│   ├── chapter_1_deep-dive.md
│   ├── chapter_1_summary.md
│   └── ...               # every chapter has both chapter_N_deep-dive.md and chapter_N_summary.md
├── quick-preview.md
├── characters/
│   ├── {Character Name}.md
│   └── relationships.md
├── plot/
│   ├── {story-unit title}.md
│   ├── storylines.md
│   ├── pacing.md          # key-info progression / emotional touchpoints / burst rhythm
│   ├── emotional-beats.md # reader needs / emotional engine / reproducible modules
│   └── loose-threads.md
├── setting/
│   ├── worldview/         # background.md / power-system.md / geography.md / (subdirectory form)
│   └── factions/          # {Faction Name}.md (one file per faction)
├── teardown-report.md
├── style.md          # Stage 6 style: writing-technique view + source anchor excerpts
└── _progress.md
```

#### Short-form teardown-library structure

Short-form analysis outputs to `teardown-lib/{Book Title}/`, matching the story-short-analyze teardown pipeline:

```
teardown-lib/{Book Title}/
├── source/
│   └── source.txt          # extension follows the source file; pasted text saved as source.md
├── teardown-report.md
├── plot-nodes.md
└── craft-methods.md
```

### The long-form full pipeline (Stage 0-6)

> Pipeline details in story-long-analyze (run `/story-long-analyze`); summarized here.

| Stage | Name | Input | Output | Completion marker |
|-------|------|-------|--------|-------------------|
| 0 | Overview extraction | raw text | overview.md + chapter index | chapter structure recognized |
| 1 | Opening hook chapters | first 3 chapters | chapter_1_deep-dive.md / chapter_2_deep-dive.md / chapter_3_deep-dive.md → **stops to produce quick-preview.md** (import scenario auto-continues without stopping to ask) | 3 chapters done |
| 2 | Per-chapter summary | chunked chapter text | chapter summaries (plot points + characters + **key info and expansion techniques**). 10-40 plot points per chapter (density 150-200 words/point, adjusted by word count). Character filtering (walk-ons not extracted, aliases merged). **Parallel chapter-extractor agent mode** (serial degradation when agents aren't deployed). **Count validation: summary count == chapter count**. | all chapters processed |
| 3 | Aggregation analysis | all chapter summaries | `plot/*.md` + `plot/README.md` + `plot/storylines.md` + **`plot/pacing.md` + `plot/emotional-beats.md`**. **Story-framework recognition** (first). **Two-step plot aggregation** (identify the plot outline from summaries first, then assign plot points by it). **Key-info progression index**, **emotional touchpoints and burst rhythm**, **reader needs / emotional engine / reproducible modules**. **Character merge** (cross-chapter dedup + alias normalization). **Character tiering** (protagonist/antagonist/core supporting/functional). **Loose-thread safety net** (6 steps, incl. coverage validation). **Quality checks** (confidence >=0.85 / coverage 85%-95% / overlap <=35%). | quality checks passed |
| 4 | Setting + relationships | Stage 3 merged character data + plot points | setting/*.md + characters/*.md. **Two-stage character model**. **Alias resolution** (confidence ≥0.85 auto-merge). | settings and relationships extracted |
| 5 | Final report | all outputs | teardown-report.md (incl. "Reader needs / emotional engine", "Key info and expansion techniques overview", "Rhythm and emotional touchpoints", "Reproducible modules", pointing to `plot/pacing.md` / `plot/emotional-beats.md`) | report generated |
| 6 | Style | teardown-report.md + chapters/chapter_1-3_deep-dive.md + chapters/*_summary.md + source/source.txt | style.md (whole-book writing-technique view; must-read in the story-long-write daily-update loop) | style.md written to `teardown-lib/{Book Title}/style.md` |

### The short-form teardown pipeline

> Pipeline details in story-short-analyze (run `/story-short-analyze`); summarized here.

Short-form is a single full pipeline (Stage 2-6, strictly serial), artifacts landing in `teardown-lib/{Book Title}/`: Stage 2 structure + plot nodes → Stage 3 emotional line + eruption points → Stage 4 reversal + writing craft → Stage 5 characters + opening/ending → Stage 6 combined assessment, finally aggregated into `teardown-report.md`, `plot-nodes.md`, `craft-methods.md`.

### Chunking strategy (long-form)

Follows story-long-analyze's chunking strategy (Stage 2 uses chapter-extractor agents in parallel; other stages chunk per the strategy below):

| Scale | Strategy | Chunk size |
|-------|----------|------------|
| <50 chapters | whole-stage processing | no chunking needed |
| 50-100 chapters | whole-stage processing | no chunking needed (optional smart chunking) |
| 100-500 chapters | chunk by chapters | 5-8 chapters/chunk |
| >500 chapters | semantic chunking: cut at natural boundaries; when no clear boundary, cut evenly by fixed chapter counts | 50-200 chapters/chunk |

### Resume mechanism

- On interruption, track progress through the progress file
- New sessions read the progress file to locate the breakpoint
- Resume from the first chapter of the chunk containing the breakpoint
- Long-form progress files follow the story-long-analyze teardown pipeline's progress-section conventions, including the current stage, last processed chapter, completed-stage list, and update time

### Quality checks

Before long-form Stage 3-4 complete, quality checks run (confidence >= 0.85, coverage 85%-95%, overlap <= 35%), handled by the story-long-analyze teardown pipeline's built-in quality checks. Short-form quality checks per story-short-analyze's per-stage completion markers.

---

## Phase 3: structure migration

### Title and benchmark identity boundary

Keep the imported work and every external reference independent throughout the import:

- `Imported Work Title` is the title of the work being migrated and owns the destination project directory and imported-work analysis.
- `External Benchmark Title` is an unrelated comparison work and owns only its benchmark/reference directory.
- Never copy imported-work analysis into an external benchmark target, and never use the imported work as its own benchmark.

### Tracking import cutoff contract

For an imported project, set `imported_through_chapter=N` in `_tracking-state.json` and do not fabricate per-chapter records for chapters 1..N. Generate the current `character-state/{Character Name}.md` snapshots and the timeline reader-knowledge view from the authoritative state. Run `tracking_commit.py init` before any chapter `commit`; the JSON authority is the only program input.
Legacy tracking files are archived under `_retired-tracking-archive` and are not parsed or converted.

Migrate `teardown-lib/{Book Title}/`'s analysis results into the project structure the writing skills can consume.

### Routing

Route by the length verdict from Phase 1; the two paths produce completely different project structures:

| Length | Migration path | Mapping rules | Continue-writing handoff |
|--------|----------------|---------------|--------------------------|
| Long-form | **3-L: long-form structure migration** | [references/structure-mapping-long.md](references/structure-mapping-long.md) | story-long-write daily-update loop |
| Short-form | **3-S: short-form structure migration** | [references/structure-mapping-short.md](references/structure-mapping-short.md) | story-short-write Phase 3 per-scene writing |

---

## Phase 3-L: long-form structure migration

Migrate `teardown-lib/{Book Title}/`'s analysis results into the `{Book Title}/` long-form project structure. Migration rules in detail: [references/structure-mapping-long.md](references/structure-mapping-long.md).

### Migration steps

#### Step 1: create the project skeleton

```
{Book Title}/
├── setting/
│   ├── worldview/
│   ├── characters/
│   └── factions/
├── outline/
├── prose/
├── tracking/
├── benchmark/
│   └── {Book Title}/plot/
└── reference/
```

#### Step 2: standardize the prose

Migrate the source into `prose/`, unified naming: `chapter_NNN_Title.md`.

- Recognize chapter separators (Chapter X, plain numbered titles, etc.)
- Extract chapter titles
- Zero-pad the numbering (Chapter 1 → chapter_001)
- Keep the original content unchanged

#### Step 3: migrate the character files

Migrate `teardown-lib/{Book Title}/characters/{Character Name}.md` into `setting/characters/{Character Name}.md`.

Add the story-long-write character-template fields during migration:

```markdown
---
name: {Character Name}
---

# {Character Name}

## Basic info
- Identity: {}
- Core traits: {}
- Current ability: {}
- Core motive: {}
- Weakness/flaw: {}

## Appearance log
| Chapter | Key event | State change |
|---------|-----------|--------------|
```

Character tiering (per story-long-analyze standards):

| Tier | Criterion | Migration strategy |
|------|-----------|---------------------|
| Protagonist | appears in ≥50% of chapters + drives the main line + full growth arc | full migration |
| Antagonist | opposes the protagonist + drives the core conflict + clear motive | full migration |
| Core supporting | appears in ≥20% of chapters or drives an important subline | full migration |
| Functional | appears in <20% of chapters + limited function | simplified migration |

#### Step 4: migrate the relationship file

Convert `teardown-lib/{Book Title}/characters/relationships.md` into `setting/relationships.md`, per the "relationship-file conversion rules" target-format template in [structure-mapping-long.md](references/structure-mapping-long.md).

#### Step 5: sync the worldview settings

The current teardown contract outputs `teardown-lib/{Book Title}/setting/worldview/*.md` and `setting/factions/*.md` by topic. Sync them as-is into the project; `worldview/` must contain `background.md`. `power-system.md` may be omitted when it's under 200 words and already merged into `background.md`; otherwise, when a current-required artifact is missing, stop and tell the user to re-run story-long-analyze Stage 4. No on-the-fly splitting of flat files anymore.

#### Step 6: generate the outlines

**outline.md** (volume-level structure): back-derived from `plot/storylines.md`, `plot/*.md`, and `quick-preview.md`. **Volume split uses user-confirmation**; rules in the "outline back-derivation rules" of [structure-mapping-long.md](references/structure-mapping-long.md):

- **The source has explicit volume boundaries** ("Volume 1", "Book One" level titles) → split by the source's own volume boundaries directly; no asking.
- **The source has no explicit volume boundaries** → **don't mechanically cut "20-40 chapters per volume"**. Detect candidate volume boundaries from storylines/scene switches/large time jumps, present the candidate split to the user, **wait for user confirmation** before writing the volume outlines; before confirmation, `outline/outline.md` only records the candidates.

```markdown
# Whole-book outline (master outline)

## Volume-level outline

### Volume 1: {volume name} (about {X}K words, {Y} chapters)
- Function: {inferred from the plot analysis}
- Core event: {one sentence}
- Starting state → ending state: {inferred from character arcs}
```

**Volume outlines**: after the volume split is confirmed, aggregate from the plot files into `outline/volume_outline_{X}.md`, per the "volume-outline back-derivation" template in [structure-mapping-long.md](references/structure-mapping-long.md).

**Chapter outlines**: back-derived from the chapter summaries into `outline/outline_chapter_NNN.md`:

```markdown
## Chapter Outline (Chapter N)

### Chapter N: {title}
- Core event: {extracted from the summary}
- Target words: {the source chapter's actual word count}
- Target emotion: {from the chapter tone/emotion curve; unknown → [TBD]}
- Opening hook: [TBD]
- Payoff: {inferred from plot points; no clear evidence → [TBD]}

#### Content summary (five-part)
- Cause: {generalized from plot points; unknown → [TBD]}
- Development: {generalized from plot points; unknown → [TBD]}
- Turn: {generalized from plot points; unknown → [TBD]}
- Climax: {generalized from plot points; unknown → [TBD]}
- Ending: {what action/image/line the source ends on; unknown → [TBD]}

#### Plot arrangement (multi-line)
- Main line: {back-derived from the story-unit index/summary}
- Sub-line: {no evidence → "none" or [TBD]}
- Event & task line: {the external event chain}
- Relationship line: {only with evidence; else "none visible" or [TBD]}
- Logic line: cause → action → result → consequence/new problem

#### Characters and appearance order
- Appearance order: {the order characters/factions/key objects appear in the summary}
- Relationship changes: {before this chapter → after this chapter; unknown → [TBD]}
- POV & information gap: {who knows what; what the reader knows; what the protagonist misjudges; unknown → [TBD]}

#### Plot detail
- Plot-point sequence: {back-derived from the summary plot points, "who did what + function tag" per point}
- Action cost (optional)/benefit attribution: {only with evidence; the action cost may be absent — don't invent; unknown → [TBD]}

#### Ending and hook
- Ending design: {what action or image the source closes on; unresolved problems; the next chapter's driver; unknown → [TBD]}
- Chapter-end hook: [TBD]
```

> Fields that can't be reliably determined from the chapter summaries — hooks, relationship changes, sub-lines/relationship lines, action cost/benefit attribution — are uniformly marked `[TBD]`; story-import only back-derives evidence-based blueprints and never invents relationships or sub-lines to fill fields.

#### Step 7: generate the tracking files

The tracking directory has four files, **generated in this order** (each depends on the previous one's output):

```
① tracking/foreshadowing.md  ← generated first (character-state's "pending foreshadowing" field depends on it)
② tracking/timeline.md       ← together with or right after foreshadowing
③ tracking/character-state.md ← depends on foreshadowing.md existing
④ tracking/context.md         ← generated last (its "character state: recent changes" field depends on character-state.md)
```

**① tracking/foreshadowing.md**: extract candidate foreshadowing from the "setup" type plot points:

```markdown
# Foreshadowing Tracking

## Foreshadowing status table

| ID | Foreshadowing | Planted in | Expected recovery in | Status | Importance |
|----|---------------|------------|----------------------|--------|------------|
| F001 | {extracted from setup plot points} | Chapter {N} | {mark if already recovered} | {planted/recovered} | {medium} |
```

**② tracking/timeline.md**: extracted from time markers:

```markdown
# Story Timeline

## Key-event chronology

| Chapter | Story time | Event | Characters involved | Relation to the main line |
|---------|------------|-------|---------------------|---------------------------|
```

**③ tracking/character-state.md**: back-derive each major character's current state from the teardown artifacts. The back-derivation algorithm: [references/character-state-reverse.md](references/character-state-reverse.md):

- **Input sources**: existing teardown-library artifacts (`characters/{Character Name}.md`, `characters/relationships.md`, `chapters/chapter_N_summary.md` plot points, `plot/*.md`) + the generated `tracking/foreshadowing.md`; **do not re-read `source/`**.
- **Tracking scope**: protagonist, antagonist, core supporting; functional characters stay out.
- **Output alignment**: strictly align with the standard `character-state.md` template in the "output format" section of [character-state-reverse.md](references/character-state-reverse.md) (current identity / current ability / key relationships / public image / pending foreshadowing / state-change log).
- **Generation timing**: must come after `tracking/foreshadowing.md` (the "pending foreshadowing" step depends on the foreshadowing status).
- **Partial books**: when the last chapter is a draft, character state reflects "the last complete chapter before the draft"; note the baseline chapter in the file header.

> This file is not optional. story-long-write's daily-update pre-write "state filtering" depends on `tracking/character-state.md`; if missing, the imported book permanently runs the "infer from character sheet and prior text" fallback branch in daily updates — a permanent degradation.

**④ tracking/context.md**: progress summary (generated last; the "current state" section's character-state changes reference `character-state.md`):

```markdown
## Writing progress

- Last completed chapter: Chapter {N}
- Updated: {import date}
- This session: imported {N} chapters, {X} words total

## Current state

- Active foreshadowing: {A} pending recovery
- Character state: recent changes in `tracking/character-state.md`
- Next chapter outline status: exists
- Notes: when the last chapter is a draft, note here that the draft runs through chapter N and the user's chosen continuation strategy
```

#### Step 8: genre positioning

Extract core findings from the teardown report and generate `setting/genre-positioning.md` (per the "genre-positioning generation" template in [structure-mapping-long.md](references/structure-mapping-long.md)).

`setting/genre-positioning.md` **must include a "benchmark-book list + primary benchmark book" section**. The primary benchmark book is at most 1; secondary/reference benchmark books are unlimited in number — append by the user's material and genre relevance; don't truncate to "one secondary book". Format:

```yaml
primary benchmark book: {Book Title}  # with multiple benchmarks, which one's style the daily update defaults to; when missing, story-long-write uses the first alphabetically and tells the user to fill it in
benchmark book list:
  - title: {Book Title A}
    reference strength: primary  # primary / secondary / reference
    genre: {genre}
    relevance: same-genre
    use: style + core structure
  - title: {Book Title B}
    reference strength: secondary
    genre: {genre}
    relevance: same-genre / weakly-related
    use: {supplement settings/outline/modules, not style}
  - title: {Book Title C}
    reference strength: secondary
    genre: {genre}
    relevance: same-genre / weakly-related
    use: {supplement settings/outline/modules, not style}
  - title: {Book Title D}
    reference strength: reference
    genre: {genre}
    relevance: same-genre / weakly-related
    use: {recall summaries by budget only}
```

For later quick overviews, you may additionally write a "benchmark analysis (derived summary)" table; that table is not the authoritative registry and must not replace the `primary benchmark book` + full `benchmark book list`.

#### Step 9: benchmark structured-asset sync

Sync the teardown library's structured analysis assets to the project reference view `{project}/benchmark/{Book Title}/`, which story-long-write's benchmark-book path lookup reads first. The sync doesn't regenerate content; the teardown library stays the single canonical source:

| Source path | Project benchmark path | Use |
|-------------|------------------------|-----|
| `teardown-lib/{Book Title}/plot/pacing.md` | `{project}/benchmark/{Book Title}/plot/pacing.md` | story-long-write reads key-info progression, emotional touchpoints, burst rhythm |
| `teardown-lib/{Book Title}/plot/emotional-beats.md` | `{project}/benchmark/{Book Title}/plot/emotional-beats.md` | story-long-write reads reader needs / emotional engine, reproducible modules |
| `teardown-lib/{Book Title}/plot/*.md` | `{project}/benchmark/{Book Title}/plot/*.md` | story units and storylines reference |
| `teardown-lib/{Book Title}/chapters/*.md` | `{project}/benchmark/{Book Title}/chapters/*.md` | matching-chapter summaries and key-info/expansion-technique evidence |
| `teardown-lib/{Book Title}/characters/*.md` | `{project}/benchmark/{Book Title}/characters/*.md` | character functional-slot reference |
| `teardown-lib/{Book Title}/setting/` | `{project}/benchmark/{Book Title}/setting/` | worldview/faction reference |
| `teardown-lib/{Book Title}/teardown-report.md` | `{project}/benchmark/{Book Title}/teardown-report.md` | human-readable summary projection |

**Missing-artifact handling**:

- Missing `plot/pacing.md` or `plot/emotional-beats.md` → **stop the import and give a fix action**: tell the user to re-run `/story-long-analyze` Stage 3+ or manually complete the files; the import report writes `module_or_rhythm_required_missing`; don't keep generating a seemingly complete benchmark view.
- Other missing structured subdirectories → follow the existing import missing-item prompts; don't block project creation.

#### Step 10: style sync

Copy `teardown-lib/{Book Title}/style.md` to `{project}/benchmark/{Book Title}/style.md`. Pure copy; no regeneration.

**Missing-artifact handling**:

- No style file in the teardown library (analyze didn't run Stage 6) → the import report tells the user to re-run `/story-long-analyze` before syncing; a missing style before daily updates is intercepted by fail-fast
- An old style file already exists in the project benchmark → overwrite (latest teardown artifacts win); note it in the import report

---

## Phase 3-S: short-form structure migration

Migrate `teardown-lib/{Book Title}/`'s short-form teardown artifacts into the `{ShortTitle}/` short-form project structure for story-short-write Phase 3 per-scene writing to take over seamlessly. Migration rules in detail: [references/structure-mapping-short.md](references/structure-mapping-short.md).

> **The short-form project is completely different from long-form**: the short-form body is the single file `prose.md` (no chapter splitting), and **does not produce** `tracking/`, `outline/`, `prose/` (directory), or other long-form directories. During migration it is forbidden to mistakenly create these long-form-only directories.

### Short-form target project structure

```
{ShortTitle}/
├── AGENTS.md               ← book-level language, market, and content contract
├── setting.md              ← contains the core framework + benchmark summary
├── section-outline.md      ← back-derived by segment-episode structure
├── prose.md                ← the whole piece in one file
└── benchmark/{Book Title}/ ← optional: the teardown reference view
    ├── teardown-report.md
    ├── plot-nodes.md
    └── craft-methods.md
```

### Migration steps

#### Step 1: prose migration

Migrate the full text from `teardown-lib/{Book Title}/source/` into the single file `{ShortTitle}/prose.md`, normalized per [format-and-structure.md](references/format-and-structure.md) (episode markers `###1.`, single line break between paragraphs, dialogue quotes unified per project/platform convention). **The source is a finished draft — don't rewrite the content, only normalize the format.**

#### Step 2: setting generation

Create or update `{ShortTitle}/AGENTS.md` from the shared English book contract, then back-derive `{ShortTitle}/setting.md` from `teardown-report.md` and `craft-methods.md`, with two blocks:

- **Core framework**: aligned with the story-short-write core-framework template (basic info, one-line synopsis, core reversal, emotion design, character sketches).
- **Benchmark summary**: write the story structure, emotional rhythm, core reversal mechanics, and reusable writing craft into the benchmark-summary block.

#### Step 3: section-outline generation

Back-derive `{ShortTitle}/section-outline.md` from `plot-nodes.md`'s functional segments, mapped onto opening/development/escalation/reversal/ending segments; shorts get a lightweight blueprint only: per episode write `structure segment / five-part function`, the main event, 3-5 sub-events, the target emotion, character/relationship changes, the causal/logic chain, and the episode-end handoff/hook. Hooks or relationships that can't be judged are marked `[TBD]`; don't apply the long-form full chapter blueprint.

#### Step 4: benchmark reference view (optional)

Copy `teardown-lib/{Book Title}/` wholesale into `{ShortTitle}/benchmark/{Book Title}/` for benchmark-context loading during continuation. Generated by default.

---

## Phase 4: project activation

### Step 1: quality checks

Check against the matching quality checklist by length:

- **Long-form**: the full migration quality checklist at the end of [references/structure-mapping-long.md](references/structure-mapping-long.md) (incl. prose file-count comparison, major-character coverage, `tracking/character-state.md` generated and aligned with the standard template, volume split user-confirmed, etc.).
- **Short-form**: the quality checklist at the end of [references/structure-mapping-short.md](references/structure-mapping-short.md) (incl. `prose.md` single file present and format-compliant, `setting.md` containing the core framework + benchmark summary, no mistakenly created long-form-only directories, etc.).

### Step 2: missing-item prompts

Output the import summary and to-do items, branched by length.

**Long-form import completion report**:

```
=== Import completion report (long-form) ===
Title: {Book Title}
Source: {X} chapters, {Y}K words
Project directory: {path}

## Files generated
- Prose: {N} chapters
- Character files: {M}
- Outlines: outline.md + {V} volume outlines + {N} chapter outlines
- Tracking: foreshadowing.md + timeline.md + character-state.md + context.md
- Settings: {worldview file count} files
- Benchmark sync: `benchmark/{Book Title}/plot/pacing.md` (rhythm synced/not) + `benchmark/{Book Title}/plot/emotional-beats.md` (modules synced/not) + style.md + teardown-report.md

## To-do items
- [ ] Chapter-outline opening/ending hooks need filling
- [ ] The genre-positioning core-hook three-way split needs confirmation
- [ ] Foreshadowing entries in the tracking reviewed
- [ ] character-state.md reviewed (daily-update pre-write depends on it)
- [ ] Volume split confirmed (when the source has no explicit volume boundaries)
- [ ] style.md synced from the teardown library to `benchmark/{Book Title}/` (daily-update fail-fast depends on it)
- [ ] Rhythm synced to `benchmark/{Book Title}/plot/pacing.md`; when missing, fix or re-run Stage 3 first
- [ ] Emotional modules synced to `benchmark/{Book Title}/plot/emotional-beats.md`; when missing, fix or re-run Stage 3 first
- [ ] `setting/genre-positioning.md` includes the `primary benchmark book` field (required with multiple benchmarks)

## Next steps
- Run `/story-review lean` to review the import result
- Run `/story-long-write` + "daily" to start continuing
```

**Short-form import completion report**:

```
=== Import completion report (short-form) ===
Title: {ShortTitle}
Source: {Y} words
Project directory: {path}

## Files generated
- prose.md (single file, {Y} words)
- setting.md (core framework + benchmark summary)
- section-outline.md ({N} episodes)
- benchmark/{Book Title}/ (optional reference view)

## To-do items
- [ ] All [TBD]-marked files reviewed
- [ ] Section-outline opening/ending hooks need filling
- [ ] Core-reversal setup clues confirmed

## Next steps
- Run `/story-short-write` Phase 3 to start continuing
```

### Step 3: project activation

- Set `.active-book` to point at the imported book/title directory
- Confirm the project is recognizable by the matching writing skill (long-form → story-long-write, short-form → story-short-write)
- Optional validation: if the project has the story-explorer agent deployed (prefer checking `.claude/agents/` for `story-explorer.md`; if absent, check `.opencode/agents/`, then `.codex/agents/`), you may spawn `Agent(subagent_type: "story-explorer", prompt: "Project directory: {dir}\nQuery type: progress\nQuery parameters: import validation")` to cross-validate the migrated data completeness

> Setup environment detection already happened in Phase 1's "environment detection (pre-flight)"; no repeated detection here.

---

## Large works (>200 chapters)

> This section applies to long-form import only. Short-form is a single-file full migration; no incremental import needed.

Works over 200 chapters use the incremental import strategy:

1. **First import**: import only the first 50 chapters + the whole-book overview
2. **Incremental additions**: later batch-import the remaining chapters per user request
3. **Context summaries**: generate simplified summaries for unimported chapters (200 words/chapter)

---

## Reference index

Load by phase; don't load everything at once.

This skill's own reference files all live in `references/`; load by scenario. For methodology/templates in other skills, story-import doesn't load the files directly — it runs the corresponding `/command` and lets that skill load them itself.

### Phase 1: confirm the import source

| Scenario | Load |
|----------|------|
| Length routing verdict | `references/length-routing.md` |
| Chapter-format recognition | handled by the story-long-analyze teardown pipeline (run `/story-long-analyze`) stage 1 |

### Phase 2: deep analysis

| Scenario | Load file / relevant skill |
|----------|---------------------------|
| Long-form deep analysis (methodology, quality checks, output templates included) | run `/story-long-analyze` to call the long-form teardown pipeline |
| Short-form deep analysis (methodology, quality checks, output templates included) | run `/story-short-analyze` to call the short-form teardown pipeline |

### Phase 3: structure migration

| Scenario | Load |
|----------|------|
| Long-form migration mapping rules | `references/structure-mapping-long.md` |
| Short-form migration mapping rules | `references/structure-mapping-short.md` |
| Character-state back-derivation rules (long-form) | `references/character-state-reverse.md` |
| Character-state rules (dependency of character-state-reverse.md) | `references/state-tracking.md` |
| Short-form prose format conventions | `references/format-and-structure.md` |

> The long-form chapter-outline template format comes from story-long-write (Phase 3 chapter-outline part); the short-form core-framework template comes from story-short-write (core-framework part). Both are plain-text guidance; story-import doesn't load those skills' files.

### Phase 4: project activation

| Scenario | Notes |
|----------|-------|
| Long-form project structure conventions | see story-long-write (Phase 4 project file structure) |
| Short-form project structure conventions | see story-short-write (Phase 3 project structure) |
| Environment deployment | deployment templates provided by `/story-setup`; story-import doesn't deploy |

---

## Flow handoffs

**Pipeline:** long-form / short-form
**Position:** import (before opening a new book)

| When | Jump to | Command |
|---|---|---|
| Imported, want to keep writing (long-form) | story-long-write | `/story-long-write` + "daily" |
| Imported, want to keep writing (short-form) | story-short-write | `/story-short-write` |
| Imported, want a quality review | story-review | `/story-review` |
| Want deep benchmark analysis (long-form) | story-long-analyze | `/story-long-analyze` |
| Want deep benchmark analysis (short-form) | story-short-analyze | `/story-short-analyze` |
| Start a new book from zero (long-form) | story-long-write | `/story-long-write` + "open a book" |
| Start a new book from zero (short-form) | story-short-write | `/story-short-write` |
| Project environment not deployed | story-setup | `/story-setup` |

---

## Language

> - Load the deployed English book contract and resolve language from the book profile, then the source prose, then the repository default `en-US`. Do not use the user's chat language as a fallback.
> - English prose follows the house style rules in the skill's `references/` files (especially `anti-ai-writing.md`); keep sentences conversational, concrete, and free of AI-flavor patterns.
