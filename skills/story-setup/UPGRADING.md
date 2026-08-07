# Upgrade Guide

## Current version

- `setup_skill_version: 1.3.0`
- `agents_version: 23`

If `.story-deployed` is missing either field, or `agents_version` is missing / non-integer / less than `23`, the deployment counts as pending update. Simply re-run `/story-setup` (Codex uses `$story-setup`); the runtime does not stage-by-stage compat old templates. If the project's `agents_version` is greater than `23`, the local story-setup is older than the project: update oh-story-claudecode first; never downgrade-overwrite a newer deployment. Historical version changes are in the repo-root `CHANGELOG.md`.

## Upgrade strategy

| Strategy | When | Behavior |
|----------|------|----------|
| Overwrite deployment | brand-new project | writes the current agents/hooks/rules/reference bundle |
| Merge deployment | existing project | replaces story-setup-managed files, merges user-maintained files |
| Manual update | update only specific files | recommended only for maintainers familiar with the deployment contract |

It is recommended to always re-run story-setup and let the deployer handle files by owner class.

## File ownership

### Story-setup managed, replaceable

These files are managed by story-setup and contain no user-customized content:
- `.claude/hooks/` — all hook scripts and the `lib/` helper library
- `.claude/agents/` — all agent definitions
- `.claude/rules/` — all path-scoped rules
- `.claude/skills/story-setup/references/agent-references/` — copy of the agent reference material
- `.zcode/skills/{13 known skills}/`, `.zcode/commands/{13 known commands}.md` — only overwrites oh-story-known names
- `.zcode/hooks/story_zcode_hook.js` — the ZCode-specific hook runner

### Co-maintained by the user and story-setup, only managed blocks are merged

These files may contain user-customized content:
- `CLAUDE.md` — merged by marker/section; user-only sections are kept
- `.claude/settings.local.json` — hooks appended deduplicated by command; other config kept
- `AGENTS.md` — merged by marker/section for ZCode/OpenCode/Codex/OpenClaw/generic
- `.zcode/config.json` — only oh-story hooks merged deduplicated by event, matcher, and process args; other fields kept

### User state, never overwritten

- `{BookTitle}/prose/`, `prose.md`
- `{BookTitle}/setting/`, `outline/`, `tracking/`
- `.active-book`

## Current contract

- Writing and import accept only the current teardown artifacts: when `plot/emotional-beats.md` and `plot/pacing.md` are missing, fail fast with the fix actions of re-running Stage 3+ or re-importing.
- Newly created, backfilled, or revised chapter outlines accept only complete chapter blueprints: when the stage position, structure formula, forbidden early release, content summary, plot arrangement, characters and appearance order, plot detail, or ending design is missing, complete them first, then write. Legacy chapter outlines missing these fields do not block daily updates; they fall back to consuming the legacy fields (core event, plot-point sequence, target emotion, opening/chapter-end hooks, target words).
- A chapter outline's fields are a content spec for "what happens" in the chapter; they do not dictate the prose's shape: every field must be honored in the prose, but the prose may merge, interleave, or reorder plot points instead of marching one paragraph per list item. The outline's "Ending / Ending design" records what action, image, or line the chapter finally lands on — not a state verdict.
- Each agent adapter reads only its target's canonical reference path: Claude `.claude/skills/`, OpenCode `skills/`, Codex `.codex/skills/`.
- `_progress.md` recovery accepts only `schema_version: 2` with the chapter-boundary table; implicit historical migrations are no longer performed.
- Codex hook upgrades replace registrations by stable managed identity: stale direct Python commands and existing launcher commands are removed first, then the current 6 registrations are written — no double execution.
- If a custom hook calls the removed `discover_book_dir()`, switch it to `discover_active_book()`. This release no longer keeps that compatibility alias.
- The "incomplete teardown" reminder for `teardown-lib/` filters on the "final status" value in `_progress.md`: `completed` / `completed_with_errors` are excluded; any other value, a missing field, an empty file, or an unreadable file is reported as incomplete. The check lives in `discover_incomplete_analyses()` in `lib/common.sh`.
- The passive version-update reminder throttles the notice itself by 24h; when GitHub is unreachable it writes a negative cache entry so the request is not repeated within the same window.

## Upgrade steps

1. Re-run story-setup in the project root.
2. Confirm `.story-deployed` records `agents_version: 23` and `setup_skill_version: 1.3.0`.
3. Confirm the target CLI's agents, hooks/rules, and reference bundle all pass installation verification.
4. Start a new session so custom agents and hooks re-register from the current files.
5. If existing teardown libraries or chapter outlines do not meet the current contract, re-tear-down/re-import or complete the chapter outlines first, then continue writing.

## Version history

### v23 (current)

- `setup_skill_version` upgraded to `1.3.0`, and `.story-deployed`'s `agents_version` upgraded to `23`.
- **English-language edition (0.8.0)**: full English conversion of all skills, hooks, agents, references, and dashboard; English project structure (`teardown-lib/`, `tracking/`, `prose/`, `outline/`, `setting/`, `benchmark/`; `outline_chapter_N.md`, `tracking/context.md`; Chapter N chapter files; `<!-- deslop:skip -->` exemption marker).
- Deployed projects must re-run `/story-setup` and open a new session.

### v22

- `.story-deployed`'s `agents_version` was bumped to `22` (`setup_skill_version` stayed at `1.2.7`).
- **Chapter summaries became narrative prose (#276)**: the "summary" field of the `chapter-extractor` template no longer requires key events chained with "because… therefore…". It now narrates in event order what happened, why it happened, and how it turned out, prioritizing actions and outcomes that change the story's direction, anomalous information, foreshadowing threads that carry into later chapters, and recognizable concrete details (numbers, direct quotes, anomalies); the same connective must not be reused to chain events, and vague evaluation and subjective interpretation remain banned. Quality-check item 1 and the Domain Boundary were rewritten in sync; the summary keeps its single-line `**Summary:**`-at-line-start shape (the lossless concatenation check at the end of Stage 2 depends on it).
- **Source quotes became selective (#275)**: the primary evidence for plot points is now a P-line plain description — who did what, what resulted, the cause given in the source, and foreshadowing clues must all be written out; the P line gained a standalone plain-description field (previously only the parallel-agent path lacked this, diverging from the serial template). Source quotes are no longer spread point by point; they are kept only for key turns / key lines / craft samples, at most 8 per chapter with continuous slices ≤400 characters; for overly long or scattered passages, use `Source location: {5–15 character snippet}` instead. Quality-check item 5 and the `summary` / `plot_points` keys in the JSON schema were updated in sync; the nominal self-check count was corrected from "10 items" to the actual 12.
- **The two paths were unified**: the parallel chapter-extractor and the solo/direct serial fallback used to be two drifting specs, and ZCode / OpenClaw / Reasonix / generic can only run the serial one. `story-long-analyze/references/output-templates.md` now carries the plain-description rules, tone/theme-tag disambiguation, source-quote selection rules, and the Stage 2 output self-check, so the serial path no longer needs to read `chapter-extractor.md` (those clients cannot see it).
- **P-line titles vs. plain description**: the bolded slot changed from `{event summary}` to `{title}` — it previously sat next to `{plain description}`, and both slots were asking for the same summary, so the plain description degenerated into a retelling of the title. Now the title is a short label of ≤15 characters and the plain description is the sentence that carries the facts; quality-check item 2 and `plot_points.title` in the JSON schema were synced.
- **A new mechanical hard check**: after Stage 2 is written to disk, verify every `P` line has a plain-description field (`grep -cE '^P[0-9]+ [^|]+\|[^|]*[^|[:space:]][^|]*\|[^|]*涉及'` == number of plot points). With selective quotes, the plain description carries the factual look-up, and a missing one fails quality: the parallel path retries with sonnet, the serial path has the main thread rewrite the chapter once for each failed item.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/rules/references; **start a new session after deployment**, otherwise the old session keeps using the v21 deployment, and agent-template changes only register at session start.

### v2

- 4 creative agents + 1 research agent (story-architect, character-designer, narrative-writer, consistency-checker, story-researcher)
- Agents reference skill references for writing theory
- Hook script optimization (reduced context output)
- 4 path-scoped rules

### v3

- Added the story-explorer read-only query agent (character/foreshadowing/setting/progress queries, fast daily-update context loading)
- 6 agents in total (story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer)
- story-explorer is called by story-long-write, story-review, and the story router

### v4

- Added the chapter-extractor chapter-extraction agent
- 7 agents in total (story-architect, character-designer, narrative-writer, consistency-checker, story-researcher, story-explorer, chapter-extractor)

### v5

- Updated narrative-writer scene craft: use the "three-dimension blend" and control paragraph density by segmenting on visual beats
- Word counting now prefers Python character counting, with `wc -m` only as the macOS/Linux fallback, improving Windows + DeepSeek/Claude Code compatibility
- Deployed projects get the new agent definitions by re-running `/story-setup`

### v6

- Unified the short-form prose format between the narrative-writer subagent and the main session: always write to `prose.md`, consistent section markers, no blank lines between paragraphs, half-width double quotes for dialogue
- Short-form writing no longer has narrative-writer create a long-form `tracking/context.md`

### v7

- Fixed the continuation rules in the `/story-long-write daily` batch continuation: within the same batch, "continue/resume/daily" stays in the daily workflow instead of jumping straight into prose continuation.
- Fixed `detect-story-gaps.sh` false positives on the foreshadowing table header and normal open foreshadowing (`unseeded`/`seeded`); SessionStart now only warns about `expired` or abnormal states.
- Deployed projects must re-run `/story-setup` to overwrite `.claude/hooks/`, `.claude/agents/`, `.claude/rules/` and get the new hook behavior.

### v8

- Fixed story-review and the deployed reviewer agent looking for bare filenames (e.g., `quality-checklist.md`) when reading reference files from the project root, which made skill references unresolvable.
- Agent templates gained a reference-path rule: resolve canonical `story-setup/references/agent-references/*.md` paths by joining `.claude/skills/` or `skills/` first, avoiding dependence on the current working directory and never cross-referencing another skill's references.
- Deployed projects must re-run `/story-setup` to overwrite `.claude/agents/` and get the new reference-path rule.

### v9

- `setup_skill_version` bumped to `1.1.0`; `.story-deployed`'s `agents_version` bumped to `9`.
- The deployment contract gained a mechanically checkable manifest: hooks, rules, agents, agent references, settings hooks, `CLAUDE.md` merging, and the `.story-deployed` fields must all specify source, target, owner, merge mode, and validation.
- Hook deployment changed from "copy only `.sh` files" to recursively copying the full `references/templates/hooks/` directory tree, so `lib/common.sh` is never missed; new `lib/sentinel.sh` reads `.story-deployed` fields uniformly.
- The hook runtime became root-aware: `CLAUDE_PROJECT_DIR` first, then the git root, then cwd; `discover_active_book` and `discover_all_books` were split so single-book session logic and whole-project sweeps cannot pollute each other.
- `detect-story-gaps.sh` uses bash 3.2-compatible array/dedup logic and gets all books from the shared library.
- `session-end.sh` does not write `session-log.txt` by default; with explicit `STORY_SESSION_LOG=1` it only writes to an existing long-form `tracking/` and never creates `tracking/` for short-form projects.
- `validate-story-commit.sh` gained an in-script self-check: after parsing `CLAUDE_TOOL_INPUT.command` / `STORY_COMMIT_COMMAND`, it only acts on real `git commit` calls, so non-commit commands like `echo git commit docs` do not misfire.
- The agent reference bundle was completed and canonicalized:
  - `genre-readers.md`: copied from `story-long-write/references/genre-readers.md` as the story-setup canonical copy.
  - `genre-writing-formulas.md`: copied from `story-long-write/references/genre-writing-formulas.md` as the story-setup canonical copy.
  - `emotional-methods.md`: copied from `story-long-write/references/emotional-methods.md` as the story-setup canonical copy.
  - `style-combat-face.md`: copied from `story-long-write/references/style-combat-face.md` as the story-setup canonical copy.
  - `output-templates.md`: not copied; `chapter-extractor` has the output format built in, and the old bare references were rewritten to "follow this file's output format".
- `story-format.md` dropped the old "separate chapters with `---`" rule and now forbids horizontal rules inside prose, matching narrative-writer.

### v10

Deployed projects should re-run `/story-setup` to refresh the writing agents; the main effect is that daily-update continuations more consistently follow the benchmark style.

### v11

- `setup_skill_version` bumped to `1.2.0`; `.story-deployed`'s `agents_version` bumped to `11`.
- **New pre-prose flow-guard hook** `guard-outline-before-prose.sh` (PreToolUse Write/Edit/MultiEdit): creating `prose/chapter_N_*.md` for the first time while `outline/outline_chapter_N.md` is missing, or creating a short-form `prose.md` for the first time while `section-outline.md` is missing, is blocked outright (exit 2), forcing the outline to exist before prose. Existing prose (continuation / deslop / revision) and non-prose files always pass.
- **You must start a new session after deployment**: custom agents only register as `subagent_type` at session start. `/story-setup` leaves the one-time marker `.claude/.agents-pending-restart` after deployment, and session-start.sh confirms the agents registered and clears the marker in the next session. Spawning agents inside the deployment session still degrades to solo — start a new Claude Code session.
- **Writing rules gained "long-short alternation + dense/light allocation"**: `format-and-structure.md` no longer cuts paragraphs at a fixed word-count ceiling; paragraphs now break naturally by dramatic unit, emotional beat, and dense/light allocation; `writing-craft.md` added "dense/light allocation (uneven detail)"; `anti-ai-writing.md` turned long-short sentence alternation into an executable natural-rhythm target; the narrative-writer template added Gate D long-short variation and a "sentence-type diversity" review; story-review's paragraph gate changed from the old word-count ceiling to checking long/short and dense/light variation. In response to feedback that generated content was overly literary, monotonous in sentence shape, and flat in rhythm.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/references; **start a new session after deployment**.

### v12

- `setup_skill_version` bumped to `1.2.1`; `.story-deployed`'s `agents_version` bumped to `12`.
- **Teardown-to-writing module chain (issue #149)**: `story-long-analyze` Stage 2 summaries gained a "key information and expansion techniques" table; Stage 3 produces the authoritative artifacts `plot/pacing.md` (key-information progression / emotional trigger points / eruption rhythm) and `plot/emotional-beats.md` (reader needs · emotional engine / reproducible modules); `story-import` syncs them into `benchmark/{BookTitle}/plot/`; `story-long-write` daily updates read and reproduce them by authoritative priority.
- **Agent template updates**: `chapter-extractor` added "key information and expansion techniques" extraction; `story-explorer`'s `benchmark_style_load` added return fields such as `selected_emotion_module`/`rhythm_reference`. **Deployed projects must re-run `/story-setup` to get the new agent behavior**; otherwise daily updates fall back to manual loading in the main session (no feature loss, just the agent shortcut).
- `consistency-checker` expanded from pure grep-first literal contradictions to "grep-first + reasoning-based consistency review": it additionally checks rule-boundary paradoxes, setting-hierarchy conflicts, cross-chapter causal chains, abusable rule loopholes, and cost consistency.
- **Natural paragraphing + subject rhythm**: `format-and-structure.md` and `writing-craft.md` no longer treat the `60/45` word counts as hard split rules; paragraphs break by dramatic unit / shot / the end of one event; complete reasoning chains, atmosphere building, and emotional shifts may keep somewhat longer paragraphs.
- **Subject-density fix**: the narrative-writer template and story-review check items gained a rhythm rule — name the subject at paragraph start to establish it, use pronouns/ellipsis mid-paragraph, and name it again at key turns — instead of a blanket chapter-wide name-count cap.
- Deployed projects must re-run `/story-setup` to refresh agents/references; **start a new session after deployment**.

### v13

- `setup_skill_version` bumped to `1.2.2`; `.story-deployed`'s `agents_version` bumped to `13`.
- **Chapter outlines upgraded to chapter blueprints (issue #162)**: creating or backfilling a long-form `outline/outline_chapter_XXX.md` now includes, beyond the legacy fields: content summary (cause / development / turn / climax / ending), plot arrangement (main line / sub-line / event line / relationship line / logic line), characters and appearance order, plot detail, and ending design and hook; legacy chapter outlines can still be continued, missing fields do not block, and unknown items are backfilled as `[TBD]`.
- **Tone-punctuation spectrum (issue #161)**: writer references, narrative-writer, and review/deslop gained the rule that punctuation follows tone/character voice, avoiding whole-text period-ization and also banning random piles of question/exclamation marks; hesitation / trailing off / interruption / drawn-out beats are handled with action pauses, short sentences, or line breaks; finished prose does not use `……` or `——`, and the `「」` quotation style (legacy Inkitt platform convention) remains valid.
- `story-architect` now produces the new chapter blueprints; `consistency-checker` consumes the logic line, relationship changes, appearance order, and cost/gain payoff from the chapter outline; `narrative-writer` applies the tone-punctuation spectrum for prose punctuation rhythm.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/references; **start a new session after deployment**, otherwise the old session keeps using the v12 agent definitions.

### v14

- `setup_skill_version` bumped to `1.2.3`; `.story-deployed`'s `agents_version` bumped to `14`.
- **Hard ban on AI sentence patterns (issue #166)**: `narrative-writer`, the writing skills, and review/deslop all list "negate-then-affirm" flip sentences as a hard ban; style recall, benchmark imitation, and Gate B soft rules cannot override it.
- **Local prose checks**: `story-deslop`, `story-long-write`, `story-short-write`, and `story-review` each carry a local `check-ai-patterns.js`; the file mode runs `node scripts/check-ai-patterns.js --check --fail-on=blocking <prose files...>` on the prose before pre-check or delivery; `blocking` hits send it back for rewriting and re-scanning until 0; `advisory` only flags reading-experience risks to handle by context; functional writing is kept or marked `[needs review]`.
- **narrative-writer delivery boundary**: when the agent itself has no Bash/Node tools, it may only report that it self-checked against the rules — it must not claim scripts were run; when the main session or caller has execution capability, the actually-written files must be re-scanned.
- **Word-count fix (issue #170)**: `narrative-writer` Gate E added a "concrete word-count claim check" — the prose must not contain unverified "these five words" style count assertions; use non-numeric phrasing instead.
- **Mechanical dialogue / essay tone / context-blind fixes (issue #171)**: `narrative-writer`'s reference table gained `dialogue-mastery`, the review checklist added per-item dialogue quality, and a final "post-write dialogue self-check" step; the pre-write intent confirmation added a "dialogue voice baseline" (high-pressure beats yield to comedic voice, info-role side characters do not lecture, respond to the other's emotion line by line), with the `consistency-checker`/`character-designer` review sides synced.
- **Per-chapter style-drift self-check on continuation (issue #168)**: `narrative-writer` added a "post-write style self-check" and pins the target sentence-length band snapshot into the "## Style fingerprint" section of `tracking/context.md` (compact-resistant); continuations merge fragment sentences back into mid-length and long sentences per the target band, chapter by chapter, preventing comma-stutter prose.
- **Reader anchors for first mentions of new terms/settings (issue #175)**: `anti-ai-writing.md` added, after the Gate G self-check, the counterweight "removing explainer tone ≠ leaving readers baffled": a new term's first mention conveys its immediate function in a half-line of action/dialogue or a scene consequence.
- **Passive update check (issue #173)**: `session-start.sh` added a passive update reminder — at most once per 24h, 5s curl timeout, fully silent fallback, disabled by `STORY_NO_UPDATE_CHECK=1`, and only warns when behind.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/references; **start a new session after deployment**, otherwise the old session keeps using the v13 agent definitions and cannot get the full set of v14 improvements above.

### v15

- `setup_skill_version` bumped to `1.2.4`; `.story-deployed`'s `agents_version` bumped to `15`.
- **Prose fallback + deterministic cross-batch continuity net (#195)**: new deployed hook `check-prose-after-write.sh` (runs hard-signal fallback after PostToolUse Write/Edit lands — truncation, refusal language/AI self-reference, engineering-word leakage, line-by-line repetition, word-count shortfall); `session-start.sh`'s deployment self-check gained the hook, and `detect-story-gaps.sh` plus the Codex `story_codex_hook.py` share the cross-batch continuity fallback.
- **Custom style-fingerprint source refresh (#196)**: the "Style fingerprint" sections of the narrative-writer template and `context.md.tmpl` gained a "Source" field; after the user adds/edits `setting/style.md`, the new source can refresh the sentence-length band snapshot instead of being permanently overridden by the old benchmark.
- **Model-degeneration / fragment-period detection wired into the writing pipeline (#193/#192)**: `check-degeneration.js` (repetition/truncation/engineering-word leakage) and the upgraded `check-ai-patterns.js` (fragment-period style / long paragraphs / dashes rewritten by function) deploy with the writing skills; prose is re-scanned at the end, and every finding carries `severity: blocking|advisory`.
- **Codex / OpenClaw adapters (#186/#189)**: `$story-setup` deploys `.codex/agents/*.toml` and `.codex/hooks.json`, completes OpenClaw skills-only compatibility, and guards the Codex `.agents/skills` symlink.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/references; **start a new session after deployment**, otherwise the old session keeps using the v14 agent definitions and cannot get the full set of v15 improvements above.

### v16

- `setup_skill_version` bumped to `1.2.5`; `.story-deployed`'s `agents_version` bumped to `16`.
- **Short-form reference stack cleanup (#206)**: `story-short-write` no longer inherits the long-form generic references; `short-format.md`, `short-craft.md`, `short-deslop.md`, and the `genre-styles/` genre packs now carry short-form format, direct emotion delivery, rhythm density, and de-AI-flavoring rules.
- **narrative-writer short-form exceptions synced (#206)**: the Claude/OpenCode/Codex agent templates all gained the "short-form genre-pack exceptions" — when a short story needs direct emotion delivery, "emotion words + physical-feeling/action anchoring" is allowed; only vague AI emotion summaries are removed, and short-form payoff writing is no longer mistakenly converted wholesale into pure action externalization.
- Deployed projects must re-run `/story-setup` to refresh agents/reference bundle; **start a new session after deployment**, otherwise the old session keeps using the v15 narrative-writer template and cannot get the v16 short-form writing rules above.

### v17

- `setup_skill_version` bumped to `1.2.6`; `.story-deployed`'s `agents_version` bumped to `17`.
- **Genre prose prompt-card recall (#226)**: the Claude/OpenCode/Codex narrative-writer templates wire in "genre prose prompt card" recall — read the index first, then read only the single card `genre-prose-cards/{genre}.md`; the card only calibrates genre flavor internally, and the anti-leak hard constraint ensures the card name/genre tag/confidence/compliance self-rating never reach the prose; the style fingerprint and Gate G anti-explainer rules are refined per genre.
- **Outline boundary and per-chapter writing formula (#225/#226)**: the narrative-writer template only expands plot points planned in the chapter outline and returns an `outline_underfilled` shortfall report to the main session for outline completion when they are insufficient; the chapter-extractor template added the `chapter_formula` per-chapter writing-formula artifact (emotional flow / rhythm ratio / structure formula / chapter-end stop point).
- **Generic Web AI deployment (#216)**: story-setup added the `target_cli=generic` file mode; Web AI / generic agent projects get `skills/` and the generic `AGENTS.md` copied in, with no claim of platform-native hooks/custom agents.
- Deployed projects must re-run `/story-setup` to refresh agents/reference bundle; **start a new session after deployment**, otherwise the old session keeps using the v16 agent templates and cannot get the v17 improvements above.

### setup 1.2.7 (ZCode, agents v17)

- Added `target_cli=zcode`: deploys `.zcode/skills/`, `.zcode/commands/`, `.zcode/hooks/story_zcode_hook.js`, merging `.zcode/config.json` and the root `AGENTS.md`.
- ZCode 3.3.4 does not run project/plugin custom agents; `.zcode/agents/` and `.zcode/rules/` are not created, and specialist roles reliably degrade to solo/direct.
- The ZCode hook relies on `node` in PATH and uses only the supported SessionStart / PreToolUse / PostToolUse events; there is no PreCompact / SessionEnd equivalent.
- Existing ZCode projects re-run `$story-setup` after upgrading and start a new ZCode session; the Claude/OpenCode/Codex agents bundle stays at v17 and does not need a standalone `agents_version` bump for this item.

### v18

- `.story-deployed`'s `agents_version` was bumped to `18` (`setup_skill_version` stayed at `1.2.7`).
- **Skill-contract health check (#242)**: new `check-current-skill-contracts.py` bakes the version anchors, primary artifact paths, chapter-outline required fields, and the "silent downgrade" ban into a CI contract; `agents_version` became the sole authority for runtime staleness.
- **Missing benchmark primary artifacts became fail-fast**: when `plot/emotional-beats.md` / `plot/pacing.md` are missing, stop, set `missing_primary_contract`, and prompt re-running `/story-long-analyze` Stage 3+ or `/story-import` — no more silent fallback to `teardown-report.md` / chapter summaries / storylines.
- **Legacy outline tolerance kept**: legacy volume outlines missing the volume contract/story unit card and legacy chapter outlines missing chapter-blueprint fields still do not block daily updates; infer in memory for this round, write unknown items as `[TBD]`, and only write back when explicitly completing/revising an outline; creating, backfilling, or revising must follow the current chapter blueprint in full.
- session-start / story-outline rules and agent templates refreshed in sync. Deployed projects must re-run `/story-setup` to refresh hooks/agents/references; **start a new session after deployment**, otherwise the old session keeps using the v17 deployment.

### v19

- `.story-deployed`'s `agents_version` was bumped to `19` (`setup_skill_version` stayed at `1.2.7`).
- **Terminology unified as "story unit"**: story strips / loop cards / formal plot loops / story segments are all now **story units** (recorded as **story unit cards** in the volume outline); the fields loop ID/loop beat/loop emotional engine/loop promise became unit ID/unit beat/unit emotional engine/unit promise; the word "loop" now only carries rhythm meaning (payoff loops / small-medium-large loops, etc.). Existing volume outlines using the old words are not blocked — read back by field structure — and are upgraded to the new words when completed/revised.
- **Teardown story units wired into volume/chapter outlines**: volume-outline story unit cards gained the optional field "benchmark plot reference"; "benchmark rhythm migration" now selects segments by story unit (grouping like items by type/trope tag); chapter-outline batching boundaries became "one batch = one story unit", with the plot batch recalled once and conclusions fixed into the story unit card; story-long-write's scenario table gained a "complete/expand outline" entry and a volume-outline locking definition. On the teardown side, `plot/README.md` gained a "story unit list" index (existing books can backfill mechanically with "backfill story unit list"). Legacy volume outlines / chapter outlines / teardown libraries missing these fields are never blocked and fall back to the original flow.
- **Volume-outline rules synced to the new advancement model**: the deployed rule story-outline.md changed the volume-outline required fields to the volume contract / endgame reserve / story unit card schema, retiring the fixed "one big payoff every N chapters" cadence; chapter-outline missing-field handling returned to legacy tolerance (only creating/backfilling/revising requires full current-blueprint completeness).
- **story-architect template alignment**: the chapter-outline minimum structure gained unit ID/position and protagonist goal/key choice; "cost payoff/gain payoff" was renamed "action cost (optional)/gain attribution"; Phase 2 spawns must also carry a contract summary (one new chapter-outline-level field).
- **Review line aligned with the new advancement model**: agent-references/quality-checklist.md synced the seven-state grading and suspense/payoff spacing exemptions by chapter positioning, and added a "reader contract and endgame reserve two-way review" section.
- **Hook robustness**: session-start's deployment self-check list now includes `story_hook_cli.js` / `story_hook_core.js`, and when node is missing it emits a one-time [WARN] that the prose guardrail net / commit reminders / continuity checks are disabled (the outline block still has a pure-bash fallback); the four staged-commit scan implementations (JS core / Codex python / Claude bash / OpenCode pre-commit) now share identical semantics and message text, and the parity tests gained Part E (py↔js character-level lock on staged warnings and outline blocking).
- **De-AI-flavoring gate mechanized (stateless)**: the post-write prose net gained deterministic toxic-sentence detection (the whole "not A but B" family / voice-contrast / negation-parade / trailer-ending), scanning automatically when prose lands and pushing hits back, with Claude/ZCode/OpenCode/Codex sharing one core; before writing the next chapter, a new "toxic-sentence debt gate" blocks when the previous chapter has uncleared blocking hits without a `<!-- deslop:skip -->` exemption (the judgment is computed live from the file itself, no state files are written, and missing node or parse failures always pass); the exemption marker accepts both full-width and half-width colons and also makes the post-write net skip that chapter's toxic-sentence push-backs (the other nets continue normally); `check-ai-patterns.js` also gained voice-contrast / negation-parade / reverse-not-is / trailer-ending (blocking, calibrated to zero false positives on real human corpora) and quote-emphasis-tic (advisory); on the SKILL side, the most-toxic-pattern quick reference was inlined into the writing steps, a "clear in the same round after writing" requirement was added, and hookless OpenClaw/generic platforms are covered by the AGENTS template self-lock clause.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/rules/references; **start a new session after deployment**, otherwise the old session keeps using the v18 deployment.

### v21

- `.story-deployed`'s `agents_version` was bumped to `21` (`setup_skill_version` stayed at `1.2.7`).
- **Chapter-end state-summary closers entered the pre-write gate (#255)**: the deployed hook's toxic-sentence debt gate gained the `trailer-summary` rule, sharing the final-600-character window with the existing `trailer-ending`; it catches closers like "this night was destined to…", "it's all over now", "a new life was just beginning", "the wheel of fate", "and so, everything ended" — endings that write the chapter outline's "ending design · closed state" verbatim as a summary sentence — all forms already banned by name in `banned-words.md`. They must be cleared before the next chapter; `<!-- deslop:skip -->` still exempts. All four CLIs (Claude / OpenCode / ZCode sharing the JS core + Codex Python) are synced, with the four `check-ai-patterns.js` copies on the same rules.
- **Not catching "(this|that) moment… finally understood" or bare cognition sentences**: in real human corpora these are normal cognition beats, and the first-person judgment zinger in short stories is still a selling point (`short-craft.md` "judgment zingers / heart-death afterglow"); this family is still covered by the advisory `abstract-summary-tic` by density.
- All branches must land in sentence-final assertion position, avoiding conditional clauses ("when it all ends…"), verb complements ("explained very clearly"), cross-matching idioms ("it was fated"), copula constructions ("the outcome was destined"), transitive uses ("only then ended this topic"), and in-scene announcements ("declared… a complete success") — these shapes are pinned as negative fixtures in `scripts/test-ai-patterns.sh`.
- Calibration (final-600-character window, every hit manually reviewed): qimao mid-chapter corpus — 1 hit in 20,000 chapters (0.005%); heiyan full-piece corpus — 22 hits in 3,999 pieces (0.550%, all of the banned forms above); in the same batch, the existing `trailer-ending` hit 1.345% / 6.602% respectively. Short pieces close at their very end, so their baseline is naturally higher than a long-form chapter's mid-section; hence the two populations are reported separately.
- **Chapter-outline template now asks for the closing action (#255)**: in the `story-architect` chapter-outline template, the chapter-outline fields of `story-long-write` and `story-import`, and the required-field descriptions in `rules/story-outline.md`, "Ending / Ending design" changed uniformly from "what state it closes into" to "whose action, image, or line it finally lands on" — the spec itself is no longer a summary-sentence shape. Based on real-corpus measurement: among long-form chapter-final sentences, dialogue endings are ~29%, action or image ~26%, question or ellipsis suspension ~6%, and explicit state summaries only ~1%; the median length of the final paragraph is 23 characters — real chapters mostly stop on a concrete action without wrapping up.
- **Two session-start reminders fixed (#173)**: the "incomplete teardown" reminder for `teardown-lib/` now filters on the "final status" value in `_progress.md` — `completed` / `completed_with_errors` no longer count (the old implementation just counted files, so every finished book was reported each session); the determination lives in `analysis_incomplete()` / `discover_incomplete_analyses()` in `lib/common.sh`, shared by `session-start.sh` and `detect-story-gaps.sh`. Only the status after the colon is read; template placeholders and parenthetical notes like `pending (re-run after a previous completed)` count as incomplete — better to over-report than miss one.
- **Passive update reminder throttles the notice itself by 24h (#173)**: the old implementation only throttled network requests, so with `latest` cached the same version was announced every session; also, a failed curl wrote no cache, so environments that cannot reach GitHub waited a pointless 5 seconds each session and never saw the reminder. Now a failure still writes a timestamp as a negative cache.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/rules/references; **start a new session after deployment**, otherwise the old session keeps using the v20 deployment, and agent-template changes only register at session start.

### v20

- `.story-deployed`'s `agents_version` was bumped to `20` (`setup_skill_version` stayed at `1.2.7`).
- **narrative-writer Gate D wired to the sentence-length standard**: Gate D changed from "shatter rhythm" to "adjust rhythm" — only bloated-modifier, stacked-metaphor, or information-overloaded long sentences are split, and rewritten narration still leans on comma-connected long sentences (agent-references/anti-ai-writing.md rule 3, "how long should sentences be": 8–12 characters between commas, 20–30 characters per sentence, no runs of ≤5-character fragments); "mobile reading density" explicitly means splitting paragraphs, not fragmenting inside sentences.
- **agent-references sentence-length governance**: anti-ai-writing.md rule 3 was rewritten as "how long should sentences be (short sentences are a tool, not the default)" and now declares rule 3 authoritative for this file (calibrated on real hit corpora: long-form narration averages 8.8–9.6 characters between commas, 22–24 characters per sentence, comma-connected long sentences 74–80%); in banned-words.md, the slow-motion adverb quartet (slowly/slightly/gently/faintly) dropped from tier-1 to tier-2 density control (≤3 combined per thousand characters); quality-checklist / writing-craft / format-and-structure / genre-writing-formulas removed inducing clauses such as "split whenever long" and "externalize all emotion" in sync.
- **narrative-writer externalization prescriptions capped**: "psychological externalization / Gate C mental-description externalization / emotion words externalized by default" went from absolute rules to one-place-aim, non-ironclad guidance: necessary inner thought may be written directly, and do not pile up functionless micro-gestures like sleeve-rubbing or trouser-gripping; emotional-arc-design's "short sentences = decisive and passionate" became "sentence length follows emotion and rhythm"; the high-density opening example in writing-craft switched from telegraphic short sentences to comma-connected flow, clarifying that density means how many events are in a paragraph, not that every sentence is chopped.
- Deployed projects must re-run `/story-setup` to refresh hooks/agents/rules/references; **start a new session after deployment**, otherwise the old session keeps using the v19 deployment.
