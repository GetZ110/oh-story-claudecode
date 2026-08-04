# Teardown Output Templates
Load on demand; use with SKILL.md and material-decomposition.md.

This file is organized by the stages of story-long-analyze's single pipeline: Stage 0-5 output templates + the stop-point "quick preview report" template + cross-stage quick references.

---

## General quick reference

### Payoff types

| Type | Definition | Example |
|------|------|------|
| Status flex + comeuppance | overwhelming the person who looked down on you | "You? Not worthy." |
| Comeback reversal | turning a dead end around | trash talent awakens |
| Fortune gained | getting what others don't have | finding a divine artifact |
| Information-gap domination | reader and protagonist know what others don't | second-chance foresight advantage |
| Emotional fulfillment | relationship development | confession / reunion / recognition |
| Hidden-strength reveal | hidden power suddenly shown | the weak one is actually the strong one |

### Hook types

| Type | Definition | Example |
|------|------|------|
| Suspense hook | unresolved mystery | "Why did the sword choose him as master?" |
| Conflict hook | direct confrontation | opening chase |
| Contrast hook | violates common sense | "Bankrupt on the first day of transmigration" |
| Immersion hook | reader resonance | similar dilemma |
| Information-gap hook | reader knows what the character doesn't | "He doesn't know that what's in front of him is…" |

### Payoff loop structure

Three-layer micro-loop:
- **Setup layer (charging)**: oppression / dilemma / information gap create an emotional gap
- **Release layer (gratification)**: showing strength / comeuppance / domination; intensity set by reaction-layer count and length
- **Handoff layer (transition)**: the old loop ends and plants a new hook

Reaction-layer progression: doubt/contempt → shock/comeuppance → the strong re-evaluate → diffusion effect
Reaction-length ratio = reaction total words / flex words. Below 1.5 = the gratification wasn't caught.

### Handoff/transition patterns

| Pattern | Mechanism | Example |
|---------|-----------|---------|
| Beat the small, the big comes | the release layer's opponent calls a stronger one | beat the disciple → the master shows up |
| Win, then find the hidden problem | successful release exposes a new issue | won the match → discovered poison |
| Identity exposure/reversal | identity recognized mid-release | recognized for who they really are after the comeuppance |
| Stakes escalation | results point at a bigger goal | clue → deeper treasure |
| Relationship upheaval | the release changes the relationship landscape | the person you saved is the enemy's descendant |

### Genre payoff shapes

| Genre | Release-layer form | Reaction-layer source | Setup-layer gap |
|-------|--------------------|-----------------------|-----------------|
| Xianxia/cultivation | power domination / realm breakthrough | sect peers / rivals / elders shocked | incomplete technique / scarce resources / bloodline suppression |
| Urban | prediction accuracy / identity reveal | business rivals / ex-girlfriend / the powerful | bankruptcy / fired / engagement broken |
| System fiction | rare skill unlock / quest rewards | system rarity labels | quest-failure penalties / skill cooldowns |
| Historical | weak-beats-strong / foresight advantage | advisors / emperors / enemy generals shocked | information asymmetry / low status |
| Mystery | truth reveal / counter-kill | the exposed one crumbles / reader epiphany | misdirecting clues / suspect exonerated |

---

## Quick preview report

The Stage 1 stop-point deliverable, written to `teardown-lib/{Book Title}/quick-preview.md`. **Every field comes from Stage 0/1 data already produced** (overview.md + opening-hook-chapters deep dives); don't introduce fields that would need Stage 2-6 to compute. It's upward-compatible with the final `teardown-report.md` — the "Basic info" and "Opening-chapter scorecard" sections share the same name and structure; after the full teardown, `teardown-report.md` is a superset of `quick-preview.md`.

```markdown
# Quick preview: {Book Title}

> Early judgment based on the opening hook chapters + the whole-book overview. The full teardown follows in Stage 2-6.
> Status: Stage 0-1 done, {paused / full teardown continued}

## Basic info

Title | Genre | Total chapters | Total words | Target platform (the source book's platform, identified during the teardown; leave blank if none)

## Opening-chapter scorecard

Directly reuse the three opening-chapter deep-dive conclusions, 5-dimension scoring table:

| Dimension | Score | Notes |
|-----------|-------|-------|
| Opening hook | 1-5 | |
| Protagonist building | 1-5 | |
| Payoff design | 1-5 | |
| Worldview laying-out | 1-5 | |
| Chapter-end suspense | 1-5 | |

## Opening judgment

- Opening hook type and effect (from Stage 1 chapter 1 "opening hook")
- Protagonist character-building technique
- Worldview laying-out method
- Opening-hook-chapters rhythm: each chapter's function

## Early borrowable points

3-5 items aggregated from each chapter's "borrowable elements" in Stage 1.

## Is a full teardown worth it — recommendation

One-sentence conclusion: based on the quality of the opening hook chapters, {continue the full teardown / focus on tearing down a specific part / this book's reference value is limited}.

## Next step

Continuing the full teardown produces: per-chapter summaries, plot aggregation, character files, worldview settings, and the complete teardown report.
```

> `quick-preview.md` and `teardown-report.md` coexist: the former is the stop-point snapshot, the latter is the final state. Don't delete `quick-preview.md` once the final report exists — keep the early-judgment trace.

---

## Stage 0 overview (thin first-pass)

> **Scope note**: Stage 0 may only produce the thin first-pass (~200 words) based on chapter titles + volume/part structure + sampled openings/endings. **Forbidden** to write the 500-1000-word plot-aware overview at this stage — the reading scope can't support that density. The full version is written over it at Stage 5 (see "Stage 5 final report + whole-book overview" below).

Output `overview.md`: total words {X}K | total chapters {N} | genre {type}

| Volume/Part | Chapter range | Chapters | Estimated words |
|-------------|---------------|----------|-----------------|
| {volume name} | Chapters 1-X | {N} | {W}K |

First-pass overview (~200 words, thin): {the core driver + protagonist name + rough setting generalized from chapter titles + chapter-1/end-chapter sampling; don't force plot turns}
Chapter index: | Chapter | Title | Word count |

> After Stage 5 completes, the "first-pass overview" section of this file is overwritten in place by the "whole-book overview (500-1000 words, plot-aware)". The chapter index and volume/part table stay unchanged.

## Stage 1 opening hook chapters

The three opening chapters are torn down into three single-chapter files, one per chapter: `chapters/chapter_1_deep-dive.md`, `chapter_2_deep-dive.md`, `chapter_3_deep-dive.md`. Each file follows the template below.

~{X} words | Core event: {one sentence}

**Opening hook** (chapter 1: look at the first 500 words): type{suspense/conflict/contrast/immersion/information-gap} | technique{description} | effect{strong/medium/weak}—{reason}

**Character entrances**: {list} | Protagonist building{direct description/dialogue/behavior/others' assessments} | First impression{description}

**Worldview laying-out**: reveals{info} | hides{info} | method{dialogue/narration/event}

**Structure breakdown**: | Passage range | Function{setup/conflict/payoff/wrap-up} | Word count |

**Payoff analysis**: type{status-flex comeuppance/comeback reversal/fortune gained/information-gap domination/emotional fulfillment} | setup{X} words / release{Y} words / setup-release ratio{Z:1} | emotion curve

**Reaction-layer breakdown** (if any):

| Layer | Character | Reaction | Length |
|-------|-----------|----------|--------|
| Doubt/contempt | | | |
| Shock/comeuppance | | | |
| The strong re-evaluate | | | |
| Diffusion | | | |

Reaction-length ratio {N:1} — below 1.5 = insufficient gratification

**Post-release follow-through** (if any): the antagonist's real attitude after the payoff releases? {behavior + source quote}

**Conflict escalation** (if any): {behavior} | escalation level{verbal → financial → physical} | effect on the character profile

**Background-info reveal** (if any): reveals{what} | narrative function{overthrows a premise / re-interprets / plants a new line / cognitive bias} | effect on the main line

**Chapter-end hook**: type{suspense/reversal/new info/new character} | content{description} | expectation strength{strong/medium/weak}

**Borrowable elements**: {reusable techniques}

> Chapters 2-3 additionally focus on: info density / conflict escalation (vs the previous chapter) / rhythm change / payoff interval in words.
> If the antagonist is non-human (abstract-adversary types: qi-revival, apocalypse, national-fate), use the abstract-adversary routing in "Payoff analysis" instead: core adversarial front{description} | source of urgency{description} | escalation mechanic{description} | narrative substitute{what replaces the traditional comeuppance}.

## Stage 2 chapter summary + plot points

Output `chapters/chapter_{N}_summary.md`:

**Summary**: {100-300 words, written as a single flowing paragraph — no line breaks, no bullet lists. Tell in event order, coherently, what happened in this chapter, why, and what resulted. Cause and effect written truthfully, but not chained by the same connector ("because…so…") repeatedly. Prioritize: actions and results that change the story's direction, abnormal information, foreshadowing threads that will carry into later chapters, distinctive concrete details (numbers, verbatim lines, abnormal phenomena). Only facts present in this chapter's source — no empty praise ("moving", "brilliant", "shocking") and no subjective interpretation}
**Key events**: 1.{event} 2.{event} 3.{event}

**Key info and expansion techniques**:

| Key info / plot direction | How the source expanded it | Expansion technique | Effect on reader emotion | Reusable reminder |
|---|---|---|---|---|
| {what this chapter must make the reader know / misjudge / expect / confirm} | {which events, dialogue, reaction layers, details, misdirection or callbacks the author used to expand it into scenes} | {delayed setup/reaction-layer amplification/information gap/contrast anchor/delayed reveal/body reaction/nested small goals/other} | {curiosity/anticipation/oppression/gratification/sympathy/tension/warmth/hype/other} | {keep the emotional logic; replace characters, scenes, event material; copying specific scenes is forbidden} |

**Per-chapter writing formula**:

- **Emotional flow**: open:{opening emotion} → develop:{setup/pressuring emotion} → turn:{eruption/reversal emotion} → close:{aftershock/hook emotion}
- **Pacing mix**: slow setup {X%} / fast conflict {X%} / payoff eruption {X%} / suspense white space {X%}
- **Chapter structure formula**: {node 1 action (purpose)} + {node 2 action (purpose)} + {node 3 action (purpose)} + {node 4 action (purpose)}
- **Core technique of this chapter**: {one sentence on the chapter's most transferable structural technique, e.g. amplifying an information gap with a reaction layer, or using small goals to carry a big conflict; describe the craft only, don't grade quality}
- **Hook and foreshadowing**: chapter-end hook: {type + content + next-chapter expectation}; foreshadowing planted/recovered: {foreshadowing name/object/info → chapter function}

**Cast of characters**: | Character | Importance this chapter | Aliases | Performance this chapter |

**Plot points** (10-40 per chapter, adjusted by word count, 150-200 words/point; hard floor of 10 — short chapters split the full key steps):

Too coarse (a whole fight in one point) → loses detail; too fine ("raised his right hand") → fragmented. Right-sized: a complete dramatic event ("the protagonist defeats the antagonist in three moves; the onlookers are stunned").

P{index} **{title}**: type{turning point/info reveal/conflict/resolution/setup/action/dialogue/state change} | {one-sentence plain description: who did what, with what result; include causes or reasons given by the source; write out foreshadowing clues when planted; no motive speculation} | involves{full names, comma-separated; for pure environmental setup with no named characters, keep the "involves" label with an empty value} | location{if clear} | item{if involved} | time{if clear}

> The title is a short label of ≤15 words (e.g., "courtroom scene", "dragon-blood needle test"); the plain description is the sentence that carries the facts. Don't make them the same sentence — restating the title isn't a plain description.

{optional quote line: ≤400 words of verbatim source quote, no "source quote:" label. Only for key plot points; selection criteria below; unselected plot points just jump to the next line}
Theme tags{romance/family/friendship/growth/mystery/adventure/revenge/redemption/survival/identity/other} | Tone: {tense/light/sad/hot/sweet/warm/horror/oppressive/other}

> End-line hard constraints: the `Tone:` ASCII colon must not be omitted (Stage 6 style greps on it); `Theme tags` takes no colon; both take only the listed enums — don't mix (warm/horror/tense are tones, not themes); use "other" when nothing fits.
>
> Enum disambiguation: sweet = the cathartic relief of a comeuppance/revenge landing or a reversal paying off; hot = the burning hype of striving/fighting; warm = romantic-ambiguity sweetness; horror = eerie/visceral fear; tense = a crisis hanging unresolved. Themes: family = family/mentor/quasi-family bonds; romance = romantic love; friendship = friends/partners/brothers; growth = personal growth; mystery = suspense/investigation; adventure = quests/exploration; revenge = revenge; redemption = redemption; survival = survival; identity = identity. Use "other" only when nothing fits — don't force near-synonyms.

**Plain-description iron rules** (the P-line plain description is the plot point's primary evidence; if it's wrong, everything downstream tilts):

| Dimension | Forbidden | Correct |
|-----------|-----------|---------|
| Emotion | Shaoyang felt heartbroken and angry (the source only shows him seeing the embrace) | Shaoyang watched Song Li hug someone; his expression went from stung to cold |
| Judgment | This was a brilliant fight | Lin Lei defeats the opponent in three moves; the onlookers gasp |
| Atmosphere | The atmosphere grew tense | Everyone stopped talking; all eyes fixed on the door |
| Intent | He wanted to show off his strength | He lifts the stone lock overhead one-handed and sweeps his gaze around |
| Narrative-frame words | Through the conversation, Zheng Song learned that Zhang Zihao trained in Korea | Wu Zhibin told Zheng Song that Zhang Zihao trains in Korea |

Causes, reasons, and inner states the source explicitly gives are written as-is ("his savings ran out, so he went to Xu Xinnian to borrow money" — the cause comes from the source); you just don't speculate motives the source never wrote. When the source gives both, prefer external behavior. Plot points strictly follow the source's event order — no reordering, no logical regrouping.

**Source-quote rules (curated, not point-by-point)**: the plot point's primary evidence is the P-line plain description — facts, results, source-given causes, and foreshadowing clues must be complete there. Quotes are supplementary evidence; keep them only for three kinds of plot points: key turning points (turns/solutions that change this chapter's or the whole book's direction), key lines (distinctive verbatim lines that will be called back), and craft samples (passages worth re-checking as sentence/rhythm/dialogue samples).

- At most 8 per chapter; other plot points get no quote line. If the chapter genuinely has nothing worth re-checking, you may leave zero — don't pad transitions and pure environment setup with quotes
- Quotes ≤400 words, verbatim contiguous slices, preserve the source's tone — no rewriting, no abbreviating, no cross-paragraph stitching
- If the selected passage is too long or scattered, use a `Source locate: {5-15 word phrase greppable back to the source}` line instead of a full quote

**Stage 2 output self-check** (same requirements for both the parallel-agent path and the solo/direct serial path): the summary is a coherent chronological narrative (not a bullet list, not chained by one connector) ｜ every plot point's plain description is objective and complete with facts/results/source-given causes ｜ titles are ≤15-word short labels not sharing a sentence with the plain description ｜ plot points strictly chronological ｜ plot-point count 10-40 (adjusted by word count; hard floor 10) ｜ key-turning-point/key-line/craft-sample plot points carry a quote or `Source locate`, at most 8 per chapter ｜ characters use full names ｜ type/tone/theme tags only from the listed enums ｜ character descriptions don't span chapters ｜ `Key info and expansion techniques` and `Per-chapter writing formula` complete.

## Stage 2 character filtering

| Category | Criterion | Extraction depth |
|----------|-----------|------------------|
| Not extracted | appears once with no lines (generic passerby) | skip |
| Simplified extraction | appears 2-3 times with a single function | function label + first chapter |
| Full extraction | appears 3+ times / has lines and drives plot / interacts directly with the protagonist | full file |

Alias merging: the first formal name is the main entry; aliases listed in `aliases: []`.

## Stage 3 aggregation analysis

### Stage 3 prerequisite: story-framework recognition

Written at the top of `plot/storylines.md`:

```markdown
## Story framework

| Item | Content |
|------|---------|
| Framework type | {escalation flow/revenge line/daily-unit/multi-line interweaving/transformation growth/mixed} |
| Core driver | {one sentence on the book's core narrative engine} |
| Spine contradiction | {the fundamental contradiction running through the book} |
| Escalation mechanic | {how power/status/relationships escalate; "—" if none} |
| Narrative rhythm pattern | {the typical cycle: setup → conflict → payoff → new suspense} |
| Basis | {which chapters/plot points support this judgment} |
| Expected plot count | {expected range based on total chapters; see the expected-count guide table in material-decomposition.md} |
```

**Post-recognition self-check** (written after the framework section of `plot/storylines.md`):

```markdown
## Framework-recognition self-check

| Check | Result | Notes |
|-------|--------|-------|
| Coverage | {X%} | {covered chapters/total chapters} |
| Granularity check | {pass/fail} | {if failing, which plot is too fine/too coarse} |
| Independence check | {pass/fail} | {if failing, which plot fails which criterion} |
| Count check | {pass/fail} | {actual plot count vs expected range} |
```

### Stage 3 authoritative artifact division

Besides the plot files, Stage 3 must write a lightweight index `plot/README.md` and two authoritative files:

```markdown
# Plot Directory Index

| File | Authoritative scope | Downstream use |
|---|---|---|
| `pacing.md` | key-info progression, payoff cycles, emotional touchpoints, burst rhythm | produces `rhythm_reference` |
| `emotional-beats.md` | reader needs, emotional engine, trope frameworks, reproducible module cards | produces `selected_emotion_module` |
| `storylines.md` | story framework and storyline summaries | summary projection; doesn't override authoritative files |
| `teardown-report.md` | human-readable report | summary projection; doesn't override authoritative files |

On conflict, `pacing.md` / `emotional-beats.md` win; the two files cross-reference each other with EM/RH/TR IDs.

## Story-unit list

| Story unit | Type | Trope tags | Chapter range | Size |
|---|---|---|---|---|
| `{title}.md` | {type} | {trope tags} | Chapters {X}-{Y} | {N} chapters, about {M}K words |

The list is only a retrieval-index projection (each column takes the story unit's existing fields); the authoritative plot definitions live in each story-unit file; rhythm/emotion authority still lives in `pacing.md` / `emotional-beats.md`.
```

- `plot/pacing.md` is the **rhythm-and-touchpoint authoritative index**: key-info progression, payoff cycles, emotional touchpoints, burst rhythm, and long-gap risks all land here.
- `plot/emotional-beats.md` is the **reader-needs-and-reproducible-modules authoritative index**: why readers love it, how the emotional engine runs, how gratification tropes embed into the story framework, and how to reassemble and reproduce them.
- `plot/storylines.md` and `teardown-report.md` only write summaries and references; they don't copy full module definitions. On conflict, downstream writing reads `plot/pacing.md` / `plot/emotional-beats.md`.

### Stage 3 plot

Output `plot/{title}.md`:

| Item | Content |
|------|---------|
| Title | concise and strong, ≤15 words |
| Type | {main line/romance/growth/revenge/treasure-hunting/mystery/combat/scheming/cultivation/crisis/enigma/daily/other} — mystery = active deduction/investigation; enigma = unsolved world/identity questions |
| Summary | {150-300 words, a coherent chronological narrative of this line's setup-development-turn-climax and causality, not chained by one connector; includes core characters and their roles, key locations, key props (if any), and the impact on the protagonist/world} |
| Core goal | {a concrete, measurable dramatic goal, e.g., "win the tournament championship"} |
| Core conflict | {specific conflict target + conflict event} |
| Key-info function | {what information this line exists to make the reader gain/wait-for/misjudge/confirm} |
| Reader need | {which of safety/superiority/anticipation/emotional compensation/cognitive reversal/companionship it satisfies} |
| Emotion module ID | {reference EM-001 etc. in `plot/emotional-beats.md`; don't repeat the full card here} |
| Trope-framework position | {broken-engagement comeuppance/late regret/upgrade trial/identity-reveal shock/small-beats-big/other; explain how it runs inside this story framework} |
| Trope tags | hit items from the trope word list, comma-separated; may add tropes genuinely present but not in the list; empty when no match, don't force (list in references/deconstruction-notes.md) |
| Chapter range | Chapters {X}-{Y} ({N} chapters, about {M}K words) |

Structure distribution: setup period | development period | climax period | wrap-up period (each with its chapter range)

Plot-point index: | Index | Chapter | Description | Assignment confidence |

### Stage 3 storylines

Output `plot/storylines.md` (after framework recognition):

Per storyline:

| Item | Content |
|------|---------|
| Title | concise and strong, ≤15 words |
| Type | {main line/romance line/growth line/revenge line/treasure line/conflict line/enigma line/other} |
| Description | {300-600 words, divided into 3-8 development phases; each phase includes: core conflict, key characters and their roles, capability/resource/status evolution, thematic motifs. Track the foreshadowing plant-and-recovery chain. Note interweaving with other storylines} |
| Emotional-engine summary | {1-2 sentences on how this line creates gaps, delays gratification, releases, and leaves aftershocks; details point to `plot/emotional-beats.md`} |
| Trope operating mode | {how gratification/emotion/mystery tropes embed in the story framework rather than standing alone; details point to the module ID} |
| Themes | {at most 3} |
| Contained plots | {plot-title list in chronological order. Each storyline contains at least 1 plot} |
| Module references | {EM-001, EM-002; references only, don't copy full cards} |

Storyline relationships: parallel / interwoven / dependent

### Stage 3 pacing.md (authoritative index)

Output `plot/pacing.md`:

```markdown
# Pacing Index: {Book Title}

> Authoritative scope: key-info progression, payoff cycles, emotional touchpoints, burst rhythm. `teardown-report.md` only quotes this file's summaries.

## Whole-book emotional rhythm overview

- Emotion polyline: {oppression/anticipation → tension/pressure → gratification/reversal → aftershock/new crisis; mark key chapter ranges}
- Payoff frequency: {a small payoff every N chapters; a medium climax every M chapters; big-climax positions}
- Climax distribution: small climaxes: Chapters {X/Y/Z}; medium climaxes: Chapters {X/Y}; big climax: Chapter {X}
- Conflict escalation path: {low-level conflict → mid-level conflict → high-level conflict → endgame conflict; mark trigger chapters}
- Cross-chapter foreshadowing map: {foreshadowing | how it was planted in Chapter X → recovery effect in Chapter Y; only list foreshadowing spanning more than 2 chapters or affecting the main line}

## Loop units

- Small loop (about 3 chapters): {gap/misjudgment → pressure/probe → release/new hook; what varies}
- Medium loop (about 7 chapters): {phase goal → multiple rounds of obstruction → mid-loop reversal → phase payoff → bigger problem}
- Large loop (about 15 chapters): {volume goal → resource/relationship/opponent upgrade → core conflict eruption → aftershock and transition}

## Key-info progression table

| Chapter/range | Key info | How expanded | Progression function | Rhythm effect | Related plot/module |
|---|---|---|---|---|---|
| Chapter {N} | {info the reader must gain/misjudge/wait for} | {dialogue setup/event validation/reaction layer/delayed reveal/multi-segment callback} | {set goal/pressure/release/transition/plant hook} | {speed up/slow down/charge/erupt/cool down} | {plot title / EM-001} |

## Payoff-cycle index

| Cycle ID | Chapter range | Setup layer | Release layer | Reaction layer | Handoff/new hook | Intensity progression |
|---|---|---|---|---|---|---|
| RH-001 | Chapters {X}-{Y} | {oppression/misjudgment/anticipation gap} | {comeuppance/identity reveal/goal achieved/emotional fulfillment} | {who is shocked/regretful/re-evaluating} | {new expectation raised after the old payoff} | {stronger/weaker than the previous round, in what way} |

## Emotional-touchpoint index

| Touchpoint ID | Chapter | Triggering event | Target reader emotion | Eruption point | Aftershock/cool-down | Reproduction note |
|---|---|---|---|---|---|---|
| TR-001 | Chapter {N} | {the specific plot that triggers reader emotion} | {anticipation/sympathy/anger/gratification/warmth/hype/fear} | {the highest-emotion sentence/passage or event} | {character reaction/relationship change/new suspense} | {keep the emotional chain; don't carry the specific event} |

## Burst-rhythm summary

- Burst density: {once every N chapters / once every N words / peak position within a volume}
- Burst form: {progression / delayed gratification / W-shape / staircase / unit loop}
- Long-gap risks: {which ranges have too few touchpoints, and how the author sustains with small hooks}
- Downstream writing reminder: {how to schedule touchpoints per chapter/volume when reproducing in a new book}
```

### Stage 3 emotional-beats.md (authoritative index)

Output `plot/emotional-beats.md`:

```markdown
# Emotional Beats: {Book Title}

> Authoritative scope: reader needs / emotional engine / trope-framework operation / reproducible modules. Copying the source's specific scenes as templates is forbidden.

## Reader needs / emotional engine

| Reader need | How this book satisfies it | Evidence chapter/plot point | Sustained-follow mechanic | Transfer boundary |
|---|---|---|---|---|
| {superiority/safety/being understood/vicarious revenge/relationship compensation/cognitive surprise, etc.} | {how the story keeps delivering} | {Chapter {N}/Px} | {how the next-layer expectation gets raised} | {the emotional logic can stay; the specific setting/characters/events must be replaced} |

## Story framework and trope-operation map

| Framework/trope | Position in this book | How it runs | Why it works | Failure risk |
|---|---|---|---|---|
| {broken-engagement comeuppance/escalation flow/late regret/identity reveal/small-beats-big/love-triangle drama/other} | {chapters/story unit} | {setup → delay → release → aftershock} | {the reader need it answers} | {copying it wholesale reads as derivative/character mismatch/insufficient setup} |

## Reproducible module cards

### EM-001 {module name}

| Field | Content |
|---|---|
| What the reader wants to see | {one-sentence abstract need} |
| Emotional chain | {gap → pressure → trigger → eruption → aftershock} |
| Dramatic unit | {the structure stripped of material, e.g., "the disdained one proves the point publicly with results"} |
| Key trigger slots | {replaceable functional slots: misjudger/witness/cost/evidence/reward} |
| Reproduction steps | {1. build the gap 2. add reaction layers 3. control the eruption point 4. raise a new hook} |
| Replaceable items | {character identity, scene, props, opponent type, target outcome} |
| Do not copy | {source proper nouns, specific event order, signature lines, unique settings} |
| Related rhythm | {`plot/pacing.md` RH-001 / TR-001} |

## Reassembly and reproduction guide

1. Pick the reader need first, then the module card — don't back-copy from the source's scenes.
2. Keep the emotional chain and functional slots; replace characters, scenes, motives, props, and event material.
3. When reproducing into a new book's outline, change at least three of: conflict target, public/private setting, triggering evidence, aftershock direction.
4. If the character design conflicts with the module, let the character design drive the module rebuild; don't warp the character to fit a trope.
```

### Stage 3 character operations

**Merge**:
1. Collect all chapters' character-mention data
2. Alias matching (only proper_name and nickname, confidence ≥0.85)
3. descriptor/title never triggers a merge
4. After confirmation, keep the first formal name

**Tiering**:

| Tier | Criterion | Extraction depth |
|------|-----------|------------------|
| Protagonist | appears in ≥50% of chapters + drives the main line + has a full growth arc | full file + arc + motive chain |
| Antagonist | opposes the protagonist + drives the core conflict + has a clear motive | full file + motive chain |
| Core supporting | appears in ≥20% of chapters or drives an important subline | full file + relationships |
| Functional | appears in <20% of chapters + limited function | simplified file |

Ambiguous boundaries default to the lower tier.

### Stage 3 loose-thread safety net

1. Compute the orphan ratio; <5% → skip the rest (write the few strays into loose-threads.md)
2. List the unassigned plot points
3. Compute relevance on three clues — character overlap, location overlap, causality (three-tier confidence)
   - Strong correlation (0.8-1.0): assign to the existing unit, mark `[orphan assigned]`
   - Medium correlation (0.5-0.8): mark `[low-confidence assignment]`, pending review
   - Weak correlation (<0.5): don't force assignment; better left unassigned
4. <0.5 clusters by theme, mark `[cluster-generated]` (only create a unit with ≥5 points)
5. Unclassifiable → write into `loose-threads.md`; don't force into unrelated plots
6. Coverage validation: target thresholds in the quality-threshold system of [material-decomposition.md](material-decomposition.md); if not met, return to step 3 and retry with lowered thresholds

### Stage 3 coverage

Coverage = classified count / total count × 100%, target thresholds in the quality-threshold system of [material-decomposition.md](material-decomposition.md).

## Stage 4 setting + relationships

> **Stage 4 writes multiple topic-split files directly** (aligned with the current import and long-form writing project structure). Downstream no longer splits flat files on the fly.
> **Fact fidelity**: hard facts such as ranks/numbers/distances/attributes/faction counts must be checked against the source; what the source doesn't give is written as "not stated in the source" — inventing fills is forbidden (see "fact fidelity in the synthesis stage" in material-decomposition.md).

`setting/worldview/power-system.md`:
- Text description, incl. ranks and promotion conditions. Note multi-tier power systems for long-form
- Content < 200 words and not an independent system → merge into `setting/worldview/background.md`; this file may be omitted

`setting/worldview/geography.md`:
- Distribution, main regions, key locations (text description)
- Content < 200 words → merge into `background.md`; this file may be omitted

`setting/worldview/background.md`:
- Core rules + special settings
- Things too small to stand alone ("power system / geography / factions") also merge here
- No special worldview: this file outputs "This book is a realistic-genre work with no special worldview"

`setting/cheat.md`:
- Type{system/space/rebirth/transmigration/special_physique/artifact/bloodline/other} | Name | Description (300-600 words, incl. capability/acquirement/mechanic/evolution history/multi-capability development) | Core mechanic | Current capability
- Merge rules per the "cheat merge rules" in material-decomposition.md
- No cheat: output an empty file noting "this book has no obvious cheat/special-ability setting"

`setting/factions/{Faction Name}.md` (one file per core faction):
- Name / type (sect/organization/family/nation) / core figures / stance / relations with other factions / key events
- Standalone when ≥200 words; otherwise merge into `setting/worldview/background.md` (no information lost)

`characters/{Character Name}.md` (per character):
- 200-500-word file (identity background → core experiences → personality traits → abilities/skills → relationships → growth trajectory)
- archetype: protagonist/antagonist/supporting/minor
- Key plot events (3-5 turning points, chronological)
- Growth arc (character_arc: summarize if visibly changing, e.g., "from an ordinary boy to a powerhouse awakened with bloodline")
- Alias list (with type and confidence)

`characters/relationships.md` (batched every 5 chapters, extracted from plot points): A<->B: relationship type | emotion | description (50-200 words) | evolution trajectory. Keep the latest state per pair; historical changes go into the evolution trajectory.

## Stage 5 final report

Output `teardown-report.md` (a superset of `quick-preview.md`; the two shared sections keep the same names and structure — see "Quick preview report" above).

Report sections:

- **Basic info**: Title | Genre | Total chapters | Total words | Target platform (same structure as `quick-preview.md`)
- **Opening-chapter scorecard**: the 5-dimension scoring table (opening hook / protagonist building / payoff design / worldview laying-out / chapter-end suspense; same structure as `quick-preview.md`)
- **Reader needs / emotional engine**: summary of `plot/emotional-beats.md`'s core reader needs, emotional gaps, and sustained-follow mechanics (the report only summarizes; details live in the module file)
- **Structure analysis**: main line / sublines / story units / coverage
- **Key info and expansion techniques overview**: how key plot info is expanded per chapter/story unit (details per `chapters/*_summary.md` and `plot/pacing.md`)
- **Whole-book emotional rhythm overview**: summary of `plot/pacing.md`'s emotion polyline, payoff frequency, small/medium/large climax distribution, loop units
- **Payoff density**: {N} cycles/{M} chapters | completion {X%} | density{high ≥70% / medium 50-70% / low <50%}
- **Rhythm and emotional touchpoints**: summary of `plot/pacing.md`'s burst density, touchpoint distribution, long-gap risks, burst rhythm
- **Foreshadowing and conflict network**: cross-chapter foreshadowing map (only foreshadowing spanning >2 chapters or affecting the main line) + conflict escalation path (low → medium → high → endgame)
- **Core mechanics**: payoff types | rhythm pattern | update strategy
- **Character system**: protagonist/antagonist/core supporting/functional tiering overview
- **Quality assessment**: confidence / coverage / overlap
- **Borrowable tropes**: 1.{trope + scenario} 2.{...} 3.{...}, each with its `EM-*` module ID
- **Reproducible modules**: Top 3 modules from `plot/emotional-beats.md` — reader need, emotional chain, replaceable items, do-not-copy items
- **Writing techniques**: 1.{technique + usage} 2.{...} — covering one-stroke-two-uses, delayed reveal, POV deception, contrast anchors, behavior loops, body reactions replacing inner monologue, **cross-chapter callbacks** (objects/imagery serving different functions in different chapters)
- **Not recommended to imitate**: 1.{problem + reason}

## Stage 6 style

Output `teardown-lib/{Book Title}/style.md`. A whole-book writing-technique view, fed to the narrative-writer in story-long-write's daily-update loop.

**Field quick reference**:

| Section | Content | Confidence required | Cap |
|---|---|---|---|
| Generation record | materials consulted + chapters sampled + style usable or not | no | <100 words |
| Overall voice | sentence-length distribution / punctuation habits / paragraph rhythm | yes (per subitem) | ~500 words |
| Dialogue technique | subtext patterns / dialogue tags / character voice differentiation | yes (subtext required) | ~400 words |
| Emotional alternation pattern | in-chapter tone switching / cross-chapter tone cycle / comedy↔heavy-beat transitions | yes (in-chapter required) | ~400 words |
| Borrowable techniques | Top 5 writing techniques + Top 3 borrowable tropes (quoted from the teardown report; emotional/rhythm intent only references `plot/emotional-beats.md` / `plot/pacing.md`, not redefined in the style) | no | ~300 words |
| Tiered imitation advice | base tier / advanced tier / adaptation tier, each with executable boundaries | no | ~350 words |
| **Source anchor excerpts** | **4-6 × 300-500 words**, by tone class, labeled "source + line numbers + demonstrates" | no | ~2400 words |
| Do not imitate | the benchmark book's weaknesses or techniques that don't fit the project | no | <100 words |

**Total cap ~4000 words**.

Full template and generation method: [style-profile-protocol.md](style-profile-protocol.md) + [style-profile-generator.md](style-profile-generator.md).
