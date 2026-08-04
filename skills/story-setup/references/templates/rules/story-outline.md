---
paths:
  - "**/outline/**"
---

# Story Outline Rules

Rules for outline files.

## Rules

1. **Required volume-outline fields**: every volume outline (`volume_outline_*.md`) must include the following sections (field templates: see the volume-outline template and the "story unit card" field template in the story-long-write skill; contract/progression rules: see its reader-contract and progression references; legacy outlines with missing fields: see rule 8):
   - Core information (chapter range / target words / volume positioning)
   - Volume contract & endgame reserve (volume contract / main push line of this volume / wins of this volume / endgame milestones unlocked this volume / endgame trump cards off-limits this volume / contract risk)
   - Story unit card (10,000-30,000 words per unit is an adjustable rule-of-thumb; units live inside the volume outline, not in separate files; payoff pacing is managed by the story unit card — no fixed "one big payoff every N chapters" cycle; the per-chapter floor is tiered by platform/genre: fast-paced platforms keep the floor "each chapter needs visible event or payoff advancement")
   - Core conflict (one sentence: what problem this volume solves or what goal it reaches)
   - Emotional arc (the volume's overall emotional trajectory)
   - Character arc (major characters' growth/change in this volume)
   - Foreshadowing this volume (foreshadowing planted in this volume and its planned recovery time)
   - Reversals this volume (if any: type / characters involved / misdirection path / reveal chapter)

2. **Required chapter-outline fields**: every chapter outline (`outline_chapter_*.md`) must contain the current "chapter blueprint":
   - Stage position: the volume/stage it sits in, the stage goal, this chapter's advancement and what it picks up from / hands to
   - Chapter structure formula: the emotion-and-conflict formula this chapter uses
   - Forbidden early release: truths, trump cards, relationship conclusions, or endgame contradictions this chapter must not unveil early
   - Base execution fields: core event, target words, target emotion, unit ID/position, protagonist goal/key choice, opening hook, payoff, chapter-end hook, contract risk (filled after re-verifying against outline safety checks ⑥ and ⑦ per chapter)
   - Content summary (five-part): cause / development / turn / climax / ending — the ending writes the concrete action or image the chapter lands on, not a state verdict
   - Plot arrangement (multi-line): main line progress / sub-line progress / event & task line / relationship line / logic line
   - Characters and appearance order: list characters/factions/key objects in actual appearance order, and note relationship changes
   - Plot detail: the plot-point sequence written as "who did what + function tag", with action cost (optional) / benefit recipient marked — action cost may be None; do not manufacture a price; when a legacy outline only has cost delivery / benefit delivery, fall back to those fields for the check and do not block
   - Ending and hook: closing state (written as a concrete landing action or image), open problems, next chapter's driving force, chapter-end hook

3. **Incremental writing**: outlines must be written incrementally — skeleton first (key events and payoffs), then fill in details section by section. Do not write all details in one pass.

4. **Sync with prose**: after finishing a chapter of prose, go back and update the "actual completion" part of the chapter outline.

5. **Opening hooks must be chosen from these types** (full techniques: `story-setup/references/agent-references/hooks-chapter.md`):
   suspenseful-dialogue opener | flash-forward fragment | countdown opener | mysterious monologue | contrast scene | unfinished-action opener | image portent

6. **Chapter-end hooks must be chosen from these types** (full techniques: `story-setup/references/agent-references/hooks-chapter.md`):
   sudden reveal | urgent crisis | unfinished action | identity reversal | dilemma | mysterious object/clue | countdown | promise/threat | eerie disappearance | hidden meaning | image hook | echo hook | blank-space hook

7. **Every chapter needs emotional change**: the chapter outline must mark emotion start → end (e.g. "calm → shocked → furious"); 2 consecutive chapters without emotional change = needs adjustment.

8. **Missing-field handling**: a legacy chapter outline missing blueprint fields does not block continuation — fall back to the old fields (core event, plot-point sequence, target emotion, opening/end hooks, target words), infer in memory for this round, and only write back when the outline is explicitly backfilled/revised. Newly created, backfilled, or revised chapter outlines must be completed to the current chapter-blueprint template before entering prose. Legacy volume outlines likewise do not block — when parts of rule 1's sections are missing (e.g. only volume goal / payoff pacing) or old field names are used (e.g. Loop ID), read them back per field structure; only upgrade to the current structure when the user explicitly backfills/revises. Volume outlines locked for already-written ranges are not auto-rewritten. Sub-lines, relationship changes, or cost/benefit that cannot be confirmed from the material go as `[TBD]` — never invented.

## Examples

### Correct — a complete volume outline
```
# Volume Outline: Volume 1
## Core Information
- Chapter range: Chapters 1-30
- Target words: 90,000
- Volume positioning: setup
## Volume Contract & Endgame Reserve
- Volume contract: Shen Zhi's come-from-behind gratification, from being crushed to joining the Shadow Guard; promise debt: the mystery of her origins
- Main push line: strength line (spirit power third layer → fifth layer)
- Wins this volume: identity line (a formal Shadow Guard post), relationship line (building trust with the master)
- Endgame milestones unlocked: reaching the Shadow Guard system
- Endgame trump cards off-limits: the master's true identity, the intact ancient mirror
- Contract risk: safe
## Story Unit Card
### Story Unit L1-1
- Unit ID: L1-1
- Chapter range: Chapters 1-12
- (remaining fields per the "story unit card" field template in the story-long-write skill)
## Core Conflict
Shen Zhi must earn entry into the Shadow Guard before the clan purge.
## Emotional Arc
oppression → rock bottom → awakening → eruption → lingering resonance
## Character Arc
Shen Zhi: from silent endurance to active counterattack
## Foreshadowing This Volume
- Foreshadowing#3: ancient-mirror shard (planted chapter 8, recovered volume 2)
- Foreshadowing#7: the master's true identity (planted chapter 12, recovered volume 3)
## Reversals This Volume
Chapter 18: the Shadow Guard captain turns out to be Shen Zhi's long-lost brother (identity reversal; misdirection path: the captain repeatedly targets Shen Zhi)
```
All required fields present, endgame trump cards clearly bounded, foreshadowing with clear recovery plans.

### Wrong — a volume outline missing required fields
```
# Volume Outline: Volume 1
## Volume Goal
Shen Zhi joins the Shadow Guard.
## Payoff Pacing
One big payoff every 5 chapters.
```
Missing the required volume contract & endgame reserve, story unit card, etc.; payoff pacing is managed by the story unit card — no fixed "one big payoff every N chapters" cycle; for fast-paced platforms only the per-chapter floor "each chapter needs visible event or payoff advancement" remains. Legacy volume outlines in existing projects that look like this are read back per rule 8 — not blocked, not auto-rewritten.
