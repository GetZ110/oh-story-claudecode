---
name: output-contract
description: |
  story-short-analyze output contract. Defines the Stage → file mapping, the _meta.json schema,
  and downstream consumption rules (story-short-write reads the full set of markdown + source +
  _meta.json to write new short fiction).
sync-policy: |
  This file must stay byte-equal (identical bytes) between story-short-analyze and story-short-write.
  After editing either copy, you must sync the other copy and verify with
  bash scripts/check-shared-files.sh.
  Do not add this file to the IGNORE_NAMES list — it must stay in sync; it is not an intentional difference.
---

# Output Contract: story-short-analyze ↔ story-short-write

After `story-short-analyze` tears down a short story, the artifacts land in `teardown-lib/{Book Title}/`. When `story-short-write` writes the next story in the same genre, it reads **all** the outputs in that directory at once.

---

## Output directory and file tree

```
teardown-lib/{Book Title}/
├── source/                  # pipeline pre-step output; backup of the source file
├── teardown-report.md       # human-readable combined report (Stages 2-6 combined)
├── plot-nodes.md            # Stage 2 plot-node list
├── craft-methods.md         # Stage 4 writing-craft analysis
└── _meta.json               # pipeline metadata + structure counts (resume + acceptance numbers)
```

**Filename conventions**: `teardown-report.md / plot-nodes.md / craft-methods.md` are hardcoded consumers of `story-short-write`; they must not be renamed. Analysis narrative goes in markdown; numbers/enums go in `_meta.json.structure_counts`.

---

## Stage → file mapping

| Stage | Name | Landing files | Main content |
|-------|------|---------------|--------------|
| 2 | Structure + plot nodes | `teardown-report.md` (story core/structure/summary sections) + `plot-nodes.md` | story core / 4-6 segment structure / story summary / plot-node list |
| 3 | Emotional line + eruption points | `teardown-report.md` (emotion-curve + eruption-point sections) | emotion curve ≥5 nodes / eruption 6 dimensions / anticipation |
| 4 | Reversal + writing craft | `teardown-report.md` (reversal section) + `craft-methods.md` | pre-reversal check / reversal analysis (setup clues ≥2) / craft ≥5 items |
| 5 | Characters + opening/ending | `teardown-report.md` (characters + opening/ending sections) | character classification + function assessment / opening analysis / ending analysis / opening-ending echo |
| 6 | Combined assessment | `teardown-report.md` (combined section) + `_meta.json` (write structure_counts) | five-dimension score / eruption potential / topicality / resonance ≥3 layers / reusable structures ≥3 / rhythm briefing |

---

## `_meta.json` schema

`_meta.json` is pipeline metadata + structure counts. **No analysis content** — only numbers and enums, for acceptance completeness checks. The analysis narrative all lives in `teardown-report.md`.

```jsonc
{
  "version": "2.0",
  "word_count": 5234,                   // source word count (filled by the Phase 1 probe)
  "genre_detected": "enemies-to-lovers", // Phase 1 genre recognition; fill "general" when unrecognized
  "created_at": "{ISO8601 timestamp}",    // teardown start time; fill current UTC when writing
  "stages_completed": [2, 3, 4, 5],      // completed stages, appended in completion order
  "last_stage_in_progress": null,        // the stage currently executing; null when idle

  "structure_counts": {                 // written once at Stage 6 completion; basis for the structure_counts numeric validation
    "beats": 5,                         // number of structure segments (structure split: opening/development/climax/ending, Stage 2)
    "hooks": 4,                         // number of hooks (Stage 3)
    "setup_clues": 3,                   // number of reversal setup clues (Stage 4)
    "character_archetypes": 3,          // number of characters with contrast (Stage 5)
    "reusable_structures": 3,           // number of reusable craft items (Stage 6)
    "reversal_type": "perspective"      // reversal-type enum (perspective/identity/motivation/timeline/information/perception/none); sweet/comedy/karmic-justice stories fill "none"
  }
}
```

### Write order (crash safety)

1. **Before Stage N starts**: `last_stage_in_progress = N`, write to disk.
2. **After Stage N files are written**: non-empty + minimum-length sanity check (e.g., the new `teardown-report.md` section ≥ 200 words).
3. **Pass**: clear `last_stage_in_progress`, append `N` to `stages_completed[]`.
4. **Fail**: `stages_completed` untouched, `last_stage_in_progress` stays `N`.
5. **Extra action at Stage 6 completion**: compute `structure_counts` in one go and write it into `_meta.json`, then enter acceptance.

### Resume protocol

- `last_stage_in_progress` non-empty → that stage was interrupted last time; **re-run it from scratch** (don't reuse half-written files).
- `last_stage_in_progress` empty → start from `max(stages_completed) + 1`.
- `stages_completed` contains 6 → already done; ask the user to overwrite or cancel.

**Stage 6 = content written AND acceptance passed.** Until acceptance passes, `last_stage_in_progress` stays `6` and `stages_completed` has no `6`; on resume the body/structure_counts are already on disk — only re-run the acceptance checks, don't rewrite the Stage 6 body.

---

## Acceptance entry points

After the Stage 6 content is written, before appending `stages_completed[6]`, run three checks:

### Step 1: teardown-report AI-flavor self-check

Scan the full text of `teardown-report.md` against the banned-word list and report-AI-flavor rules loaded locally by the teardown flow. This is the teardown report's quality gate; the finished-prose de-AI rules are maintained by the writing flow inside its own skill — don't read reference files across skills and don't mix the two rule sets.
Hit → don't write `stages_completed[6]`; list the locations and ask the user to fix the AI flavor of **the teardown report itself** (AI flavor in the source doesn't count — this scans the report the analyst wrote).

### Step 2: `_meta.json.structure_counts` numeric validation

| Field | Minimum | If below |
|-------|---------|----------|
| `structure_counts.beats` | ≥ 4 (structure segments: opening/development/climax/ending) | block |
| `structure_counts.hooks` | ≥ 3 | block |
| `structure_counts.setup_clues` | ≥ 3 (skip this row when reversal_type=none) | block |
| `structure_counts.character_archetypes` | ≥ 2 | block |
| `structure_counts.reusable_structures` | ≥ 3 | block |
| `structure_counts.reversal_type` | within the enum (incl. "none") | block |
| `genre_detected` | non-empty | block |

> Plot-node count (15-60 by the word-count tier) goes through `plot-nodes.md`'s own density validation (see material-decomposition.md), not this table. `beats` is the structure-segment count, not the plot-node count.

### Step 3: `story-short-analyze` BLOCK item scan

Scan the output templates loaded locally by the teardown flow and confirm every `[BLOCK]`-labeled item's output section appears in `teardown-report.md`.
Any missing → block. `[WARN]` items → write into the "to-do" list at the end of the teardown report; don't block.

### Step 4: Pass

Clear `_meta.json.last_stage_in_progress`, append `6` to `stages_completed[]`, and tell the user "teardown complete — run `/story-short-write` to write the next story".

---

## Downstream consumption rules (how story-short-write uses this)

> `story-short-write` currently hardcodes reading the three markdown files `teardown-report.md / plot-nodes.md / craft-methods.md`.
> `_meta.json` is an optional enhancement: reads tolerate it; if it's absent, writing isn't blocked.

| File | Role | How to read |
|------|------|-------------|
| `_meta.json` (optional) | numeric facade + genre recognition | check `genre_detected` to pick the genre yardstick; read `structure_counts` to confirm teardown completeness; read `structure_counts.reversal_type` to pick the reversal skeleton |
| `teardown-report.md` | analysis narrative body | read the "story core", "structure", "emotion curve", "eruption points", "reversal analysis", "characters", "five-dimension score", "resonance analysis", "reusable structures", "same-type writing actions" sections — the writer's primary input |
| `plot-nodes.md` | rhythm anchors | look at each node's word-count position + function + triggering event; schedule the new story's rhythm off them |
| `craft-methods.md` | craft library | POV / dialogue / time / info control etc. with source examples; reuse in the new piece |
| `source/` | voice source | copy the dialogue register, rhythm, imagery, and comeuppance tension. **Don't copy the specific plot** — copy the craft. |

### Writing-flow suggestions

1. Look at `_meta.json.genre_detected` and `structure_counts.reversal_type` to pick the skeleton.
2. Read the "core craft", "resonance analysis", "reusable structures" sections of `teardown-report.md` to decide what to keep / adjust.
3. Read `plot-nodes.md` to copy the rhythm anchors onto the new story's word-count positions.
4. When writing scenes, consult `craft-methods.md` + `source/` for concrete craft.
5. After writing, optionally write `derived_from: teardown-lib/{Book Title}/` in the new document's frontmatter for traceability.

### Maintainer smoke test

```bash
ls teardown-lib/{Book Title}/   # should contain: source/ teardown-report.md plot-nodes.md craft-methods.md _meta.json
/story-short-write teardown-lib/{Book Title}/
# pass: outputs a 4000+ word new short story in the same genre, with the source's dialogue register and imagery
# fail: reads like fill-in-the-blanks / or short-write can't find the three markdown files
```

---

## Version conventions

- `_meta.json.version` is coupled to this file's `sync-policy`.
- A breaking change (field rename / type change / required change) must bump the major version and sync both copies; CI intercepts one-sided edits via `scripts/check-shared-files.sh`.
- An additive change (new optional field) may bump minor; producer, consumer, and both copies must upgrade to the current schema in the same change.
