# Short-Fiction Teardown Output Templates

> Load when producing teardown output. First check the routing table to pick the Stage, then fill in the template. Methodology details in material-decomposition.md.
>
> **Output-contract SSOT**: the Stage→file mapping, `_meta.json` fields (incl. `structure_counts`), downstream consumption rules, and acceptance checks are authoritatively defined in [output-contract.md](output-contract.md).
> The templates in this file eventually land in `teardown-report.md` and the other markdown files; each template's destination is labeled in the HTML comment at the end of each Stage. Quality-check required fields carry `[BLOCK]` / `[WARN]` labels at the end: a BLOCK failure → the "BLOCK item scan" blocks; a WARN failure → written into the "to-do" list, doesn't block.

## Decision routing

| Which Stage you're running | Load which template | Required fields |
|---------------|-------------|---------|
| Phase 1 confirm target | no template (user interaction, see SKILL.md) | user provided text + teardown direction |
| Stage 2 structure + plot nodes | Stage 2 whole-piece structure + Stage 2B plot nodes | story core + at least 4 structure segments + nodes covering the whole piece |
| Stage 3 emotional line + eruption points | Stage 3 emotion curve + eruption analysis | at least 5 nodes + eruption 6 dimensions |
| Stage 4 reversal + writing craft | Stage 4 reversal analysis + writing craft | pre-reversal check + setup clues ≥2 + craft ≥5 items |
| Stage 5 characters + opening/ending | Stage 5 characters + opening/ending | all named characters + first-3-lines quotes + ending type |
| Stage 6 assessment report | Stage 6 combined assessment | five-dimension score + eruption potential + resonance ≥3 layers + reusable structures ≥3 |
| Same-type comparison (optional) | same-type comparison | differentiation highlights |
| Platform adaptation (optional) | platform-adaptation assessment | three-platform suitability |
| Detailed rhythm (optional) | detailed rhythm analysis | rhythm metrics + anomaly detection |

## Contents

1. [Stage 2 whole-piece structure](#stage-2-whole-piece-structure)
2. [Stage 2B plot-node extraction](#stage-2b-plot-node-extraction)
3. [Stage 3 emotional line + eruption points](#stage-3-emotional-line--eruption-points)
4. [Stage 4 reversal + writing craft](#stage-4-reversal--writing-craft)
5. [Stage 5 characters + opening/ending](#stage-5-characters--openingending)
6. [Stage 6 combined assessment](#stage-6-combined-assessment)
7. [Detailed rhythm analysis](#detailed-rhythm-analysis)
8. [Short-fiction structure quick library](#short-fiction-structure-quick-library)
9. [Quality-check required fields](#quality-check-required-fields)

---

## Stage 2 whole-piece structure

<!-- output to: teardown-report.md (story core + story summary + structure split + narrative timeline sections) -->

{word count} words | {section count} sections | platform{platform} | type{genre/emotion type} | ending{HE/BE/open} | POV{first/third person}

### Story core

**Premise**: {the story's precondition / triggering condition, e.g., "killed three times by her mother and brother, reborn each time"}
**Theme**: {core contradiction / values conflict, e.g., "extreme son-preference in the family"}
**Core action**: {what the protagonist does, e.g., "lets them destroy themselves this fourth life"}
**One-liner**: {combined, e.g., "A girl killed three times by her mother and brother lets them destroy themselves in the fourth life"}

### Story summary

{200-500 words covering the whole piece}

### Structure split (4-6 segments; must include opening/development/climax/ending)

| Segment | Word range | Share | Function | Sections |
|---------|------------|-------|----------|----------|
| Opening | {X}-{Y} | {Z%} | {function} | {section numbers} |
| Development | {X}-{Y} | {Z%} | {function} | {section numbers} |
| {Turn/transition (optional)} | {X}-{Y} | {Z%} | {function} | {section numbers} |
| Climax | {X}-{Y} | {Z%} | {function} | {section numbers} |
| Ending | {X}-{Y} | {Z%} | {function} | {section numbers} |

### Narrative timeline

| Trait | Description |
|-------|-------------|
| Timeline type | {linear/interleaved/flashback/double-line crossing} |
| Time span | {in-story time span} |
| Key time jumps | {if any, mark position and span} |
| Time-manipulation purpose | {creating information gaps / compressing boredom / creating contrast} |

---

## Stage 2B plot-node extraction

<!-- output to: plot-nodes.md (standalone file) + teardown-report.md (plot-node list section mirror) -->

> Methodology and the word-count tier table for node counts: the "plot-node extraction rules" in material-decomposition.md (sole authority).

### Node template

```markdown
N{index} **{event summary}**: type{emotion/info/conflict/turn/dialogue/atmosphere} | emotion{type}{intensity -9~+9} | involves{full names} | craft{when present}

Source quote (≤300 words)
```

### Output example

```markdown
## Plot-node list

N1 **Overheard call**: type{info} | emotion{shock}{-7} | involves{Mara Vance} | craft{information gap}

> "Does Hale even plan to let Mara and the kid through the door?"
> "No need. A by-blow's a by-blow."
> I was reaching for the handle. My hand stopped mid-air.

N2 **Self-recognition**: type{turn} | emotion{heartache}{-5} | involves{Mara Vance}

> I was a Vance bastard, and I'd given him a bastard son.
> Hale never loved me.
> I drew my hand back without a sound.
```

### Quality self-check

- [ ] Node count within the density-guide range
- [ ] Every node has an objective plain description (no narrative-frame words, no subjective judgment)
- [ ] Every node has an emotion label (type + intensity value)
- [ ] Nodes strictly chronological
- [ ] Source quotes ≤300 words and contiguous

---

## Stage 3 emotional line + eruption points

<!-- output to: teardown-report.md (emotion curve + eruption analysis + anticipation analysis sections) -->

### A. Emotion curve

At least max(5, section count) nodes, with word-count positions; each node labeled with its hook type:

| Position | Words | Node index | Emotion | Intensity & direction | Triggering event | Hook type |
|----------|-------|------------|---------|-----------------------|------------------|-----------|
| Opening | {X} | N{N} | {curiosity/heartache/shock} | {misery -9 ~ gratification +9} | {event} | {suspense/conflict/contrast/immersion/information gap/none} |
| Trough | {X} | N{N} | {sympathy/despair/anger} | {misery -9 ~ gratification +9} | {event} | {hook type} |
| Reversal point | {X} | N{N} | {shock/sympathy} | {misery -9 ~ gratification +9} | {event} | {hook type} |
| Climax | {X} | N{N} | {emotion} | {misery -9 ~ gratification +9} | {event} | {hook type} |
| Ending | {X} | N{N} | {satisfaction/bittersweet/healing} | {misery -9 ~ gratification +9} | {event} | {hook type} |

Hook-type quick reference: suspense (want to know what happens next), conflict (contradiction intensifying), contrast (cognitive overturn), immersion (feeling it with the character), information gap (reader knows what the character doesn't)

Curve traits: start{...} | direction{uphill/downhill/wave/V-shape/inverted-V/staircase/cliff/compressed-spring} | extrema{peak at X% trough at Y%} | net change{from X to Y} | direction flips{N}

### B. Eruption-point analysis

| Dimension | Analysis |
|-----------|----------|
| Setup | {what makes the reader start to care}, done by word {X} |
| Accumulation | {what is building emotional potential}, accumulating {X} words |
| Delay | {delayed-release mechanism: information gap/misunderstanding/suspense} |
| Eruption point | {the instant that releases all the emotion}, exact sentence: "{quote}" |
| Aftershock | {the tremor after release: character reactions} |
| Impression | {what remains after the release, what the reader remembers} |

**Stacked eruption** (when applicable): surface eruption{X} → deep eruption{Y} → stacking effect{where 1+1>2}

**Multi-eruption chain** (when applicable): eruption ①{event + position} | eruption ②{event + position} | eruption ③{event + position} → chain mode{progressive/parallel}

### C. Anticipation analysis

Track the reader's expectation state section by section:

| Section | Expectation created | Fulfilled/escalated/suspended | Remaining expectation |
|---------|--------------------|------------------------------|-----------------------|
| 1 | {expectation A} | {created} | {A} |
| 2 | {expectation B} | {escalated A} | {A+, B} |
| ... | | | |

Anticipation rule: no more than two sections without creating a new expectation; no more than one section without advancing the core expectation.

---

## Stage 4 reversal + writing craft

<!-- output to: teardown-report.md (reversal-analysis section) + craft-methods.md (standalone file: POV/dialogue/time/info/other/imagery) -->

### A. Reversal analysis

#### Pre-reversal check

> Is there a lie / misjudgment that predates the story's timeline?

| Pre-reversal | Who was deceived/blinded | When exposed | How exposed | Role in the main reversal |
|--------------|--------------------------|--------------|-------------|---------------------------|
| {e.g., the "drugged" incident three years ago was actually a setup} | {Dorian Hale} | {episode 9} | {Mara Vance refutes him face to face} | {setup: proves the judgment was built on a false premise} |

If none exists, write "none".

#### Karma design (for no-reversal / karmic-justice stories)

> When the story has no traditional reversal, skip the reversal-mechanics breakdown and analyze the karma design instead.

| Stage | The antagonist's misdeeds | Karmic result | Source of gratification |
|-------|--------------------------|---------------|--------------------------|
| {e.g., abusing wife and daughter} | {specific behavior} | {corresponding punishment} | {taste-of-their-own-medicine / hoist with their own petard} |

Karma-chain effect: {progressive / one-to-one / chain reaction}

#### Reversal chain (for multi-reversal stories)

> If the story contains several consecutive reversals (public-opinion reversal, nested reversal), list them in order:

| # | Reversal type | Triggering event | Reader cognitive change | Causal link to the previous layer |
|---|---------------|------------------|-------------------------|-----------------------------------|
| 1 | {type} | {event} | {from cognition A to cognition B} | — |
| 2 | {type} | {event} | {from cognition B to cognition C} | {how reversal 1 explains/deepens reversal 2} |

Reversal-chain effect: {progressive/stacking/out-of-the-blue}
Causal-chain strength: {strong/medium/weak — if you delete any layer, do the others still hold?}

**Foreshadowing-style reversal**: if an opening sentence's meaning completely changes after the truth is revealed, note:
- The sentence + position to look back at
- First-read understanding vs look-back understanding
- The event that triggers the cognitive upgrade

Single-reversal stories skip this table and go straight to the main/side reversal analysis below.

#### Main/side reversal analysis (for single-reversal stories)

**Reversal type**: {perspective/identity/motive/timeline/info/cognitive}

> **Cognitive reversal**: the reader's overall understanding of a character/relationship gets overturned (e.g., "the mother actually loved her all along"). Unlike an info reversal (a single piece of information), a cognitive reversal changes the reader's emotional coloring of the whole character/relationship.

**Reversal mechanics**:
- Setup clues: {which clues the text planted, with positions}
- Misdirection: {which direction the text steers the reader}
- Truth reveal: {how the reversal is uncovered}
- Plausibility: {does the reversal hold up on re-read}

**Timing**: at {X}% of the piece | setup:release = {X:1}

**Effect**: surprise{1-5} | plausibility{1-5} | emotional impact{1-5}

### B. Writing craft

> Methodology: the "writing-craft analysis" section of material-decomposition.md.

#### POV strategy

| Dimension | Analysis |
|-----------|----------|
| POV type | {first/third person/omniscient/other} |
| Choice effect | {intimacy/info control/distance} |
| Info manipulation | {unreliable narrator/selective memory/concealment} |
| POV switch | {if any: switch position, method, effect assessment. If none: "none"} |
| POV cost | {which perspective/info was lost} |

#### Dialogue craft

> The standard dialogue-share range is in the "rhythm analysis" section of material-decomposition.md; judge high/low against it.

| Metric | Value | Assessment |
|--------|-------|------------|
| Dialogue share | {X%} | {standard/high/low} |
| Subtext rate | {X%} | {master-level >60%/medium/low} |
| Dialogue pattern | {interrogation/suppression/information-gap/push-pull/appellation change} | {specific notes} |

#### Time manipulation

| Technique | Position | Effect |
|-----------|----------|--------|
| {time jump/scene compression/flashback/quick cut/real-time expansion} | {episode N} | {specific effect} |

#### Info control

| Moment | Reader knows | Protagonist knows | Rival knows | Information gap |
|--------|--------------|-------------------|-------------|-----------------|
| Opening | | | | |
| Middle | | | | |
| Ending | | | | |

#### Other craft

| Technique | Position | Effect | Reusability |
|-----------|----------|--------|-------------|
| {sensory anchoring/sentence rhythm/contrast design/imagery-object/white space/opening-ending echo} | {episode N} | {specific effect} | {high/medium/low} |

#### Imagery/object tracking

| Object/imagery | Appearances | Meaning carried each time | Evolution trajectory |
|----------------|-------------|---------------------------|----------------------|
| {object} | {episode 1, 5, 9} | {meaning change} | {from A to B} |

If no repeated objects/imagery, write "no notable imagery repetition".

**Thematic imagery cluster**: if several objects point to the same theme, note the shared theme, each object's angle, and the overall effect.

**Craft total**: {N} items | core craft{Top 3} | innovative craft{if any}

---

## Stage 5 characters + opening/ending

<!-- output to: teardown-report.md (character analysis + opening analysis + ending analysis + opening-ending echo + hook-recovery check sections) -->

### A. Character analysis

> Methodology: the "character extraction rules" section of material-decomposition.md.

**Character overview**: {N} named characters

| Character | Narrative role | Action role | Function labels | Inner contradiction | Arc | Key lines |
|-----------|----------------|-------------|-----------------|---------------------|-----|-----------|
| {protagonist name} | {protagonist/major supporting} | {active/passive/transforming} | {emotion carrier/...} | {core psychological conflict} | {start→turn→end} | "{most representative line}" |
| {supporting name} | {major supporting/functional} | {active/passive} | {pressure source/...} | {contradiction} | {arc/flat} | "{line}" |

> If a dual-protagonist structure is recognized, mark both as "protagonist" in the overview table and note each one's driven chapter range below the table.

**Character function assessment**:

| Character | Entrance efficiency | Function density | Deletability | Dialogue contribution |
|-----------|---------------------|------------------|--------------|-----------------------|
| {name} | {high/medium/low} | {carries N functions} | {undeletable/deletable} | {every line advances/partly advances} |

**Character relationships**:

| Pair | Relationship essence | Evolution trajectory | Contribution to the emotional line |
|------|----------------------|----------------------|------------------------------------|
| A ↔ B | {e.g., one-way dependence → equal refusal} | {episode N: state A → episode M: state B} | {what emotion it manufactures} |

### B. Opening analysis

**First 3 lines**: {source quote}

| Dimension | Analysis |
|-----------|----------|
| Hook type | {suspense/conflict/contrast/immersion/information gap} |
| First 50 words | {conflict/anomaly present? yes/no} |
| First 100 words | {does the reader know the core contradiction? yes/no} |
| Info density | {high/medium/low} |
| Immersion | {strong/medium/weak} |
| Voice distinctiveness | {strong/medium/weak} |
| Opening emotional intensity | {1-10, absolute-intensity scale, not the emotion-curve -9~+9} |

### C. Ending analysis

**Last paragraph**: {source quote or summary}

| Dimension | Analysis |
|-----------|----------|
| Ending type | {satisfying(HE)/regretful(BE)/open-ended/reversal aftershock/white space} |
| Emotional landing | {what the reader is thinking when they leave} |
| Aftershock design | {yes/no, describe} |
| Shareability | {would the reader recommend it, why} |
| Closure completeness | {are all hooks recovered; list unrecovered ones} |
| Values conveyed | {what this story ultimately wants to say?} |
| Ending emotional intensity | {1-10, absolute-intensity scale (not the emotion-curve -9~+9). Reference standards: misery ≥8 / gratification ≥7 / healing ≥6 / clarity-satisfaction ≥5 / shock-reversal ≥7 / BE bittersweet ≥8} |

### D. Opening-ending echo analysis

| Echo element | Opening position | Ending position | Echo mode | Effect |
|--------------|------------------|-----------------|-----------|--------|
| {element} | {e.g., episode 1 "just a by-blow"} | {e.g., ending: never remarried} | {contrast/reversal/escalation} | {closes the loop/creates regret} |

**Re-read discovery**: if an opening sentence's meaning completely changes after the truth is revealed, list: the sentence + position + first-read understanding vs post-truth understanding.

### E. Hook-recovery check

| Hook | Planted at | Type | Recovered at | How recovered | Status |
|------|------------|------|--------------|---------------|--------|
| {description} | {episode N} | {suspense/conflict/information gap} | {episode M} | {how} | {recovered/white space/omitted} |

---

## Stage 6 combined assessment

<!-- output to: teardown-report.md (combined section: five-dimension score + eruption potential + topicality + resonance + core craft + reusable structures + same-type writing actions + rhythm briefing) + _meta.json.structure_counts (numbers into metadata; see the "_meta.json.structure_counts production template" below) -->

**One-sentence assessment**: {the concrete reason it works — point at the actual mechanism, no vague praise}

### Five-dimension score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Opening attraction | 1-5 | {specific: hook type + effect + room to improve} |
| Emotional pull | 1-5 | {specific: curve shape + extrema + flips} |
| Reversal design | 1-5 | {specific: reversal type + setup quality + plausibility} |
| Rhythm control | 1-5 | {specific: density distribution + anomaly detection + rhythm fit} |
| Ending aftershock | 1-5 | {specific: ending type + landing + shareability} |

### Eruption potential

{What is the core eruption point? Is the setup sufficient? Is the release on point? How shareable?}

### Topicality

{What will readers discuss? Controversy points? Immersion self-reflection? "What would I do" discussion space?}

### Resonance analysis

| Resonance layer | Intensity | Trigger point |
|-----------------|-----------|---------------|
| Emotional resonance | {strong/medium/weak/none} | {specific trigger} |
| Values resonance | {strong/medium/weak/none} | {specific trigger} |
| Experience resonance | {strong/medium/weak/none} | {specific trigger} |
| Social-phenomenon resonance | {strong/medium/weak/none} | {specific trigger} |
| Cultural resonance | {strong/medium/weak/none} | {specific trigger} |
| Universal-values resonance | {strong/medium/weak/none} | {specific trigger} |
| Philosophical resonance | {strong/medium/weak/none} | {specific trigger} |
| Deep emotional resonance | {strong/medium/weak/none} | {specific trigger} |
| Character-depth resonance | {strong/medium/weak/none} | {specific trigger} |

### Core craft

Reversal type{...} | Emotion-curve shape{...} | Key hook{...} | Core craft Top 3{...}

### Reusable structures

1. **{craft name}**: {usage} — Applicable to: {what kind of short stories}
2. **{craft name}**: {usage} — Applicable to: {...}
3. **{craft name}**: {usage} — Applicable to: {...}

### Same-type writing actions

{concrete actions — directly operable in the next artifact; avoid "practice more"}

### Rhythm briefing

| Metric | Value | Judgment |
|--------|-------|----------|
| Event density | {X per 1000 words} | {standard/high/low} |
| Dialogue density | {Y%} | {standard/high/low} |
| Conflict density | {Z%} | {standard/high/low} |

### `_meta.json.structure_counts` production template

> At Stage 6 completion, write this section's structure counts into `_meta.json.structure_counts` as the basis for the "structure_counts numeric validation" number checks. The analysis narrative body goes into the corresponding sections of `teardown-report.md`; don't re-explain it in the JSON.
> Field definitions and thresholds in [output-contract.md](output-contract.md).

```jsonc
"structure_counts": {
  "beats": 5,                    // from Stage 2 structure-segment count (opening/development/climax/ending, ≥4)
  "hooks": 4,                    // from Stage 3 hook count (≥3)
  "setup_clues": 3,              // from Stage 4 reversal setup-clue count (≥3; no-reversal genres fill 0 and skip this threshold)
  "character_archetypes": 3,     // from Stage 5 contrast-character count (≥2)
  "reusable_structures": 3,      // from Stage 6 reusable count (≥3)
  "reversal_type": "perspective" // enum: perspective/identity/motive/timeline/info/cognitive/none
}
```

---

## Optional module: same-type comparison

> Methodology: the "optional module: same-type comparison" section of material-decomposition.md.

| Dimension | This piece | Benchmark A | Benchmark B |
|-----------|-----------|-------------|-------------|
| Emotion-curve shape | {e.g., compressed-spring} | {e.g., V-shape} | {e.g., wave} |
| Core craft | {e.g., faked death + information gap} | {e.g., timeline reversal} | {e.g., nested reversal} |
| Opening hook strength | {1-5} | {1-5} | {1-5} |
| Reversal surprise | {1-5} | {1-5} | {1-5} |
| Ending aftershock | {1-5} | {1-5} | {1-5} |

**Differentiation highlights**: {this piece's key difference from similar works — advantage or disadvantage}

---

## Optional module: platform-adaptation assessment

> Methodology: the "optional module: platform-adaptation assessment" section of material-decomposition.md.

| Platform | Suitability | Reason | Adjustment action |
|----------|-------------|--------|-------------------|
| Wattpad | {high/medium/low} | {reason} | {if any} |
| Radish / Dreame / GoodNovel / Galatea | {high/medium/low} | {reason} | {if any} |
| Inkitt / Tapas | {high/medium/low} | {reason} | {if any} |

---

## Detailed rhythm analysis

> Optional module. Methodology: the "rhythm analysis" section of material-decomposition.md.

### Rhythm metrics

> The authoritative "standard range" numbers for each dimension are in the rhythm-metrics table of material-decomposition.md; judge against them when filling.

| Dimension | Value | Judgment |
|-----------|-------|----------|
| Event density | {N} per 1000 words | {standard/high/low} |
| Dialogue density | {X%} | {standard/high/low} |
| Conflict density | {X%} | {standard/high/low} |
| Info density | {X%} | {standard/high/low} |

### Per-section rhythm distribution

| Section | Words | Event density | Dialogue share | Conflict share | Rhythm judgment |
|---------|-------|---------------|----------------|----------------|-----------------|
| 1 | {N} | {X/1000 words} | {Y%} | {Z%} | {fast/medium/slow/transition} |

### Rhythm anomalies

| Anomaly type | Position | Notes |
|--------------|----------|-------|
| {rhythm collapse/conflict overload/info flood/dialogue desert/dialogue flood} | {episode N} | {specific notes} |

If none, write "no notable rhythm anomalies".

---

## Short-fiction structure quick library

> Full version: the "structure-type quick reference" of material-decomposition.md (incl. matching-analysis points).

---

## Quality-check required fields

Check item by item before a Stage completes; a single miss makes it incomplete. **Numeric thresholds (node density, dialogue share, etc.) are authoritatively defined only in the "quality standards" of material-decomposition.md; this table only lists the check items, not the numbers.**

**Label conventions**:

- `[BLOCK]`: quantified or required output; if missing → the "BLOCK item scan" blocks, `_meta.json.stages_completed[6]` is not written, and the user is asked to go back to the corresponding Stage and complete it.
- `[WARN]`: qualitative or auxiliary item; if missing → written into the "to-do" list at the end of `teardown-report.md`, **does not block** moving to the next stage.

**Stage 2 (structure + plot nodes)**:
- [ ] Story core extracted (one-sentence core hook) `[BLOCK]`
- [ ] Structure split 4-6 segments (must include opening/development/climax/ending), each with word range, share, and function `[BLOCK]`
- [ ] Ending type labeled `[WARN]`
- [ ] POV identified `[WARN]`
- [ ] Narrative timeline labeled `[WARN]`
- [ ] Plot-node count within the density-guide range (by word-count tier, see "plot-node extraction rules" in material-decomposition.md) `[BLOCK]`
- [ ] Every node has an emotion label (type + intensity value) `[BLOCK]`

**Stage 3 (emotional line + eruption points)**:
- [ ] At least max(5, section count) emotion nodes, each with word position, intensity value, and direction (misery -9 ~ gratification +9) `[BLOCK]`
- [ ] Every node labeled with a hook type (incl. "none") `[WARN]`
- [ ] Curve traits 5 items complete (start/direction/extrema/net change/direction flips) `[BLOCK]`
- [ ] Eruption analysis 6 dimensions complete (setup/accumulation/delay/eruption point/aftershock/impression) `[BLOCK]`
- [ ] Anticipation table complete `[WARN]`

**Stage 4 (reversal + writing craft)**:
- [ ] Pre-reversal check executed (exists/doesn't) `[WARN]`
- [ ] Reversal type identified `[BLOCK]`
- [ ] Setup clues at least 2, with source positions `[BLOCK]`
- [ ] Misdirection described `[WARN]`
- [ ] Writing-craft analysis ≥5 dimensions `[BLOCK]`
- [ ] POV strategy analyzed (choice effect + cost + switch) `[WARN]`
- [ ] Dialogue metrics quantified (share + subtext rate) `[WARN]`

**Stage 5 (characters + opening/ending)**:
- [ ] All named characters extracted, with the two-dimension classification (narrative role: protagonist/major supporting/functional + action role: active/passive/transforming) `[BLOCK]`
- [ ] Character function assessment complete `[BLOCK]`
- [ ] Character relationships labeled with evolution trajectories `[WARN]`
- [ ] First-3-lines source quote `[BLOCK]`
- [ ] First-50-words / first-100-words checks done `[WARN]`
- [ ] Opening emotional intensity labeled (1-10) `[WARN]`
- [ ] Ending type and emotional landing described `[WARN]`
- [ ] Hook-recovery check done `[WARN]`
- [ ] Opening-ending echo analysis done `[WARN]`
- [ ] All hooks labeled with recovery status (recovered/white space/omitted) `[WARN]`

**Stage 6 (combined assessment)**:
- [ ] One-sentence assessment points at a concrete mechanism (not vague praise) `[WARN]`
- [ ] Five-dimension score with specific notes per item (not vague) `[BLOCK]`
- [ ] Eruption potential analyzed `[BLOCK]`
- [ ] Topicality analyzed `[BLOCK]`
- [ ] Resonance analysis at least 3 layers `[BLOCK]`
- [ ] At least 3 reusable structures, each with applicable scenarios `[BLOCK]`
- [ ] Same-type writing actions are concrete actions `[WARN]`
- [ ] `_meta.json.structure_counts` written, every field meeting the "structure_counts numeric validation" thresholds (see the same-named table in [output-contract.md](output-contract.md)) `[BLOCK]`

**Acceptance hook**: the `[BLOCK]` items above together with the "field minimum counts" table in [output-contract.md](output-contract.md) form the "BLOCK item scan" checklist. The SKILL.md "Acceptance" section calls this section after the Stage 6 content is written and before appending `stages_completed[6]`.
- [ ] Rhythm briefing included
