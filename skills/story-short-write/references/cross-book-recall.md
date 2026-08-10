---
name: cross-book-recall
description: Multi-benchmark cross-book recall
---

# Cross-Book Recall

## Trigger

Benchmark discovery must exclude the current imported work, current project prose, and the current work's own teardown; only external books can be benchmark candidates.
Enabled when the project root `teardown-lib/` or the project `benchmark/` has ≥2 books. The primary benchmark book comes from the `Primary benchmark book` field in `setting/genre-positioning.md` (inside the "Benchmark registry" or import-generated "Benchmark book list" section; field name identical); if missing, use the lexicographically first book (over `benchmark/`; over `teardown-lib/` if no `benchmark/`) and prompt the user to fill it via `gaps.main_benchmark_unspecified: true` / in the import report.

> **Quantity rules**: at most 1 primary benchmark book, used for style and final prose input; secondary / reference benchmarks have **no registration limit**. During execution, recall per book by genre relevance, citation strength, and stage budget; when over budget, trim items — never delete book registrations.

## Three defense lines
1. Secondary benchmarks' `style.md` is never read, avoiding cross-book style pollution
2. character/plot/setting modules may be recalled from all secondary benchmarks, but must be sorted by "same genre > weakly related > reference" and bounded by per-book/total budgets
3. The narrative-writer prose prompt only receives the primary benchmark's style/source anchors + budget-filtered `secondary benchmark recall summary`; it never reads or receives secondary benchmarks' `style.md` or secondary source text

## Cross-genre judgment
Read each secondary benchmark's `Genre` and `Citation strength` from the `Benchmark book list` field in `setting/genre-positioning.md` (unregistered books count as "reference", and output `gaps.benchmark_registry_missing: true`):
- Same genre + citation strength = secondary: recall at all stages, take items up to the per-book cap
- Same genre + citation strength = reference: take only the most relevant items, default no more than half the per-book cap
- Weakly related: setting/outline only, ≤1 item per book
- Unrelated: skip

Sorting: first by relevance (same genre > weakly related), then by citation strength (secondary > reference), then by the user's order in the `Benchmark book list`; if the `Benchmark book list` is missing or does not register a book, remaining secondary books sort stably by directory/book-name Unicode order, and output `gaps.benchmark_registry_missing: true` prompting completion of the list. No limit on secondary-book count; if total items exceed the stage budget, trim items, not book registrations.

## Stage consumption
Numbers below are **per-secondary-book recall caps**; a stage total budget is also set so many secondary books cannot blow up the context. Rows marked `—` mean that format has no such stage; ignore the whole row.

| Stage | Long-form output | Short-form output | Same-genre per-book cap | Weakly-related per-book cap | Stage total budget |
|------|---------|---------|----------------|----------------|------------|
| Setting | `teardown-report.md` | `teardown-report.md` + `plot-points.md` | ≤2 | ≤1 | ≤8 |
| Outline | `chapters/*_summary.md` + `plot/*.md` | `plot-points.md` + `writing-techniques.md` | ≤3 | ≤1 | ≤10 |
| Modules | `characters/` + `plot/` + `setting/` | — | ≤2 | 0 | ≤8 |
| Prose | `style.md` + source | `writing-techniques.md` + source | 0 | 0 | 0 |

> **Outline-stage retrieval is by story unit**: the retrieval keys are the story unit's `Type` (first key, required enum) / `Beat tag, pattern-framework position` (second key); within same-genre, hits of the same type enter the budget first. This only applies to outline-stage story-unit retrieval; it does not change the sorting and budgets of other stages. When same-type hits are zero, fall back to the primary benchmark's items and output a non-blocking `gaps.similar_plot_not_found: true`, then continue.

## Output requirements

Cross-book recall output must include:

```markdown
## Secondary Benchmark Recall Summary
| Book | Citation strength | Relevance | Recall stage | Items recalled | Use |
|---|---|---|---|---|---|
| {book} | secondary/reference | same genre/weakly related | setting/outline/modules | {n} | {supplements a certain structure type; does not enter style/source anchors} |
```

If many secondary books exist, only output the books actually recalled this stage; an unrecalled secondary book is not deleted, it simply missed this stage's budget. The prose stage may pass this table in as structure/emotion/setting reference, but must keep the "secondary books never enter style or source anchors" boundary.

## Teardown fields → writing references
When reading `_meta.json.structure_counts`, look up the corresponding writing reference registered in the current skill via this table. Short-form prefers the genre-styles pack and short-craft; long-form prefers same-type long-form theory files; do not load files across skills that are not registered in the current skill's `Reference Index`.

| Teardown field | Meaning | Writing reference |
|---------|------|---------|
| `beats` | structure segments (opening/development/climax/ending) | the current skill's genre structure files; short-form prefers genre-styles pack / `genre-writing-formulas.md` |
| `hooks` | hook count | `hooks-chapter.md` / `hooks-suspense.md`; short-form opening density supplements short-craft |
| `setup_clues` | reversal setup clues | `reversal-toolkit.md` |
| `character_archetypes` | contrast characters | the current skill's character/genre style files; short-form prefers genre-styles pack / genre-writing-techniques |
| `reusable_structures` | reusable techniques | `genre-writing-formulas.md`; short-form may add short-craft |
| `reversal_type` | reversal type (7-enum) | corresponding skeleton in `reversal-toolkit.md` |
