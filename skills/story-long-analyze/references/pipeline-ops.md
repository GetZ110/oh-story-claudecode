# Pipeline Operations Reference

The operations manual for the story-long-analyze teardown pipeline: `_progress.md` template, error handling, resume procedure.

> Quality thresholds (confidence / coverage / overlap) live in the quality-threshold system of [material-decomposition.md](material-decomposition.md).

---

## `_progress.md` template

```markdown
# Deep-teardown progress: {Book Title}
- Novel: {title} | Total chapters: {N} | Output directory: {path} | Started: {date}
- Final status: {pending/paused_after_stage1/completed/completed_with_errors}
- schema_version: 2
## Pipeline progress
| Stage | Status | Progress | Notes |
|-------|--------|----------|-------|
## Chapter boundary (produced by the Stage 0 chapter-boundary substep; single source of truth)
| Chapter | Title | Start line | Word count |
|---------|-------|------------|------------|
## Chunk progress
| Chunk | Chapters | Status |
## Failure log
| Type | Chapter/stage | Error message | Retry status |
|------|---------------|---------------|--------------|
## Quality checks
| Check item | Stage | Result | Fix |
## Character merge
| Before merge | After merge | Basis | Confirmed |
## Breakpoint
- Last processed: Chapter {N} | Current stage | Next operation
```

**schema_version notes**:

| Version | Meaning |
|---------|---------|
| 2 | Current contract: includes the chapter boundary table (produced by the Stage 0 chapter-boundary substep). Stages 1/2/6 all use this table as their slicing truth; no stage runs its own regex slicing anymore |

Do not resume without `schema_version: 2` and the chapter boundary table; rebuild `_progress.md` from the Stage 0 chapter-boundary substep before resuming.

**Final status values**:

| Value | Meaning |
|-------|---------|
| `pending` | Pipeline in progress, not finished yet |
| `paused_after_stage1` | Paused at the Stage 1 stop point — Stage 0/1 done, `quick-preview.md` produced, waiting for the user's decision on whether to continue Stage 2-6. On resume, skip Stage 0/1 and start from Stage 2 |
| `completed` | Full pipeline Stage 0-6 done |
| `completed_with_errors` | Full pipeline done, but with per-chapter/per-stage failures (see the Failure log table; noted in the teardown report) |

---

## Story-unit list backfill (existing books)

Trigger: the user says "backfill the story-unit list", or a writing-side search finds `plot/README.md` without a "Story-unit list" table.

Action: read the existing `teardown-lib/{Book Title}/plot/*.md` (or `benchmark/{Book Title}/plot/*.md`) story-unit headers — the Title / Type / Trope tags / Chapter range fields — and mechanically rebuild the list table in `plot/README.md` per the "Story-unit list" table template in output-templates.md; sync a copy when the project `benchmark/{Book Title}/` view exists. Do not read the source, do not re-run any stage, do not change story-unit content, do not touch `plot/pacing.md` / `plot/emotional-beats.md`. When an old story unit's chapter-range row has no word-count info, write only "N chapters total" in the size column and "unknown" for the word count — never invent it.

Writing-side consumers automatically fall back to per-file search for books without the list (see story-long-write's outline-structure-theory.md "Benchmark rhythm migration" step 1); the backfill only speeds things up, it's not a blocker.

## Error handling

| Scenario | Handling |
|----------|----------|
| Chapter recognition fails | Ask to confirm the format; custom regex supported |
| Chunking interrupted | Resume from the breakpoint in `_progress.md` |
| Aggregation quality below threshold | Re-classify orphan plot points; relax threshold to 0.5 |
| Character-merge conflict | Record in a pending-confirmation list |
| Output-directory conflict | Append instead of overwrite; mark conflicts `[re-analyze]` |

---

## Resume procedure

1. On pipeline start, check whether `_progress.md` already exists in the output directory
2. Validate `schema_version: 2` and the chapter boundary table; if either is missing, stop and tell the user to rebuild the progress file from the Stage 0 chapter-boundary substep
3. Read the breakpoint info (last processed chapter + current stage + final status)
4. **Breakpoint status `paused_after_stage1`** (Stage 1 stop point) → skip Stage 0/1 and resume straight from Stage 2 per-chapter summaries; don't re-run the finished overview and opening hook chapters
5. Other breakpoint statuses → resume from the first chapter of the chunk containing the breakpoint, overwriting that chunk's existing outputs
