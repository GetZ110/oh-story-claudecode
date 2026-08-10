# Format & Structure

> Read before writing. The formats below are the repo's default prose delivery format; when the user or the target platform has explicit requirements, the user/platform requirement wins.
>
> **Scope**: paragraph formatting (dramatic-unit/shot priority, short paragraphs as the base texture, long paragraphs for complete reasoning, atmosphere, and emotion chains) and dialogue formatting apply to all formats. Beat structure and word-count standards apply only to short-form; long-form chapter word counts follow the current skill's word-count hard constraints.

---

## Chapter markers

Default formats (by flexibility):

| Format | Platform use | Example |
|------|----------|------|
| `###1.` | short-form default | `###1.` `###2.` `###3.` |
| `###Chapter 1` | some platforms | `###Chapter 1` `###Chapter 2` |
| `1.` (bare number) | Zhihu | `1.` `2.` `3.` (no `###` prefix) |

**Rule**: one format for the whole text, no mixing. Short-form prefers `###1.` or bare numbers — simple and efficient.

---

## Paragraph formatting

### Core rule: dramatic unit first

Default delivery layout is **breaking paragraphs by dramatic unit/shot, tightly packed**. Do not treat a fixed word count as a forced cutting knife; first judge whether "one thing / one reasoning chain / one emotion change" is complete.

- One paragraph carries one dramatic unit: an action chain, a clue discovery, a gaze shift, a round of judgment, or one continuous atmosphere/reasoning/emotion chain.
- Scene end, one thing finished, a new action, a new object, new information, or new dialogue starts a new paragraph; the happening, perception, and reaction of the same instant weave together — do not split into action layer / perception layer / reaction layer.
- Adjacent prose paragraphs allow **only one newline `\n`**; no blank lines or consecutive newlines `\n\n` (tight packing).
- No indentation (platform renderers handle it; no full-width spaces).
- Length is diagnostic only: break when it feels crowded, mixes multiple beats, or is hard to follow on a phone screen; longer paragraphs may stay when a complete reasoning chain, atmosphere build, or emotion progression is unfinished.

### Paragraph rhythm (long-short alternation + dense/light spread)

Short paragraphs read fast and are the base texture of phone reading; long paragraphs carry complete reasoning, atmosphere, and emotion settling. **Avoid uniform length throughout**, and avoid cutting every paragraph at the same word threshold:

- **Long-short alternation**: climaxes, comeuppance, and reversals compress to shortest (single-sentence paragraphs); reasoning chains, environmental pressure, emotion settling, and chapter closes may keep longer paragraphs so the reader finishes one complete change.
- **Dense/light spread (detail allocation)**: payoff/turn beats written dense (perception, action, detail filled in); transition/connection beats written light (1-2 sentences, not evenly weighted). Every beat the same length and same detail is exactly the AI voice.
- **No over-fragmentation**: if several consecutive ultra-short paragraphs still belong to the same shot / the same thing, merge them into a natural paragraph — avoid reading like an outline or poetry lines.

### Subject & character-name rhythm

Do not endlessly omit names, but do not name-drop every sentence either. Use by "subject reset":

- At paragraph heads, scene switches, multi-character scenes, or when the subject could confuse, use the protagonist name / character name to establish the POV.
- Inside the same paragraph or action chain, prefer mixing pronouns, action continuation, and reasonable omission — avoid starting every sentence with the same character name.
- At key turns, emotion bursts, identity contrasts, or when the reader needs to re-focus on the protagonist, re-name for emphasis.
- Review subject rhythm by "does it stumble when read aloud", not by a whole-chapter occurrence count; subject density is only a problem when consecutive sentences/paragraphs have no subject reset yet repeatedly name-drop.

---

## Dialogue formatting

### Dialogue markers

Choose per the target platform/user requirement; default format when unspecified:

| Priority | Format | Platforms |
|--------|------|----------|
| First choice | `“speech”` | English projects and platforms that render typographic quotes |
| Platform/project specified | `"speech"` or `「speech」` | Explicit platform/user requirement; `「」` is legacy Zhihu Yan compatibility |

**Default is curly `“ ”` for English projects**; use straight quotes or `「」` only when the book's contract or platform explicitly specifies them. Never treat a recorded legacy quote style as an error.

### Dialogue rules

1. Dialogue stands on its own line, not embedded inside narration paragraphs
2. Dialogue tags on demand: high-frequency or formulaic tags ("he said" / "she said" / "he said with a smile") are replaced by action description; plain "said" used at low frequency may stay (consistent with "avoid mechanical dialogue tags" in the absolute bans below)
3. In two-person exchanges, omit tags and let the content distinguish the speakers

**Correct example**:
```
She set the cup down.
"You should leave."
He didn't move.
"I said, you should leave."
```

**Also legal (plain "said" at low frequency)**:
```
She set the cup down.
"You should leave," she said.
He didn't move.
"I said, you should leave."
```

**Wrong example**:
```
She set the cup down and said: "You should leave." He didn't move, so she said again: "I said, you should leave."
```

---

## Punctuation tone spectrum

Punctuation serves tone, character voice, and emotion rhythm: it cannot be all periods, but cannot be randomly stacked symbols for "richness" either. First judge the sentence's function, then pick the punctuation:

| Tone / function | Punctuation strategy | Guardrail |
|---|---|---|
| Pressure / calm / restraint | short sentences, commas, periods; colons to land a judgment when needed | no artificial exclamation marks; restraint is not period-flattening every sentence |
| Accusation / testing / rhetorical | question marks + short follow-up fragments, with action pauses | avoid ending every line with `?` |
| Surprise / burst / comeuppance | 1 exclamation mark at the true burst; at most 1-2 in a continuous burst | no `!!!`, no whole-paragraph shouting |
| Hesitation / swallowing / unfinished | commas, periods, short-sentence breaks, action beats | no `……` to manufacture pauses; prefer actions and sentence-length change |
| Interrupted / dragged-out | no `——`; use action interruption, line breaks, short sentences, or unfinished actions | `——` / `—` / `--` banned in prose and dialogue |
| Info reveal / judgment landing | colons, semicolons, or single-sentence paragraphs to make the landing | keep phone-friendly; no essay-style semicolon chains |

Execution rules:
- When writing dialogue, first look at the characters' relationship and power positions: dominant characters often close with short sentences; testing characters use more question marks and half-sentences; only collapsing characters get a few exclamation marks/ellipses.
- When writing narration, use sentence length, comma pauses, and single-sentence paragraphs for rhythm; never treat dashes as a rhythm tool, and do not use them in dialogue either.
- At polish time check two problem classes: **whole-text period flattening** (tone pressed flat) and **random punctuation stacking** (question/exclamation marks carrying no emotional function, or ellipses/dashes forcing pauses).
- Quote style follows the project/platform convention; Zhihu Yan's `「」` is a legal dialogue format — do not silently change it under `quote-mode keep`.

---

## Beat structure

### Basic rules

- Split beats with numbers (`1` `2` `3`); each beat is a complete narrative beat
- 800-1500 words per beat (payoff fiction may compress to 500-800/beat, see genre-writing-formulas.md)
- 8-15 beats cover the whole piece (derive by target words; 8000÷1000≈8 beats, 12000÷800≈15 beats)
- Each beat advances one clear plot point

### Inside a beat

Each beat should have:

1. **One main event** + **3-5 sub-events** (the main event advances the core plot, sub-events add layers; when a first draft is short, return to the beat/chapter outline and fill in planned sub-events, dialogue, or conflict before writing prose; never add plot when de-AI-ing existing prose)
2. **One emotion change** (how the reader's feeling changes)
3. **One piece of new reader information**
4. **3-5 rounds of dialogue exchange** (revealing relationships / escalating conflict; see writing-craft.md dialogue power games. Specific scenes like solitary discovery or diary reading may mark zero, per the current skill's outline/design task requirements)
5. **Each sub-event weaves all three dimensions**: happening + perception + reaction woven into the same paragraph (see writing-craft.md scene writing)

### Between beats

- Leave a hook at the beat end (suspense / unresolved emotion / new question)
- The next beat opens fast, no re-setup
- Emotion progresses across beats: each beat's intensity ≥ the previous. Exception: after a peak emotion (reversal beat), one beat may hold without dropping, but no sudden drops

---

## Platform dialogue-format override table

| Platform | Chapter marker | Dialogue | Special requirements |
|------|----------|----------|----------|
| Zhihu Yan | `1.` | `「」` | lead-in marked separately |
| Webnovel | `###Chapter 1` | `""` | first paragraph needs pull |
| Redguo | `###1.` | `""` | none |

**General principle**: when the user does not specify a platform, default to the generic short-form format (`###1.` + `""`); when the user or platform specifies the Yan style, `「」` is allowed.

---

## Absolute bans

The following rules run through all writing; they do not change by genre or style:

1. **No mechanical word-count paragraph breaking**: do not force a break just because a word count is passed; first judge whether the paragraph is still one complete dramatic unit. Break when it mixes multiple actions/info/gaze shifts; complete reasoning, atmosphere, and emotion chains may keep longer paragraphs
2. **No blank lines between paragraphs**: adjacent prose paragraphs allow only one `\n`; no blank lines or `\n\n`
3. **Avoid mechanical dialogue tags**: high-frequency or formulaic "he said" / "she said" / "he said with a smile" are replaced by action/context; plain "said" may stay
4. **No indentation**: no full-width or half-width space indentation
5. **No Markdown rendering inside prose paragraphs**: apart from unified beat/chapter markers (like `###1.`), no bold `**`, italics `*`, headings `#`, or separators `---` inside prose paragraphs
6. **Functional dashes only**: prose may use a single em dash `—` for a real interruption, aside, or break; remove `--`, repeated pause padding, and em-dash clusters. Do not rewrite a legitimate English em dash merely to satisfy a detector.
7. **No whole-text period flattening or random punctuation stacking**: punctuation must match tone/character voice/emotional function; question marks for accusation, a few exclamation marks for bursts; hesitation, swallowing, unfinished speech expressed by action or sentence-length change, not `……` / `——` forced pauses, and no functionless `?`/`!` sprinkling
8. **No chapter meta-information in prose**: chapter numbers appear only in titles/beat markers/filenames/tracking records. Narration, dialogue, and interiority must not contain `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` or variants (last chapter / previous chapter / next chapter / earlier text / later text); rewrite into event anchors or relative time the character can perceive — e.g. "more painful than those three seconds of gunfire in chapter one" becomes "more painful than those three seconds of gunfire". Exceptions: a character genuinely reads/discusses "chapter X" text inside the story world, or is truly an author/reader talking about being a reader.

---

## Quick check

After every paragraph, self-check with this list:

- [ ] Paragraphs break by dramatic unit/shot, not mechanically by word count?
- [ ] Three-dimension woven paragraphs break by shot/information change, with complete reasoning/atmosphere/emotion chains kept continuous?
- [ ] Subject/name rhythm natural: paragraph head establishes the subject, mid-paragraph pronouns/omission, re-name at key turns, no unnecessary consecutive repetition?
- [ ] Adjacent prose paragraphs have only one `\n`, no blank lines / `\n\n`?
- [ ] Dialogue on its own lines, quote style per project/platform convention (Zhihu Yan `「」` legal)?
- [ ] Punctuation rhythm matches tone/voice, no whole-text period flattening, no random `?`/`!` stacking or repeated `……`/`——` pauses?
- [ ] Functional em dashes and ellipses are intentional, with no `--`, ellipsis runs, or em-dash clusters?
- [ ] Dialogue tags avoid high frequency/formula, plain "said" kept per context?
- [ ] No indentation?
- [ ] Every beat has event + emotion + information?
- [ ] Outside titles/beat markers, no `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` meta words; in-story reading/discussion of "chapter X" or genuine reader-identity contexts excepted?
