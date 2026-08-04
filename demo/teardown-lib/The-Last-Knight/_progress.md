# Deconstruction Progress: The Last Knight

- Book: The Last Knight (first 5 chapters excerpt) | Total chapters: 5 | Output directory: demo/teardown-lib/The-Last-Knight/ | Started: 2026-08-04
- Final status: completed
- schema_version: 2

## Pipeline Progress

| Stage | Status | Progress | Notes |
|-------|--------|----------|-------|
| Stage 0 Overview extraction | Done | 5/5 chapters identified | Source backed up to source/source.txt; overview.md (first pass) + chapter index + chapter boundary table written |
| Stage 1 Golden three chapters | Done | 3/3 chapters | chapter_1/2/3_deep-dive.md produced; stop-point snapshot quick-preview.md written (human-shaped antagonist, routine payoff routing) |
| Stage 2 Per-chapter summaries | Done | 5/5 chapters | chapter_1-5_summary.md produced; count verification passed (5 summaries == 5 chapters); 68 plot points; tone/theme tags and type enums compliant |
| Stage 3 Aggregated analysis | Done | 3 plotlines | Story framework (progression with moral hardening) + 3 plotlines + 1 storyline + scattered threads; coverage 100% |
| Stage 4 Setting + characters | Done | 3 characters | Worldview (background/geography/cheat) + faction (the-iron-coven.md); kael.md + maren.md + relationships.md |
| Stage 5 Summary report | Done | - | teardown-report.md produced (writing techniques include cross-chapter callbacks); overview.md backfilled as plot-aware version |
| Stage 6 Style | Done | - | style.md produced (deterministic sentence-length stats + 4 source anchors) |

## Chapter Boundaries (Stage 0 output, single source of truth)

| Chapter | Title | Start line | Words |
|---------|-------|-----------|-------|
| 1 | The Last Prisoner | 1 | 1520 |
| 2 | The Long March | 121 | 1380 |
| 3 | The Archive Thief | 232 | 1120 |
| 4 | Oaths and Ash | 301 | 1090 |
| 5 | The Salt Road | 379 | 1090 |

## Chunking Progress

| Chunk | Chapters | Status |
|-------|----------|--------|
| Whole book | Chapters 1-5 (5 chapters < 50, processed by stage in one pass) | Done |

## Failure Log

| Type | Chapter/Stage | Error | Retry status |
|------|---------------|-------|--------------|
| - | - | All 5 chapters + all 6 stages eventually succeeded | - |

## Quality Checks

| Check | Stage | Result | Correction |
|-------|-------|--------|------------|
| Chapter structure recognition | Stage 0 | Passed (5/5 chapters identified, boundary table written) | - |
| Summary count verification | Stage 2 | Passed (5 summaries == 5 chapters) | - |
| Enum compliance | Stage 2 | Passed (68 plot points; tone/theme tags and type enums all inside the enums) | - |
| Coverage | Stage 3 | 100% (3 plotlines cover 5/5 chapters, 0 scattered threads) | Slightly above the 85-95% band; sample is small and single-threaded, re-checked for over-merging |
| Confidence | Stage 3 | 0.96 (most plot points at 1.0, a few knowledge/exposition beats at 0.85-0.95) | - |
| Overlap rate | Stage 3 | 0% (plotlines split cleanly by chapter, no shared chapters) | - |
| Character merging | Stage 4 | No conflicts (descriptor/title class names did not trigger merges) | - |

## Character Merging

| Before merge | After merge | Basis | Confirmed |
|--------------|-------------|-------|-----------|
| Kael / Kael of the Dawnward Order | Kael | proper_name points to the same person | Confirmed |
| Roran / old soldier Roran | Roran | proper_name points to the same person | Confirmed |

## Breakpoint

- Last processed: chapter 5 | Current stage: Stage 6 complete | Next action: none (full pipeline Stages 0-6 done)
- Note: this pass ran in one-shot mode (demo rebuild). The Stage 1 stop point was handled per the skill's skip-questions rule: after writing quick-preview.md the pipeline continued to Stage 6 without pausing. Final status: completed.
