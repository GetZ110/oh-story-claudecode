# workflow-revision.md: Major Revision Workflow

This file is the complete guide for the "major revision / rework" scenario. After SKILL.md routes here, execute the flow below.

---

## Applicability

- The user says "revise chapter X" / "rework chapter X" / "rewrite chapter X"
- Goal: modify the content of already-written chapters

> The user must specify a chapter number or title. Which chapter needs revision cannot be inferred automatically.

---

## Step 1: Locate the chapter

1. Find the file by chapter number: `prose/chapter_{X}_*.md`
2. If the user gives a title rather than a number, search with `find prose/ -name "*{keyword}*"`
3. If not found, ask the user to confirm the exact chapter
4. If the user specifies a passage range ("paragraphs 3-5" / "that fight" / "the dialogue part"), record it as a partial-revision target

---

## Step 2: Load context

Load more context than for daily writing (revision needs to understand what comes before and after):

| # | File | Use | If missing |
|------|------|------|-----------|
| 1 | `prose/chapter_{X}_*.md` | the chapter to revise | must exist |
| 2 | `outline/outline_chapter_{X}.md` | original writing plan | skip |
| 3 | `prose/chapter_{X-1}_*.md` | previous chapter (continuity) | for chapter 1, load `setting/worldview/background.md` instead |
| 4 | `prose/chapter_{X+1}_*.md` | next chapter (continuity) | for the last chapter, check `outline/outline_chapter_{X+1}.md` (if any) to ensure continuity |
| 5 | `tracking/foreshadowing.md` | involved foreshadowing | skip |
| 6 | `setting/characters/{relevant}.md` | this chapter's characters | skip |

**Relevant-character determination**: extract character names from `outline/outline_chapter_{X}.md`. If the outline does not exist, search the chapter's prose for character-name keywords present under `setting/characters/`. Map names to filenames: `setting/characters/{Name}.md`.

---

## Step 3: Revise

1. **Read the original**: read the full chapter, record the original word count
2. **Back up the original**: copy the original to `prose/chapter_{X}_{Title}_original_{YYYYMMDD}.md` so it can be rolled back
3. **Confirm the revision scope**: ask whether it is a "full rewrite" or "revise specific passages"
   - Full rewrite: rewrite from the outline, keep the backup
   - Partial revision: only change the specified passages (locate by scene number or keywords), leave everything else untouched
4. **Execute the revision**: rewrite the file
4. **Word-count comparison**: if the post-revision word count differs from the original by >30% or >800 words (whichever is larger), alert the user

**Research (on demand)**: if the revision involves external facts needing verification (historical dates, geography, professional details, etc.), spawn the `story-researcher` agent to search and verify.

---

## Step 4: Cascade check

After the revision, check one by one whether later chapters are affected:

1. **Foreshadowing check**: compare the foreshadowing list before/after (old snapshot vs new content), mark changes:
   - New foreshadowing → add to `tracking/foreshadowing.md`
   - Removed foreshadowing → remove from `tracking/foreshadowing.md` and check whether later chapters reference it
   - Modified foreshadowing → update the description, check later references stay consistent
2. **Timeline check**: compare the event order before/after, update `tracking/timeline.md`
3. **Downstream impact**: if the revision changed character states/relationships/worldview setting, scan later chapters' prose and mark affected items:

```
⚠️ After revising chapter {X}, the following chapters may need sync adjustments:
- Chapter {X+1}: {reason} (suggested check)
- Chapter {X+3}: {reason} (suggested check)
```

4. **Prose meta-information scan**: check outside the title line for `chapter outline|plot point|story unit|target words|this chapter|the reader|foreshadowing` and variants; rewrite hits into event anchors or relative time the character can perceive; in-story reading/discussion of "chapter X" or genuine reader-identity contexts excepted
5. **Banned-word scan**: per `references/banned-words.md`, scan the revised content

---

## Step 5: Quality check

Run the Phase 5 quality check on the revised chapter (at minimum):

1. **Banned-word scan**: if Step 4 did not cover the whole chapter, scan again
2. **Prose meta-information scan**: same as the "prose meta-information scan" in the cascade check; confirm full-chapter coverage
3. **Character consistency**: does the revised character behavior match the character setting
4. **Rhythm check**: did the revision break the chapter's rhythm

> Full checklist in [Phase 5: Quality check](../SKILL.md#phase-5-quality-check).

---

## Common issues

| Issue | Handling |
|------|------|
| User did not say what to change | ask "which chapter do you want to change, and what aspect? Plot / rhythm / dialogue / description?" |
| Word count exploded or collapsed after revision | alert the user; the user decides whether to adjust |
| Revising multiple chapters in a row | revise chapter by chapter, each chapter independently runs Steps 2-5 |
| Inconsistencies found after revising | list the affected chapters; the user decides whether to fix now |
