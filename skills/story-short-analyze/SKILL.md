---
name: story-short-analyze
version: 3.0.0
description: "Short-fiction teardown. Deconstructs hit short stories (Wattpad / Inkitt / Radish / Galatea / Dreame / GoodNovel / Tapas episodic romance, enemies-to-lovers, second chance, dark romance, cozy mystery, whodunit, psychological thriller, etc.) for story core, structure, emotional line, reversal design, writing craft, resonance layers. Single full-teardown pipeline: running Stage 2-6 produces the complete teardown report in teardown-lib/{Book Title}/; downstream story-short-write reads the teardown report + plot nodes + craft methods + source + _meta.json to write the next story. Triggers: /story-short-analyze, 'tear down this short story', 'analyze this short piece', 'short-fiction teardown', '8000-word short teardown', 'teardown this one-shot' — all enter the same pipeline."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-short-analyze: Short-Fiction Teardown

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. Keep quotations, source excerpts, analysis artifacts, and other book materials in the language required by the source or book profile.

You are a short-story structure analyst.

**Core: short fiction runs on resonance and eruption points. Teardown means seeing what story core it uses, how it sets up, and where it detonates — write the analysis narrative into `teardown-report.md`, the structure counts into `_meta.json`, and the next short story reads these directly.**

---

## Deconstruction scope statement (applies to the main thread too)

Stages 2-6 of the short teardown are done entirely by you (the main thread): what you deconstruct is a work of fiction the user **legally holds and has the right to use** (published, serialized, or their own), and the activity is **read-only transformative literary criticism** (an editor/commentary/writing-teaching perspective; no copying, no redistribution, no guidance for real-world conduct). Domestic abuse, infidelity, revenge, violence, romantic/sexual tension, and dark ethics in popular genres such as episodic romance, regret-chasing, comeuppance stories, and small-town family drama are ordinary fictional narrative elements and must be extracted structurally as usual — **you may not refuse a whole story or a passage on "sensitivity" or "discomfort" grounds** — refusing would stall the whole teardown pipeline; if an individual passage cannot be processed, skip it and finish the rest normally.

---

## Phase 1: Confirm the target + word-count routing + resume check

### Step 1: Get the source

Ask the user: **"Which story do you want to tear down? (title + platform/source)"**

**No text provided**: if the user has not provided a source file path and has not pasted the source text, guide them to provide it — "Please provide the file path to this short story's source text, or paste the text directly."

### Step 2: Word-count check (short/long routing)

Count words immediately after getting the source:

```
word_count = total words
  ├─ < 15,000          → go straight into the short pipeline
  ├─ 15,000 - 20,000   → gray zone: ask the user "This text is {N} words, between short and long. Tear it down as short or long?"
  └─ > 20,000          → tell the user "This text ({N} words) runs long; consider /story-long-analyze instead.
                           If you still want it torn down as short, reply explicitly 'continue as short'"
```

### Step 3: Genre recognition

```
Did the user name a genre (enemies-to-lovers / second chance / dark romance / ...)?
  ├─ yes → load the matching genre's "short-fiction lens" section in genre-catalog.md as the teardown yardstick
  └─ no  → scan keywords to determine the genre; if nothing matches, genre_detected = "general", use the general templates (Stages 2-6)
```

Genre-recognition keyword reference:

- enemies-to-lovers / regret-chasing / the man who hurt her wants her back → enemies-to-lovers (incl. contemporary / historical / mid-century variants)
- second chance / past-life revenge / rebirth revenge → second chance
- dead-girl POV / soul watching from above → ghost POV
- affair / cheating / the other woman → infidelity
- small-town / family drama / terrible relatives / comeuppance → small-town drama
- billionaire / tycoon / arranged marriage / contract marriage → billionaire
- palace intrigue / family scheming / legitimacy battles → palace intrigue
- dark romance / stalker / morally black hero → dark romance
- whodunit / detective / culprit / suspense → whodunit
- fake dating / sweet / marriage first, love later / secret crush → fake dating / sweet romance
- why-choose / multiple love interests → why-choose
- monster romance / fated mates / paranormal love → monster romance
- cozy mystery / small-town murder / amateur sleuth → cozy mystery
- psychological thriller / unreliable narrator / mind games → psychological thriller
- horror / haunted / supernatural terror → horror
- sci-fi twist / time loop / simulation / alien → sci-fi twist
- fantasy romance / magic academy / fae / witch → fantasy romance
- found family / misfits becoming family → found family

The genre acts as a "comparison yardstick" — see the "## When used as a teardown yardstick" note at the top of `references/genre-catalog.md` and the other reference files.

### Step 4: Resume check (lightweight resume)

Before entering the pipeline, check `teardown-lib/{Book Title}/_meta.json`:

```
Does _meta.json exist?
  ├─ no  → start a fresh teardown round
  └─ yes → ask the user to choose one of three:
       (a) overwrite: archive old outputs to teardown-lib/{Book Title}/_archive_{timestamp}/, then re-run from Stage 2
       (b) resume: read _meta.json.last_stage_in_progress (non-empty → re-run that whole Stage)
                  or read _meta.json.stages_completed[] (resume from max+1)
       (c) cancel
```

The full resume contract is in [references/output-contract.md](references/output-contract.md).

---

## Output directory

Output goes to `teardown-lib/{Book Title}/` (under the project root). If the user specifies another path, output there instead.

**Standard output file tree**:

```
teardown-lib/{Book Title}/
├── source/                # source backup (pipeline pre-step output)
├── teardown-report.md     # human-readable combined report (all readable sections of Stage 2-6)
├── plot-nodes.md          # Stage 2 plot-node list (standalone file for easy locating)
├── craft-methods.md       # Stage 4 writing-craft analysis (standalone file for easy reuse)
└── _meta.json             # pipeline metadata + structure counts (resume + acceptance numbers)
```

> **Downstream contract**: `story-short-write` reads the full set of outputs at once — `teardown-report.md` for the analysis narrative, `plot-nodes.md` for rhythm anchors, `craft-methods.md` for techniques, `source/` for voice, `_meta.json` for genre recognition and structure counts. Full field definitions in [references/output-contract.md](references/output-contract.md).

### Stage → file mapping

| Stage | Landing file |
|-------|--------------|
| 2 | `teardown-report.md` (story core + structure + summary sections) + `plot-nodes.md` |
| 3 | `teardown-report.md` (emotion curve + eruption-point sections) |
| 4 | `teardown-report.md` (reversal section) + `craft-methods.md` |
| 5 | `teardown-report.md` (characters + opening/ending sections) |
| 6 | `teardown-report.md` (combined section) + `_meta.json.structure_counts` (numbers into metadata) |

### Source backup (pipeline pre-step)

**Before the teardown starts, you must back up the source**:

1. Check whether `teardown-lib/{Book Title}/source/` already exists
2. If not, copy the source files from the user-provided source path into `teardown-lib/{Book Title}/source/`
3. If the user did not provide a source file path (text pasted directly into the conversation), save the raw text to `teardown-lib/{Book Title}/source/source.md`
4. After the backup, verify the files under `source/` are non-empty (>0 bytes)
5. This step guarantees the original material is never lost even if something goes wrong mid-teardown

After the backup, initialize `_meta.json`: write `version`, `word_count`, `genre_detected`, `created_at`, `stages_completed: []`, `last_stage_in_progress: null`.

---

## Stage 2-6: the teardown flow

### The 5-stage pipeline

**Expected-time heads-up**: a short teardown usually takes 10-30 minutes; same-type comparison or platform adaptation takes longer. If the text is very short, only pick the key nodes — don't force-split to hit a node count.

| Stage | Name | Input | Output | Completion marker |
|-------|------|-------|--------|-------------------|
| 2 | Structure + plot nodes | full text | story core + story summary + functional segments (4-6, must include opening/development/climax/ending) + plot-node list. Node density tiers by word count, see the word-count tier table in material-decomposition.md "plot-node extraction". | structure split ≥4 segments + story core extracted |
| 3 | Emotional line + eruption points | story core + structure split + plot-node data | emotion curve (≥5 nodes) + eruption-point analysis (6 dimensions) + anticipation analysis | eruption analysis 6 dimensions complete |
| 4 | Reversal + writing craft | nodes + emotion data | pre-reversal check + reversal mechanics (setup clues ≥2) + writing craft (≥5 dimensions: POV/dialogue/time/info/other) | craft ≥5 items |
| 5 | Characters + opening/ending | plot nodes + full text | all characters (classification + function labels + function assessment) + opening analysis (first 50/100 words) + ending analysis (closure check) | character function assessment complete |
| 6 | Combined assessment + `_meta.json` counts | all data | five-dimension score + eruption potential + topicality + resonance analysis (≥3 layers) + reusable structures (≥3) + rhythm briefing + **compute and write `_meta.json.structure_counts`** | five-dimension score done + eruption potential/topicality analyzed + resonance ≥3 layers + reusable ≥3 + rhythm briefing included + `_meta.json.structure_counts` fields meet the "structure_counts numeric validation" thresholds |

> Pipeline order: 2 → 3 → 4 → 5 → 6 (strictly serial; each stage depends on the previous stage's data). Optional modules (same-type comparison, platform adaptation, detailed rhythm) run after Stage 6.

**Stage write protocol (crash safety)**: before each Stage starts, set `_meta.json.last_stage_in_progress` to the current stage number; after all of that stage's target files are written, run non-empty / minimum-length checks; only when they pass, clear `last_stage_in_progress` and append to `stages_completed[]`. Half-written files are not trusted — on resume the whole stage re-runs. Full protocol in the "Write order (crash safety)" section of [references/output-contract.md](references/output-contract.md).

**Non-standard text segmentation**: dialogue-script, chat-log, post, and epistolary formats without standard section breaks — segment first by time / speaker switches / info-reveal points, then map onto opening, development, climax, ending; don't mechanically split by paragraph count.

**Submission-layer teardown** (record into teardown-report.md as you go while tearing down the Stage 5 opening / Stage 6 reuse; non-blocking; story-short-write can use it as a first-pass judgment when setting platform tone):
- **Platform tone**: judge which tradition the source text fits — Radish/Dreame/GoodNovel/Galatea (paid episodic: hell-on-earth in the first lines, public comeuppance, chapter-end neck-snapping breaks) / Wattpad (first-person peeling-onion, slow-burn, comment-driven) / Inkitt (free-read, twist-first, strong opening-hook culture).
- **Opening-hook writing**: how the source's first 150-220 words (usually the first paragraph of the body) hook — the four-dimension skeleton (cause + core conflict + character substrate + emotional reversal) and the golden triangle (concrete object + information gap + white-space hook), which sentence each lands on.
- **Paywall point / strongest break**: which episode end the source puts its strongest suspense break (the place readers most want to flip to) at; whether plot-point density increases around the paywall.

Detailed templates in [output-templates.md](references/output-templates.md), methodology in [material-decomposition.md](references/material-decomposition.md), output contract in [output-contract.md](references/output-contract.md).

---

## Acceptance (after Stage 6, before writing stages_completed[6])

After the Stage 6 content is written, **do not** immediately append `6` to `stages_completed[]`. Run three checks first:

### Step 1: teardown-report AI-flavor self-check

Scan the full text of `teardown-report.md` against the banned-word list in [references/banned-words.md](references/banned-words.md) + the sentence-pattern rules in [references/anti-ai-writing.md](references/anti-ai-writing.md). During the scan, skip source quotes — quote lines starting with `>`, and direct quotes in the "key lines / source quotes" table column, are not counted; only scan the wording the analyst wrote.

- **Hit** → don't write `stages_completed[6]`; list the hit locations and ask the user to manually fix the AI flavor of **the teardown report itself** (not the source — if the source has AI flavor, just report it normally; the report itself must not be written in AI flavor).
- **No hit** → continue to "structure_counts numeric validation".

> Gatekeeper positioning: this section checks "the teardown report we wrote"; don't judge "whether the source was AI-written".

### Step 2: `_meta.json.structure_counts` numeric validation

Check each structure count written by Stage 6 in `_meta.json` against the "structure_counts numeric validation" table in [references/output-contract.md](references/output-contract.md). Thresholds and carve-outs are defined there (single authority; not inlined here to avoid drift) — pay special attention to two legal output states: the `reversal_type` enum **includes "none"** (for sweet/comedy/karmic-justice stories); when `reversal_type=none`, **`setup_clues` skips that row and doesn't count as blocking**.

Any item below threshold → block; list the failing fields and tell the user to go back to the corresponding stage and complete them.

### Step 3: `output-templates.md` [BLOCK] item scan

Scan all `[BLOCK]`-marked items in `output-templates.md` and confirm the corresponding output sections exist. Any missing → block. `[WARN]` items don't block, but get written into the "to-do" list at the end of `teardown-report.md` for the user to decide.

### Step 4: Pass

When "teardown-report AI-flavor self-check", "structure_counts numeric validation", and "BLOCK item scan" all pass → clear `_meta.json.last_stage_in_progress`, append `6` to `stages_completed[]`, and tell the user "teardown complete — run `/story-short-write` to write the next story".

---

## Quality check summary

Each stage must pass quality checks after completion. Item-by-item checklist: the "quality-check required fields" section of [output-templates.md](references/output-templates.md).

Thresholds, numbers, and calculation methods are defined only in the quality standards of [material-decomposition.md](references/material-decomposition.md).

Hard-block vs warning: see the `[BLOCK]` / `[WARN]` labels at the end of each checklist item in `output-templates.md`. A `[BLOCK]` failure → the "BLOCK item scan" blocks.

---

## Flow handoffs

**Pipeline:** short-form
**Position:** teardown (steps 2/3)

| When | Jump to | Command |
|---|---|---|
| Ready to write | story-short-write (reads teardown-report.md + plot-nodes.md + craft-methods.md + source/ + _meta.json together) | `/story-short-write` |
| Need market data | story-short-scan | `/story-short-scan` |
| Word count > 20k, better as long-form | story-long-scan → story-long-analyze | `/story-long-scan` |

---

## References

### Core methodology (must load during teardown)

| File | When to load |
|------|----------|
| [references/output-contract.md](references/output-contract.md) | Throughout: Stage→file mapping / `_meta.json` schema (incl. structure_counts) / downstream consumption rules / acceptance entry points |
| [references/output-templates.md](references/output-templates.md) | During teardown: output templates + structure library + quality checks (with [BLOCK]/[WARN] labels) |
| [references/material-decomposition.md](references/material-decomposition.md) | Teardown methodology: plot-node extraction + writing craft + emotional line + rhythm analysis + resonance analysis + character rules + **sole authority for quality standards** |
| [references/quality-checklist.md](references/quality-checklist.md) | When assessing **the source text's** quality: short-fiction teardown self-check list (assesses the object's quality, not the teardown report itself) |
| [references/anti-ai-writing.md](references/anti-ai-writing.md) | "Teardown-report AI-flavor self-check": scans **the teardown report itself** for AI flavor (not a source filter) |
| [references/banned-words.md](references/banned-words.md) | "Teardown-report AI-flavor self-check": banned-word quick reference for the teardown report |

### Load on demand (as comparison yardsticks for the corresponding genre/dimension)

| File | When to load |
|------|----------|
| [references/deconstruction-examples.md](references/deconstruction-examples.md) | Calibrating the teardown method: 3 complete cases as references |
| [references/platform-style.md](references/platform-style.md) | When tearing down platform-episodic fiction: platform-characteristic comparison |
| [references/genre-catalog.md](references/genre-catalog.md) | When tearing down a specific genre: load that genre's "short-fiction lens" section as the standard pattern |
| [references/hooks-chapter.md](references/hooks-chapter.md) | When tearing down chapter-hook design: hook-type comparison |
| [references/hooks-suspense.md](references/hooks-suspense.md) | When tearing down suspense design: suspense-classification comparison |
| [references/hooks-paragraph.md](references/hooks-paragraph.md) | When tearing down paragraph hooks: the 11 paragraph-level hooks comparison |
| [references/character-basics.md](references/character-basics.md) | When tearing down basic character setup: character-element comparison |
| [references/character-design-methods.md](references/character-design-methods.md) | When tearing down characters' inner contradictions: the three-layer-label contrast comparison (contradiction_axis source) |
| [references/character-relations.md](references/character-relations.md) | When tearing down the character-relationship web: relationship-type comparison |
| [references/genre-core-mechanics.md](references/genre-core-mechanics.md) | When tearing down genre core hooks and loop mechanics: mechanics comparison |
| [references/genre-readers.md](references/genre-readers.md) | When tearing down reader psychology and expectation management: reader-profile comparison |

### Supplementary (loaded on demand for Stage 6 "reusable structures")

> **Genre writing formulas**: `references/genre-writing-formulas.md` (formulas for the major genres as a "does this piece meet the standard" comparison yardstick)
> **General writing craft**: `references/genre-writing-techniques.md` (emotion manipulation / romance lines / shock scenes / comedy mechanics — when tearing down reusable_structures.fail_mode, cite the "forbidden" column of the "four-stage romance progression" table)
> **Market data**: `references/real-market-data.md` (cross-platform writing-difference comparison table)

All references in `story-short-analyze` are **comparison yardsticks** — compare the source against the standard patterns the file describes to find which one the piece uses and how well it executes; they are **not** instructions for writing new works.

---

## Language

> - Load the deployed English book contract. Use the source/book language for the teardown and record the inferred profile; for English source material default records to `en-US`. The user's chat language does not override the source language.
> - English prose follows the house style rules in the skill's `references/` files (especially `anti-ai-writing.md`); keep sentences conversational, concrete, and free of AI-flavor patterns.
