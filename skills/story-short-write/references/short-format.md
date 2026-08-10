# Short-Story Body Format

> Required reading before writing the body. This file only governs delivery formatting: section markers, paragraph shape, dialogue, punctuation, and the meta-information ban.
> Writing method (emotion externalization, hook density, reversals, endings) lives in `short-craft.md` and the genre packs; it is not repeated here.
> This is this repo's default delivery format; when the user or the target platform has explicit requirements, the user/platform requirement wins.

---

## Section markers

Pick one style for the whole text; never mix.

| Format | Platforms | Example |
|--------|-----------|---------|
| `###1.` | Short-story default | `###1.` `###2.` `###3.` |
| `###Part N` / `###Chapter N` | Wattpad / Galatea serials, longer episodes | `###Part 1` `###Chapter 2` |
| `1.` (bare number, no `###`) | Tapas episodes, minimalist shorts | `1.` `2.` `3.` |

Short stories default to `###1.` or bare numbers. Episode serializations with longer chapters use `###Part N`.

---

## Paragraphs: two platform templates

Short-story body shape splits by platform. **No universal hard line like "every paragraph ≤ 3 sentences" or "800-1500 words per section"** — that's a long-form transplant that slices shorts into equal-length outlines. First fix the platform's base color, then allocate words per `short-craft.md`'s dense/sparse principle.

### One-line-per-paragraph, white space for fast reads (Tapas / Wattpad short episodes / Radish one-shots)

- One sentence per paragraph as the base, heavy line breaks for drop and pause.
- Fast rhythm, small section mass, every section end carries a hook.
- Single-sentence paragraphs are the norm — don't weld sentences back into long blocks just to "hit a word count."

Template:

```
###1.

The house came with three rules, taped to the pantry door in my great-aunt's handwriting.

One lamp burns all night. Never answer the third knock. If you hear the rocking chair, the house is already gone.

I kept the rules for six days.

My sister visited on the seventh.
```

### Short paragraphs as base, narration interwoven with dialogue (Wattpad serials / Inkitt / Galatea / Dreame / GoodNovel)

- Short paragraphs remain the mobile-reading base, but **multi-sentence retrospective narration and dialogue interweaving are allowed**: one paragraph may carry interiority, a memory strike, an action, then dialogue.
- Romance and emotional genres may write longer narration paragraphs carrying complete emotion chains and scene setup.
- Payoffs, comebacks, and reversals compress short (may be single-sentence paragraphs); transitions and information deliveries pass in one line.

Template:

```
###Part 1

I set the hot soup in front of him while he scrolled his phone, the screen glowing with her name. Three years of this, and I'd told myself the hard years were over. The hard years were me.

"You don't have to do this anymore," he said, without looking up. "She doesn't like the smell of cooking oil."

My hand paused on the bowl's edge.
```

### Shared hard constraints (all platforms)

- Adjacent body paragraphs are separated by **exactly one newline `\n`**; no blank lines / `\n\n` runs (tightly packed). Section markers count separately.
- **No indentation**: no full-width or half-width space indents; platform renderers handle it.
- **No Markdown in body paragraphs**: outside the unified section/chapter markers (like `###1.`), no bold `**`, italics `*`, headings `#`, or divider lines `---` in body text.
- Long and short alternate; never uniform lengths. Cutting every paragraph to the same word count is a source of AI-flavor.

---

## Dialogue

### Quotes

| Priority | Format | Applies to |
|----------|--------|------------|
| First choice | `“speech”` curly double quotes | Short-story default, Wattpad, Tapas, Inkitt, Galatea, Dreame, GoodNovel |
| Platform/project-specified | Straight `"speech"` | Platforms rendering straight quotes; user preference |

**Default is curly `“ ”`**; use straight quotes only when the platform or user specifies them. Do not "correct" a user's specified quote style.

### Rules

1. Dialogue stands **on its own line**, not embedded inside a narration paragraph.
2. Replace dialogue tags with action beats: instead of "he said," "she laughed and said," use an action beat + the line; a plain "said" may stay where the context needs it.
3. In two-person exchanges, drop the tags; the content identifies the speaker.

Correct:

```
She set the cup down.
"You should go."
He didn't move.
"I said, you should go."
```

Wrong:

```
She set the cup down and said, "You should go." He didn't move, so she said again, "I said, you should go."
```

---

## Punctuation hard constraints

**Functional English punctuation is allowed**: a single ellipsis (`…`) or em dash (`—`) may carry hesitation, interruption, or an intentional break. Do not use repeated pause padding, `--`, long em-dash clusters, or ellipsis runs. The detector reports clusters as a style warning rather than banning a legitimate English construction.

Pauses, sobs, unfinished speech, interruptions, and white space are done with:

- Short sentences, periods, commas.
- Action beats ("She paused." "His grip tightened.").
- Line breaks / single-sentence paragraphs.

Everything else follows tone:

| Tone / function | Punctuation | Guardrail |
|---|---|---|
| Pressure / calm / restraint | Short sentences, commas, periods; a colon to land a judgment when needed | Don't hand-add exclamation marks; don't period-flatten the whole text either |
| Challenge / rhetorical question | Question marks + short follow-ups | Don't end every sentence with `?` |
| Burst / comeuppance | 1 exclamation mark at the true peak; 1-2 max in a row | No `!!!`; no whole-paragraph shouting |
| Info reveal / judgment landing | Colon, single-sentence paragraph | No essay-style semicolon chains |

If a genre pack's example retains `...` for illustration, re-write it per this rule when it lands in the body.

---

## No meta-information in the body

Chapter numbers and writing-engineering words may appear only in titles / section markers / file names / tracking records. The body's narration, dialogue, and interiority must not contain:

```
Chapter N | last chapter | previous chapter | this chapter | earlier | later | foreshadowing | outline | reader | first half | second half | Part N
```

Use event anchors or relative time the character can perceive instead. Example: "it hurt worse than the three seconds of gunfire in chapter one" becomes "it hurt worse than those three seconds of gunfire."

Exception: a character genuinely reading or discussing a "chapter" inside the story world, or a character who really is an author/reader talking about reader identity, may keep it.

---

## Platform override table

| Platform | Section marker | Dialogue | Paragraph base | Special |
|-----------|----------------|----------|----------------|---------|
| Wattpad | `###Part N` or `###1.` | `" "` curly | Short paragraphs + narration interleave | Blurb must be a storefront; episodes 1500-3000 words |
| Tapas | `1.` bare numbers | `" "` | One-line paragraphs, fast | Episode ends must hook |
| Inkitt | `###1.` or `###Chapter N` | `" "` | Short base; multi-POV allowed | Varies by subgenre; check the genre pack |
| Radish | `###1.` | `" "` | Short base, app-first drama | Episodes 1500-3000 words; chapter-end cut points |
| Galatea | `###Chapter N` | `" "` | Short base | App-first pacing; strong chapter-end hooks |
| Dreame / GoodNovel | `###1.` | `" "` | Short base | One-shot + serialized both; high hook density |
| Kindle short reads / anthologies | `###1.` or `1.` | `" "` | Short base | Whole-story shape; no episode breaks |

When the user doesn't specify a platform, default to the general short-story format: `###1.` + curly quotes + the short-paragraph base.

---

## Quick check after each batch

- [ ] Paragraph shape matches the target platform's template (one-line style / short-paragraph-interweave)? Not sliced into equal-length outline chunks?
- [ ] Exactly one `\n` between adjacent paragraphs; no blank lines / `\n\n`?
- [ ] No indentation (no full-width spaces or space indents)?
- [ ] No Markdown (`**` `*` `#` `---`) in body paragraphs outside titles/section markers?
- [ ] Dialogue on its own line; quote style matches the platform (curly by default); tags not mechanical?
- [ ] No `...` / `——` / `—` / `--` in the body (including dialogue); pauses done with short sentences / action beats / line breaks?
- [ ] Punctuation follows tone: no whole-text period flattening, no random `?` / `!` scattering?
- [ ] No meta words in the body (`Chapter N` / `last chapter` / `earlier` / `foreshadowing` / `reader` etc.) except in genuine in-world reading contexts?
