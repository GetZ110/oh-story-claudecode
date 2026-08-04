# writing-workflow.md: Short-Story Writing Workflow Detail

This file contains story-short-write's detailed workflow guidance. SKILL.md keeps only the summary and trigger conditions.

---

## Phase 2 design tasks (execute after the framework is fixed)

### Load references before starting (check each item; no skipping)

- Fix genre voice/moves → load `genre-styles/{genre}.md` + `short-craft.md` ✅/❌
- Write antagonist/reveal method → load `villain-and-reveal.md` ✅/❌
- Write the outline → the genre pack's `genre-styles/{genre}.md` rhythm skeleton + (unusual directions) `genre-writing-formulas.md` quick tables ✅/❌
- Reversal information-gap validation → load `reversal-toolkit.md` ✅/❌
- Foreshadowing recheck → see "foreshadowing recheck list" below ✅/❌
- If an item doesn't apply (e.g., no antagonist), note the reason and skip it

### Design steps

1. **Design the through-line object** (optional, 1-2): see the genre pack's move library "through-line object meaning flip" (e.g., the estranged-spouse pack's keepsake flip)
   - Fill in: `- 1st appearance (section X): {scene} ({meaning})` — repeated three times with section locations
2. **Design the antagonist** (if any): use the villain-and-reveal.md antagonist template
   - Fill in: `{identity} + {motive} + {method} + {fatal flaw} + {comeuppance}`
3. **Decide the reveal method**: pick one of villain-and-reveal.md's 4 truth-reveal mechanics
4. **Write `section-outline.md`**: one line per section, format:
   `structure-beat/five-part function | main event | sub-events ×3-5 | emotion | character/relationship change | cause-effect/logic chain | new reader info | end carry/hook | foreshadowing/object | action-quiet | dialogue density | target words`
   - `structure-beat/five-part function` uses opening/setup/escalation/reversal/ending (or cause/development/turn/climax/ending), for light correspondence to the long-form content summary — do not apply the long-form full chapter blueprint
   - `character/relationship change` writes the before/after change; if no explicit change, write "no explicit change, but relationship pressure/misunderstanding/distance shifts to…" or `[to fill]`
   - `cause-effect/logic chain` writes `cause → action → result → consequence/new problem`, so sections don't become emotion piles
   - `end carry/hook` writes how this section connects to the next; the last section writes the ending landing
   - Sub-events must have explicit functions (advance plot / seed reversal / raise emotion); decorative sub-events forbidden
   - Fewer than 3 sub-events → use the expansion rules (add obstacles / side-character reactions / discoveries mid-move / short flashbacks / action escalation; see short-craft.md sections 10-11)
   - Sub-events connect with `->`; each contains a concrete plot-point description + function tag:
     `what concretely happens {function tag}` e.g. `found the extra charge on the bill{discovery}` / `flushed the ring{conflict}` / `he smiled{escalation}`
     Function tags: `dialogue` / `conflict` / `foreshadowing` / `memory` / `discovery` / `escalation`
     Plot-point descriptions must be specific to "who did what" — never just a tag like `dialogue` or `conflict`
   - Action-quiet marker: `action` or `quiet` or `both`; adjacent sections alternate when possible; if the genre needs consecutive same markers, ensure in-section emotion change (e.g., two "quiet" sections, but section 1 runs "confusion → ache" and section 2 runs "heartbreak → collapse" — the curve still rises)
   - Dialogue density: `high` (3+ rounds) / `medium` (1-2 rounds) / `zero` (no dialogue all section); avoid 2 consecutive `zero` sections; diary-reading and solo-discovery scenes may exempt, but consecutive zero-dialogue sections must push emotion through woven sensory details and body reactions
5. **Reversal information-gap validation** (must validate after the outline, before writing):
   - Answer: at which section does the reader learn the truth? Compute position % = `reveal section number ÷ total section count`
     - < 50% → delayed reveal; reversal invalid (reader knew too early; no shock later)
     - 50-60% → grey zone; review whether the reversal's force is enough (are the earlier misdirection clues sufficient?)
     - > 60% → position reasonable (reader waited long enough; impact maximized)
   - Check: at least 1 fake clue the reader was successfully misled by (not "reader guessed and waited for the character to catch up")
   - Check: ≥ 3 clues pointing to the truth planted before the reversal (hidden, not explicit)
   - Verify: have someone (or self-simulate) read only the outline — can they guess the truth before the reversal? Guessed = fail
6. **Foreshadowing recheck list** (check after the outline, before writing):
   - List every key element of the ending (objects/info/characters/relationship changes)
   - Does each ending element have ≥ 1 earlier setup? No = sky-fallen; must add setup
   - Through-line object's three appearances complete? (1st in the setup beat, 2nd in the reversal beat, 3rd in the ending beat)
   - Distance between setup section and reveal section ≥ 3 sections (too short = setup ineffective)

### Loads before writing (as needed, ≤ 3 at once)

- Required: `short-format.md` (body format) + `short-craft.md` (general base)
- Required: `short-deslop.md` (AI-flavor self-check while writing)
- One genre pack: `genre-styles/{genre}.md` (core packs) or `genre-writing-formulas.md` (unusual directions)
- As needed: `villain-and-reveal.md` / `emotional-methods.md`

### Working directory structure

Working directory structure per [Phase 2: Design the core framework](../SKILL.md#phase-2-design-the-core-framework). `setting.md` contents: core framework + characters + reversal setup + through-line object (with the three-appearance tracking table) + antagonist design + benchmark summary. `section-outline.md` one line per section, format per design task step 4 above.

### Operating principles

- Write the body directly to the file; don't just output it in the conversation.
- When polishing, read the file and rewrite; change records reflect directly in setting.md's through-line tracking.
- setting.md maintains the through-line tracking table:
  `| Object | 1st appearance (section/meaning) | 2nd appearance (section/meaning) | 3rd appearance (section/meaning) |`

---

## Phase 4 polish

### Polish checklist

```
## Polish list

### Opening
- [ ] Do the first 3 sentences grab?
- [ ] No meaningless background introduction?
- [ ] Contains an opening hook?

### Emotion
- [ ] Does the emotion curve have a clear direction?
- [ ] Is the emotion setup before the reversal enough?
- [ ] Is the impact after the reversal enough?

### Reversal
- [ ] Is the reversal unexpected?
- [ ] Is it reasonable (re-reading shows the setup)?
- [ ] Is the timing right?

### Rhythm
- [ ] Any dragging parts?
- [ ] Does every sentence earn its place?
- [ ] Word count in target range?

### Format
- [ ] Paragraphs short-based with long/short alternation and dense/sparse variation (not uniform)? No consecutive overlength blocks?
- [ ] Single newline between paragraphs?
- [ ] Dialogue on its own line; quote style matches the project/platform convention?
- [ ] Punctuation rhythm matches tone/voice: no whole-text period flattening, no random question/exclamation stacking, no `...`/`--` forced pauses?
- [ ] `...` / `——` / `—` / `--` in the body (including dialogue) converted to action/short sentences/commas/periods?
- [ ] No "he said/she said" tag chains?

### Hooks
- [ ] A hook every 2-3 sections?
- [ ] Section end has a hook (suspense or residue)?

### AI flavor
- [ ] No banned similes: "the gears of fate," "like a tide," "as gentle as a spring breeze," "heart dropping," "eyes welling up"
- [ ] Same body part/emotion description ≤ 5 times (count: hands/heart/knees/eyes; over-limit must replace)
- [ ] "like" usage: ≤ 10 total across the whole text (including "seemed like," "wasn't like")
- [ ] Full AI-flavor blacklist in short-deslop.md

### Technique
- [ ] Emotion externalization: does each direct emotion word land on a scene-specific action or object? No hollow emotion summaries ("a sliver of X surfaced")?
- [ ] Through-line object (if used): meaning flip complete? (check setting.md tracking table)
- [ ] Action and quiet: does each section have both?
- [ ] Opening density: ≥ 3 events in the first 100 words?

### Ending
- [ ] Does the ending leave residue?
- [ ] Would the reader want to share it?
```

### Deterministic punctuation cleanup

After polishing, run `node scripts/check-ai-patterns.js --check --fail-on=blocking prose.md` on the body first. Fix blocking hits in the body and re-scan; advisory hits are read-feel hints only — fix only genuine problems, mark functional writing `[needs review]`.
Then run `node scripts/normalize-punctuation.js prose.md` (default `--quote-mode keep`) to clean non-functional ellipses, em dashes, double hyphens, and standalone dividers.

### Deletion principles

1. Dialogue that doesn't advance the plot → delete
2. Description that doesn't seed the reversal → delete
3. Interiority that doesn't raise emotion → delete
4. What the reader can guess → shorten
5. Repeated-emotion expression → merge

---

## Common problems and solutions

| Problem | Cause | Solution |
|---------|-------|----------|
| Opening doesn't grab | Background setup | Start from the conflict |
| Middle drags | Information density too low | Cut or merge scenes |
| Reversal has no force | Setup insufficient or too obvious | Add misdirection clues |
| Ending is weak | Too long after the reversal | Wrap up within 500 words of the reversal |
| Whole piece flat | Emotion curve too even | Increase the emotion gaps |
| Reads like a diary log | Lack of emotion description | Add the character's inner feelings |
