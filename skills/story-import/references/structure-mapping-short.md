# Structure Migration Mapping Rules (Short-Form)

The detailed mapping rules for Phase 3-S short-form structure migration: converting `teardown-lib/{Book Title}/`'s short-form teardown artifacts into the `{ShortTitle}/` short-form project structure, for `story-short-write` Phase 3 to take over seamlessly.

> Long-form migration rules: `structure-mapping-long.md`.

Use `{Imported Work Title}` for the work being migrated and `{External Benchmark Title}` only for an unrelated comparison work. Keep their analysis and benchmark paths separate; the imported work must never be registered as its own benchmark.

---

## Key differences from long-form

| Dimension | Short-form | Long-form |
|-----------|------------|-----------|
| Body | single file `prose.md`, **no chapter splitting** | `prose/chapter_NNN_Title.md`, multiple files |
| Tracking directory | **no `tracking/`** | produces `tracking/` (foreshadowing/timeline/character-state/context) |
| Character state | **no `tracking/character-state.md`** | produced, back-derived per `character-state-reverse.md` |
| Outline system | **no volume outlines, chapter outlines** | produces `outline/volume_outline_{X}.md` + `outline/outline_chapter_NNN.md` |
| Outline directory | **no `outline/` directory** | produced |
| Continue-writing handoff | story-short-write Phase 3 (per-scene writing) | story-long-write daily-update loop |

---

## Mapping overview

| Teardown artifact | Short-form project file | Conversion |
|-------------------|-------------------------|------------|
| Full source text (`teardown-lib/{Book Title}/source/`) | `{ShortTitle}/prose.md` | single-file migration, normalized per the 'prose.md format conventions' below; no content rewriting |
| `teardown-report.md`'s story core / genre / benchmark fields | `{ShortTitle}/setting.md` (core-framework block) | back-derive the core framework, format in the "setting.md back-derivation rules" below |
| `plot-nodes.md`'s functional segments | `{ShortTitle}/section-outline.md` | back-derive the section outline (by opening/development/escalation/reversal/ending segments; hook fields marked `[TBD]`) |
| `teardown-report.md` + `craft-methods.md` | `{ShortTitle}/setting.md` (benchmark-summary block) | write structure/emotion/reversal/writing-craft into the benchmark summary |
| `teardown-lib/{Book Title}/` wholesale | `{ShortTitle}/benchmark/{Book Title}/` | optional: copy as a reference view for on-demand loading during continuation |

---

## setting.md back-derivation rules

The target file uses the current core-framework template defined in this file, in two blocks:

### Block one: core framework

Extracted from the story core, structure split, and character analysis fields of `teardown-report.md` into the following template:

```markdown
## Short-Story Core Framework

### Basic info
- Title: {original title}
- Target words: {the source's actual word count} words
- Target platform: {extracted from the teardown report; if none, fill [TBD]}
- Emotional goal: {the reader feeling extracted from the teardown report's "emotional line/eruption analysis"}

### One-line synopsis
{protagonist + dilemma + reversal + emotional landing (from the teardown report's story core)}

### Core reversal
- Reversal type: {extracted from the teardown report's reversal analysis: perspective/identity/motive/timeline}
- Reversal content: {one sentence}
- Setup clues: {from the "setup" type nodes in plot-nodes.md, at least 3; mark [TBD] when insufficient}

### Emotion design
- Opening emotion: {from the first node of the emotion curve} (intensity {1-10})
- Middle emotion: {mid emotion node} (intensity {1-10})
- Reversal emotion: {the reversal node's peak} (intensity {1-10})
- Ending emotion: {the ending node's emotion} (intensity {1-10})

### Character sketches
- Protagonist: {one-sentence persona, from the character analysis}
- Key characters: {one-sentence persona}
- Relationship: {their relationship}
```

> Any uncertain field gets the `[TBD]` marker; never leave an empty field.

### Block two: benchmark summary

Extracted from `teardown-report.md` and `craft-methods.md`, aggregated into the benchmark-summary block:

```markdown
## Benchmark summary: {original title}

### Story structure
{extracted from the teardown report's "functional segments" field, summarizing each segment's function}

### Emotional rhythm
{extracted from the emotion curve / eruption analysis, describing the emotional trend and peak positions}

### Core reversal mechanics
{extracted from the reversal-mechanics analysis, incl. the setup path}

### Reusable writing craft
{extracted from craft-methods.md or the teardown report's "reusable structures" field, ≥3 items}
```

---

## section-outline.md back-derivation rules

Extracted from `plot-nodes.md`'s functional-segment structure, mapped onto the short-form segment-episode structure.

### Segment-level mapping

| Short-form segment | Matching plot-node functional segment | Notes |
|--------------------|---------------------------------------|-------|
| Opening segment | opening (introducing the protagonist/world/dilemma) | usually 1-2 episodes |
| Development segment | early development (conflict accumulation / foreshadowing placement) | usually 2-4 episodes |
| Escalation segment | late development (conflict escalation / misunderstanding deepening) | usually 2-3 episodes |
| Reversal segment | climax (the core reversal detonates) | usually 1-2 episodes, the emotional peak |
| Ending segment | ending (closure / emotional landing) | usually 1-2 episodes |

### Episode-entry template

```markdown
## Opening segment

### Episode 1
- Core event: {the segment's main plot node(s) from plot-nodes.md}
- Emotional goal: {the matching emotion-curve node's emotion word}
- Opening hook: [TBD]
- Ending hook: [TBD]
- Target words: {estimated from the source segment's word count}
```

> Hook fields are marked `[TBD]` — they can't be reliably extracted; left for the user or for continuation writing.

### Episode-count estimation

Estimate by the source's actual word count: `total words ÷ 1000 ≈ episode count` (short-form reference range 8-15 episodes). The episode count matching the body's actual paragraph structure is a mandatory quality-checklist item.

---

## prose.md format conventions

Migrate the source into the single file `prose.md`, normalized per `format-and-structure.md`:

| Convention | Requirement |
|------------|-------------|
| Episode markers | `###1.` `###2.` `###3.` (the general short-form format; when the user specifies a platform, switch per the platform override table in `format-and-structure.md`) |
| Paragraph splits | break naturally by dramatic unit/shot/one-completed-thing; no forced splits by fixed word counts; complete reasoning, atmosphere, and emotional chains may keep slightly longer paragraphs; avoid uniform lengths or outline-shattering |
| Blank lines between paragraphs | adjacent body paragraphs allow **exactly one line break `\n`**; no blank lines or `\n\n` |
| Dialogue quotes | default curly double quotes `""`; straight quotes or corner brackets per platform/user specification |
| Indentation | none; no full/half-width spaces |
| Markdown | no `**` `*` `#` `---` Markdown syntax in body paragraphs (except the episode markers) |

**The source content is not changed** — only format normalization (paragraphing, quote unification, episode markers added).

---

## Benchmark reference view (optional)

Copy `teardown-lib/{Book Title}/` wholesale into `{ShortTitle}/benchmark/{Book Title}/` for benchmark-context loading during continuation:

```
{ShortTitle}/benchmark/{Book Title}/
├── teardown-report.md
├── plot-nodes.md
└── craft-methods.md
```

This view is optional. Generating it by default is recommended, so continuation can retrieve it per the "benchmark-context loading" rules.

---

## Quality-check checklist

Run after Phase 3-S migration completes:

- [ ] `prose.md` single file exists and its format meets `format-and-structure.md` (episode markers, paragraph splits/subject rhythm, single line break between paragraphs, quote format)
- [ ] `setting.md` contains the core-framework block + the benchmark-summary block, and the core framework matches this file's template
- [ ] `section-outline.md`'s episode count matches the body's actual paragraph structure
- [ ] All `[TBD]` markers added (no empty uncertain fields)
- [ ] No mistakenly created long-form-only directories (`tracking/`, `outline/`, `prose/` directory, etc.)
