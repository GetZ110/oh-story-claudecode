# Novel Material Decomposition Methodology

---

## The 5-phase decomposition process

### Phase 1: Chapter parsing

- Recognize chapter separators (Chapter X, `###01`, numbered titles, etc.)
- Extract chapter titles, record each chapter's word count

### Phase 2: Atomic extraction (parallel agents, one per chapter)

Parallel/degradation strategy: see "Stage 2 parallel agent strategy" in SKILL.md.

Agent output format strictly matches the merged A/B/C/D output of this phase; see the Stage 2 templates in output-templates.md.

#### A. Chapter summary

- Chapter summary (100-300 words; coherent chronological narration of events, causes, results; writing rules and self-check in output-templates.md "Stage 2 chapter summary + plot points")
- Key events (3-5, in time order)
- Cast of characters, theme tags, chapter tone
- Plot progress (major turn / daily transition / setup foreshadowing)

#### B. Plot-point extraction (10-40 per chapter, adjusted by word count)

Density formula: word count ÷ 200 (floor) to word count ÷ 150 (ceiling), i.e. one plot point per 150-200 words. When the formula lands outside [10, 40], the hard bounds win.

| Words | Target range | Notes |
|-------|-------------|-------|
| ≤1000 | 10 | short chapters split the full key steps by the hard floor (formula suggests 5-7; floor is 10) |
| 3000 | 15-20 | standard density |
| 5000 | 25-34 | medium-long chapter |
| 8000+ | ≤40 | long-chapter cap |

Written as the plot-point subsection of the chapter summary .md (no separate .json output). Each plot point:

| Field | Notes |
|-------|-------|
| Index | strictly chronological |
| Title | ≤15-word short label; not the same sentence as the description |
| Type | turning point/info reveal/conflict/resolution/setup/action/dialogue/state change |
| Description | objective plain description: who did what, with what result; causes given by the source included; write out foreshadowing clues when planted (no narrative-frame words, no motive speculation) |
| Source quote | curated, not point-by-point: only key turning points / key lines / craft samples, ≤8 per chapter, ≤400 words contiguous slices; when too long or scattered, use `Source locate: {5-15 word phrase}` instead |
| Characters involved | full names, no pronouns |
| Location | geographic info |
| Key item | items related to the plot |
| Time marker | relative time (next day, half a month later, at the same time) |

#### C. Key info and expansion-technique extraction

Each chapter must additionally output the `Key info and expansion techniques` table, the base data for `plot/pacing.md` and `plot/emotional-beats.md`. It avoids subjective commentary by separating "the plot info this chapter must deliver" from "how the author expanded it into a readable scene".

| Field | Extraction method |
|-------|-------------------|
| Key info / plot direction | from key events and plot points, generalize what this chapter must make the reader know / misjudge / expect / confirm |
| How the source expanded it | record which events, dialogue, reaction layers, details, misdirection, callbacks the author used to expand the info into scenes |
| Expansion technique | choose or supplement from: delayed setup / reaction-layer amplification / information gap / contrast anchor / delayed reveal / body reaction / nested small goals / other |
| Effect on reader emotion | label the curiosity / anticipation / oppression / gratification / sympathy / tension / warmth / hype etc. the expansion produces |
| Reusable reminder | abstract the emotional logic and functional slots only; copying specific scenes, lines, proper nouns, or unique settings is explicitly forbidden |

Quality: at least 1 row per chapter; standard chapters usually 2-5. If the chapter is only a transition, say what expectation it sustained or what emotion it cooled — don't write "none".

#### D. Character extraction

Per character: external presentation (identity/speech-and-deeds/appearance), function in this chapter, aliases.
Only record newly appearing characters or new developments of existing ones.

**Character-importance tiers** (by this chapter's screen time):

| Tier | Criterion |
|------|-----------|
| **major** | chapter core: ≥3 lines OR drives this chapter's main line OR makes an important decision |
| **supporting** | chapter secondary: 1-2 lines OR participates but isn't core |
| **minor** | mentioned only OR no lines but named |

### Phase 3: Aggregation analysis (cross-chapter)

> **Corpus reading**: this phase and phase 4a/4c and the loose-thread safety net read "all chapter summaries / all plot points" **once from `_merged-summaries.md`** (the whole-book concatenation produced at the Stage 2 wrap-up, see SKILL.md "Stage 2 wrap-up: merging chapter summaries") **and reuse it in context** — no per-file glob rescanning; 4-5 cold reads of the same corpus become 1. If the merged file is missing or the corpus exceeds context, fall back to the original "scan all chapter summaries" per-file method / chunking strategy — behavior unchanged.

#### 0. Story-framework recognition (aggregation prerequisite)

Before aggregating plots, recognize the whole book's story framework. The framework decides the aggregation strategy:

| Framework type | Traits | Aggregation strategy |
|----------------|--------|----------------------|
| Escalation flow | clear tier system, segmented by realm | divide story units by tier/realm stage |
| Revenge line | clear core contradiction, goal-driven | divide by revenge target/stage |
| Daily/unit | each volume a self-contained story, weak continuity | divide by volume/unit |
| Multi-line interweaving | multi-POV / multi-timeline | divide by thread; mark intersections separately |
| Transformation growth | protagonist's inner change is the main line | divide by growth stage |

Recognition method: scan `overview.md` (the Stage 0 thin first-pass suffices; no need to wait for the Stage 5 whole-book overview) + the first 3 chapter summaries + the last 3 chapter summaries to judge the core driving pattern.
Output written into the framework-recognition section of `plot/storylines.md`.

**Expected story-count guide** (mandatory reference, not a suggestion):

| Total chapters | Expected independent plots | Basis |
|----------------|---------------------------|-------|
| <30 chapters | 3-6 | short-form, compact structure |
| 30-100 chapters | 5-15 | each plot spans 5-20 chapters |
| 100-300 chapters | 10-25 | main line + sublines + supplements |
| >300 chapters | 15-40 | multi-volume multi-line structure |

A deviation beyond ±30% requires re-checking granularity. First principle: keep the complete narrative arc of the core dramatic goal.

**Granularity-tier mess detection** (self-check after framework recognition):

| Mess pattern | Detection | Fix |
|--------------|-----------|-----|
| Containment | plot A's chapter range fully contains plot B | keep the appropriately-sized B; split the too-coarse A |
| Overlap >50% | two plots share over half their chapters | check whether "plot" and "plot stage" got confused |
| Plot is only another plot's opening/ending | plot A covers only the first/last few chapters of plot B | merge into one plot, B's stages |
| Plot has no independent goal | goal description is another plot's subgoal | demote to that plot's stage |

**Post-recognition self-check** (must pass before aggregation):
1. Coverage: do all plots' covered chapters (deduped) reach ≥85%?
2. Granularity: any too-fine (single event) or too-coarse (macro theme) plots? Run the granularity-tier mess detection
3. Independence: does every plot meet the 4 independence criteria?
4. Count: is the total plot count within the expected range?

#### A. Plot aggregation (two-step)

Split aggregation into two steps: first identify the plot outline from the summaries, then assign plot points by that outline.

**Step one: plot-outline recognition (from chapter summaries)**

Scan all chapter summaries and recognize each independent plot's outline. Each outline includes:

| Field | Notes |
|-------|-------|
| Title | concise and strong, ≤15 words |
| Summary | 150-300 words; coherent chronological causality, not chained by one connector; includes core characters, key locations, event development |
| Core goal | concrete, measurable dramatic goal |
| Core conflict | specific conflict target + conflict event |
| Type | main line/romance/growth/revenge/treasure-hunting/mystery/combat/scheming/cultivation/crisis/enigma/daily/other |
| Themes | at most 3 |
| Chapter range | start/end chapter numbers |

After recognition, run the framework-recognition self-check (4 items).

**Step two: plot-point assignment (by plot outline)**

For each plot outline, scan all plot points and assign the nodes directly serving that goal.

**Assignment logic** (4 steps):
1. **Theme trace and node collection**: for each outline's core goal, scan all plot points and pick the event nodes that directly serve, advance, or block that goal
2. **Boundary recognition**: recognize the plot's start (triggering event / precondition) and end (completion/failure markers), plus the key transition nodes connecting them
3. **Index building and validation**: order the selected plot points chronologically and validate coverage completeness
4. **Profile data supplementation**: based on the final node set, complete fields like the summary and structure distribution

**Plot-point selection criteria** (for judging membership):
- **Theme-related**: point content matches the plot summary and themes
- **Character match**: characters involved relate to the plot's core characters
- **Causality**: the point has a causal or logical continuation with the plot's development
- **Goal-directed**: the point advances or blocks the plot goal
- **Chapter range**: prioritize points within the plot's chapter range

**Plot granularity standard (core requirement)**:

| Granularity | Example | Problem |
|-------------|---------|---------|
| Too fine (single event) | "got the divine artifact" (1-2 chapters), "first cultivation" (Chapter 3) | events, not independent plots |
| Too coarse (macro theme) | "the protagonist's path of growth" (Chapters 1-100) | a theme, not a concrete plot |
| **Right-sized** | "family awakening and inheritance recognition" (Chapters 1-6), "artifact acquisition and meeting the mentor" (Chapters 7-13) | has an independent goal, conflict, character set, and complete narrative arc |

**Plot-independence criteria** (all must hold):
1. **Independent core goal**: a clear, measurable dramatic goal (not a macro theme or abstract concept)
2. **Independent primary conflict**: a concrete opposing force and conflict event (not a sub-stage of a bigger conflict)
3. **Relatively independent character set**: characters specific to this plot (may share some characters with other plots)
4. **Independent narrative rhythm**: its own tension-release rhythm

**Three-tier coverage strategy**:
1. **Main-line plots** (highest priority): drive the overall story, usually 60-70% of chapters
2. **Subline plots**: romance, growth, combat lines, usually 20-30% of chapters
3. **Supplement plots**: transition and daily plots, ensuring coverage ≥85%

**Plot types**:
- Main line (core plot driving the overall story)
- Romance (relationship development)
- Growth (capability/mind/status rises)
- Revenge (revenge-related)
- Treasure-hunting (contending over an item or goal)
- Mystery (deduction, truth reveal)
- Combat (war, tournament, duel)
- Scheming (political struggle, power contention)
- Cultivation (training, breakthrough, inheritance)
- Crisis (crisis response, rescue, escape)
- Enigma (worldview unsolved mysteries, identity secrets, hidden truths)
- Daily (everyday life, transitional content)
- Other (nothing above fits)

Each plot extracts: title, summary (150-300 words, coherent chronological causality), core goal, core conflict, type, chapter range.
Mark the structure distribution: which chapters belong to setup/development/climax/wrap-up periods.

**Core-goal type reference**:
- Acquire: "win the tournament championship", "obtain the key artifact/inheritance", "take the fortress"
- Resolve: "lift the family crisis", "repay the huge debt", "escape the pursuit"
- Create: "found a new sect", "develop a new technique", "start a school"
- Explore: "investigate the parents' disappearance", "explore the ancient ruins", "expose the conspiracy"

#### B. Storyline extraction

Aggregate multiple plots into a "storyline": title, description (300-600 words with development phases), main characters, theme keywords, contained-plot list (at least 1 plot).

**Storyline types**: main line / romance line / growth line / revenge line / treasure line / conflict line / enigma line / other

**Storyline description requirements**:
- Divide into 3-8 development phases (periodization); find key turning points or milestone events as phase boundaries
- Each phase includes: core conflict, key characters and their roles, capability/resource/status evolution, thematic motifs
- Independently track the foreshadowing plant-and-recovery chain (foreshadowing-recovery pairs that echo each other)
- Note interweaving with other storylines (parallel / interwoven / dependent)
- Contained plots in chronological order; each storyline contains at least 1 plot

#### C. Pacing index and emotional-module generation

After Stage 3 aggregation, two authoritative artifacts must be generated, read directly by the Stage 5 report summary and `story-long-write`:

1. **`plot/pacing.md` (pacing authority)**
   - Input: plot points of all chapter summaries, the `Key info and expansion techniques` tables, plot outlines, storylines
   - Output: key-info progression table, payoff-cycle index, emotional-touchpoint index, burst-rhythm summary
   - Method: scan key events and key info in chapter order, marking the chain "info enters the reader's view → delayed/misdirected/validated → emotional eruption → aftershock/new hook"
   - Validation: every payoff/touchpoint must point back to a chapter or plot point; every long gap (3+ consecutive chapters without a touchpoint) must explain how the author sustains anticipation with small hooks or info progression

2. **`plot/emotional-beats.md` (module authority)**
   - Input: story-framework recognition, story units, `plot/pacing.md`, reader-need judgments, trope tags
   - Output: reader needs / emotional engine, story framework and trope-operation map, reproducible module cards, reassembly and reproduction guide
   - Method: first abstract "what the reader wants to see", then abstract concrete plots into emotional chains and functional slots; module cards must include replaceable items and do-not-copy items
   - Validation: best-effort module source labeling (relate to RH/TR entries in `plot/pacing.md` or chapter plot points); when unsure, leave blank, don't force, don't delete modules; copying the source's proper nouns, unique event orders, or signature lines into reusable templates is forbidden

**Authority relationships**: `plot/pacing.md` owns rhythm/touchpoints; `plot/emotional-beats.md` owns reader needs/module reproduction. `teardown-report.md` and `plot/storylines.md` may only summarize or reference these two files — they can't be co-authorities.

#### D. Whole-book overview generation (written at Stage 5, overwriting the Stage 0 thin first-pass)

Whole-story-framework recognition + 500-1000-word dense whole-book overview (covering the main plot lines' phased development, core character functions, key turning points, causality).

> **On-disk timing**: the aggregation phase (Material phase 3 ≈ pipeline Stage 3) produces the overview text, but the actual **write into `overview.md` happens at pipeline Stage 5** (the final report) — by then Stages 3/4 are all done and information is most complete. Stage 5 overwrites the Stage 0 thin first-pass section; the chapter index and volume/part table stay.

### Phase 4: Worldview and setting extraction

Stage 2's lightweight character mentions are upgraded into full files here.

#### The two-stage character model

**Stage A: lightweight mentions (Stage 2 output)**
- Each agent returns a cast table (name/importance/aliases/performance this chapter)
- No cross-chapter analysis; only record what's visible in this chapter

**Stage B: full files (Stage 4 build)**
- Merge all chapters' character-mention data
- Cross-chapter alias resolution
- Build full character files

#### One-person-one-entity principle

- **Absolutely forbidden** to merge different people's info into one entity
- Each character entity must correspond to exactly one person
- If you can't determine whether two appellations refer to the same person, create separate entities

#### Alias resolution rules

**Alias types**:

| Type | Definition | Mergeable | Example |
|------|------------|-----------|---------|
| proper_name | proper/full/common name | yes | "Hillman", "Lin Lei Baruch" |
| nickname | moniker/epithet, needs same-reference evidence | yes (confidence ≥0.85) | "dragon-blood warrior Lin Lei" |
| descriptor | descriptive appellation | no | "red-haired brute", "attendant", "captain" |
| title | honorific/position | no | "guard captain", "family head", "clan chief" |

**Merge constraints**:
- Only proper_name and nickname (confidence ≥0.85) can trigger merges
- descriptor and title **never** trigger entity merges
- nickname must provide same-reference evidence: apposition, parenthetical alias, contextual reference, explicit rename

**Archetype quantitative judgment**:

| Type | Criterion |
|------|-----------|
| **protagonist** | appears in ≥50% of chapters + drives the main line + has a full growth arc |
| **antagonist** | opposes the protagonist + drives the core conflict + has a clear motive |
| **core supporting** | appears in ≥20% of chapters OR drives an important subline OR has an independent personality and growth |
| **functional** | appears in <20% of chapters + limited function (info/props/one-off interactions) |

**Special**: early minor → later supporting counts as supporting. Important mentors/companions count as supporting even with few appearances.

**Character-file structure** (200-500 words):
1. Identity background (1-2 sentences)
2. Core experiences (3-5 sentences, chronological)
3. Personality traits (1-2 sentences, generalized from behavior)
4. Abilities/skills (1-2 sentences)
5. Relationships (1-2 sentences)
6. Growth trajectory (if any, 1 sentence)

#### Cheat merge rules

- Elements that interact and work together **merge into one** (e.g., "ring + mentor soul" is one whole)
- Different descriptive angles of the same thing **don't split**
- Only fully independent, mutually non-dependent capability sources split into multiple
- Long-form trait: the cheat can be complex and multi-faceted — describe its evolution history and multi-capability development in detail
- Note it explicitly when there is no cheat

**Cheat types**: system / space / rebirth / transmigration / special_physique / artifact / bloodline / other

#### Worldview (split into multiple files by topic)

Fields and landing files:

| Field | Notes | Landing file |
|-------|-------|--------------|
| Type | fantasy / reality / parallel world | noted in each file's frontmatter or opening |
| Power system | name, ranks, promotion method (text) | `setting/worldview/power-system.md` (standalone ≥200 words, else merged into background) |
| Geography | distribution, main regions, key locations (text) | `setting/worldview/geography.md` (same, standalone ≥200 words) |
| Factions | sects/organizations/families/nations | **one file per faction** `setting/factions/{Faction Name}.md` (standalone ≥200 words; else merged into `setting/worldview/background.md`) |
| Core rules | the basic rules the world runs on | `setting/worldview/background.md` |
| Special settings | unique settings differing from reality | `setting/worldview/background.md` (same file as core rules) |
| Cheat | see "cheat merge rules" above | `setting/cheat.md` |

> Templates and examples in the "Stage 4 setting + relationships" section of [output-templates.md](output-templates.md). Downstream imports sync these topic files as-is; no on-the-fly splitting of flat files.

### Phase 5: Relationship extraction

Per pair:

| Field | Notes |
|-------|-------|
| Character A | full name |
| Character B | full name |
| Relationship type | family/mentor-student/friends/enemies/lovers/colleagues/superior-subordinate/business/other |
| Emotional valence | positive/negative/neutral/complex |
| Description | relationship essence + how it formed + key interactions (50-200 words) |

#### Relationship-extraction strategy

**Data source**: extract relationships from the already-extracted plot-point descriptions (not from the source) — more efficient and more focused.

**Batched extraction**: extract every 5 chapters; only record new relationships or relationship changes.

**Evolution tracking**: when a pair's relationship changes, record the trajectory:
```
Chapter {N}: {relationship state A} → Chapter {M}: {relationship state B}
Triggering event: {specific event}
Emotional shift: {positive→negative / negative→positive / neutral→complex, etc.}
```

**Final-state merge**: for multi-stage relationships of the same pair, keep the latest state as the main record; historical changes go into the evolution trajectory. Avoid duplicate relationship entries for the same pair.

**Implied-relationship inference**: when two characters have no direct interaction but indirect evidence exists:
- Infer from a third party's evaluation/description (confidence 0.7)
- Infer from co-appearance frequency and occasions (confidence 0.6)
- Inferred relationships are marked `[inferred]`, distinguished from directly-evidenced ones

**Relationship-network density**:
- Count the main characters' (protagonist + core supporting) relationship counts
- <3 relationships → the network is thin; check for misses
- >10 relationships → the network is too dense; check for wrong merges

---

## The six iron rules of atomic extraction

1. **Absolute chronology**: strictly ordered by event time
2. **Objective plain description**: record "what happened" and the result; causes the source states are written as-is; don't speculate unwritten motives; no narrative-frame words
3. **Information fidelity**: don't drop key details that change the context
4. **High compression**: one sentence per plot point
5. **Composite merging**: consecutive micro-actions serving the same dramatic purpose merge into one plot point
6. **Objective facts**: extract objective facts; no narrative analysis

**Objective plain description vs narrative-frame words**:
- Forbidden: "Through the conversation, Zheng Song learned that Zhang Zihao trains in Korea"
- Correct: "Wu Zhibin told Zheng Song that Zhang Zihao trains in Korea"
- Forbidden: "Lin Feng showed off his strength"
- Correct: "Lin Feng defeats the opponent in three moves; the onlookers gasp"
- Forbidden: "Shaoyang felt heartbroken and angry"
- Correct: "Shaoyang watched Song Li hug someone; his expression went from stung to cold"

---

## Fact fidelity in the synthesis stage (Stages 3-5: plot/setting/character/report)

Stages 3-5 synthesize from chapter summaries — two hops from the source, the easiest place to backfill "plausible" facts the summary never stated into "apparently confirmed" facts. This is the biggest source of teardown fact errors (typical: inventing a second element for a "dual-element mage", attributing the mount's rank to the rider, making up a number for a field the source never gave, or filling an appearance range across chapters the character never appeared in). Even strong models drift, because the further from the source, the more the model fills gaps with world knowledge and "reasonableness". Three hard constraints:

1. **Hard facts must be traceable**: power ranks, numbers, distances, attributes, faction counts, who said what to whom, character appearance chapters — before writing such hard facts into settings/characters/report, check against the source (read the source directly if the summary is insufficient); only write what checks out.
2. **Missing → "not stated in the source", inventing fills forbidden**: for fields the source never gives, write "not stated in the source / not covered in the excerpt" — never substitute a near-synonym, an example from elsewhere, or a convention to produce a plausible-looking value.
3. **No cross-referent leakage**: adjacent entities' attributes don't get swapped — mount rank ≠ rider rank, A's lines ≠ B's lines, this chapter's numbers ≠ adjacent chapters' numbers.

After writing to disk, run a **fact-traceability self-check**: spot-check hard facts in settings/characters/report — can each be grepped back to the source? A hit passes; a miss gets rewritten as "not stated in the source" or deleted — no source-less assertions kept. This self-check is independent of the three ratios below: the ratios check classification quality; this checks factual truth.

---

Directory structure in SKILL.md "Output directory structure".

---

## Quality-threshold system

Self-check after phases 3 and 4:

| Metric | Threshold | Calculation | If below threshold |
|--------|-----------|-------------|--------------------|
| Confidence | >= 0.85 | plot points with clear assignment / total plot points in the unit | below 0.85 mark "pending review" |
| Coverage | 85%-95% | classified plot points / total plot points | <85% triggers orphan reclassification; >95% re-check boundaries |
| Key-info coverage | >= 1 per chapter | chapters containing `Key info and expansion techniques` / summary chapters | missing chapters go back to Stage 2 for re-extraction |
| Module source labeling | best-effort | emotion module cards label RH/TR or chapter plot-point sources when possible | uncertain sources left blank, not forced, modules not deleted (same best-effort handling as trope tags) |
| Overlap | <= 35% | plot points shared across story units / total plot points | >35% signals blurred boundaries; consider merging |

> **Small excerpts (<30 chapters, single-mainline continuous narration)**: when such material is sliced chronologically, coverage naturally approaches 100% and stray plots approach 0 — a normal result of linear structure, not over-aggregation. Re-check focus then is "were different plots force-merged into one line", not the coverage number itself — don't artificially split to get under 95%.

---

## Loose-thread safety net

Executed after phase 3 aggregation completes (6 steps, incl. coverage validation):

1. **Compute the orphan ratio**: orphan plot points / total plot points. If <5%, skip the rest and mark "few strays, no processing needed"
2. **Collect unassigned plot points**: gather plot points from all chapter summaries that weren't classified into any story unit
3. **Three-tier confidence assignment**: compute relevance on three clues — character overlap, location overlap, causality
   - **Strong correlation** (0.8-1.0): character match + theme match → assign into the existing unit, mark `[orphan assigned]`
   - **Medium correlation** (0.5-0.8): character match or theme match → assign and mark `[low-confidence assignment]`, pending review
   - **Weak correlation** (<0.5): don't force; better left unassigned
4. **Theme clustering**: cluster weak-correlation plot points by theme keyword
   - ≥5 points in a cluster → candidate story unit, mark `[cluster-generated]`
   - <5 points → no standalone unit
5. **Archive the strays**: still-unclassifiable points go into `loose-threads.md`, ordered by chapter, with the reason noted
   - Don't discard any plot point; don't force points into unrelated plots
   - Count stray points and their share in the teardown report
6. **Coverage validation**:
   - Coverage = (total − strays) / total × 100%
   - Target: 85%-95%
   - <85% → back to step 3, retry with a lowered confidence threshold
   - >95% → check for over-aggregation; re-review boundary units

---

## Claude Code execution guidance

### Chunking strategy

Stage 2 uses chapter-extractor agents in parallel (one agent per chapter, 5-8 per batch) — no chunking.
Other stages (0, 1, 3, 4, 5) chunk as follows:

| Scale | Strategy | Chunk size |
|-------|----------|-----------|
| <50 chapters | whole-stage processing | no chunking needed |
| 50-100 chapters | whole-stage processing | no chunking needed (optional smart chunking) |
| 100-500 chapters | chunk by chapters | 5-8 chapters/chunk |
| >500 chapters | **smart chunking**: recognize natural boundaries from chapter summaries, cut by semantic coherence | 50-200 chapters/chunk |

### Smart chunking (>500 chapters)

For very large novels, recognize natural boundaries from chapter summaries rather than fixed slicing:

**Chunking principles (four iron rules)**:
1. **Semantic coherence**: each chunk is a relatively self-contained content unit (a large story phase or major event line)
2. **Natural boundaries**: cut at content turning points, scene switches, time jumps — never mid-tight-plot
3. **Right size**: 50-200 chapters per chunk; semantic completeness outranks uniform size
4. **Avoid tearing**: don't cut in the middle of a tightly-woven plot

**Genre-specific chunking reference**:

| Genre | Chunking basis | Example |
|-------|----------------|---------|
| Cultivation/escalation | realm breakthroughs, map switches | Qi-refining → Foundation Establishment → Golden Core |
| Urban | event lines, identity changes | student → founder → business empire |
| Historical | historical stages, campaigns | uprising → unify the north → southern campaign |
| Fantasy | world map, faction changes | eastern domain → central continent → upper world |
| Has volumes/parts/sections | prefer the original structure | by the author's own volumes/parts |

**No clear structure** → cut evenly by fixed chapter counts. **Hard constraints**: every chapter must be covered; chunks must not overlap (each chapter belongs to exactly one chunk). **Chunk cap**: at most 10 chunks (when exceeded, enlarge chunk size, keeping semantic completeness).

Per-chunk metadata: `chunk title | chapter range | core themes (2-5) | key events (2-5) | protagonist stage`.

Chunk input size 6-8K tokens/chunk (small-medium), chapter boundaries aligned. Output length limits per SKILL.md (Stage 2 agent mode outputs by the density formula; Stages 3-5 single-stage ≤8000 words). Update `_progress.md` after each chunk.

### Cross-chunk merge (large novels >500 chapters)

After chunking, boundary plots of adjacent chunks may be mechanically torn apart. Stage 3 aggregation runs a cross-chunk merge check:

**Merge criteria** (all must hold):
1. ✓ Same core event/goal: telling the same core event (not two independent events)
2. ✓ Same main characters: the main characters involved are the same
3. ✓ Continuous development: plot B is the natural continuation of plot A
4. ✓ Not causally independent events: not two independent events related only by cause-effect

**Should merge**:
- "running for county secretary (preparation phase)" + "running for county secretary (voting phase)" → the same event torn apart by chunking
- "cultivation breakthrough (early)" + "cultivation breakthrough (late)" → the same breakthrough process

**Should not merge**:
- "standing firm in the office" + "running for county secretary" → two independent goals
- "Qi-refining training" + "Foundation-Establishment training" → independent plots at different stages
- "eastern-domain training" + "central-continent training" → independent plots on different maps

**Conservative principle**: when unsure, prefer not merging (keep independent).

**Boundary detection principle**: only check plot pairs near chunk boundaries; plots far from boundaries don't participate in cross-chunk merging.

### Cross-session resume

- Progress tracked through `_progress.md`
- New sessions read `_progress.md` to locate the breakpoint
- Resume from the first chapter of the chunk containing the breakpoint (overwriting that chunk's existing outputs)
