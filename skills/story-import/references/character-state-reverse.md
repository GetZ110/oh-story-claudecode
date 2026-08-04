# Character-State Back-Derivation Rules (Long-Form Only)

> Scope: long-form import only. Short-form does not produce `tracking/character-state.md` (per `state-tracking.md`: "this section applies to long-form writing only; short-form usually doesn't need a standalone character-state tracking file").
>
> Generation-order constraint: the back-derivation described in this file depends on `tracking/foreshadowing.md` already existing (step 6 "pending foreshadowing" consults the foreshadowing status). The correct Phase 3-L order is: **generate `foreshadowing.md` and `timeline.md` first → then `character-state.md` (these rules) → finally `context.md`** (context.md's "character state: recent changes" field depends on this file).

---

## I. Input sources

Back-derive from the already-on-disk teardown artifacts; **do not re-read the `source/` directory**. The teardown artifacts are already structured distillations; re-reading the source is duplicate work and violates the "analyze first, then migrate" principle.

| Input file | Use |
|------------|-----|
| `teardown-lib/{Book Title}/characters/{Character Name}.md` | basic file (identity, ability, motive, appearance log, growth arc) |
| `teardown-lib/{Book Title}/characters/relationships.md` | key relationships' current/final states and evolution trajectories |
| `teardown-lib/{Book Title}/chapters/chapter_N_summary.md` | per-chapter plot points (chronological evidence of character-state changes) |
| `teardown-lib/{Book Title}/plot/*.md` | character arcs, faction/identity turns, storyline summaries |
| `tracking/foreshadowing.md` (already generated) | query the foreshadowing related to this character with status "planted" |

---

## II. Selecting the tracking targets

Reuse the `state-tracking.md` rule: **only track characters appearing ≥3 times or with an independent plot line**.

Cross-referencing the story-import character-tier table:

| Tier | In character-state.md? |
|------|------------------------|
| Protagonist | yes (full entry) |
| Antagonist | yes (full entry) |
| Core supporting | yes (full entry) |
| Functional | no (not tracked; appears in <20% of chapters and has limited function) |

Ambiguous boundaries default to the lower tier (not tracked).

---

## III. The back-derivation algorithm (one entry per major character, 6 steps)

For every character to track, execute in this order:

### Step 1 — current identity

From `characters/{Character Name}.md`'s appearance log or growth arc, take the **chronologically latest** (final-chapter) identity/profession description. If `teardown-report.md` has a later summarizing identity label, the report wins.

### Step 2 — current ability

Same approach: take the latest ability-level description in the character's appearance log. The ability system's background comes from `setting/worldview/` (power-system.md / background.md); ability details read from the character file.

### Step 3 — key relationships

From `relationships.md`, take the "current/final state" field of every relationship entry involving this character (A↔B format: relationship type | emotion | current state). Write the evolution-trajectory summary into the relationship description's parentheses ("changed in Chapter N").

### Step 4 — public image

Scan each chapter's `chapters/chapter_N_summary.md` plot points for the latest (chronologically) one whose type involves "outside assessment / reputation / identity exposure / social-status change". No matching plot point → fill `[TBD]`.

### Step 5 — pending foreshadowing

Query `tracking/foreshadowing.md` and filter for foreshadowing meeting both conditions:
1. The characters-involved field contains this character's name;
2. The status field is "planted" (not yet recovered).

List the foreshadowing titles (multiple → one per line). No related planted foreshadowing → fill "none".

> Note: this step depends on `tracking/foreshadowing.md` already existing. If the foreshadowing file isn't generated yet, finish `foreshadowing.md` first, then come back to this step.

### Step 6 — state-change log

Scan `characters/{Character Name}.md`'s appearance-log column, extract the chapters with clearly labeled state changes (identity/ability/relationship/image), convert each into a log line in chapter order:

```
Chapter {N}: {change description (one sentence, incl. the change type)}
```

**Over 10 entries, compress per these rules** (reusing `state-tracking.md` rules):
- Merge the earliest entries' summary into the corresponding field (e.g., "Current identity: Chapters 1-20, from student to singer");
- Delete the merged old log lines;
- Keep the most recent 10 detailed change records.

---

## IV. Output format

This section is the standard template for `character-state.md` (field-aligned with the same-named artifact in story-long-write); every field maps one-to-one — no added fields, no removed fields.

```markdown
# Character State Tracking

## {Character Name}
- **Current identity**: {latest identity/profession}
- **Current ability**: {latest ability level}
- **Key relationships**:
  - With {Character B}: {current relationship state} (changed in Chapter {N})
  - With {Character C}: {current relationship state}
- **Public image**: {how the outside world views this character}
- **Pending foreshadowing**: {unrecovered foreshadowing related to this character; "none" when absent}
- **State-change log**:
  - Chapter {N}: {change description}
```

Each tracked character gets its own `## {Character Name}` section, ordered protagonist → antagonist → core supporting.

---

## V. Partial-book handling

When the last chapter is a draft (half-written, visibly truncated):
- Character state reflects **the last complete chapter before the draft**; the draft's content is excluded.
- Note in the `>` quote block at the top of the file:

```
> Partial-book note: based on the Chapter N state; the draft Chapter N+1 content is not included.
```

"Whether the last chapter is complete" is explicitly confirmed in Phase 1's basic-info step; the verdict carries into this step.

---

## VI. Large works (>200 chapters) incremental import

When incremental import only imports the first N chapters, character state covers only the imported chapters; note it at the top of the file:

```
> Incremental note: based on the imported first N chapters; this file updates on later incremental imports.
```

---

## VII. Quality self-check

After `character-state.md` is generated, confirm against this checklist:

- [ ] Tracking targets are only protagonist/antagonist/core supporting; functional characters stayed out
- [ ] Every field maps one-to-one with this file's "output format" template; no missing fields
- [ ] Uncertain fields marked `[TBD]`
- [ ] "Pending foreshadowing" references actual entries in `tracking/foreshadowing.md` (or "none")
- [ ] Change logs over 10 entries compressed per the rules
- [ ] Partial books note their baseline chapter
