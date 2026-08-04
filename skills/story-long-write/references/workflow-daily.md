# workflow-daily.md: Daily Continuation Workflow

This file is the complete guide for the "daily continuation" scenario. After SKILL.md routes here, execute the flow below.

> **Daily pre-writing steps**: 4 steps before each chapter — state filtering + genre prose card recall + style recall + intent confirmation, embedded in the Step 2 per-chapter loop. Reader contract, protagonist agency, promise debt, and endgame reserve uniformly defer to `reader-contract-and-progression.md`.
>
> Step 2 must read / generate five kinds of pre-writing material:
> 1. `{benchmark path}/plot/emotional-beats.md` (reader needs / emotional engine + reproducible modules; if missing, stop and repair per "module/rhythm missing" below)
> 2. `{benchmark path}/plot/pacing.md` (key info advancement + emotional trigger points + burst pacing; if missing, stop and repair per "module/rhythm missing" below)
> 3. `setting/genre-prose-card.md` (genre boundaries / core logic / reader expectations / pacing density; if missing, generate by exactly matching the `references/genre-prose-cards.md` index from `setting/genre-positioning.md` and reading the single card `references/genre-prose-cards/{genre}.md` first, with `references/style-genre-modules.md` generic style modules as fallback)
> 4. `{benchmark path}/style.md` (whole-book level, ~4000 words, with source-anchor example excerpts)
> 5. `{benchmark path}/chapters/chapter_K_summary.md` (pick 1 chapter by this chapter's emotion/tone); if `chapter_K_deep-dive.md` exists for the same chapter, read it too; otherwise fall back to the golden-three-chapters deep dives / transferable techniques in the style file
>
> Benchmark path lookup: prefer `{project}/benchmark/{Book}/`, fall back to `teardown-lib/{Book}/`.
>
> **Genre prose card**: prefer `setting/genre-prose-card.md`; when missing, non-blocking — first exactly match the `references/genre-prose-cards.md` index from `setting/genre-positioning.md`, read only the single card `references/genre-prose-cards/{genre}.md` (keep the card's high/medium/low confidence labels), and if nothing matches, extract a short `genre_prose_card` from `references/style-genre-modules.md` generic style modules. The genre card only constrains genre flavor and prose tradeoffs: it does not change the outline, does not override the emotion/pacing authoritative files, and does not take over sentence length/punctuation style details. The genre card calibrates tradeoffs inside the writer's head only; card names/genre labels/confidence/items/compliance self-assessments never go into the prose.
>
> **Custom style (`setting/style.md`, highest priority)**: the main session reads `setting/style.md` directly before each chapter (not via story-explorer — it only looks at the benchmark `style.md`). If it exists with substantive content (≥200 words after whitespace removal, or containing style subsections for sentence length / punctuation / dialogue / anchors / tone with executable constraints: ratios / examples / bans or preferences), enter "custom-style mode": it is the **authoritative** style base of the book's established voice; narrative-writer's sentence-length band / punctuation rhythm / dialogue subtext / emotional alternation follow it; the benchmark/teardown `style.md` demotes to "**reference**" — source anchor examples and sentence-length distribution numbers only, no longer the final style followed. Empty / whitespace-only / title-only / placeholder stubs (TODO / to be added / ___) count as nonexistent. It takes over style only and does **not** override the emotion/pacing intent of `plot/emotional-beats.md` / `plot/pacing.md` (same as the "conflict rules" below). **Hard gates do not yield**: writing in `setting/style.md` that hits hard safety lines (`……`, em dashes `——`/`—`, blank lines between paragraphs, 3-5-word fragments) still normalizes per narrative-writer to periods / commas / action beats / single `\n`; the custom style only takes over sentence length / soft punctuation rhythm / subtext / emotional alternation.
>
> **Style missing**: **not in custom-style mode** and the benchmark book lacks `style.md` → stop this chapter's writing, do not inline-generate, error: 「Benchmark book X is missing style.md. Run `/story-long-analyze` Stage 6 to generate the style profile, then `/story-import` to sync.」 **In custom-style mode, no fail-fast** — continue with `setting/style.md`.
>
> **Module/rhythm missing**: when the benchmark book lacks `plot/emotional-beats.md` or `plot/pacing.md`, stop this chapter's preparation, set `gaps.missing_primary_contract: true`, prompt to re-run `/story-long-analyze` Stage 3+ or re-run `/story-import`; never assemble a low-confidence substitute from summary files.
>
> **Conflict rules**: `plot/emotional-beats.md` and `plot/pacing.md` are authoritative for emotion and pacing; `teardown-report.md` and `plot/storylines.md` are projection summaries; `style.md` governs style only. If a summary or the style conflicts with the authoritative modules/pacing, keep `gaps.conflict` and let the prose intent follow the authoritative files.
>
> **No-benchmark projects**: when there is no `setting/style.md`, skip the "benchmark module/rhythm/genre-card/style recall" and mark "no benchmark reference" in the intent confirmation — do not read nonexistent files, no blocking, no warnings; **with `setting/style.md` (custom-style mode), write with it** — with no benchmark to recall, emotion/pacing targets come from internal material such as this book's chapter outline "Target emotion", volume outlines, and `setting/genre-positioning.md`; `selected_emotion_module` / `rhythm_reference` record "none" and never claim benchmark recall.
>
> **Multiple benchmark books**: read the `Primary benchmark book` field from `setting/genre-positioning.md`; when missing, use the lexicographically first book under `benchmark/` and prompt the user to fill the field.
>
> Full pre-writing logic lives in SKILL.md Phase 4.

---

## Applicability

- The project already has `prose/` and `tracking/` directories
- The user explicitly says "daily update" / "continue" / "keep writing", or explicitly specifies "write chapters N-M"
- Goal: write 2-3 chapters per session (4000-9000 words)

> **Bare invocation does not enter daily**: if the user merely triggers `/story-long-write` / `$story-long-write` without saying "daily update/continue/keep writing/write chapter N/1 chapter only/chapter-by-chapter confirmation", do not enter this workflow. Return to SKILL.md's "bare invocation and stopping points" and only show current progress and available commands, avoiding auto-writing 3 chapters after a session restart.

---

## Step 1: Quick context load

**Optional: use the story-explorer agent to load context in bulk.** If the project has deployed a story-explorer agent (check whether `.claude/agents/story-explorer.md` exists), you may run `Agent(subagent_type: "story-explorer", prompt: "Project directory: {dir}\nQuery type: context_load\nQuery params: preparing to write chapter {N}")` to fetch all writing context in one `context_load` query. Use its results directly after spawn, skipping the manual loading steps below. If the agent is unavailable or returns incomplete results, fall back to the manual loading below.

Manual loading (default):

| # | File | Use | If missing |
|------|------|------|-----------|
| 1 | `tracking/context.md` | last writing progress summary | rebuild from `tracking/foreshadowing.md` + `tracking/timeline.md` |
| 2 | `tracking/foreshadowing.md` | pending-foreshadowing list | skip |
| 3 | `tracking/timeline.md` | current event order | skip (infer from prose while writing) |
| 4 | `outline/outline_chapter_{N}.md` | this chapter's writing plan | **must build first**; skipping is not allowed |
| 5 | `outline/volume_outline_N.md` | volume contract, current story unit, endgame reserve | legacy outlines missing volume contract/story-unit cards do not block: infer in memory and record in `tracking/context.md`; only write back when explicitly extending/revising outlines this round; unknown fields get `[to be determined]`; never auto-modify locked volume outlines |

**On-demand character files**: extract this chapter's character names from the outline and load `setting/characters/{Name}.md` on demand. If the outline lists none, skip.

**On-demand creation formulas**: when writing needs formula constraints (anticipation formula, payoff formula, information-gap formula), load `references/genre-writing-formulas.md`. Not loaded by default, to avoid unconditionally loading a 1500+ line file and wasting tokens.

### Layered summary of written content

When the project passes 30 chapters, the written-content summary in `tracking/context.md` should use a three-layer structure, compressing early chapters and keeping recent detail:

| Layer | Granularity | Format | Maintained at |
|------|------|------|----------|
| **Last 5 chapters in detail** | chapter-by-chapter summaries of the last 5 | keep current format (one paragraph per chapter: event + state change + foreshadowing) | after each chapter |
| **10-chapter overviews** | one paragraph per 10 chapters | `chapter range | written core events | character state changes` | one paragraph per 10 completed chapters |
| **Volume-level overview** | one sentence per volume | `volume | written main-line progress | key turns` | at each volume end |

**Example (a 50-chapter project)**:
```markdown
## Last 5 chapters in detail (chapters 46-50)
Chapter 46: the protagonist enters the secret realm and finds the ancient ruins...
Chapter 47: fights the guardian beast, barely wins and receives the inheritance...
...

## 10-chapter overviews
Chapters 1-10 | protagonist awakens the cheat, enters the training academy | from useless disciple to inner disciple
Chapters 11-20 | academy tournament, defeats the prodigy rival | gains elder attention, breaks through
Chapters 21-30 | leaves the academy, explores the secret realm | finds identity clues, makes allies
Chapters 31-40 | dragged into faction war, identity exposed | hunted, breaks through again
Chapters 41-50 | kills the pursuers, enters a new map | bloodline inheritance confirmed, ascends to the upper realm

## Volume-level overview
Volume 1 · Awakening | from useless disciple to genius | cheat awakened, identity begins to surface
```

> **First-daily fallback**: if all files under `tracking/` are empty or nonexistent (Phase 3 just finished, no daily yet), additionally load `outline/volume_outline_N.md` and the latest chapter's prose to rebuild context.

> **Determining the next chapter number N**: read the "last completed chapter" field from `tracking/context.md`. If the file does not exist, scan `prose/` for the highest-numbered chapter and add 1.

After determining this round's writing range, go straight to Step 2 — no "continue?" confirmation. K defaults to 2-3 chapters; adjust per the user's explicit "1 chapter only" / "daily 3 chapters" / "chapter-by-chapter confirmation". When the user gives N>3, write only the first 3 this round and note in the Step 4 progress summary that remaining chapters continue next round. Pause for confirmation only on chapter-number conflicts, missing chapter outlines, requests beyond existing outlines, requests that would change existing outlines/tracking, or other blocking information that would cause writing errors.

---

## Step 2: Serial batch writing

Load multiple chapter outlines at once, but **must write chapter by chapter serially in the main session**: never hand multiple chapters to multiple subagents to write concurrently. Long-form chapters depend on the previous chapter's prose and tracking files; concurrency breaks context, overwrites tracking, and breaks title dedup.

**Batch continuation rule**: after entering this step, "continue" / "write more" / "daily update" only mean continuing the current daily batch flow. Do not interpret these words as direct prose continuation that skips "state filtering" or "benchmark module/rhythm/genre-card/style recall"; do not re-ask whether to continue between chapters unless the user explicitly wants chapter-by-chapter confirmation or a blocker appears. After reaching this round's K (max 3 chapters), enter Step 3/4 finishing and stop — do not keep writing the next batch just because more outlines exist.

1. **Read the writing plan**: the authoritative order of the writing plan is **volume contract → current story unit → chapter outline**; already-written facts are authoritative in the prose and `tracking/` files. First read the volume contract, current story unit (unit ID/position), unit emotional engine, this volume's primary push line/result lines, and endgame trump card boundaries from `outline/volume_outline_N.md`, then load this round's 2-3 chapter outlines. Legacy volume outlines missing volume contract/story-unit cards do not block daily updates: infer this round in memory and record in `tracking/context.md`; write back to the volume outline only when explicitly extending/revising outlines; unknown fields get `[to be determined]`; never auto-modify a locked volume outline. New-format outlines are read preferentially via 「Stage position」「Chapter structure formula」「Forbidden early release」「Content summary (Cause/Development/Turn/Climax/Ending)」「Plot arrangement (Main line/Sub-line/Event & task line/Relationship line/Logic line)」「Characters and appearance order」「Plot detail」「Ending and hook」; legacy outlines missing these fields do not block — fall back to core event, plot-point sequence, target emotion, chapter-open/close hooks, target words. When a legacy outline has a target word count but no per-point budgets, derive temporary budgets by function tag after writing to locate deficits (payoff/comeuppance/reversal = dense, transition/travel = light), then allocate — no guessing by feel.
   - **Batch positioning & stage constraints**: before writing the batch, extract from `outline/outline.md`, the corresponding `outline/volume_outline_N.md`, and this batch's chapter outlines: which stage the current chapter range belongs to, this batch's advancement target, what this batch may release, what this batch is strictly forbidden from releasing early, and the boundary chapter-end hooks may not cross. Confirm this batch's primary push line and result lines against the endgame reserve; do not touch endgame trump cards this stage may not unlock (multi-line result gains allowed); action cost may be absent — never fabricate costs. With no explicit stage overview, summarize temporarily for this round from the volume outline and written progress; write back only when explicitly extending/revising outlines this round, otherwise record in `tracking/context.md`; never auto-modify locked master/volume outlines.
   - **Stage progress self-check**: after each batch or outline batch, check whether the writing is ahead of, behind, or drifting from the stage rhythm; if drifting, record the compensation plan in `tracking/context.md`'s notes (e.g. next batch speeds up conflict, delays a truth, adds one relationship payoff) — never force speed by leaking later-stage information early.
2. **Per-chapter execution** (each step inside the per-chapter loop):
   - Read the outline → load character setting on demand
   - **Title pre-check**: scan existing chapter titles; if this chapter's title duplicates or clearly resembles one, rename by this chapter's core event, keeping outline title and prose filename in sync
   - **Previous-chapter deficit check**: before writing this chapter's prose, confirm the previous chapter's prose has no uncleared blocking toxic-pattern deficits (the write hook auto-blocks; when the hook is unavailable, run `node scripts/check-ai-patterns.js --check --fail-on=blocking` on the previous chapter); clear deficits first, unless the previous chapter carries `<!-- deslop:skip -->` (explicit user exemption)
   - **State filtering**: before each chapter, confirm the following sources were read or just updated within this round's workflow: this chapter's outline, the previous chapter's prose (or the prose just written), `tracking/context.md`, `tracking/foreshadowing.md`, `tracking/timeline.md`; when characters are involved, also confirm `tracking/character-state.md` or the corresponding `setting/characters/{Name}.md` sources. "Loaded" means actually read/updated within this round's workflow — never substitute chat memory without a stated source. Character latest state is filtered preferentially from `tracking/character-state.md` (if absent, infer from character setting); pending/advancing foreshadowing from `tracking/foreshadowing.md`; when the outline does not exist, still handle per the build flow below — direct prose writing is not allowed
   - **Benchmark module/rhythm/genre-card/style recall**:
     - Call story-explorer's `benchmark_style_load` query_type (input: project directory + this chapter's target emotion + this chapter's payoff type + this chapter's target words) to get in one shot: `{style_profile_path, style_profile_summary, selected_emotion_module, rhythm_reference, module_source_path, rhythm_source_path, matched_chapter_K, matched_chapter_techniques, anchor_excerpts, gaps}`
     - **Genre prose card recall**: the main session prefers `setting/genre-prose-card.md`; when missing, first read `setting/genre-positioning.md` + the `references/genre-prose-cards.md` index, exactly match the primary genre and read only the single card `references/genre-prose-cards/{genre}.md` (e.g. contemporary-romance / mafia-romance / cultivation; low-confidence cards must be flagged low-confidence in the intent confirmation and calibrated against a same-genre benchmark), then fall back to `references/style-genre-modules.md` generic style modules. Cross-genre: 3-5 items from the primary genre, 1-2 from the secondary, produce a `genre_prose_card` (genre boundaries, core logic, reader expectations, core payoff/emotion, pacing density, scene granularity, drift bans, this-chapter tradeoffs, card confidence). The genre card must enter the narrative-writer prompt, but only as a short summary, with the note that the card is for internal genre calibration only and card wording or compliance self-assessments must never appear in the prose
     - **Custom-style override (before the gaps judgments below)**: the main session reads `setting/style.md` directly (not via explorer); with substantive content (≥200 words after whitespace removal, or containing style subsections for sentence length / punctuation / dialogue / anchors / tone with executable constraints: ratios / examples / bans or preferences) set `custom_style=true` — it becomes the authoritative style base that **replaces** `style_profile_path` fed to narrative-writer (sentence length / punctuation / subtext / emotional alternation), and the benchmark/teardown `style_profile_path` demotes to reference (source anchors + sentence-length distribution numbers). Empty / whitespace-only / title-only / placeholder stubs (TODO / to be added / ___) count as nonexistent. It takes over style only and does **not** exempt the emotion/pacing axis
     - If `gaps.no_benchmark: true` → with `custom_style` true, enter "custom-style mode" (write with `setting/style.md`; no benchmark to recall, emotion/pacing targets come from internal material such as the chapter outline's "Target emotion", volume outlines, `setting/genre-positioning.md`; `selected_emotion_module` / `rhythm_reference` record "none" and never claim benchmark recall); otherwise skip style recall and mark "no benchmark reference" in the intent confirmation
     - If `gaps.missing_primary_contract: true` → stop this chapter's preparation, prompt per `repair_action` to re-run `/story-long-analyze` Stage 3+ or re-run `/story-import`; do not enter narrative-writer (the emotion/pacing axis is independent of the style axis — **custom-style mode does not exempt this stop**: repair `plot/emotional-beats.md` / `plot/pacing.md`, not by writing `setting/style.md`)
     - If `gaps.conflict` or `gaps.module_rhythm_conflict: true` → the intent confirmation must state the conflict and execute per the authority of `plot/emotional-beats.md` / `plot/pacing.md`; never let `style.md` override emotion/pacing targets
     - If `gaps.profile_missing: true` → with `custom_style` true, continue in custom-style mode; otherwise stop per the fail-fast flow above
     - If `gaps.profile_degenerate: true` (benchmark style unusable) → with `custom_style` true, write with `setting/style.md`; otherwise skip style and write under the default Gates
     - If `gaps.tone_match_failed: true` → write with the whole-book style only; do not feed matched_chapter
     - Otherwise pass through `style_profile_path`, `style_profile_summary`, `selected_emotion_module`, `rhythm_reference`, `module_source_path`, `rhythm_source_path`, `matched_chapter_K`, `matched_chapter_techniques`, `anchor_excerpts`, and `genre_prose_card` to the narrative-writer spawn prompt at the end of Step 2; `selected_emotion_module` must enter the emotion target, `rhythm_reference` must enter the rhythm/burst arrangement, `genre_prose_card` must enter the genre tradeoffs, `matched_chapter_techniques` must enter the "style recall directive". The pre-writing record must keep `gaps` values, especially `gaps.module_missing`, `gaps.rhythm_missing`, `gaps.conflict`, `gaps.matched_deep_dive_missing`; if `matched_deep_dive_missing` is true, the style recall directive explicitly states "same-chapter deep dive missing, fell back to golden-three-chapters/style techniques", and later reports must not flip it back to false
     - **Without story-explorer, execute directly**: the main session manually follows the benchmark path lookup: first read `plot/emotional-beats.md` to pick `selected_emotion_module`, then `plot/pacing.md` to pick `rhythm_reference`, read `setting/genre-prose-card.md` or generate `genre_prose_card` on the fly via the `genre-prose-cards.md` index + single-card priority, read `setting/style.md` first (substantive content → `custom_style=true`, authoritative style base, benchmark `style.md` demotes to reference / sentence-length fallback), then read the benchmark `style.md` + grep the `tone:` field in `chapters/*_summary.md` for a matching chapter, then read the corresponding `chapter_K_summary.md`; if `chapter_K_deep-dive.md` does not exist, read the chapter in `chapters/chapter_001-003_deep-dive.md` closest in tone to this chapter. When module or rhythm files are missing, set `missing_primary_contract` and stop to repair
   - **Intent confirmation**: confirm this chapter's emotion target from the outline's "Target emotion" field, combine the state-filtering results + `selected_emotion_module` + `rhythm_reference` + `genre_prose_card` + style recall output, and write this chapter's intent in one sentence (emotion + rhythm + module + genre tradeoffs + style directive). The intent must express "**emotion pre-state → trigger → post-state**", not just an emotion label, and state which link of the unit's emotional engine this chapter advances. The intent confirmation must consume protagonist agency, the current story unit's protagonist goal/key choice, this unit's primary push line/result lines, endgame trump card boundaries, and benefit attribution. Only when a new carrier, key turn, or climax enters, run emotional-methods.md's "five plausibility questions"; do not fill forms every paragraph. When a new-format outline exists, the intent confirmation must explicitly bring in: stage position and forbidden early release define this chapter's boundary; the structure formula defines the advancement skeleton; the content summary defines the cause-development-turn-climax-ending; the plot arrangement defines main/sub/event/relationship/logic line tradeoffs; characters & appearance order define the order in which the camera enters; plot detail defines action cost (optional) / benefit attribution; ending & hook defines the chapter-end handoff — but these fields only define "what happens" in the chapter, not the shape of the prose: do not expand plot points one by one into paragraphs, do not copy "who did what" summary wording into narration, the five-part structure is not five sequentially written blocks — plot points may be merged/interleaved/reordered freely; play each point as a scene (see writing-craft.md "from outline to prose"); and implement four writing requirements — ① development/turn = payoff(climax) setup charge; before a payoff lands, first lay an identifiable crisis/anticipation (plot-emotion-system back-derivation; unset = hollow); ② status-flex/comeuppance/reveal chapters amplify POV/information gap through the present side characters in appearance order into differentiated reactions (plot-core-methods information-gap × relationships × emotion / collective shock); ③ dialogue voice baseline follows the tone — in high-pressure/life-and-death/grief beats, comedy-relief/light side-character voices yield, info-role side characters do not lecture, lines answer the other person's emotion line by line; ④ **outline-priority boundary** — only expand this chapter's outline events/people/foreshadowing/hooks; no self-invented main lines, new characters, new reversals, no writing later-chapter plot early. Write it into this chapter's intent and converge per the tone at generation time. Per the authoritative file's causal rights + settlement rights and the "key-node four questions", confirm expectation ownership: side characters may execute local actions, the protagonist need not do everything personally, but promised highlights/benefits must not be silently stolen; if captured by side characters, institutions, or chance without a visible exchange, mark `protagonist_agency_risk` and fix the outline/volume outline before prose. Whether a voluntary cession is a red light and how strategic concessions count follow the authoritative file — do not expand here. Example: 「Fast comeuppance — cause = bill exposed; logic line = discovery → interrogation → counter-evidence → public cost; reproduce the reader anticipation of M03 "information-gap counter-kill", land it per the urban-genre card on bills/transfers/onlooker reactions, hold the key info then burst it, and use a cooldown beat after the burst to carry the next hook; punctuation follows the style file's pause rhythm, dialogue subtext uses answering-not-asking; plot boundary = no new enemies beyond the bill and no early resolution of the next chapter's hook.」
   - Write prose → **word-count verification (prefer Python character statistics; `wc -m` is a Unix-only fallback; < 90% of target: locate the deficit dense points against the plot-point word budgets and rewrite once to quota — no repeated refires; may only expand outline-listed plot points; if the existing outline cannot reach the target, stop and output `outline_underfilled` deficit points; > chapter target×1.1: compress transitions/merge light points; 90% is the release floor, not the goal — aim for [chapter target, chapter target×1.1])** → check hooks/payoffs → **prose meta-information scan** → banned-word scan (including the most-toxic-pattern quick pass in SKILL Phase 4 step 11; write-hook push-backs of toxic patterns are cleared in the same round, never left to batch end)
     - **Prose meta-information scan**: outside the title line, prose must not contain `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` (and variants: last chapter / previous chapter / next chapter / earlier text / later text). These are writing/engineering meta-information; rewrite into event anchors or relative time the character can perceive; e.g. "more painful than those three seconds of gunfire in chapter one" becomes "more painful than those three seconds of gunfire". Exceptions: a character genuinely reads/discusses "chapter X" text inside the story world, or is truly an author/reader talking about being a reader.
   - After each chapter, **immediately update**:
     - `tracking/foreshadowing.md` (new/collected foreshadowing)
     - `tracking/timeline.md` (event order)
     - `tracking/character-state.md` (if the chapter changed a character's state — identity, ability, relationship, public image — update the entry and append a change record)
     - `tracking/context.md` (progress meta only: current position + written words + this round's changes; no detailed character-state/foreshadowing content; reuse existing planned-beats/actual-results/promise-progress post-writing records to reflect engine advancement, appending this chapter's unit execution state: unit ID, planned beats, actual results, benefit changes, primary push line/result lines, promise progress, drift aligned|adaptive|structural, next chapter's hard task. Do not add fields beyond these; do not create separate memory packs or unit tracking files)
   - **Quality-check prompt** (optional): this chapter is written. For consistency checks, run `/story-review lean`. Batch mode skips this step; review everything together after the batch.
3. **Uninterrupted but not concurrent**: after one chapter, do not ask the user — write the next directly (unless the user wants chapter-by-chapter confirmation); the next chapter must read the previous chapter's just-written prose and tracking updates before starting.

**Research (on demand)**: if the writing needs external facts verified (historical dates, geography, professional details, etc.), pause, spawn the `story-researcher` agent to search and output into the `reference/` directory. Continue after research completes.

---

## Step 3: Quality check

After the batch, run the Phase 5 quality check on all newly written chapters (at minimum):

1. **Banned-word scan**: per `references/banned-words.md`; tier-1 hits replaced on sight
2. **Title dedup**: collect this round's new chapter titles and existing titles; on duplicates or clear similarity, rename in the corresponding outline and prose files uniformly
3. **Prose meta-information scan**: check outside the title line for `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` and variants; rewrite hits into in-scene expressions; in-story reading/discussion of "chapter X" or genuine reader-identity contexts excepted
4. **Hook check**: does each chapter end give a reason to keep reading (low-pressure/transition chapters need only a weak hook or stage goal — no strong-hook requirement, per the outline's chapter positioning; see references/outline-structure-theory.md "chapter positioning & tension"); with a new-format "Ending and hook", check the ending lands on a concrete action/image/suspense ("settled state" is planning language, not a state-summary sentence to write into prose), leaves unresolved problems, and a next-chapter driving force
5. **Contract & outline cross-check**: first per `reader-contract-and-progression.md` check reader contract, causal rights + settlement rights, key-node four questions, expectation ownership, promise-debt repayment, endgame reserve (the overdraw two questions); chapter-level advancement tiers per the authoritative file's seven state types (fast-paced keeps the visible-event/payoff floor), judged against this book's genre and benchmark; short low-pressure passages and small visible gains/rewards after climaxes are allowed. New maps/institutions/abilities/enemies/mysteries must be checked for new-element debt; fulfillment-genre/ability-fantasy books additionally check whether the protagonist repeatedly creates disasters through avoidable incompetence that others then clean up. Then cross-check the prose against the outline — did it write to the outline. With a new-format outline, verify the prose consumed the five-part content summary, the multi-line plot arrangement, the relationship changes/appearance order, action cost (optional) / benefit attribution; and verify three writing requirements (fail → fix): ① is there an identifiable crisis/anticipation setup passage before the payoff lands? Cannot point = hollow → return to Step 2 and add setup plot points (plot-emotion-system back-derivation); ② in status-flex/comeuppance/reveal chapters, are the present side characters given differentiated reactions (collective shock / varied), or only the protagonist acts? None → add side-character reactions (plot-core-methods); ③ is the density distributed by purpose words (payoff/selling points expand, transitions skim, info density alternates), or evenly padded? Even → cut transitions, expand payoff points. Legacy outlines only check core event, target emotion, chapter-open/close hooks, and target words
6. **Foreshadowing inventory (this round's increments only)**: confirm only this batch's new/advanced/collected foreshadowing is written into `tracking/foreshadowing.md` with updated status; do not read through all sessions or scan all prose for a full foreshadowing audit in the daily flow. Full audits happen only via `/story-review` or explicit "fully check foreshadowing" requests
7. **Deterministic finishing**: the main session runs `node scripts/check-ai-patterns.js --check --fail-on=blocking prose/chapter_NNN_*.md` on this batch's landed prose; blocking hits are fixed in the prose and rescanned; advisory is reading-feel hints only; functional writing gets `[needs review]`.
   Then run `node scripts/normalize-punctuation.js prose/chapter_NNN_*.md` (default `--quote-mode keep`) to clean non-functional ellipses, dashes, double hyphens, and standalone separators. The narrative-writer agent does not run these scripts.
   - **Degeneration protection**: then run `node scripts/check-degeneration.js --check prose/chapter_NNN_*.md`. Blocking (verbatim repetition, truncation, refusal language, tier-1 engineering-word leaks) → rewrite only the affected chapters, at most 2 times; if still failing, report evidence and let the user decide. Advisory: check the exceptions first; only fix genuine engineering-word leaks or degeneration.

> Full checklist in [Phase 5: Quality check](../SKILL.md#phase-5-quality-check).

---

## Step 4: Progress summary

Update `tracking/context.md` (already incrementally updated per chapter; final summary here):

```markdown
## Writing Progress

- Last completed chapter: Chapter {N}
- Updated: {date}
- This round: {K} chapters, {X} words total

## Current state

- Active foreshadowing: {N} items (see tracking/foreshadowing.md)
- Character states: latest change {character} (see tracking/character-state.md)
- Next chapter outline: {exists / needs building}
- Notes: {key decisions or changes to remember}

## Unit execution state (updated inside the existing context.md; no separate tracking file)
- Unit ID: {Lx-y}
- Planned beats: {original planned beats}
- Actual results: {what was actually written}
- Benefit changes: {delivery increased/deferred/transferred and its attribution}
- Primary push line/result lines: {this chapter's advanced lines}
- Promise progress: {promise-debt progress}
- Drift: {aligned|adaptive|structural}
- Next chapter's hard task: {the hard task the next chapter must handle}
```

---

> **Drift handling**: aligned = advanced per plan; adaptive = details adapted without changing the contract; structural drift = the prose has already changed the volume contract, unit promise, advancement line, or delivery attribution — must fix the prose or re-plan future chapter outlines; a context note alone is not enough.

## Chapter-outline build flow (missing outlines)

When an outline is detected missing, it cannot be skipped. Build it as follows:

1. Load `outline/volume_outline_N.md` (this chapter's event plan) and read this chapter's story-unit card; when the card has a "benchmark plot reference", additionally read the referenced story-unit file (1), using its "structure distribution" position as this chapter's function reference; if the whole story unit starting from this chapter has no outlines, prefer building the whole batch per outline-structure-theory.md "chapter outlines by story-unit batch" rather than a single chapter. Missing references / legacy volume outlines without the field never block; continue the original flow
2. Load the involved `setting/characters/{Name}.md` (character states)
3. Read the latest chapter's prose (plot continuity)
4. Build this chapter's outline per the SKILL.md Phase 3 new-format template, completing stage position, chapter structure formula, forbidden early release, content summary, plot arrangement, characters & appearance order, plot detail, ending & hook; fields that cannot be determined from the volume outline/prose/setting get `[to be determined]` — no fabrication
5. Continue Step 2 writing after the build

---

## Common issues

| Issue | Handling |
|------|------|
| Chapter outline missing | run the "chapter-outline build flow" above |
| Outline missing new-format fields | legacy outlines do not block daily updates: consume via Step 2-1's fallback fields; backfill only when explicitly extending/revising outlines this round; new/built outlines must follow the current template completely, unknown items `[to be determined]` |
| Tracking files empty | continue normally, fill in while writing |
| User asks to change the outline | remind "changing the outline affects later chapter outlines", confirm, then modify and mark affected outlines |
| Volume end reached | prompt the user "this volume is complete — open a new volume?" |
| User interrupts the batch | save the current chapter, tracking files already updated, resume from the breakpoint next time |
