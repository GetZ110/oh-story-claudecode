# De-AI-Flavor Complete Guide

<!-- Byte-identical copy ×5; after editing run scripts/check-shared-files.sh -->

> Identify AI-writing fingerprints, the systematic three-pass de-AI method, banned
> phrase constraints, and a rewrite example library. Consult after writing prose for
> self-check and rewriting.

---

## Decision routing

| What you're doing | Which module to consult |
|-------------------|-------------------------|
| Self-check prose after writing | Core rules -> AI pattern detection -> quality dimension checks |
| Rewriting a passage heavy with AI flavor | Rewrite example library + conflict-dialogue rewrite examples |
| Checking for banned phrases | Banned words & patterns quick ref -> AI high-frequency phrases (Pattern 1) |
| Removing AI flavor from a whole chapter systematically | The systematic three-pass de-AI method |
| Checking whether a chapter end summarizes or elevates | AI fingerprints -> chapter-end summary body |
| Judging whether emotion writing is tell-not-show | Show Don't Tell + supplementary de-AI techniques |
| Fast full-chapter quality scan | Quick self-check mnemonic + quality dimension checks |

## Tone

This file is mostly problem patterns and high-risk lists. Check tier-1 high-risk
phrases first; tier-2/context-sensitive words are judged by frequency, context, and
laziness. When in doubt, creative intent and plot function outrank mechanical
replacement.

---

## AI writing fingerprints (must avoid)

### High-frequency AI phrases

> The full banned list lives in [banned-words.md](banned-words.md)

**Supplementary categories** (advanced replacements not covered by `banned-words.md`):

| Category | Replacement principle |
|----------|----------------------|
| Abstract elevation words (fate, destiny, destined, profound) | Replace the abstract concept with a concrete event |
| Universal similes (like a wave, like a bolt of lightning, like the dawn) | Prefer no metaphor; if truly needed, keep only a few everyday, character-bound ones |

### Chapter-end summary body

**Forbidden** ways to close a chapter:
- Summary reflection ("He finally understood...")
- Elevated exclamation ("That night was destined to be sleepless")
- Philosophic close ("Life is just like that...")
- Teaser preview ("Little did he know, a greater storm was coming")

**Correct**: close with action, dialogue, or suspense — let the events create the
aftertaste.

### Layered description (the same action written three times)

**Detection pattern**: an action/emotion is written as (1) the event, then (2) the
perception detail, then (3) the body reaction, in three separate paragraphs. The
reader sees the same beat sliced into three passes.

**Typical traits**:
- A summary action first, then the same action's detail, then the body reaction:
  three paragraphs about the same thing
- "Event layer -> perception layer -> reaction layer" appears as sequential paragraphs
- Each dimension gets its own paragraph instead of being folded into one continuous passage

**Bad example**:
> Old Man Lin lowered his head, pressing the document flat with his left hand, pen
> in his right, moving it toward the paper.
>
> His hand was shaking from elbow to wrist.
>
> The nib paused over the paper, wrote one stroke, stopped again. The leftward slash
> of that "Lin" came out crooked.

→ The same beat (shaking hand / writing) is spread across three paragraphs, each
paragraph a different dimension of the same instant.

**Correct**: fold event, perception, and reaction into one continuous passage so the
reader gets one complete instant:

> Old Man Lin pressed the document flat with his left hand, pen in his right — the
> nib veered the moment it touched paper, the tremor running from elbow to wrist as
> the first stroke dragged sideways.

→ Event, perception, and reaction all in one paragraph.

**Principle**: keep the emotion details that have a function; merge the repeated
descriptions of the same instant into one continuous picture. If the merge makes the
passage clearly thinner, restore the functional information from the original, or
re-express existing information as more natural action/dialogue; never add plot,
setting, relationships, or timeline that the original didn't have.

---

## Core rules

> **Sentence length follows Rule 3**: wherever Rules 1-4 or other parts of this file
> say "short sentences / split short / cut whenever possible," Rule 3 wins.

### Rule 1: paragraph density diagnosis

Paragraph length has no fixed good or bad. The check is whether reading aloud and
on mobile flow without stalling:

- One paragraph usually carries one action, one piece of changing information, or a
  tightly related set of reactions.
- When a comma chain is too long or several complete actions are packed into one
  paragraph and the reader has to gasp for air, split at the action or the
  information change.
- When consecutive short paragraphs shatter into an outline, merge adjacent
  sentences in the same shot so the picture stays continuous.

```
Too dense: He stared at the rain on the window, a nameless feeling rising in his
chest, all the roads he'd walked and things he'd forgotten surging back in that one
moment.

More natural: He watched the rain streak down the glass. It had been falling since
afternoon.
"You still thinking about her?" Old Liu asked.
He didn't answer.
```

### Rule 2: action + dialogue + emotional reaction

Cycle the three elements; don't write pure interiority for more than 2 paragraphs:

```
action -> dialogue -> emotional reaction -> action -> dialogue -> ...
```

Emotion doesn't use "he felt / she felt" — use body reactions and behavior:
- Don't write "He was nervous" -> write "His palms were wet and he nearly dropped the chopsticks"
- Don't write "She was furious" -> write "She threw the cup on the floor and didn't bend to pick up the shards that bounced off her foot"
- Don't write "He was heartbroken" -> write "He sat in the car for twenty minutes before starting the engine"

These replacements apply to key emotion beats; low-intensity transition emotions can
be written in one line ("He was a little annoyed") without externalizing everything.

### Rule 3: how long should sentences be (short sentences are a tool, not the default)

Narration defaults to **mid-length sentences**: one sentence carries 2-4 actions or
pieces of information linked by commas/and, then lands on a period; clauses run
8-14 words, whole sentences 15-25 words. Short sentences are occasional isolated
heavy beats, not the default voice.

| Scene | Length | Example |
|-------|--------|---------|
| Daily / advancing / describing (most narrative sentences) | clauses 8-14 words, whole sentence 15-25 words | The damp cold hit him in the face, and under him lay a thin layer of straw, sticky against his skin. |
| Dialogue | colloquial, length follows the character | "Are you out of your mind?" "Maybe." |

**Unacceptable (same class as AI voice)**:
- Clause after clause of fragments ≤5 words ("He raised a hand, opened the door,
  stepped in, sat down" style)
- Whole passages of 3-8 word sentences, periods thick as an outline (telegraphic
  style, see Pattern 9)
- Mechanical long-short alternation (also a template)

> **Corpus calibration (v1 baseline)**: these are conservative English prose
> heuristics, not an AIGC score. The repository's human-prose regression fixture
> must pass with zero blocking findings. Before tightening thresholds, evaluate
> against a licensed, genre-labelled English corpus and record false-positive
> rates for narration, dialogue, first person, YA, romance, and thriller prose.
> A single genre's cadence must not become a universal rewrite rule.

### Rule 4: colloquial speech

- Slang and profanity are allowed when they fit the character
- Dialogue must not be bookish ("I believe this approach may be inadvisable" -> "I don't think that's a good idea")
- Narration shouldn't be stiff either ("His gaze was piercing" -> "He stared without blinking")
- Plain phrases beat formal register ("commence" -> "start", "endeavor" -> "try") — this applies to dialogue and character-voiced narration; formal voice is fine in a deliberately literary narrator

---

## Show Don't Tell

| Tell | Show |
|------|------|
| He was a coward | He turned the medical report over three times without opening it |
| The bar was loud | The bartender had to shout twice into his ear before he heard |
| She was rich | She tossed a credit card on the table — the number on it was worth ten times this meal |
| Their relationship was bad | He stubbed out his cigarette in her fresh tea; she pushed the cup away without a word |
| He was sharp | Three seconds. He looked at the file for three seconds and closed it. "Page three, line two." |

**Core method**:
1. Behavior replaces adjectives
2. Detail replaces summary
3. Dialogue replaces narration
4. Reaction replaces emotion words

---

## Quality dimension checks

### 1. Core consistency (highest weight)
- Does the plot match the outline / earlier chapters
- Do character actions fit their design
- Any setting contradictions

### 2. Surface rewrite (anti-AI fingerprint)
- Any AI high-frequency phrases (see table above)
- Chapter end with summary/elevation
- Long blocks of pure interiority
- Paragraphs broken naturally by dramatic unit/shot instead of mechanical one-line-per-sentence or shattering into an outline

### 3. Format consistency
- Dialogue format consistent: one quote style per project/platform convention
- Punctuation rhythm matches tone: avoid whole-text period flattening; keep functional question marks and a few exclamation marks; express hesitation or interruption with action/short sentences, not ellipsis or dash padding
- Scene changes clearly marked
- Timeline traceable

### 4. Readability
- Consecutive long sentences crushing the reading rhythm with no action, dialogue, or short-sentence breathing room
- Dialogue colloquial?
- Unexplained jargon/setting terms
- Rhythm varied (can't be all one pace)

### 5. Logical coherence
- Character motivation reasonable
- Cause-effect chain clear
- Timeline consistent
- Character knowledge scope reasonable (no god-view)

---

## Quick self-check mnemonic

```
One thing per paragraph, break at the shot.
Dialogue must sound like a person talking.
Feelings aren't narrated as inner monologue.
Endings don't rise to grand summaries.
Fights aren't written as camera logs.
Daily scenes still plant their seeds.
```

> Paragraph rules: break naturally by dramatic unit/shot/one completed thing; short
> paragraphs read fast, long ones carry complete reasoning, atmosphere, and emotion
> chains — avoid mechanical one-line paragraphs or uniform lengths.

---

## Banned words & patterns quick ref

> The complete banned list and template table live in [banned-words.md](banned-words.md)

### Correct replacement examples
- 'He felt a flash of nervousness' -> 'His hands were shaking'
- 'She was heartbroken' -> 'She turned away and crushed the edge of her sleeve in her fist'
- '"Okay." He said' -> '"Okay." He slid the key card back into his pocket'
- 'He took a deep breath' -> 'He swallowed the words'

---

## 10 AI writing pattern detections

### Pattern 1: AI high-frequency phrases

| Banned | Replace with |
|--------|--------------|
| couldn't help but | delete |
| as if on cue | delete |
| took a deep breath | delete or make it specific |
| heart raced/sank/lurched | specific body detail, or nothing |
| a wave of X washed over | pick one; show it in behavior |
| the kind of X that Y | concrete detail or action |
| in that moment / at that moment | delete or name the exact beat |
| eyes widened/narrowed/met | posture, breath, words |
| for some reason / somehow / deep down | write the cause |
| a beat passed / a moment passed | cut to the answer |

### Pattern 2: weak adverb flood
Threshold: more than 3 per 1000 words = AI signature. Watch: almost, barely,
slightly, gently, softly, quietly, slowly, really, very, quite.

### Pattern 3: meaning inflation
- "profoundly significant" -> write the concrete consequence
- "unprecedented" -> give a comparison reference
- "one might say" -> delete

### Pattern 4: universal conclusions
- "a bright future awaits" -> end on unresolved tension
- "boundless potential" -> delete
- "full of hope" -> write the specific next step

### Pattern 5: essay-style paragraph openings
These openers in fiction = AI intrusion:
- "It is worth noting that" / "As we can see" / "In conclusion" / "In fact" / "Needless to say" / "Interestingly"

### Pattern 6: formal connective flood
Frequent in narrative prose: "furthermore", "moreover", "consequently",
"additionally", "nevertheless", "thus", "therefore" -> plain alternatives or delete.

### Pattern 7: triple-parallel habit
AI likes to group things in threes to look "complete". -> Cut to the strongest one.

### Pattern 8: explainer voice / god-view / arranged feeling
The hardest to spot and the most "AI-like" of all. The narrator steps out of the
character's present to explain, spoil, summarize, classify, or elevate — the reader
smells "the author is here" and "the plot was arranged". This is the source of the
preachy/god-like/explainer/mechanical/arranged feeling.

| Manifestation | Example (delete/rewrite) |
|---|---|
| Explaining cause-effect | "The reason was that... / What he didn't know was... / This meant... / Precisely because..." -> delete. Let the reader assemble cause from the character's actions, dialogue, and reactions |
| God-view spoilers | "Little did she know", "Years later", "As fate would have it", "As if foreshadowing" -> delete. Write only what the character knows right now; let suspense hang |
| Verdicts for the reader | "He was that kind of cold man", "She had seen this play before" -> delete. Present the evidence (expression, action, line) and let the reader judge |
| Summarizing the character's psychology | "She understood: this was fate" -> replace with one biased flash-thought or one body reaction |
| Meaning-complete summary chains | "He finally understood", "It was the best choice", "Everyone would remember this moment" -> delete the verdict; replace with the concrete gap the character must handle now, the unfinished action, or local feedback — not keeping the verdict and shoving an object/action in |
| Arranged setup / hard seeding | Forcing background for later, whole-paragraph flashback -> bring background out as the character actually needs it now: flash-thoughts, half-sentences, fragments of objects |
| Elevated endings | Parallel grand closers, aphorism points -> close with one action or one blank beat, pressing the "meaning" into the image |
| Abstract fate closures | "Fate had finally bared its teeth", "The game was already set", "He finally understood in this moment", "His counterattack was just beginning" -> rewrite as documents, actions, dialogue, or physical consequences the character can see right now; when `check-ai-patterns.js` reports `abstract-summary-tic`, treat it first |
| Cliche density too high | "couldn't help but / a wave of / took a deep breath / somehow" strings (`cliche-density-tic`) -> not synonym rotation; return the whole passage to the character's present evidence: documents, actions, dialogue, physical consequences |
| Metaphor density too high | like/as if/as though marker sheets (`metaphor-density-tic`) -> keep the one or two that carry the most information or emotion; return the rest to concrete action, objects, sounds, consequences; don't swap in new metaphors |
| System-notice formality too dense | [bracketed] rule/panel/notice lines full of hard rule words (`system-notice-formality-tic`) -> keep them as the screen/notice/rule carrier the character sees; plain-language some hard words inside the carrier or show the concrete consequence the character understands on the spot — don't rewrite into narrator explanation |

**A deeper layer (hardest to self-check, no marker words)** — the same
arranged/god feeling:
- Judging adverbs/complements: "he asked with just the right amount of concern",
  "she smiled exactly as expected" -> the author is stamping "this is fake" for the
  reader. Only write the action ("she pressed her handkerchief to her mouth, eyes
  still"), let the reader decide.
- Spoiler-like point-outs: "she read the smile plainly", "anyone could see he was
  lying" -> exposing what's hidden. Leave it un-pointed-out.
- Verdict metaphors: "like a sentence already passed", "like looking at a dead
  thing" -> the metaphor is passing judgment for the character. Delete unless it's
  the character's strong subjective feeling in this moment; if kept, it must be her
  biased flash-feeling, not an objective assertion.

Self-check: ask of every sentence — is this "the character experiencing" or "the
author explaining/arranging"? Whenever the author steps out to talk, delete it or
re-present it inside the character's POV. The root cure is locking the deep limited
POV (see writing-craft.md "POV stance: deep limited") — the camera nailed inside the
character's body leaves no room for the author to step out.

Fix priority: delete or in-place replace the polluted sentence first; don't tack a
"humanity tail" onto the paragraph end. When information must be kept, turn the
summary/motivation/verdict sentence into the concrete pressure the character can
touch right now: problems, procedures, replies, payments, sounds outside the door.
When the text already has phones, screens, notices, door plates, forms, etc., keep
them as in-scene carriers the character sees — don't rewrite the same information as
narrator explanation. The carrier follows the plot; don't apply a fixed list.

**Task blockers are not a fixed formula or a universal fill button**: they merely
land existing explanations back into a gap the character must handle now. First ask
whether the original has a "thing to do" and a "blockage"; only then compress the
explanation into a task blocker; if not, just delete the explanation or change it to
action/dialogue — don't invent a new event chain. After rewriting, run the "delete
test": if deleting it loses no information, emotion, relationship, cost, or
foreshadowing, compress or delete.

**But deleting explainer voice ≠ confusing the reader**: when a new term/setting/
prop first appears, the reader still needs one anchor — through the character's
action-reaction, a half-line in dialogue, or a physical consequence in the scene —
one stroke that shows its current function or weight; neither a whole passage of
backstory/principles nor a bare unknown word that leaves the reader stranded.
Character memory, emotional buffering, and causal continuity work the same way: if a
sentence that looks like explanation actually carries local coherence (why the
character's face is hot, why she pauses, why this sound can't be suppressed), don't
mechanically delete it into an itemized list; compress it into the character's
present plain speech, action, object, or half-thought. Example: the first appearance
of the "blue crystal" doesn't require "this is a device that stores memories" — but
it can show her pressing the blue crystal to her temple and someone else's memory
fragments exploding behind her eyes. Function is seen; the full picture stays a
mystery. Distinction: an anchor is "the perceptible consequence/memory/emotion the
character collides with right now" (keep or compress); an explanation is "the author
stepping out to teach the setting's origins/principles or conclude for the reader"
(delete).

### Pattern 9: overcompression (telegraphic style)

The reverse fingerprint of over-aggressive de-AI. Every sentence squeezed to minimum,
function words swept clean, every action capped with a hedged micro-reaction. Each
sentence looks clean alone; read together it's an outline — the reader feels "not
smooth, can't breathe". The goal of cutting is deleting waste (explanation, padding,
filler), not deleting English's natural redundancy.

| Manifestation | Fix |
|---|---|
| Non-peak narrative sentences all crushed to minimum | Keep heavy-beat sentences (action/emotion/suspense peaks) short; write setup, transition, and daily actions as natural sentences, keeping function words (the/and/was/had/but/then/when) |
| Hedged micro-beat repetition: "smiled slightly / nodded gently / sighed softly" (`micro-action-tic`) | Merge actions, vary with concrete detail; not every action needs a reaction tail |
| Emphatic adverbs swept clean | Judge meaning before deleting: keep those carrying characterization, contrast, or irony |
| Dialogue particles zeroed out | Keep natural low-frequency interjections per character; don't reverse-flood either — humanity comes from natural structure, not chat-speak |
| Narration keeps formal residue ("must/shall/thus/hereby" in non-system prose) | Plain it ("has to / should / so / now"). System notices, rule text, panel broadcasts may keep cold function; if `system-notice-formality-tic` fires, plain-language part of it inside the carrier only, don't turn it into narrator explanation |
| Short narrative paragraphs in sheets (`overcompressed-prose-tic`) | Don't lengthen all short paragraphs. Read first: heavy-beat short sentences and dense shots that flow fine stay; only process the transitions that read like an outline, merging them back into the same shot so the reader flows through action, space, and causation |
| Low connective density outside quotes with few mid-long sentences (`low-connective-density-tic`) | Not a global "add the/and/but" pass, and don't touch naturally terse dialogue/chat/system text. Find the narration joints that read like an outline/telegraph, restore necessary connectives, reference, and mid-length sentence groups; text with a chain of mid-long sentences can stay |

Self-check: after cutting, read it once through — if it reads like an outline or
drill commands, you over-cut. Restore non-peak sentences to natural speech; don't
keep cutting.

This pattern governs the *degree* of cutting, not the cleaning standard: banned
words, template sentences, and tell-not-show psychology still get cut per Patterns
1-8 and Gates A-G in full; restorations only add structural function words and
connectives — never keep or restore template phrasing.

### Pattern 10: second-pass fake naturalness (greasy inversion / camera action lists / dialogue metrics)

Some "anti-detection" prompts push text into another template: random inversions to
look sudden, mechanically sprinkled verbal slips and profanity for "realism",
forced line breaks for mobile reading, and psychology/narration converted into
dialogue to hit a dialogue percentage. These are not natural web fiction — they're
second-pass traces.

| Manifestation | Fix |
|---|---|
| Greasy inversion | Don't write "Holding the knife in his hand, he charged" style front-loaded participial motion. With a continuing subject, prefer in-scene objects, sounds, body parts, or environment feedback to vary sentence openers; don't abuse animating dead objects |
| Camera action list | A paragraph stacking "reached, grabbed, pulled open, set down, turned, walked" like a procedure table. Merge trivial steps; keep only actions with emotional, plot, or spatial function; buffer with hesitation, misjudgment, others' reactions, or environment feedback when needed |
| High-pressure over-dehydration | Conflict, chase, and fight scenes may shed explanation and logical glue; daily, romantic, and setup scenes can't be dehydrated for a whole chapter. Cut waste, not natural connectives (and/but/then/when/though) |
| Eaten words | After de-AI, if verbs have no object, actions point nowhere, and the reader can't tell who did what to whom, restore the necessary object, carrier, or physical feedback |
| Dialogue metrics | Don't inflate dialogue to hit a 50-60% ratio. Add lines only when a character truly would and must speak now; long exchanges can break into action; explanatory dialogue compresses into conflict, avoidance, or half-information |
| Hard formatting gaming | Don't force one sentence per line, 50-60 char lines, ellipsis as periods, or all punctuation games. Follow the platform/project's existing format |

`check-ai-patterns.js`'s `action-list-tic` is advisory, not blocking. Functional
fight/chase/ritual chains that carry information may stay or be marked `[needs
review]`.

#### Tool-report handling

`check-ai-patterns.js` is a local writing lint; blocking covers only deterministic
sentence/punctuation issues, advisory is not a completion gate. When the user pastes
another tool's report, convert only the sentence/paragraph/vocabulary issues that
land in the prose into concrete fix points — don't write "0% AI / 100% human" or
"fixed formula", and don't fine-tune around a score.

Tool reports don't outrank reading-feel rules. If reference text contains banned
phrases or tell-not-show psychology ("couldn't help but", "he felt"), still clean it
per Patterns 1-8; don't mechanically add typos, deliberately misspell, or genre-shell
it.

**Supplementary de-AI judgments**:
- Priority fixes: author explanation/summary, meaning tails, translating plot into
  "he realized / this meant / what really mattered / this growth". Delete first, or
  land them on in-scene action, dialogue, object state, task state, and the
  consequence the character must handle right now.
- In-scene carriers first: when the text already has phones, screens, notices, door
  plates, forms, bills, evidence, rule lines — keep them as text/objects the
  character sees/misreads/handles; don't rewrite the same information as narrator
  explanation rules.
- Plain but not padded: don't substitute refined dramatic-reaction phrases
  ("his scalp tightened, her heart lurched, his stomach churned") in a chain to
  replace plot progress; when a plain action or plain feeling works, write the plain
  thing, and keep natural connectives.
- Genre style first: style benchmarking helps, but must come from the target
  genre/this book's style fingerprint; don't treat one famous author's voice as a
  universal cross-genre cure.
- Not a universal fix: merely adding titles, objects, action tails, lengthening/
  shortening sentences, or adding queues/gates/log entries cannot replace treating
  the specific plot, POV, and language problems.

#### Turning outline sentences into continuous paragraphs

When the text has no blocking / obvious advisory findings but still reads like an
outline, treat only the broken joints:

1. Mark paragraphs that read like logic reports: chains of "he knew / he understood /
   this meant / the real problem / had to / needed" without present action, object,
   or dialogue feedback.
2. Land the narrator's conclusions: replace "he realized / this meant" with the
   consequence the character can touch, hear, or is forced to handle now. Don't
   apply a fixed object list, and don't treat one scene's shell as a universal rule.
3. Restore natural connectives and function words only at the broken joints; no
   ratio targets, no mechanical connective filling.
4. System notices, rule text, and panel broadcasts may keep cold short sentences;
   when `system-notice-formality-tic` fires, plain-language part of the hard rule
   words inside the carrier or let the character see the concrete consequence on the
   spot — don't rewrite into narrator explanation.

Specific fixes for `overcompressed-prose-tic` / `low-connective-density-tic`:

1. Circle the consecutive short narrative paragraphs and label each one's function:
   explosion/reversal/fear heavy-beats and dense shots may stay short; setup, space,
   causation, and action continuation should merge back into the same shot. If it
   reads fine by hand, don't keep lengthening because of the advisory.
2. When merging, prefer restoring "action order, spatial orientation, causal
   connection" ("when he looked up / outside the door / already / still / then /
   because") rather than jamming a function word into every sentence.
3. After merging, cut banned phrases and tell-not-show psychology again: reading
   smoothly is not a license to restore AI voice — don't flood "couldn't help but /
   felt / somehow / a wave of" back in.

Review handling: if the feel is still unstable after clearing
`overcompressed-prose-tic` / `low-connective-density-tic`, stop local tweaks and
switch to paragraph-level rewrite or a human read-feel comparison.

Example:

```
Overcompressed:
Lin Yao looked up.
The streetlights outside the awning went dark.
The wind stopped too.
The paper cup on the counter wobbled twice.

Smoothed:
When Lin Yao looked up, the streetlights outside the awning were blinking out one by
one. The wind had stopped, and the paper cup on the counter was still spinning
slowly in place.
```

---

## The systematic three-pass de-AI method

### Pass 1: Strip generic
- Abstract emotion summaries -> delete or replace with concrete action
- Fake-depth sentences -> delete
- Meaning inflation -> shrink to the specific effect
- Hollow conclusions -> delete
- Tidy contrast constructions -> break apart and rewrite
- Decorative adjective piles -> plain description
- Overused "then / so / in that moment / somehow" -> cut half
- All characters sounding equally "elevated" -> differentiate voices

**Principle**: delete when you can; when you can't, replace with concrete detail.
This pass removes ~80% of the AI flavor.

### Pass 2: Cut professional diction
- Analytic words in fiction ("mechanism", "structure", "logic", "system" as
  abstractions) -> everyday expression
- Abstract-noun abuse -> say the thing
- Institutional phrasing ("furthermore", "additionally", "in terms of", "with
  regard to") -> delete
- Jargon piles -> keep only what's needed, plain-language the rest

**Exception**: keep professional texture where the scene demands it (formal
historical register, deliberately dense literary prose, comedic exaggeration).

### Pass 3: Restore natural presence
- Concrete sensory details (smell, temperature, touch)
- Distinct character speech (different voices)
- Sentence-opener variety: when 3+ consecutive sentences open with the same subject
  or same word class, change the opener (action, scene, dialogue lead-in)
- Rhythm variation (long/short interleave): regulate sentence and paragraph length
  by emotion beat, action advance, and dramatic unit; avoid uniform lengths across
  paragraphs, but don't shatter into an outline for shortness. Length isn't random:
  reflective passages can slow, conflict/reversal can snap short, complete reasoning
  and emotion chains stay continuous
- Social-positioned dialogue (boss and subordinate talk differently)
- Scene-specific memory points
- Project-specific speech habits (character catchphrases)

**Principle**: less is more. 1-2 concrete details per paragraph are enough.

### Escalation strategy

| AI-flavor level | Strategy |
|-----------------|----------|
| Light | Pass 1 only |
| Medium | Pass 1 + Pass 2 |
| Heavy | Full three passes + key-paragraph rewrite |

### Self-check list
- Dialogue naturalness: colloquial? No formal register?
- Delete any sentence — does understanding suffer? No = possibly redundant
- Can you tell characters apart by dialogue?
- Is there one detail specific to this scene?

---

## Supplementary de-AI techniques

### Show vs Tell

| Tell type | AI version | Natural version |
|-----------|-----------|-----------------|
| Telling anticipation | "He was looking forward to it" | Show the anticipation -> emotion -> fulfillment chain |
| Telling intent | "She wanted a divorce" | Show the intent through action |
| Telling attitude | "She was very calm" | Convey through dialogue and reactions |
| Telling plot direction | "Something big was about to happen" | Show via setup -> reversal -> continuation |

### Interiority that works quietly

- Parenthetical inner commentary = breaks immersion
- Long interior monologue explaining motivation = AI signature
- Writing "she felt" / "she realized" directly = telling emotion

**Natural version**: interiority folds into the narration; behavior implies mind;
silence, actions, and off-behavior express the inner state.

### Immersion check
- Can the reader understand, resonate with, and accept the protagonist's actions?
- Is the antagonist strong enough? (weak antagonist = the protagonist's win feels hollow)
- Does behavior revolve around character design? (behavior/language/thinking around personality)
- Is reader-known information being manipulated effectively? (information gaps create emotional swings)

---

## Rewrite example library

### Externalizing emotion

**Nervous**
- 'A wave of nervousness washed over him, his heart beating faster against his will'
- He squeezed the paper cup until water spilled over the rim

**Angry**
- 'Anger burned inside him and he clenched his fists without thinking'
- He slammed his chopsticks on the table; soup splashed out of the bowl

**Sad**
- 'A trace of sadness rose in her chest and tears glistened in her eyes'
- She stirred her coffee, head down, for a long time

**Afraid**
- 'Fear gripped him instantly and a shudder ran through him'
- He pressed his back against the wall and didn't dare move

**Disappointed**
- 'She felt a sting of disappointment, as if something had squeezed her heart'
- "Oh." She locked her phone and set it face-down

**Surprised**
- 'His pupils contracted slightly; clearly he hadn't expected to hear that'
- His mouth opened and closed without a sound

### Scene description

**AI-style scene**
- 'Sunlight streamed through the gaps in the curtains, casting dappled shadows on the
  floor. The air was filled with the faint scent of flowers, as if the whole world
  were bathed in a serene and peaceful atmosphere.'
- Three in the afternoon, and the only thing moving in the living room was the clock.

**AI-style weather**
- 'The sky hung heavy with dark clouds, as if it might pour at any moment. A biting
  wind howled through, carrying a chill that pierced to the bone.'
- It was going to rain. The wind was whipping the laundry on the line.

**AI-style fight**
- 'His fists came like a storm, each blow carrying undeniable force. The opponent's
  pupils contracted — clearly unprepared for such a ferocious assault.'
- He threw one punch. The other guy didn't dodge, and his lip split.

### Ending rewrites

**Elevated ending** -> 'He stood at the window, gazing at the skyline, finally
understanding the truth of life: sometimes letting go is the best choice.' -> He
stubbed out his cigarette and went to bed.

**Summary ending** -> 'In that moment, everything changed. She knew her life would
turn a new page from today.' -> She closed the door behind her. Didn't look back.

**Reflective ending** -> 'Time flowed by like water, quietly...' -> Delete the
passage outright.

### Rhythm adjustments

> The following examples treat bloated modifiers, stacked metaphors, and abstract
> summaries — not "break any long sentence": after rewriting, narration still runs on
> mid-length sentences (Rule 3); don't chop healthy mid-length sentences into short
> strings.

**Parallel sentence**
- 'He looked at her eyes, looked at her lips, looked at her trembling lashes, a
  nameless emotion rising in his chest.'
- He looked at her. She didn't say anything.

**Bloated long sentence, stripped**
- 'When he finally pushed open the heavy wooden door, what met his eyes was a dim
  room, the air thick with age, the corners piled with dusty boxes.'
- He pushed open the door. The room was dim, with dusty boxes stacked in the corner.

**Tidy paragraph, broken apart**
- 'She loved the flowers of spring, the sun of summer, the leaves of autumn, the
  snow of winter. Every season had its own unique beauty.'
- She loved spring. The other seasons were fine too.

---

## Conflict dialogue rewrite examples

### AI-style polite dialogue
- 'I feel that what you're doing isn't quite appropriate. Could you please consider
  my feelings?' -> "Do I even exist to you?"

### AI-style perfect explanation
- 'Actually, I had my reasons, because the situation at the time was very
  complicated...' -> "What are you going to do about it?" She set her teacup down
  hard.

### Five-level dialogue escalation

The same conflict scene, weak to strong:

1. **Objective statement**: "You threw away my stuff."
2. **Statement + suggestion**: "You threw away my stuff. Next time, tell me first."
3. **Subjective accusation**: "What gave you the right to touch my things?"
4. **Accusation + command**: "Who do you think you are, touching my stuff? Get out."
5. **Accusation + degradation**: "I feed you, I clothe you, and you can't even put
   one thing away right. You'll never amount to anything. Without me, you're
   nothing."

### Layered shock rewrite

**AI-style one-step**: Everyone was shocked, unable to believe their ears.

**Natural layered shock**:
1. The man across the table's hand twitched; tea spilled from his cup.
2. The people beside him exchanged glances; one stepped back, someone in the corner
   started pulling out a phone.
3. The woman who'd been strutting moments ago — the smile froze on her face. Her
   mouth opened and closed without a word.

### Immersion repair

**Passive protagonist**: She was very scared and didn't know what to do, so she
just waited for it to pass.

**Active protagonist**: She locked the door, put her phone on silent, and started
recording.

---

## Quality check list

Scan every chapter after writing:

- [ ] **Paragraph control**: paragraphs break at action/information change, read without stalling
- [ ] **No em-dash clusters**: at most one em dash per line in prose (including dialogue); no `--`; no `...` runs (use single `…`)
- [ ] **AI high-frequency phrase scan**: no couldn't help but / as if on cue / took a deep breath / heart raced / a wave of / in that moment / eyes widened / for some reason
- [ ] **Weak adverb count**: no more than 3 per 1000 words of almost/barely/slightly/gently/softly/quietly/slowly/really/very/quite
- [ ] **No triple parallel**: no AI "group of three" rhetoric
- [ ] **No essay voice**: no "It is worth noting that / As we can see / In conclusion / Interestingly"
- [ ] **No formal connective flood**: no furthermore/moreover/consequently/additionally/nevertheless strings
- [ ] **Chapter end without summary/elevation**: closed with action/dialogue/suspense, no reflection/philosophy/preview
- [ ] **No long interior blocks**: interiority under 2 paragraphs, no parenthetical inner commentary
- [ ] **Emotion shown by action**: key emotion beats have no direct "angry/sad/nervous" labels — body reactions instead; low-intensity transition emotions may be written straight
- [ ] **Dialogue colloquial**: no bookish register; character voices distinguishable
- [ ] **Punctuation not flattened**: questions, outbursts, hesitation aren't all period-flattened; no random `?`/`!` stacking or `…`/`—` padding for pauses
- [ ] **Show Don't Tell**: behavior replaces adjectives, detail replaces summary
- [ ] **Sentence length on target**: narration defaults to mid-length sentences (clauses 8-14 words, whole sentences 15-25 words, Rule 3); short sentences are occasional isolated heavy beats; no consecutive ≤5-word fragments, no whole-passage telegraph
- [ ] **Low telegraph risk**: non-peak narration keeps natural function words; hedged micro-beats ("smiled slightly / nodded gently") don't repeat; if `micro-action-tic` fires, read first, merge only genuine mechanical repetition; functional light reactions may stay or be marked `[needs review]`
- [ ] **Low abstract-summary voice**: fate/wheels/finally understood/just beginning don't string; if `abstract-summary-tic` fires, treat only genuine elevation; endings close on action, objects, or unresolved questions
- [ ] **Low cliche stacking**: couldn't help but / a wave of / took a deep breath / somehow don't cluster; if `cliche-density-tic` fires, concretize only genuine template voice — no synonym rotation
- [ ] **Low metaphor stacking**: like/as if/as though don't sheet; if `metaphor-density-tic` fires, keep only the most functional metaphors, return the rest to concrete imagery — don't swap in a new batch
- [ ] **Low reasoning-chain report voice**: he knew / this meant / had to decide chains don't cluster; if `reasoning-chain-tic` fires, treat only genuine report voice, land on action, objects, dialogue, and scene feedback
- [ ] **Low system-notice formality**: [bracketed] rule/panel/notice lines don't stack hard words; if `system-notice-formality-tic` fires, keep the in-scene carrier, plain-language part of the hard words inside it, or show the consequence the character understands on the spot
- [ ] **No unexplained overcompressed short paragraphs / low connective density**: long texts don't show an outline/telegraph distribution; if `overcompressed-prose-tic` or `low-connective-density-tic` fires, read first. Intentional short shots that flow may be marked keepable; where joints genuinely break, restore connectives, necessary function words, and mid-length sentence groups only — mechanical padding is forbidden
- [ ] **No camera action lists**: one paragraph doesn't stack "reached/grabbed/pulled/set down/turned/walked" trivial steps; if `action-list-tic` fires, judge whether the chain carries fight/chase/ritual/information function first; if it's a procedure table, merge actions and add POV buffering
- [ ] **No hard metric gaming**: no forced one-line-per-sentence, no dialogue-percentage padding, no ellipsis-as-periods or punctuation games to dodge detectors
- [ ] **Task blockers respect the original boundary**: abstract summaries compressed into task blockers must come from the original's existing task/evidence/procedure/object gap; don't invent event chains the original didn't have
- [ ] **Three-pass method executed**: light = Pass 1 only, medium = Pass 1+2, heavy = all three
- [ ] **Dialogue naturalness test**: no written-register traces = pass
