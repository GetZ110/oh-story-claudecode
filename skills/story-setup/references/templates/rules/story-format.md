---
paths:
  - "**/prose/**"
---

# Story Format Rules

Format rules for prose files. Loaded automatically when the user edits prose files directly.

## Absolutely Forbidden

1. **No mechanical paragraphing or one giant block**: paragraphs break naturally on dramatic unit / shot / one thing ending; do not force-split by a fixed word count, and do not cram multiple actions, threads, or viewpoint shifts into one paragraph. Complete reasoning, oppressive atmosphere, and emotion-change chains may keep longer paragraphs.
2. **No blank lines between paragraphs**: adjacent paragraphs in prose allow exactly one newline `\n`; no blank lines or consecutive newlines `\n\n`.
3. **No "he said" / "she said" tags**: dialogue is introduced with action instead of dialogue tags.
4. **No long description piles**: description must interleave with action or dialogue; no more than 3 consecutive pure-description paragraphs.
5. **No viewpoint jumps**: once a viewpoint is fixed (first person / limited third person), do not switch into other characters' inner thoughts.
6. **No subject over-density**: within the same action chain, do not needlessly repeat the same protagonist name across consecutive sentences/paragraphs; name the subject at the start of a paragraph or when the subject resets, use pronouns/action continuity/legitimate ellipsis mid-paragraph, and re-name at key turns.

## Format Rules

- Dialogue stands on its own line, introduced by a colon or an action
- Paragraphs are units of dramatic structure, shots, emotions, or actions
- Chapter headings use `## Chapter X: Title` format; keep one blank line after the heading (Markdown rendering requires it)
- Adjacent paragraphs in prose allow exactly one newline `\n`; no blank lines or `\n\n`
- No `---`, horizontal rules, or extra blank lines between chapters

## Examples

### Correct — natural paragraphing by dramatic unit
```
Shen Zhi raises a hand; spirit power pours from her fingertips.
A crack appears in the barrier before her, fracture lines spreading like a web.
She clenches her jaw and pushes more power through, her whole arm beginning to tremble.
```
Each paragraph carries one action/information change; paragraphs advance naturally by dramatic unit, with only one `\n` between them.

### Wrong — multiple beats crammed into one paragraph
```
Shen Zhi raises a hand spirit power pours from her fingertips a crack appears in the barrier before her fracture lines spread like a web she clenches her jaw and pushes more power through her whole arm begins to tremble and finally the barrier shatters with fragments flying in all directions.
```
Mixing multiple actions, threads, and results in one paragraph leaves the reader no place to pause at key changes.

### Correct — dialogue introduced by action (no "he said")
```
Shen Zhi sets the teacup down on the table with a clink.
"What exactly are you trying to say?"
Lu Yan doesn't answer; he just looks out the window.
```
Dialogue is introduced through action and context, with no "he said" / "she said" tags.

### Wrong — using dialogue tags
```
Shen Zhi sets the teacup down on the table with a clink.
She said: "What exactly are you trying to say?"
Lu Yan doesn't answer; he sighs lightly and says, just looking out the window.
```
"Said" / "sighs and says" are forbidden dialogue tags — replace them with action.

### Correct — no extra blank line after the chapter heading
```
## Chapter 2: Undercurrents

When Lu Yan pushes open the door, three people are already seated inside.
Shen Zhi sits in the farthest corner, a scrap of paper pinched between her fingers.
```
Exactly one blank line between the `##` heading and the body (required for Markdown rendering); no blank lines between body paragraphs.

### Wrong — extra blank lines between paragraphs
```
## Chapter 2: Undercurrents


When Lu Yan pushes open the door, three people are already seated inside.


Shen Zhi sits in the farthest corner, a scrap of paper pinched between her fingers.
```
Extra blank lines between paragraphs (consecutive `\n\n`) break the tight pacing.
