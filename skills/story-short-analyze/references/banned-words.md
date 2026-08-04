# AI-Flavor Banned Words & Sentence Patterns

<!-- Byte-identical copy ×6; after editing run scripts/check-shared-files.sh -->

## Most toxic sentence patterns (fix on sight, highest priority)

The most damaging AI sentence patterns in English web fiction. Once an author picks
them up they recur constantly. Gate A's first pass must hit these:

| Toxicity | Pattern | Bad example | Fix |
|----------|---------|-------------|-----|
| ★★★★★ | "It wasn't X. It was Y." / "not X but Y" contrast flips | "He wasn't cold. He was desperate." | Write Y directly, or show it through action/detail |
| ★★★★★ | Trailer/preview endings: "Little did he know..." / "what happened next would..." / "this was only the beginning" | "Little did she know, everything was about to change." | End on a concrete action, image, or line; let the event hang |
| ★★★★★ | Chapter-end state verdicts: "It was a night that would change everything" / "nothing would ever be the same" / "everything was about to change" | "It was a night that would change everything." | The ending state is planning language — land one last concrete beat |
| ★★★★ | "the kind of X that Y" | "the kind of smile that never reached her eyes" | Concrete detail or action the reader can picture |
| ★★★★ | "couldn't help but X" | "He couldn't help but smile." | Just do X; no hedge needed |
| ★★★★ | "as if on cue" | "As if on cue, the rain started." | Delete; the sequence itself does the work |
| ★★★★ | quiet-voice contrast: "voice was quiet/soft/low, but..." | "Her voice was quiet, but it carried an unmistakable authority." | Write the line and the room's reaction |
| ★★★ | "took a deep breath" | "She took a deep breath and opened the door." | Delete or make it specific to the moment |
| ★★★ | heart verbs: "heart raced/sank/lurched/hammered/skipped a beat" | "His heart raced as he stepped forward." | Body-specific detail, or none at all |
| ★★★ | "a wave of X washed over" / "a mix of X and Y" | "A wave of relief washed over him." / "She felt a mix of anger and relief." | Pick the dominant feeling; show it in behavior |
| ★★★ | "in that moment" / "at that moment" | "In that moment, he knew..." | Delete or name the exact beat |
| ★★★ | "eyes widened/narrowed/met" | "Her eyes widened in shock." | Show the reaction through posture, breath, or words |
| ★★ | "He knew that..." / "She realized..." (filter/reasoning) | "He knew that this was his only chance." | Behavior shows the knowledge; cut the filter |
| ★★ | "before he knew it" / "little by little" / "one by one" | "Before he knew it, the day was gone." | Concrete elapsed-time detail |
| ★★ | "for some reason" / "somehow" / "deep down" / "there was something about" | "For some reason, he couldn't move." | The reason is the story; write the cause |
| ★★ | "a beat passed" / "a moment passed" | "A beat passed before she answered." | Delete the filler; cut to her answer |

> Any ★★★★★ hit is strong evidence of heavy AI flavor; ≥2 ★★★★ hits trigger a
> medium-depth rescan.

**Punctuation**: prose may keep at most one em dash per line (clusters are an AI
tell); use "…" (single ellipsis char), never "..." or "......"; never write double
hyphens "--" (convert to em dash); prefer curly quotes; no space before punctuation.

---

## Tier-1 banned phrases (replace on sight)

> What goes into tier-1: phrases that rarely appear in clean human prose and are
> AI-signature. Natural adverbs and ordinary function words stay out of tier-1 —
> they belong to tier-2 density control.

### Modal / hedging
couldn't help but, as if on cue, little did X know, unbeknownst to, before X knew it,
for some reason, somehow, deep down, in the depths of, there was something about

### Reaction templates
took a deep breath, heart raced/sank/lurched/hammered/skipped a beat,
a wave of X washed over, a mix of X and Y, in that moment, at that moment,
eyes widened, eyes narrowed, eyes met, a beat passed, a moment passed

### Judgment summaries
the kind of X that Y, he finally understood, she realized then, from that moment on,
a new chapter began, nothing would ever be the same, everything was about to change,
fate had other plans, the wheels of fate

### Fillers
for a moment, after a moment, for the longest time, at this point, as if to say,
the weight of the moment, the silence hung in the air, tension was palpable,
she let out a breath she didn't know she'd been holding

## Tier-2 (replace when they cluster)

### Context-sensitive words (only when repeated or lazy)
suddenly, immediately, instantly, abruptly, seemingly, almost, barely, slightly,
gently, softly, quietly, slowly, carefully (keep in dialogue, real sudden events,
or time compression; synonym-rotation to dodge repetition still counts as the same
word for density)

### Weak adverbs (density control)
almost, barely, slightly, gently, softly, quietly, slowly, really, very, quite,
somewhat, perhaps, maybe (≤3 per 1000 words total; these also feed
`cliche-density-tic`; isolated natural use may stay, strings of them or one per
action should be cut)

### Filter words (density control)
felt, saw, noticed, realized, knew, wondered, thought, heard, seemed, appeared
(show the evidence instead of the perception)

### Formal register → plain

| Formal | Plain |
|--------|-------|
| commence | start |
| purchase | buy |
| utilize | use |
| ascertain | find out |
| endeavor | try |
| subsequently | then |
| approximately | about |
| additional | more |
| in order to | to |
| due to the fact that | because |
| at this point in time | now |
| it is important to note | (delete) |

### Summary sentences
- "He/She finally understood..."
- "She realized then..."
- "In that moment, he knew..."
- "From that moment on..."
- "X's counterattack/revenge/story was just beginning"
- "fate/destiny + wheels/plans/game/sealed"
- "Everything was going to change"
- "This was only the beginning"

### Parallel triads
- 3+ consecutive same-structure sentences
- "No X. No Y. No Z."
- "Not X. Not Y."
- "Some X, some Y, some Z"

### Elevation sentences
- "In that moment..."
- "He knew..."
- "She understood..."
- "This was..."

## Banned template table

| Template | Example | Problem |
|----------|---------|---------|
| "It wasn't X. It was Y." | "He wasn't cold. He was desperate." | Most toxic; write Y directly |
| "couldn't help but X" | "He couldn't help but smile." | Needless hedge |
| "voice was quiet, but..." | "Her voice was quiet, but it carried authority." | AI's favorite voice move |
| "a mix of X and Y" | "She felt a mix of anger and relief." | Emotion label instead of behavior |
| "took a deep breath" | "She took a deep breath and..." | Filler before every action |
| "heart + raced/sank/lurched" | "His heart raced." | Template reaction |
| "the kind of X that Y" | "the kind of smile that never reached her eyes" | AI habit construction |
| "in that moment" | "In that moment, he knew..." | Elevation filler |
| "a wave of X" | "A wave of relief washed over him." | Emotion as weather |
| "eyes widened/narrowed/met" | "Her eyes widened in shock." | Face as telegraph |
| "a beat passed" | "A beat passed before she answered." | Scene filler |
| "It wasn't just X, it was Y" | "It wasn't just anger. It was fury." | Intensifier contrast |
| "He felt / She felt" | "She felt a sting of betrayal." | Telling instead of showing |
| "the silence hung in the air" | "The silence hung in the air like a curtain." | Atmosphere cliche |
| "she let out a breath she didn't know she'd been holding" | "She let out a breath she hadn't realized she was holding." | Signature AI reflex line |
| "gaze" stacking | "His gaze swept the room. Her gaze fell." | Fancy-word repetition; use eyes/look or cut |
| "seemed to X" stacking | "He seemed to hesitate. She seemed to wait." | Hedging every action |
| "as if to say" | "He nodded, as if to say he understood." | Narrator interpretation; write the nod |

## Metaphor classification (review by default, don't delete wholesale)

A metaphor with "like/as if/as though" is not automatically AI. The real risks are:
stacking them in sheets, reusing universal literary similes, using a polished
metaphor to replace plot advancement, or ending paragraphs with an authorial
meaning-summary. This table identifies metaphors worth reviewing:

| Class | Example | Treatment |
|-------|---------|-----------|
| Everyday / character-bound | "like a stray dog that had been kicked" | Keep if it fits the POV and carries information or feeling |
| Object / phenomenon | "sharp as a blade" "white as the snow driving past" | Functional similes may stay; templated or repeated ones go plain |
| State (cliche) | "butterflies in her stomach" "like a deer in headlights" "cold as ice" | Cut first, or replace with a concrete action/expression |
| Abstract | "like the wheels of fate" "like dust from a past life" | High risk; land back on action, objects, sounds, consequences |
| Hypothetical | "as if he could crush bone" | Keep if it's bodily perception; cut when piled for effect |

Principle: function first, then density. Keep the one or two similes that carry the
most information or feeling; return the rest to plain description, verbs, nouns,
effects, results, or facts. Don't swap deleted metaphors for a new batch.
Example: "white as the snow driving past" is a cliche unless the snow is actively
pressing on the character — then keep it or show the snow the character actually sees.

> `metaphor-density-tic` is advisory: read through and review, not blocking;
> everyday, character-bound, single functional metaphors may stay.

## Replacement quick reference

| Original type | Replacement | Example |
|---------------|-------------|---------|
| Abstract emotion | Concrete action | "nervous" → "his hands were shaking" |
| "felt X" | Externalized behavior | "felt angry" → "clenched his fists" |
| Adjective pile | Plain description | "a radiantly beautiful smile" → "she smiled" |
| Formal register | Plain speech | "He commenced" → "He started" |
| Explanatory description | Leave blank | "because he was scared..." → "He stepped back" |
| Parallel triad | Keep the strongest | 3 sentences → 1 |
| Summary/elevation sentence | Delete | "In that moment, she finally understood..." → delete |
| "It wasn't X, it was Y" | Write Y directly | "He wasn't cold. He was desperate." → show desperation |
| Redundant modifiers | Delete | "a white pill" → "pill"; "a racing car" → "car" |

**No synonym recycling**: the right column is direction, not a standard answer. When
a banned phrase hits multiple times in one chapter, give each spot a different
concretization; if one replacement keeps recurring (every reaction "shrugged", every
pause "a beat passed"), the fix itself becomes a new template fingerprint.

**Density findings first**: when `check-ai-patterns.js` reports `cliche-density-tic`,
the banned phrases are not stray misuse — they have coalesced into a template voice.
The order of operations is not synonym substitution: first cut the abstract
summaries, then land feelings and judgments on actions, objects, dialogue, and
concrete consequences the character can see right now.
