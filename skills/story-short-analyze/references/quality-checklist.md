
# Web-Fiction Quality Checklist

> **Positioning**: the quality self-check list of story-short-analyze (short-fiction teardown); check item by item when assessing the **deconstruction target's (source text's)** quality.
> The teardown pipeline's own quality checks live in the "quality-check required fields" of output-templates.md; all numeric thresholds are authoritatively defined only in the "quality standards" and "rhythm analysis" of material-decomposition.md — this list doesn't define its own numbers.
>
> **The three quality-track division (don't mix them up)**:
>
> 1. **Teardown-pipeline quality checks** (during execution) → [the "quality-check required fields" of output-templates.md](output-templates.md). Each item carries a `[BLOCK]` / `[WARN]` label; a missing `[BLOCK]` → the "BLOCK item scan" blocks.
> 2. **The assessed object's (source text's) quality** (what material to tear down) → this file. Answers "is this source well written".
> 3. **The teardown report's own quality** (what kind of report to write) → [anti-ai-writing.md](anti-ai-writing.md) + [banned-words.md](banned-words.md). **The report itself** must not be written in AI flavor; the "teardown-report AI-flavor self-check" gates it by scanning the full text of `teardown-report.md`. Note: it scans "the teardown report we wrote", not a source filter.

## Contents

- [I. General checks](#i-general-checks)
- [II. Long-form specifics](#ii-long-form-specifics)
- [III. Short-form specifics](#iii-short-form-specifics)

## I. General checks

### Chapter structure
- [ ] Opening has a hook (not weather/scenery/daily-life openings)
- [ ] Middle advances (events happen)
- [ ] The situation changes (after this chapter, the world is different)
- [ ] The ending lands on the change (not a summary)

### Opening check (first 300-500 words)
- [ ] A hook that grabs attention
- [ ] Doesn't start with weather/scenery/daily life
- [ ] The protagonist appears fast
- [ ] The selling point or crisis is visible

### Chapter advancement
- [ ] A core event exists
- [ ] The situation changes
- [ ] No word-padding (would deleting this chapter hurt understanding? no = padded)
- [ ] Advances at least one of: main line / relationships / settings

### Info delivery
- [ ] No long setting-exposition passages
- [ ] Info follows the conflict (settings delivered through events)
- [ ] Setting load controllable (≤3 new concepts per chapter)

### Scene check
- [ ] The scene has a goal (what the character wants)
- [ ] The scene has an obstacle (what blocks them)
- [ ] The scene has a change (different after it ends)
- [ ] Characters are doing things, not feeling things
- [ ] No deletable passages

### Chapter end
- [ ] Ends on the change
- [ ] At least one of: crisis / decision / discovery / reversal
- [ ] Not a summary ending
- [ ] Pulls the reader to the next page

### Language
- [ ] No hollow lyrical passages
- [ ] No multiple consecutive paragraphs of one emotion
- [ ] Dialogue fits the character (different people speak differently)
- [ ] Emotion lands on action (not "he was very sad" direct labels)

### Serialization continuity
- [ ] No forgotten promises/foreshadowing
- [ ] No sudden info-dumping of new settings
- [ ] Foreshadowing advances
- [ ] The story engine still runs

### Filler detection
These signals = likely padding:
- An entire chapter of dialogue with no new info
- The same emotion written over 3+ paragraphs
- Scene description over 500 words advancing nothing
- Characters recalling past events with no new angle
- 2+ consecutive chapters without conflict

---

## II. Long-form specifics

### The opening hook chapters
- [ ] Chapter 1's first 500 words have a hook?
- [ ] The protagonist appears in chapter 1?
- [ ] Chapter 1 has an event (not pure setup)?
- [ ] Chapter 2 escalates (the contradiction deepens)?
- [ ] Chapter 3 gives a follow reason (the motive to keep reading)?
- [ ] At least 2 payoffs in the first three chapters?
- [ ] No long setting exposition in the worldview?
- [ ] Suspense at every chapter end?

### Rhythm check
- [ ] Clear progress in the last 5 chapters?
- [ ] Payoff intervals over 5000 words?
- [ ] No 2+ consecutive conflict-free chapters?

### Character check
- [ ] Protagonist behavior matches the persona?
- [ ] Supporting have presence?
- [ ] Antagonist aura matches the current stage?

### The five-dimension scoring standards

Each dimension 0-100; pick the polish strategy by the scores.

### Dimension 1: core consistency
Check: are the key conflicts, key actions, and character motives consistent throughout?

| Problem | Severity | Fix |
|---------|----------|-----|
| Motive changes with no setup | critical | add the triggering event for the shift |
| Core conflict inconsistent | high | go back and revise the conflict setting |
| Key action contradicts the personality | high | adjust the action or add explanation |
| Minor contradiction forgotten | medium | recover or weaken it |

### Dimension 2: surface rewrite
Check: are sentence patterns and wording original enough, avoiding formulaic expression?

| Problem | Severity | Fix |
|---------|----------|-----|
| Copying original lines making the tone unnatural | medium | only rewrite when real AI flavor exists; normal lines may stay |
| Heavy AI-signature words | high | replace with concrete description |
| The same sentence pattern repeating | medium | vary the expression |
| Over-literary description (word piles, written register, metaphor strings) | medium | make it colloquial/actional; actional isn't chopping into 3-5 word fragments — after rewriting, narration still runs on comma-joined mid-length sentences |

### Dimension 3: format consistency
Check: are paragraph structure, word-count allocation, and opening/ending formats uniform?

| Problem | Severity | Fix |
|---------|----------|-----|
| Paragraph lengths wildly uneven | medium | adjust paragraph splits |
| Chapter word count off target | **high** | in writing/outline fixes, first go back to the chapter outline and complete the planned plot points, then expand; when de-AI-ing existing prose, never add new plot |
| Format mess (dialogue/description inconsistent) | low | unify the format |

### Dimension 4: readability
Check: wordiness, AI flavor, hollow summaries, formulaic rhetoric.

| AI-flavor trait | How to recognize | How to fix |
|-----------------|------------------|-----------|
| Hollow summary | "He finally understood" / "all in the unspoken" | delete; action instead |
| Formulaic rhetoric | "Fate seemed to be joking with him" | delete or replace with concrete description |
| Emotion label | "He felt a wave of sadness" | behavior instead |
| Idling inner monologue | monologue with no new info, repeating one emotion, or restating what the reader knows | compress only the idling parts; monologues carrying new info, decisions, or emotional turns are not compressed by sentence count |

### Dimension 5: logic coherence
Check: sentence/paragraph flow, setting contradictions.

| Problem | Severity | Fix |
|---------|----------|-----|
| Settings contradict | critical | find and unify |
| Timeline error | high | mark the timeline and fix |
| Character info inconsistent | high | build a character-sheet comparison |
| Causal chain broken | medium | add the transition |

### Polish strategy

| Primary problem | Strategy | Notes |
|-----------------|----------|-------|
| Low core consistency | rewrite | rewrite the related passages around the core conflict |
| Word count over | compress | cut content that doesn't advance the plot |
| Heavy AI flavor | de_ai | replace banned words, rewrite sentence patterns |
| Many small problems | polish | refine the language details |

---

## III. Short-form specifics

### The misery/gratification rhythm check

Short-form-specific items — the distribution of pain points and payoff points:

```
Ideal distribution: pain1 → pain2 → pain3 → payoff1 (small) → pain4 → payoff2 (big)
Forbidden: pain1 → pain2 → pain3 → pain4 → pain5 (no payoff; readers leave)
Forbidden: payoff1 → payoff2 → payoff3 → payoff4 (no setup; gratification fatigue)
```

Check rules:
- At least 1 small conflict per 300 words
- Pain-point intervals within 30% of the piece
- The biggest payoff must sit at 70-85% of the piece
- The ending must have an emotional landing

### Dialogue-density check

> The passing dialogue-share standard is in the "rhythm analysis" of material-decomposition.md.

| Metric | Passing standard | Alert line |
|--------|------------------|------------|
| Dialogue share of the piece | see "rhythm analysis" in material-decomposition.md | <30% (too dry) or >75% (too watery) |
| Dialogue lines per 1000 words | 12-18 | <8 (no interaction) or >25 (fragmented) |
| Hurtful-dialogue share | 35-45% (misery) / 20-30% (gratification) | misery <20% (not painful enough) / gratification >40% (too oppressive) |

### Protagonist-calmness check (comeuppance/revenge fiction)

| Check | Standard |
|-------|----------|
| The protagonist has a signature calm move? | must (holding the water glass / smoothing the jacket / twirling the pen) |
| Any emotional-losing scene for the protagonist? | at most 1 in a revenge piece, and it must be in the first 30% |
| Is the antagonist more hysterical than the protagonist? | must be — the contrast is the gratification source |
| Are the protagonist's lines shorter than the antagonist's? | average 30-50% shorter — the shorter, the stronger |
| "Interrogation dialogue"? | at least 2 (protagonist asks → the other side self-detonates) |

### Evidence-chain completeness check (revenge/comeuppance fiction)

| Check | Standard |
|-------|----------|
| Evidence released in chapters? | at least 3 reveals; never all at once |
| Every piece of evidence set up? | clues must be planted earlier |
| Does the antagonist gloat before every comeuppance? | must be — raise first, then suppress |
| Is the final evidence the most fatal? | the last evidence must change the whole-picture cognition |
| "Timed-bomb" evidence? | at least 1 piece the protagonist pre-positioned |

### Poison/immersion/shock/opening/ending/emotion/anticipation quick check

> **This table assesses the source** (whether the teardown target is well written). The detailed poison-point classification, recognition, and fixes live in [anti-ai-writing.md](anti-ai-writing.md).
> **Don't use this table on the teardown report itself**: the report's own AI-flavor check goes through the "teardown-report AI-flavor self-check" + [anti-ai-writing.md](anti-ai-writing.md) + [banned-words.md](banned-words.md).
> **Teardown-pipeline completeness** goes through the `[BLOCK]` / `[WARN]` checklist of [the "quality-check required fields" in output-templates.md](output-templates.md).

| Check | Standard |
|-------|----------|
| Gratification fiction that doesn't gratify | the cheat's effect must be shown clearly |
| Suppression without purpose | every suppression must serve a later eruption |
| Antagonist ending unrelated to the protagonist | the antagonist's fall must result from the protagonist's action |
| Economy/power broken | settings consistent throughout; ordinary people as the anchor |
| Heroine/supporting dumbed down | normal personas are fine; the old tropes are not |
| Reader expectation unmet too long | satisfy in time or introduce a new expectation |
| Protagonist behavior incomprehensible | must be understandable and resonant |
| Atmosphere broken by a random meme | atmosphere > abrupt meme (except comedy) |
| Hooks unrecovered | unrecovered hooks = unfinished story |
| Shock layering | point → network → depth; never only point-shock |
| Shock staircase | stair-step escalation, not a straight line |
| Shock breadth | the relationship web reacts |
| First 50 words have conflict/anomaly | background setup is not allowed |
| First 100 words show the core contradiction | must know it |
| Opening emotional intensity | ≥7 (1-10) |
| Ending is concrete | action/dialogue/image; summaries/reflection forbidden |
| Ending has aftershock | the reader wants more |
| Ending emotional intensity | misery ≥8, gratification ≥7, healing ≥6 |
| Emotion-matched release | what's invested in misery is repaid; the antagonist's ending ties to the protagonist |
| Expectation management | two-long-one-short unbroken; the core selling point runs through |
