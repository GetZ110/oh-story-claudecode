---
paths:
  - "**/teardown-lib/**"
  - "**/benchmark/**"
  - "**/setting/**"
---

# Story Narrative Rules

Narrative rules for teardown, benchmark analysis, and setting files.

## Rules

1. **Cross-check settings**: when adding or modifying a setting, cross-check it against existing settings for contradictions. Method: grep keywords in existing setting files to confirm there is no conflict.

2. **Consistent speech style**: character dialogue must match the speech-style profile in the character's setting (tone, word habits, exclamation frequency, etc.).

3. **Explicit worldview rules**: what is "possible" and "impossible" under the power system and social rules must be clearly recorded in the setting files and consistently honored in the prose.

4. **Every suspense needs a documented "real answer"**: every suspense/mystery you set must have a clear, unambiguous real-answer record in a tracking/ or setting/ file — no vagueness.

5. **Self-consistent motives and relationships**: a character's behavior must fit the motives in their setting, and relationship changes must have reasonable triggering events.

6. **No AI flavor** (red-line constraint):
   - No chapter-end summaries / uplift / philosophical closings ("he finally understood……", "no one would sleep tonight")
   - No "he felt/thought" direct emotion statements — use physical reactions instead ("his palms were sweating" > "he was nervous")
   - No more than 2 consecutive pure-psychology paragraphs; interleave action/dialogue
   - No universal/stacked metaphors ("like a tide", "like lightning"); a single functional, grounded, character-voiced metaphor may stay
   - No uniform dialogue for all characters — every character must fit the 7-dimension speech-style profile (verbal tics / rhythm / information preference / stance / identity diction / personality tone / relationship-stage attitude)

7. **The three-function dialogue test**: after deleting any dialogue passage, check — can the plot still advance? Is the anticipation still there? Is the emotion still delivered? All three failing = padding; delete it.

## Examples

### Correct — settings cross-checked
```
New setting: spirit-power ranks are divided into nine layers, the ninth and highest being "Rank Break".
Actions taken:
1. grep all files under setting/ to confirm no other spirit-power system description exists
2. grep "spirit power" in tracking/foreshadowing.md to confirm no contradicting foreshadowing
3. Update tracking/context.md: [2024-05-05] Added the nine-layer spirit-power system
```
Searching existing settings and foreshadowing before adding a new setting avoids contradictions.

### Wrong — setting added without cross-check
```
Adding "spirit-power ranks are divided into ten layers" straight into setting/world-rules.md.
Result: an existing setting file records "spirit power caps at nine layers" — the two contradict.
And a foreshadowing in tracking/foreshadowing.md depends on the "nine layers" setting.
```
Adding new content without checking existing settings creates worldview contradictions.

### Correct — suspense with a documented real answer
```
Chapter 15 prose: the ancient mirror in the secret chamber reflects the face of a stranger.
tracking/foreshadowing.md records: Foreshadowing#12 (chapter 15 ancient-mirror stranger) → real answer: a residual projection of Shen Zhi's past-life memories; recovery chapter: 38.
```
Every suspense has a clear real answer and a planned recovery time in the tracking files.

### Wrong — suspense without documentation
```
Chapter 15 prose: the ancient mirror in the secret chamber reflects the face of a stranger.
Nothing recorded in tracking/foreshadowing.md.
By chapter 40 the later prose forgets this suspense — or gives an explanation that contradicts the existing tracking records.
```
Undocumented suspense is easily forgotten or made self-contradictory.
