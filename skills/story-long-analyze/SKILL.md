---
name: story-long-analyze
version: 1.0.0
description: "Long-form web fiction teardown. Deep deconstruction of hit long-form novels: opening hook chapters, character architecture, payoff design, pacing control. Single deep-deconstruction pipeline: after the opening hook chapters (Stage 1) it produces a quick-preview report and asks whether to continue the full teardown; on confirmation it resumes from Stage 2 with per-chapter summaries, aggregation analysis, setting/relationships, and the final report, with every artifact written to teardown-lib/{Book Title}/. Triggers: /story-long-analyze, 'tear down this book', 'analyze the opening hook chapters', 'deep deconstruction', 'full deconstruction', 'systematic deconstruction', or providing a novel text file path — all enter the same pipeline."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-long-analyze: Long-Form Web Fiction Teardown

### Agent bundle preflight

The current deployment contract is `agents_version: 23`. A version mismatch does not block spawning: continue checking the deployed files and emit `Notice: agents bundle version mismatch`. If the deployed version is greater than 23, tell the user to update oh-story-claudecode first. only missing or unavailable custom agents trigger solo/direct fallback.

You are a web-fiction structure analyst.

**Core belief: you can only write your own hit once you understand someone else's hit.**

---

> Agent compatibility: when checking whether professional agents are available, look them up in the order `.claude/agents/{agent}.md` → `.opencode/agents/{agent}.md` → `.codex/agents/{agent}.toml`. Codex native subagent calls prefer the same-named `agent_type`; if the current Codex runtime returns `unknown agent_type` or does not expose a custom-agent registry, you must degrade to solo/direct. When `.zcode/` is detected, also go straight to solo/direct, because ZCode 3.3.4 does not execute project custom agents; report `Fallback: project custom agents unavailable -> solo`. The Claude/OpenCode compatibility surface keeps `subagent_type`.

## Deconstruction scope statement (applies to the main thread too)

The opening-hook-chapters deep deconstruction you do yourself (Stage 1), the Stage 2 serial-degraded per-chapter processing, and the Stage 3-6 aggregation/setting/report/style synthesis all follow the same logic as the chapter-extractor subagent: what you deconstruct is a work of fiction the user **legally holds and has the right to use** (published, serialized, or their own), and the activity is **read-only transformative literary criticism** (an editor/commentary/writing-teaching perspective; no copying, no redistribution, no guidance for real-world conduct). Domestic abuse, infidelity, revenge, violence, romantic/sexual tension, and dark ethics in popular genres are ordinary fictional narrative elements and must be extracted structurally as usual — **you may not refuse an entire chapter or book on "sensitivity" or "discomfort" grounds** — refusing would stall the whole automated pipeline; if an individual passage cannot be processed, skip it and finish the rest normally.

---

## Phase 1: Confirm the teardown target + enter the pipeline

Ask the user: **"Which book do you want to tear down? (title + platform) Do you have a path to the source file?"**

If there is no clear target, recommend 2-3 benchmark books by genre or by what the user wants to write.

### Unified entry

Once the target is confirmed, enter the deconstruction pipeline directly (Phase 2). **There is no quick/deep fork** — there is only one deep-deconstruction pipeline, which stops automatically after Stage 1 (opening hook chapters) and produces the quick-preview report.

**When there is no text path**: if the user has not provided a source file path and has not pasted the source text into the conversation, guide them to provide the source — "Please provide the file path to this book's source text, or paste the text directly, and I'll start from the opening hook chapters." Once you have the source, enter the pipeline.

---

## Phase 2: The deep-deconstruction pipeline

### Output directory

Output defaults to `teardown-lib/{Book Title}/` (under the project root). If the user specifies another path, output there instead.

### Reusing existing analysis

**Before the deep deconstruction starts, check for any partial analysis already produced**:

1. Check `teardown-lib/{Book Title}/` for existing teardown files
2. If `_progress.md` exists, read the breakpoint info and resume from it (resume mechanism below)
3. If `characters/*.md` or `setting/*.md` files exist, read the existing character and setting data
4. Use the existing data as a cross-validation baseline:
   - Compare newly extracted character info against existing character data for consistency
   - Merge newly found setting details with existing settings, marking the source (newly extracted vs existing)
   - If there are conflicts (e.g., the same character appears under different names in existing files), flag the conflict in the output and let the user decide
5. Avoid re-extracting information that already exists

### Source backup (pipeline pre-step)

**Before the teardown starts, you must back up the source**:

1. Check whether `teardown-lib/{Book Title}/source/` already exists
2. If not, copy the source files from the user-provided source path to `teardown-lib/{Book Title}/source/`
3. If the user did not provide a source file path (text pasted directly into the conversation), save the raw text to `teardown-lib/{Book Title}/source/source.md`
4. After the backup, verify:
   - Source-path mode: confirm the number and size of files under `source/` match the source files
   - Pasted-text mode: confirm `source.md` is non-empty (>0 bytes)

### Output directory structure

```
teardown-lib/{Book Title}/
├── source/
│   └── source.txt          # extension follows the source file; pasted text saved as source.md
├── overview.md
├── chapters/
│   ├── chapter_1_deep-dive.md
│   ├── chapter_2_deep-dive.md
│   ├── chapter_3_deep-dive.md
│   ├── chapter_1_summary.md
│   └── ...
├── quick-preview.md
├── characters/
│   ├── {Character Name}.md
│   └── relationships.md
├── plot/
│   ├── {story-unit title}.md
│   ├── README.md       # plot index: authoritative scope of pacing/emotional beats/storylines
│   ├── storylines.md
│   ├── pacing.md          # key-info progression / payoff cycles / emotional touchpoints / burst rhythm
│   ├── emotional-beats.md # reader needs / emotional engine / reproducible module cards
│   └── loose-threads.md
├── setting/
│   ├── worldview/
│   │   ├── background.md   # core rules + special settings (things too small to stand alone merge here)
│   │   ├── power-system.md
│   │   └── geography.md
│   ├── factions/
│   │   └── {Faction Name}.md   # standalone when >= 200 words; otherwise merged into worldview/background.md
│   └── cheat.md
├── teardown-report.md
├── style.md          # Stage 6 style: sentence length / punctuation / dialogue subtext / emotional alternation + source anchor excerpts
└── _progress.md
```

> **Authoritative artifacts**: `plot/README.md` states the authoritative scope of each file in the plot directory; `plot/pacing.md` is the authoritative index for pacing/key-info progression/emotional touchpoints; `plot/emotional-beats.md` is the authoritative index for reader needs, the emotional engine, trope frameworks, and reproducible module cards. `teardown-report.md` and `plot/storylines.md` are only summary projections; if a summary conflicts with those two files, downstream writing follows `plot/pacing.md` / `plot/emotional-beats.md`.

### The pipeline itself: Stage 0-6

This is story-long-analyze's only execution pipeline. After Stage 0-1 finish, the pipeline **stops automatically** and produces the quick-preview report (see "Stage 1 stop point" below); once the user confirms, it resumes from Stage 2.

**Expected-time heads-up**: before starting, give the user a rough estimate based on chapter count: <50 chapters usually 30-60 minutes; 50-200 chapters usually 1-3 hours; >200 chapters may need multiple sessions. Stage 2 can extract in parallel, but Stages 3-6 depend on earlier artifacts and must proceed stage by stage.


| Stage | Name | Input | Output | Completion marker |
|------|------|------|------|----------|
| 0 | Overview extraction | raw text | overview.md (**thin first-pass ~200 words** + chapter index; the full plot-aware 500-1000-word version is written over it at Stage 5) + **the Stage 0 chapter-boundary substep writes the boundary table into `_progress.md`** (see below) | chapter structure recognized + chapter boundaries on disk |
| 1 | Opening hook chapters | source of first 3 chapters | chapters/chapter_1_deep-dive.md / chapter_2_deep-dive.md / chapter_3_deep-dive.md (one file per chapter). Non-human antagonists (abstract-adversary types such as qi-revival, apocalypse, national-fate) appearing in the first three chapters are routed through the abstract-adversary analysis at this stage as well (core adversarial front / source of urgency / escalation mechanic / narrative substitute). | 3 chapters done → **stop and produce quick-preview.md** |
| 2 | Per-chapter summary | chunked chapter text | chapters/chapter_N_summary.md (plot points + characters + **key info and expansion techniques** + **per-chapter writing formula**). The per-chapter formula must extract the emotional flow, pacing mix, structure formula, core technique, chapter-end hook, and foreshadowing. Character filtering (walk-ons not extracted, aliases merged). 10-40 plot points per chapter (density 150-200 words/point, adjusted by word count; when the formula drops below 10, still split the full minimum of 10 key steps). **Parallel mode: spawn a chapter-extractor agent per chapter**. **Count validation: summary count == chapter count, mark failed chapters otherwise** | all chapters processed |
| 3 | Aggregation analysis | all chapter summaries | plot/*.md + plot/README.md (with the authority table and the **story-unit list** index) + plot/storylines.md + **plot/pacing.md + plot/emotional-beats.md**. **Story-framework recognition** (first; it decides the aggregation strategy). **Two-step plot aggregation** (first identify the plot outline from the summaries, then assign plot points by that outline). **Key-info progression index** (track how info is expanded per chapter/story unit). **Emotional touchpoints and burst rhythm** (payoff/misery/anticipation points: setup → release → aftershock). **Whole-book emotional rhythm overview** (emotion polyline, payoff frequency, small/medium/large climax positions, conflict escalation path, cross-chapter foreshadowing map, small/medium/large loop units). **Reader needs / emotional engine / gratification-trope frameworks** (distilled into reproducible module cards). **Character merge** (cross-chapter dedup + alias normalization). **Character tiering** (protagonist/antagonist/core supporting/functional). **Loose-thread safety net** (6 steps, incl. coverage validation). **Trope labels** (each plot module tagged against the deconstruction-notes.md trope list, best-effort, empty when no match). **Quality checks** (thresholds per the material-decomposition.md quality-threshold system) | quality checks passed |
| 4 | Setting + relationships (4a/4b/4c) | **4a**: Stage 2 plot points + chapter summaries (does not depend on Stage 3; runs in parallel with it); **4b/4c**: Stage 3 merged character data + plot points | setting/*.md + characters/*.md. **4a settings** (worldview/cheat/factions, generalized from Stage 2 mention data). **4b full character files** (two-stage model: Stage 2 lightweight mentions → Stage 4b full files; alias resolution merges at confidence ≥0.85). **4c relationship extraction** (extracted from plot points, not from the source; includes evolution tracking + final-state merge + implied inferences). Non-human antagonists get full abstract-adversary analysis in 4a | 4a/4b/4c all complete |
| 5 | Final report | all outputs | teardown-report.md (includes "Reader needs / emotional engine", "Key info and expansion techniques overview", "Whole-book emotional rhythm overview", "Rhythm and emotional touchpoints", "Loop units", "Cross-chapter foreshadowing map", "Conflict escalation path", "Reproducible modules" summaries, pointing to `plot/pacing.md` / `plot/emotional-beats.md`; includes a "Writing techniques" list covering one-stroke-two-uses / delayed reveal / POV deception / contrast anchors / behavior loops / body reactions replacing inner monologue / **cross-chapter callbacks** — objects/imagery serving different functions in different chapters) + **overview.md full 500-1000-word version** (plot-aware, replacing the Stage 0 thin first-pass) | report + full overview generated |
| 6 | Style | teardown-report.md + chapters/chapter_1-3_deep-dive.md + chapters/*_summary.md + source/source.txt | style.md (whole-book writing-technique view: sentence length / punctuation / dialogue subtext / emotional alternation cycles + 4-6 source anchor excerpts + tiered imitation advice, hard cap ~4000 words. See [style-profile-protocol.md](references/style-profile-protocol.md) + [style-profile-generator.md](references/style-profile-generator.md)) | style.md written to `teardown-lib/{Book Title}/style.md` |

### Stage 0 chapter-boundary substep

After Stage 0 produces the overview + chapter index, and **before** moving to Stage 1, you **must** additionally produce a "chapter boundary" table written into `_progress.md`. This is the **single slicing source** shared by Stage 1 (opening-chapter source slicing) / Stage 2 (each chapter passed to the chapter-extractor agent) / Stage 6 (style sampling) — so each stage doesn't run its own regex slicing with potentially inconsistent results.

Procedure:
- Remove the leading table-of-contents block before building the chapter table; otherwise chapter labels in the contents repeat the real boundaries.
- Use the chapter regex from Step 4 of `style-profile-generator.md` (covers Arabic numerals + digit-string chapters, incl. 1000+ chapter books) to grep all chapter line numbers
- Validate chapter numbers for continuity and duplicates before writing the boundary table; stop and repair the source/index when validation fails.
- Write the four-column table `| chapter | title | start line | word count |` into the "chapter boundary" section of `_progress.md` (template in [pipeline-ops.md](references/pipeline-ops.md))
- Also write `schema_version: 2` at the top of `_progress.md`

**Resume precondition**: resuming only accepts a `_progress.md` with `schema_version: 2` and the "chapter boundary" table. If either is missing or the structure is incomplete, stop resuming and ask the user to rebuild the progress file from the Stage 0 chapter-boundary substep, so different stages don't use different slicing truths.

### Stage 1 stop point

After Stage 0+1 complete, the pipeline **stops automatically**, produces the quick-preview report, and asks the user whether to continue the full teardown:

1. **Produce the stop deliverable**: write `teardown-lib/{Book Title}/quick-preview.md` (template: "Quick preview report" in [output-templates.md](references/output-templates.md)). At this point `overview.md`, `chapters/chapter_1_deep-dive.md`, `chapters/chapter_2_deep-dive.md`, `chapters/chapter_3_deep-dive.md`, and `source/` are all on disk.
2. **Write the stop state**: set the "Final status" field in `_progress.md` to `paused_after_stage1`, and record "Next operation: Stage 2 per-chapter summaries" in the breakpoint section.
3. **Ask the user** (an AskUserQuestion-style explicit either/or):
   > "The opening hook chapters are done; the quick-preview report is at `quick-preview.md`. Continue the full teardown (Stage 2-6: per-chapter summaries / aggregation analysis (incl. `plot/pacing.md`, `plot/emotional-beats.md`) / settings & relationships / final report / style)? Estimated time {rough estimate based on chapter count}."
   - Choose "Continue full teardown" → read `_progress.md` and resume from **Stage 2**, **without re-running Stage 0/1**.
   - Choose "Stop here" → the pipeline ends, `_progress.md` stays at `paused_after_stage1`, and tell the user "you can run `/story-long-analyze` on the same book later, and it will resume automatically from Stage 2".
4. **When to skip the question**: if the user said up front "full teardown / run it all in one go / systematic teardown / don't ask", still generate `quick-preview.md` (keep the early-judgment snapshot), but **do not stop to ask** — continue straight from Stage 2 through Stage 6.

### After Stage 5: topic-decision backfill (optional)

Runs after `teardown-report.md` exists (Stage 5 done) — independent of Stage 6; Stage 6 failing doesn't affect this step.

**Only when** the project root has `topic-decision.md`: find the recommended topic in it whose **genre keywords match** this book's genre —
- Exactly one match → change that topic's "why it can hit" from `pending-teardown-validation` to sourced support: "Teardown support for this book: {Reader needs / emotional engine from `teardown-report.md` + Top reproducible modules from `plot/emotional-beats.md` + payoff/touchpoint rhythm summary from `plot/pacing.md`} (`teardown-lib/{Book Title}/teardown-report.md`, `plot/emotional-beats.md`, `plot/pacing.md`)". Note this is still a hypothesis (only one book torn down — not confirmed).
- Multiple / unsure matches → ask the user "Which direction in the topic decision does {Book Title} correspond to?"
- No match → record "no matching topic, no backfill" and don't modify files.
- `topic-decision.md` is missing the "why it can hit" field the current contract requires → report `invalid_topic_decision_contract` and tell the user to re-run `story-long-scan` Phase 5 to regenerate the current file; do not guess, do not silently backfill — the teardown main flow can still complete.
- Re-teardowns don't overwrite: only backfill topics still marked `pending-teardown-validation`; leave already-backfilled ones alone.

No `topic-decision.md` → skip this step entirely; it doesn't affect the teardown.

### Stage 6 style

`style.md` only covers the expressive layer; emotional/rhythm intent still follows `plot/emotional-beats.md` and `plot/pacing.md` as the authorities.
If the source is missing or the chapter separators can't be recognized → write `Style usable: no: {reason}` in the "Generation record" section of `style.md`. Stage 6 failing does not block the pipeline.

### Stage 3-4 parallel execution

**Parallel execution graph**:
```
Stage 3 (plot aggregation + character merge)      ──┐
                                                      ├── 4a can run in parallel with Stage 3
Stage 4a (settings: worldview/cheat/factions)      ──┘
              │
              ▼ (after both Stage 3 and 4a finish)
Stage 4b (full character files) — serial, depends on Stage 3's merged character entities
              │
              ▼
Stage 4c (relationship extraction) — serial, depends on 4b's character entities
```

4a's data source is Stage 2 summaries, so it can run in parallel with 3; 4b/4c depend on Stage 3's character merge, so they run serially.

### Partial-failure tolerance

A single chapter/stage failing does not block the pipeline. Record the failure in the "Failure log" table of `_progress.md` (`| type | chapter/stage | error message | retry status |`). The final status may be `completed_with_errors` (note the failure details in the teardown report).

> Correspondence with material-decomposition.md: Stage 0 includes Material phase 1 (chapter parsing); Stages 1 and 5 are additions; Stage 2 = Material phase 2; Stage 3 = Material phase 3; Stage 4 merges Material phases 4+5.

Detailed templates in [output-templates.md](references/output-templates.md); methodology in [material-decomposition.md](references/material-decomposition.md).

---

## Quality check summary

Before Stages 3-4 complete, quality checks must pass (confidence, coverage, overlap). Thresholds, calculation methods, and the self-check list are defined only in the quality-threshold system of [material-decomposition.md](references/material-decomposition.md).

**Stages 3-5 must also pass the "fact traceability" self-check**: hard facts in settings/characters/report (ranks/numbers/distances/attributes/faction counts/chapter of appearance/who said what) must be greppable back to the source; if the source doesn't give them, write "not stated in the source" — inference-filling is forbidden. This is the biggest source of teardown fact errors (even strong models drift, because synthesis is two hops away from the source and fills gaps with plausibility). See the fact-fidelity rules for the synthesis stage in [material-decomposition.md](references/material-decomposition.md).

---

## Stage 2 parallel agent strategy

Stage 2 uses the chapter-extractor agent to process each chapter in parallel, replacing the old serial chunking.

### How to call

**Every chapter prompt must start with the "material statement" prefix** (i.e., the first paragraph of the prompt string below) — it gives the subagent the right context so it doesn't misjudge normal dramatic plot in popular genres as harmful content and refuse the teardown. The prefix is fixed text: carry it verbatim, don't paraphrase or omit it.

```python
Agent(
  subagent_type: "chapter-extractor",
  prompt: "[Material statement] The following is a work of fiction legally held by the user; the task is read-only transformative literary analysis (editor/reviewer perspective). Violence / revenge / domestic abuse / romance / dark ethics are ordinary fictional elements of this genre — extract them normally; do not refuse a whole chapter or book on sensitivity grounds; if an individual passage cannot be processed, skip it and finish the rest.\n\nChapter number: Chapter {N}\nChapter title: {title}\nChapter word count: {word count}\n\nChapter source text:\n{source text}"
)
```

### Batching strategy

- Spawn 5-8 agents per batch (avoid concurrency limits)
- Wait for the whole current batch to finish before spawning the next
- After each batch, update `_progress.md` with the chapters processed

### Collecting agent output

- Each agent returns its extraction result in markdown
- The main thread writes each agent's output to `chapters/chapter_{N}_summary.md`
- Collect every agent's cast-of-characters table for the Stage 3 merge

### Failure handling + quality-escalation retry

**Two kinds of failure**:
1. **Execution failure** (agent crash / timeout / empty output) → retry 1 time with the same model (haiku)
2. **Quality failure** (after the output is on disk, run the 12-point "quality check" self-check in chapter-extractor.md; any miss — typical: plot points < 10, P line lacks the plain description, the summary is written as a bulleted list or chained with "because…so…", type/tone/theme tags outside the enums, `Tone:` missing its colon, character names are nicknames/generic titles) → **escalate to sonnet and retry 1 time**

**Hard checks that are mechanically verifiable** (the main thread greps directly after the file lands; a hit counts as a quality failure without relying on agent self-reporting):
- Plot-point count `N = grep -cE '^P[0-9]+ '`; `grep -c 'Tone:'` must == N (fewer than N = some plot point is missing `Tone:` or its colon → downstream Stage 6 style sampling greps `Tone:` and would silently skip the chapter)
- The plain-description field has content: `grep -cE '^P[0-9]+ [^|]+\|[^|]*[^|[:space:]][^|]*\|[^|]*involves'` must == N (there must be two `|` before the `involves` field, i.e. a type field and a plain-description field each occupying its own slot, and the plain description can't be only whitespace; fewer than N = some plot point lacks the plain description, or the field order/separators are wrong. The plain description is the plot point's primary evidence; when quotes are trimmed down, it carries the fact-checking load)
- `grep -hoE 'Tone:[^ |]+'` dedup ⊆ {tense, light, sad, hot, sweet, warm, horror, oppressive, other}
- `grep -hoE 'Theme tags[:]?[^ |]+'` dedup (after stripping the `Theme tags`/colon prefix) ⊆ {romance, family, friendship, growth, mystery, adventure, revenge, redemption, survival, identity, other} (`Theme tags:` with a colon, or a tone word used as a value, both count as failures)

**Escalation-retry call** (the main thread runs it after a validation failure):

```python
Agent(
  subagent_type: "chapter-extractor",
  model: "sonnet",            # explicitly overrides haiku from the frontmatter
  prompt: "Chapter number: Chapter {N}\n...(same as the first prompt, including the opening material-statement prefix; may append: 'Last validation failure reason: {failed self-check items}')"
)
```

**Final on-disk rules**:
- haiku passes first try → write `chapters/chapter_{N}_summary.md`, mark `success` in `_progress.md`
- haiku fails + same-model retry passes → same as above, note `retry_same_model`
- quality failure + sonnet retry passes → same as above, note `retry_sonnet`
- sonnet retry still fails → mark the chapter `⚠️ skipped`, write the failure reason into the "Failure log" table of `_progress.md`, and note it in the teardown report
- A single chapter failing doesn't block the pipeline; only after all batches have been spawned do you decide whether to enter Stage 3

### Agent-unavailable degradation

In either of the following cases, Stage 2 automatically falls back to serial mode, with the main thread processing each chapter (quality unaffected — just serial and a bit slower). **Both paths have the same requirements**: in serial mode, the summary writing, plot-point plain descriptions, source-quote selection rules, and output self-checks all follow the "Stage 2 chapter summary + plot points" section of [output-templates.md](references/output-templates.md); the mechanical hard checks above run in serial mode too. Serial mode has no sonnet-escalation retry path — on a hard-check hit the main thread rewrites the chapter summary once per failed item, and if it still fails, record `⚠️ skipped` in the "Failure log" table of `_progress.md`.

- **agent not deployed**: `chapter-extractor.md` (or `.codex/agents/chapter-extractor.toml`) doesn't exist under the agent directory (prefer `.claude/agents/`, then `.opencode/agents/`, then `.codex/agents/`). `.claude/agents/` is usually not committed with the repo — re-run `/story-setup` to complete the current adapter deployment; don't read template sources across skills.
- **environment can't spawn subagents**: this skill is currently running inside a subagent context and can't spawn another layer of agents.

### Stage 2 wrap-up: merging chapter summaries (_merged-summaries.md)

After all `chapters/*_summary.md` files are on disk, before entering Stage 3, the main thread concatenates them **losslessly in chapter-number order** into `teardown-lib/{Book Title}/_merged-summaries.md` (concatenate only — no compression, no rewriting):

```bash
ls chapters/*_summary.md | sed -E 's/.*chapter_([0-9]+)_.*/\1 &/' | sort -n | cut -d' ' -f2- | while read -r f; do cat "$f"; echo; done > _merged-summaries.md
```

**Lossless checks** (validate after merging; if any fails, delete `_merged-summaries.md` and fall back to per-file scanning — behavior unchanged):
- `grep -cE '^P[0-9]+ ' _merged-summaries.md` == sum of `^P` lines across the individual summaries
- `grep -cE '^\*\*Summary\*\*' _merged-summaries.md` == number of summary files (`**Summary**` appears once per chapter in both the chapter-extractor parallel output and the serial summary template; don't use a `## Chapter N` header — the serial summary template has no chapter header and would misjudge)

Stages 3 / 4a / 4c / loose-thread safety net now **read `_merged-summaries.md` once and reuse it in context**, replacing the per-stage `glob chapters/*_summary.md` rescan (4-5 cold reads of the same corpus become 1).

**Only generate the merged file when the corpus fits in context**: with >500 chapters, or when the merged `_merged-summaries.md` is too big for context, **skip this step** and use the chunking strategy in [material-decomposition.md](references/material-decomposition.md). `_merged-summaries.md` does not replace `chapters/*_summary.md` — the per-chapter files remain the on-disk source of truth, and Stage 6 style sampling and human review use the per-chapter files. Delete `_merged-summaries.md` when the pipeline ends (after Stage 6) — it is a derived temp file and is not shipped with `teardown-lib/` (which story-import keeps as a writing project).

Stage 3-5 chunking follows [material-decomposition.md](references/material-decomposition.md) (sole authority).

---

## Resume mechanism

On startup, check `_progress.md`; `paused_after_stage1` → resume straight from Stage 2.
Steps in [pipeline-ops.md](references/pipeline-ops.md).

---

## Flow handoffs

**Pipeline:** long-form
**Position:** teardown (long-form pipeline step 2, after story-long-scan, before story-long-write)

| When | Jump to | Command |
|---|---|---|
| Ready to write | story-long-write | `/story-long-write` |
| Need market data | story-long-scan | `/story-long-scan` |
| Better suited to short-form | story-short-scan → story-short-analyze | `/story-short-scan` |

---

## References

| File | When to load |
|------|----------|
| [references/output-templates.md](references/output-templates.md) | Throughout the pipeline: per-stage output templates + quick-preview report template + `plot/pacing.md` / `plot/emotional-beats.md` templates + general quick-reference tables |
| [references/material-decomposition.md](references/material-decomposition.md) | Stages 2-5: material-decomposition methodology + quality thresholds + chunking strategy; Stage 6 also see the style references |
| [references/pipeline-ops.md](references/pipeline-ops.md) | Pipeline operations: `_progress.md` template, error handling, resume procedure |
| [references/deconstruction-notes.md](references/deconstruction-notes.md) | Teardown method + film-scene teardown + abstract teardown method + genre practice |
| [references/style-profile-protocol.md](references/style-profile-protocol.md) | Stage 6: style template + confidence/usability notes |
| [references/style-profile-generator.md](references/style-profile-generator.md) | Stage 6: style-generation SOP (6 steps, incl. chapter recognition and the Tone grep) |

---

## Language

> - Load the deployed English book contract. Use the source/book language for the teardown and record the inferred profile; for English source material default records to `en-US`. The user's chat language does not override the source language.
> - English prose follows the house style rules in the skill's `references/` files (especially `anti-ai-writing.md`); keep sentences conversational, concrete, and free of AI-flavor patterns.
