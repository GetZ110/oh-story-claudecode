---
paths:
  - "**/setting/**"
  - "**/outline/**"
  - "**/tracking/**"
---

# Story Consistency Rules

Consistency rules that apply when modifying setting, outline, or tracking files.

## Rules

1. **Setting changes must check tracking/**: whenever you modify any character setting or world rule, check the foreshadowing.md and timeline files under tracking/, so existing foreshadowing does not contradict the change.

2. **New characters must get their own file**: every major character should have an independent setting file, and relationships.md must be updated (if it exists).

3. **Timeline changes must be synced**: if the modification touches chronological order (when events happen), update timeline.md accordingly.

4. **Setting changes must be recorded in context.md**: any important setting decision must be recorded in the recent-decisions part of tracking/context.md.

5. **Consistency checks must use grep**: don't rely on memory — verify with searches. Common check commands:
   - Character attributes: `grep -rn "character name" setting/ prose/ | grep "attribute keyword"`
   - Timeline: `grep -rn "day [0-9]*\|[0-9]* days later\|after .* hours" prose/`
   - Power system: `grep -rn "system keyword" setting/ prose/`
   - Foreshadowing status: `grep -rn "Foreshadowing#" tracking/`

6. **Padding signals** (warning when present): a whole chapter of dialogue with no new information, the same emotion for 3+ consecutive sections, scene description over 500 words without advancing, a character reminiscing with no new angle, or 2 consecutive chapters without conflict.

## Examples

### Correct
```
After changing Shen Zhi's spirit-power rank to "sixth layer":
1. Check whether any foreshadowing in tracking/foreshadowing.md depends on the rank
2. Update tracking/context.md: [2024-05-05] Changed Shen Zhi's spirit-power rank to sixth layer
3. If a timeline file exists, check whether the chapter-45 time node still makes sense
```

### Wrong
```
Editing the spirit-power rank in setting/characters/shen-zhi.md directly, without checking any related files.
Result: the chapter-20 foreshadowing "Shen Zhi's spirit power is only at the third layer" now contradicts.
```
