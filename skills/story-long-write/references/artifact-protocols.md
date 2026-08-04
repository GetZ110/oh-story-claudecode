# Artifact Creation Templates

Standard templates and creation guidance for every artifact. Agents load this file on demand at the Phase 2-3 transition.

**Template list:**
- setting/relationships.md
- setting/genre-positioning.md (includes reader contract + endgame trump cards/power-up ladder + benchmark registry fields)
- outline/outline.md (whole-book bird's-eye view + book length & stage overview)
- outline/volume_outline_N.md (includes volume contract + endgame reserve + story units + emotion curve + reversal plan)
- tracking/foreshadowing.md
- tracking/timeline.md
- tracking/character-state.md
- benchmark/{Benchmark Book}/teardown-report.md
- benchmark/{Benchmark Book}/source/chapter_NNN_{Title}.md

**Hierarchy (book › volume › story unit › chapter › plot point; storylines cut horizontally across story units):**
- outline.md = whole-book bird's-eye view (one or two sentences positioning each volume)
- volume_outline_N.md = single-volume plan (story units + emotion + characters + foreshadowing + reversals)
- outline_chapter_NNN.md = single-chapter blueprint (unit ID/position + protagonist goal/key choice + content summary + multi-line plot arrangement + characters & appearance order + plot detail + ending/hook; legacy fields core event/target emotion/opening hook/payoff/chapter-end hook/target words retained for legacy compatibility)

**Concept alignment (unified names, less confusion):**
- **Story unit** = one complete stretch of plot (10k-30k words / several chapters, one conflict from start to payoff). On the teardown side it is `plot/{story-unit name}.md`; on this book's side it is the **story-unit card** inside the volume outline; the theoretical term is "level-1 structure". Same granularity, one name: story unit.
- **Storyline** (`plot/storylines.md`) = a line crossing multiple story units (main line/romance line/growth line/treasure line…), one level above the story unit.
- The word "loop" is kept only in the **rhythm sense** (payoff loop, upgrade loop, small/mid/large loop, etc.) and no longer refers to a planning unit.

---

## benchmark/{Benchmark Book}/teardown-report.md

> **teardown-lib/benchmark relationship**: `teardown-lib/` = the analyze skill's raw output (data source). `benchmark/` = the writing project's reference view. On first reference, copy from `teardown-lib/` into `benchmark/`.

This file is produced by the `story-long-analyze` teardown pipeline (quick-preview report or full teardown report). The write skill's job is to **read** it, not create it.

For a manual lightweight benchmark summary (when not using the analyze skill):

```markdown
# {Benchmark Book} Benchmark Summary

## Basic info
- Title: {}
- Author: {}
- Genre/type: {}
- Target platform: {}
- Performance: {average subscriptions / reads / heat}

## Core findings
- Opening hook: {type + technique}
- Payoff density: {about one per N words}
- Pacing pattern: {description}
- Transferable patterns:
  1. {}
  2. {}
  3. {}

## Do not imitate (no direct copying)
- {} (learn structure, do not copy scenes)
```

Creation reference: `plot-special-topics.md` (benchmark book selection rules)

---

## benchmark/{Benchmark Book}/source/chapter_NNN_{Title}.md

Original chapter text of the benchmark book, placed manually by the user or imported by the teardown pipeline.

```markdown
# Chapter {N} {Title}

{Full original chapter text}

---
> Source: {manual / imported by story-long-analyze}
> Original word count: {~N}
```

---

## setting/relationships.md

```markdown
# Character Relationship Map

## Relationship overview

| Character A | Character B | Relationship type{family/romance/friendship/emnity/mentor-superior-subordinate/interest} | Emotional valence{positive/negative/neutral/complex} | Current state | First chapter | Change node |
|--------|--------|---------------------------------------------|-----------------------------|---------|---------|---------|
| {name} | {name} | {type} | {valence} | {description} | Chapter {N} | {event} |

## Relationship evolution

{CharacterA}<->{CharacterB}:
- Start: {initial relationship}
- Turning point: {chapter · event · change}
- Current: {present state}

## Core conflict relationships

{list the 2-3 core opposition/cooperation pairs that drive the plot}
```

Creation reference: `character-relations.md` (relationship types + map drawing)

---

## setting/genre-positioning.md

```markdown
# Genre Positioning

## Basic info
- Genre type: {cultivation/urban/system/...}
- Target platform: {Royal Road/Webnovel/Wattpad/Kindle/other; story-review picks its platform rubric from this}
- Core hook: {one-sentence selling point}
- Micro-innovation points: {differences from same-genre books}

## Reader contract (see `reader-contract-and-progression.md`)
- Core reader promise: {what pleasure/emotion/relationship/career the reader comes for}
- Protagonist agency promise: {the protagonist's irreplaceable judgment, key choices, or contributions}
- Interest safety line: {boundary for core assets/selling points: not confiscated, gifted, or exposed without exchange}
- Promise debt: {what the opening/this volume promised, when and in what form it is repaid}
- Genre boundary: {individual turnaround / ensemble / mentor / institutional cooperation, etc.; check first when high-level institutions appear}

## Endgame trump cards & power-up ladder (anti-exhaustion; fill once at book opening, only check during daily updates. See `reader-contract-and-progression.md` "endgame reserve & progression pace")
- Endgame trump cards (one-time resources, mark earliest unlock volume): Head rival={}·vol {X}; Ultimate truth/identity={}·vol {X}; Cheat ceiling={}·vol {X}; Identity/status endpoint={}·vol {X}; Core emotional endpoint={delete if no romance main line}·vol {X}
- Power-up ladder: primary system {realm/level/map/faction tier} with {N} rungs × ~{W}k words per rung ≥ whole-book target words (if short, lengthen the system/add map layers); enemies/goals unlock as a tiered ladder; no skipping to insta-kill the top
- Overdraw red lines: ① touching an endgame trump card before its unlock volume ② any progression line nearing its ceiling with no rung left

## Core-hook three-way split
- Surface selling point: {the attraction readers see at a glance}
- Deep payoff: {the emotional driver that keeps them reading}
- Long-line hook: {the suspense/goal that carries the whole book}

## Benchmark analysis (summary)
> Full benchmark data lives in the `benchmark/` directory. This table is a quick overview only.

| Benchmark book | Similarities | Differences | Transferable |
|--------|-------|-------|-------|
| {book} | {point} | {point} | {point} |

## Benchmark registry (required for multi-benchmark; cross-book recall sorts and budgets by this)
- Primary benchmark book: {book; may be omitted with a single benchmark, required with multiple}
- Benchmark book list:

| Book | Genre | Citation strength{secondary/reference} | Use |
|------|---------|-----------------|------|
| {book} | {genre} | {secondary/reference} | {style primary / structure reference / …} |

## Genre framework
- Eight-node position: {which node the story is currently at}
- Key turning nodes: {list}
```

Creation reference: `genre-core-mechanics.md` (core-hook analysis and use + micro-innovation and differentiation design)

---

## outline/outline.md

Whole-book bird's-eye view. The top carries the "Book Length & Stage Overview" (total chapters / target length / whole-book emotion curve / stage breakdown / per-stage pacing formulas / key nodes & hook chain; structure per [Phase 3: Outline building](../SKILL.md#phase-3-outline-building)), followed by the volume-level outline as a one-paragraph summary:

```markdown
# Master Outline

## Book Length & Stage Overview
{fill per the Phase 3 "Book Length & Stage Overview" structure}

## Volume Outline
### Volume 1: {name} (~{X} thousand words, {Y} chapters)
- Function / Stage / Volume contract / Endgame reserve / Stage boundary / Core event / Start state → end state
(one-paragraph summary; expansion lives in each volume's volume_outline_N.md)
```

---

## outline/volume_outline_N.md

The volume outline expands the master outline — the master sets direction, the volume sets rhythm. It contains all creation planning for the volume.

```markdown
# {Volume name} Volume Outline

## Core info
- Chapter range: chapters {X}-{Y}
- Target length: {W} thousand words
- Volume positioning: {setup/development/climax/turn/closing}

## Volume contract & endgame reserve (see `reader-contract-and-progression.md`)

> Open the density per chapter; manage the endgame reserve at the macro level. Lines other than the primary push line get result gains naturally as the plot develops; one battle many gains is allowed. What is actually guarded: do not touch endgame trump cards this volume is not yet allowed to unlock.
- Volume contract: {this volume's reader expectations, protagonist highlights, main promise debts}
- Primary push line: {the 1 progression line carrying this volume's biggest climax: power line/resource line/identity line/relationship line/info line/map line/institution line/faction line/career line/emotional certainty}
- Result lines: {other lines paid off along the way; light touch to big jump all fine; one battle many gains is good design}
- Endgame milestone unlocked this volume: {see the "endgame trump cards & power-up ladder" section of `setting/genre-positioning.md`; which big milestone does this volume advance or unlock}
- Endgame trump cards off-limits this volume: {rivals/truths/identities/cheat ceilings whose unlock volume has not arrived and which this volume must not touch}
- Contract risk: {contract safe / needs reinforcement / contract broken; write the reinforcement method when needed}

## Story-unit cards (10k-30k words is an adjustable experience value; stored inside the volume outline; no separate files)

> A story unit = a level-1 structure unit in the volume outline (see outline-structure-theory.md "benchmark pacing migration") — the same unit seen from a different angle as the "benchmark structure coordinates" below, not a separate plan. Unit length adjusts to this book's genre, existing delivery rhythm, and benchmark; not a hard gate. When planning key nodes, consume the authoritative file's "key-node four questions" and expectation ownership; the protagonist need not personally perform every action. After a climax/delivery a short low-pressure passage may follow, with small visible gains/rewards carrying into the next round of pressure. When introducing new maps/institutions/abilities/enemies/mysteries, check the new-element debt first; do not use novelty to dodge old promises.

### Story unit {L-No.}
- Unit ID: {L-No.}
- Chapter range: {chapters A-B}
- Benchmark plot reference: {{book} "{plot title}" (type/beat tag; what to borrow: structure distribution/plot-point index/delivery style); 2-3 entries allowed, write "none" if no benchmark}
- Unit beats/chapter function allocation: {establish anticipation → attempt → pressure/turn → decisive action → delivery → aftermath; mark chapter ranges; adjustable by genre; when building the card, may fill from the common beats distilled from the "benchmark plot reference" story units, see outline-structure-theory.md "chapter outlines by story-unit batch"}
- Unit promise: {the emotional proposition/expectation this unit builds for the reader, and the promise debts it repays}
- Unit emotional engine: {core emotional proposition → carrier object/emotional gap → why it is blocked or kept hanging → this round's trigger → the protagonist's irreplaceable ignition/transformation action → meaning change or visible delivery → genre/contract delivery; the carrier may be a person/relationship/goal/rule/scene; inapplicable links may say none/immediate but the causal chain must stay closed; pick the mechanism by genre — misunderstanding/object/reversal are not mandatory}
- Volume-level contribution: {how it serves this volume's contract, stage rhythm, or volume goals}
- Protagonist local goal & core interests: {what the protagonist must protect/get/prove this unit}
- Causal entry: {the entry naturally led from the previous unit or existing events}
- Core obstacle: {main hostility, restriction, misjudgment, or resource gap}
- Key choice & decisive action: {the protagonist's irreplaceable judgment, choice, and action}
- Delivery method & attribution: {how the core delivery happens, who gets the benefit, how it is visible}
- This unit's primary push line/result lines: {per the volume-contract split — 1 primary push line carries the climax, other lines give results, one battle many gains allowed}
- Endgame trump card boundary: {un-unlocked rivals/truths/identities/cheat ceilings this unit must not touch; on contact, revise per the authoritative file's overdraw two questions}
- Forbidden early release: {what this unit must not resolve/reveal/upgrade early}
- Next unit's causal hook: {the question, cost, thread, or new goal that pushes naturally into the next unit}
- Risk level: {contract safe / needs reinforcement / contract broken; write the reinforcement method when needed}

## Core conflict
{one sentence: what problem this volume solves or what goal it reaches}

## Benchmark structure coordinates
{fill when a benchmark book exists; otherwise "no benchmark, arrange by eight-node percentages". Migration steps see outline-structure-theory.md "benchmark pacing migration"; benchmark key plots are preferentially taken from the referenced story unit's "plot-point index"}
- Primary benchmark segment: {benchmark book} chapters {A}-{B} (core-conflict correspondence: {one sentence})

| Normalized position | This volume's chapters | Benchmark key plot | This volume's equivalent (swapped material) | Type{reversal/turn/inciting} |
|-----------|-----------|-------------|-------------------|---------------------|
| 1/4 | Chapter {N} | {benchmark event} | {this volume's event} | {type} |
| Midpoint | Chapter {N} | {benchmark event} | {this volume's event} | {type} |
| 3/4 | Chapter {N} | {benchmark event} | {this volume's event} | {type} |

## Emotion curve
- Template: {V-shape / inverted V / W-shape / progressive / delayed-gratification / sharp-turn}
- Why: {per genre and volume positioning}

| Chapter | Chapter positioning{may be blank} | Tone{tense/light/sad/hot/sweet/warm/horror/oppressive/other} | Intensity{1-10} | Trigger event |
|------|------------|-----------------------------------------|--------------|---------|
| Chapter {N} | {high pressure/advancement/training trial/relationship payoff/low-pressure life/information assembly} | {tone} | {N} | {event} |

> Chapter positioning may be blank; blank counts as a normal advancement chapter (i.e. falls back to the status quo). Intensity is emotional intensity — distinct from the positioning's burst pressure: relationship/tearjerker chapters may be low pressure but high intensity. A volume needs a high-low spread; keep low-pressure + transition restrained (total ≤ ~15%, genre tiers in outline-structure-theory.md); scan adjacent chapters' tones row by row and do not run the same motif for more than 2-3 consecutive chapters. Positioning and floors see outline-structure-theory.md "chapter positioning & tension".

## Character arcs
| Character | Volume start | Volume end | Key change |
|------|---------|---------|---------|
| {name} | {state} | {state} | {event} |

## Volume reversals (if any)
| Type{identity/motivation/faction/info/fate} | Characters involved | Mislead path | Reveal chapter | Impact scope |
|------|---------|---------|---------|---------|
| {type} | {name} | {how the reader is misled} | Chapter {N} | {which lines it affects} |

## Volume foreshadowing
| Foreshadowing | Planted chapter | Expected collection | Type{short/mid/long} |
|------|---------|---------|---------------------|
```

Creation reference: `outline-methods.md` (three-layer outline method) + `outline-rhythm.md` (three-step progression-feel design) + `emotional-arc-design.md` (six-arc quick reference) + `reversal-toolkit.md` (five reversal types)

---

## outline/outline_chapter_NNN.md

The chapter outline is the chapter blueprint for prose writing, not just a list of events and hooks. **The single authoritative copy of the template** lives in [Phase 3: Outline building](../SKILL.md#phase-3-outline-building) (with unit ID/position, protagonist goal/key choice, task blockers, structure formula, contract risk line, dense/light word budgets, and the `Total budget:` line); this file keeps no template copy to avoid template drift. Legacy projects with `Core event / plot-point sequence / target emotion / opening hook / payoff / chapter-end hook / target words` may still run daily updates without blocking; new builds, backfills, and completions follow the authoritative template; unknown fields get `[to be determined]`; never fabricate sub-lines or relationships just to fill fields. Contract/progression fields only go on the chapter-outline summary level; long rules uniformly defer to `reader-contract-and-progression.md`.

---

## tracking/foreshadowing.md

**Status meanings**: `unplanted` = planned but not yet planted; `planted` = planted and still open, the normal long-form state; `collected` = closed; `expired` = missed the expected collection window, needs `/story-review` or explicit repair. The SessionStart hook should not alarm solely on `unplanted`, `planted`, or `collected`. The daily flow only handles this round's new/advanced/collected foreshadowing; full foreshadowing audits are triggered only by `/story-review` or an explicit user request.

```markdown
# Foreshadowing Tracking

## Foreshadowing state table

| ID | Content | Planted chapter | Expected collection | Status{unplanted/planted/collected/expired} | Importance{high/mid/low} |
|----|---------|---------|-------------|-----------------------------|----------------|
| F001 | {content} | Chapter {N} | Chapter {N} | {status} | {level} |

## Collection log
| Chapter | Foreshadowing ID collected | Method{reveal/reversal/echo} | Effect |
|------|-------------|-------------------------|------|

## Expired foreshadowing
| ID | Reason | Handling{collect late/abandon/convert to long line} |
|----|------|--------------------------|
```

Creation reference: `plot-core-methods.md` (continuity tracking & rhythm management)

---

## tracking/timeline.md

```markdown
# Story Timeline

## Time scale
- Main timeline: {the calendar/timekeeping the story uses}
- Opening time: {start point}
- Current time: {the time point of the latest chapter}

## Key event order

| Chapter | Story time | Event | Characters involved | Relation to main line |
|------|---------|------|---------|-----------|
| Chapter {N} | {time} | {event} | {characters} | {main line/sub-line X} |

## Parallel-line time comparison (for multi-line narration)
| Time point | Line A event | Line B event | Intersection |
|--------|--------|--------|-------|

## To be confirmed (timeline doubts)
| Chapter | Question | Handling status |
|------|------|---------|
```

Creation reference: `plot-core-methods.md` (continuity tracking & rhythm management)

---

## tracking/character-state.md

Character state snapshots; Phase 3 creates the initial state after the outline is complete, Phase 4 updates on demand after each chapter.

Template fields, snapshot format, and update rules uniformly live in `state-tracking.md` "character state snapshot format"; not duplicated inline here.
