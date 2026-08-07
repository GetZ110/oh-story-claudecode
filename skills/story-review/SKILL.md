---
name: story-review
version: 1.1.0
description: "Multi-perspective adversarial review. full/lean modes spawn reviewers in parallel when deployed; missing/abnormal agents or spawn failures degrade to solo automatically; when reference files are unreadable the built-in rubric fallback is used. Trigger phrases: /story-review, /review, review this chapter, check my writing."
metadata: {"openclaw":{"source":"https://github.com/worldwonderer/oh-story-claudecode"}}
---
# story-review: Multi-perspective adversarial review

You are the review coordinator. Your job is to find structural, character, prose, and setting problems in the fiction text and give actionable fixes.

**Iron rule: review finds problems; it does not validate correctness.**

---

## Choosing a Review Mode

- `/story-review` or `/story-review full` -> prefer spawning all 4 agents; if already inside a subagent, a core agent is missing/abnormal, or spawning fails, degrade to solo automatically.
- `/story-review lean` -> prefer spawning `story-architect` + `consistency-checker`; if already inside a subagent, any required agent is missing/abnormal, or spawning fails, degrade to solo automatically.
- `/story-review solo` -> no agent spawning; this session runs the base review.
- Unspecified -> default to full, and state the final effective mode in the report.

> The AI-flavor / prose-naturalness dimension is only reviewed by `narrative-writer`, covered by full mode only. lean spawns only `story-architect` + `consistency-checker` and reviews structure and setting consistency — no prose-naturalness review; use full if the prose layer needs a human-voice check.

---

## Phase 0: Preflight and degradation (must run first)

1. **Determine the request mode**: parse `full`, `lean`, `solo` from the user input; when unspecified, the target mode is `full`.
2. **Check whether spawning is allowed**: if already running inside a subagent/Agent, do not spawn recursively — degrade to `solo`.
3. **Identify ZCode capability boundaries**: if running under ZCode and the project uses `.zcode/`, ZCode 3.3.4 does not execute project/plugin custom agents; do not attempt same-name spawns just because agent files exist on disk for other runtimes — degrade to `solo` and report `Fallback: project custom agents unavailable -> solo`.
4. **Check core agent deployment** (check project agents; compatible with Claude Code, OpenCode, and Codex):
   - Check `.claude/agents/` first, then `.opencode/agents/`, then `.codex/agents/`; any of the three directories existing counts as deployed
   - full requires: `story-architect.md`, `character-designer.md`, `narrative-writer.md`, `consistency-checker.md` (Claude/OpenCode) or same-name `.toml` (Codex)
   - lean requires: `story-architect.md`, `consistency-checker.md` (Claude/OpenCode) or same-name `.toml` (Codex)
   - For each required agent file:
     - **Claude Code agent (`.claude/agents/`)**: read the frontmatter; `name:` must exactly match the subagent_type. Missing/unparseable frontmatter or a name mismatch = malformed agent.
     - **OpenCode agent (`.opencode/agents/`)**: the filename is the agent name (OpenCode does not require `name:` in frontmatter); frontmatter must have parseable `mode: subagent` and `permission` fields. Missing/unparseable frontmatter = malformed.
     - **Codex agent (`.codex/agents/`)**: filename `{agent}.toml`; the TOML must parse and contain `name`, `description`, `developer_instructions`; `name` must exactly match the target agent.
   - If `.story-deployed` exists with `agents_version` missing, non-integer, or less than `22`, treat it as a stale deployment; do not spawn, degrade to `solo`, and suggest re-running `/story-setup`. If `agents_version` is greater than `22`, do not spawn either: the installed skill is older than the project deployment — degrade to `solo` and prompt to update oh-story-claudecode first; do not redeploy with v22.
   - If any required agent file for the target mode is missing or malformed, **do not spawn the missing/abnormal agent**; degrade to `solo` automatically and state at the top of the report: `Fallback: missing agents -> solo` or `Fallback: malformed agents -> solo`, list the problem files, and suggest running `/story-setup`.
5. **Confirm Agent/Task tool availability**: if the current environment has no sub-agent/Task capability, degrade to `solo` and report `Fallback: agent tool unavailable -> solo`.
6. **Runtime failure degradation**: if any agent spawn returns failure, `subagent_type` / `agent_type` is unavailable, frontmatter/TOML fails to parse at runtime, or a subagent cannot start, stop spawning, re-review with `solo`, and report `Fallback: spawn failed -> solo` plus the failing subagent_type/agent_type; never treat partially successful agent results as full/lean conclusions.
7. **Determine the effective mode**: the report must list both `Requested Mode` and `Effective Mode`.
8. **Never treat `.active-book` as a platform source**: `.active-book` only names the current book/directory, not the target platform.

---

## Review standards and reference file rules (mandatory)

The core review standards of `story-review` must always be available. Reference files are enhancements, not a runtime prerequisite.

### Report metadata fields (must be output verbatim)

The final report must start with the following English keys, one per line — **do not translate, rename, or output only Chinese synonyms**. You may append a Chinese explanation after an English key, but the key itself must appear verbatim so scripts and users can trace the actual execution path:

```md
Requested Mode: full | lean | solo
Effective Mode: full | lean | solo
Fallback: none | project custom agents unavailable -> solo | missing agents -> solo | malformed agents -> solo | stale agents -> solo | agent tool unavailable -> solo | spawn failed -> solo | subagent recursion guard -> solo
Rubric: royal-road | webnovel | kindle | generic web-fiction
Rubric Source: file | embedded fallback
```

### Reference file resolution order

When reference files are readable, try in this order:
1. `{project root}/.claude/skills/{canonical path}` (Claude Code in-project install)
2. `{project root}/.opencode/skills/{canonical path}` (OpenCode in-project install)
3. `{project root}/.codex/skills/{canonical path}` (Codex in-project install)
4. `{project root}/.zcode/skills/{canonical path}` (ZCode in-project install)
5. `{project root}/skills/{canonical path}` (this repo's dev environment)
6. same-name `{skill-name}/...` directories on the tool's own global skill search paths

Canonical paths are as follows; bare filenames are forbidden, and reading another skill's references across skills is forbidden:

| Purpose | Canonical path |
|---|---|
| Generic quality checklist | `story-review/references/quality-checklist.md` |
| Generic content rubric | `story-review/references/quality-rubric.md` |
| De-AI-flavor methods | `story-review/references/anti-ai-writing.md` |
| Plot loops / climax formulas | `story-review/references/plot-core-methods.md` |
| Character relations / affinity | `story-review/references/character-relations.md` |
| Dialogue quality | `story-review/references/dialogue-mastery.md` |
| Review banned words | `story-review/references/banned-words.md` |
| Platform rubrics | `story-review/references/rubrics/{royal-road,webnovel,kindle}.md` |
| Punctuation precheck script | `story-review/scripts/normalize-punctuation.js` |
| AI-pattern precheck script | `story-review/scripts/check-ai-patterns.js` |

### Built-in review standards package (mandatory when paths are unreadable)

If the reference files above are unreadable in the current project, **do not degrade the review to rubric-less, and do not stop using standards while claiming "rubric could not be loaded"**. Use this section's built-in package and report `Rubric Source: embedded fallback`.

Generic web-fiction content rubric:
- Core appeal: does the chapter advance a clear appeal; if no appeal is visible, at least S2.
- Conflict advancement: is there a blocker, a choice, a cost, or a relationship change; if it only explains/chats/summarizes, at least S2.
- Emotional curve: setup, escalation, release, or reversal; flat or abrupt emotions, S2/S3.
- Hooks and anticipation: does the opening or ending create a follow-up question; no suspense or unresolved anticipation, at least S2.
- Opening freshness (only for the first chapter/first 3): does the opening cut into a concrete character/situation, or is it the genre's default template (swappable onto any comparable book)? "Has a hook / not a weather opening" does not waive homogeneity; a templated opening with a hook is at least S3, a full genre-template collision S2.
- Character motivation: does behavior follow goals, personality, situation, and relationship pressure; distortion for plot's sake is S1/S2.
- Dialogue quality: subtext, information control, character differentiation; manual-style dialogue at least S2.
- Setting consistency: no violations of established rules, timeline, or character attributes; clear factual conflicts are usually S1.
- Prose naturalness: concrete, perceptible, actions carrying information; AI flavor, cliches, and summary voice are S2/S3 by impact.
- Sentence rhythm: narration defaults to comma-linked mid-length sentences (one sentence strings 2-4 actions with commas then lands on a period); fragments and telegraphic style (consecutive <=5-word clauses, whole passages of ultra-short sentences like an outline) are the same class as AI voice — S3/S2 by impact; "short = web-fiction pacing" is not a pass.
- Punctuation rhythm: punctuation serves tone/character voice; whole-text period flattening, random `?`/`!` stacking, or leftover `...`/`--` manufactured pauses are S3/S2 by impact.
- Concrete word-count expressions: when the prose evaluates a line, inscription, letter, thought, or comment with specific word counts ("these five words / the three-word reply / eight words hitting the ground"), the counting basis, machine-verification result, and narrative necessity must be confirmable; if the count cannot be guaranteed, treat it as a prose-naturalness issue and suggest replacing with non-numeric phrasing ("the words landed", "those few words", "as the line fell").
- Format readability: short paragraphs, standalone dialogue lines, no stray blank lines; format that blocks reading is S3, severe chaos S2.
- Minimal plot loop: goal -> blocker -> action -> cost/feedback -> new anticipation; missing goal/blocker/feedback is usually at least S2.
- Climax construction: energy build -> false win -> collapse -> reversal/payoff; a flat climax with no cost or no payoff is usually S2/S3.
- Relationship/affinity: interaction intensity must match the current relationship stage; overstepping intimacy, sudden trust, or sudden hostility needs setup, otherwise S1/S2 by impact.
- Foreshadowing and serialization anticipation: foreshadowing state must be traceable; density is only a structural risk note and does not escalate to S2+ unless it directly breaks comprehension.

AI-flavor / banned-words fallback quick ref:
- High-frequency tells: `little did he know`, `it was a night that would change everything`, `a wave of relief washed over`, `the kind of smile that...`, `couldn't help but`.
- Chapter-end summary body: `he finally understood...`, `a new chapter began...`, `nothing would ever be the same`.
- Information dumps: a character directly saying "let me explain the world/rules/relationship change".
- Essay voice / universal conclusions: overuse of "however / at the same time / admittedly / this means".
- Handling principles: only output a finding with original-text evidence; give executable replacement directions, not just "AI flavor heavy". Fix direction does not default to "split sentences / delete function words / strip punctuation": chopping normal comma-linked sentences into fragments is itself the same class of problem as AI voice.

Platform fallback summaries:
- Royal Road: progression pacing, follow-through on new chapters, chapter-end hooks that pull the next chapter, system/progression clarity.
- Webnovel: serialized episode hooks, power-stone engagement, fast-gratification pacing, freemium retention.
- Kindle: KU binge-readability, page-turn rate, market fit (genre/trope clarity), series read-through.

### Rules passed to sub-agents

In full/lean modes, the main session must write the "review standards package summary" directly into every agent prompt. **Do not require sub-agents to read `story-review/references/*` to complete the task**; if supplementation is needed, read only this skill's own `story-review/references/*`, and ultimately obey the injected rubric summary and the unified Findings Schema.

---

## Phase 1: Collect the material to review

1. **Determine the review scope**:
   - User specified chapters/files -> review only what was specified.
   - User did not specify -> prefer the recently modified prose files (`git diff --name-only` files under prose/setting/outline), otherwise review the current book's current chapter.
2. **Scope-passing strategy**:
   - Prefer passing file paths, chapter names, and line ranges to reviewers; do not paste whole books or large chapter sets into every prompt.
   - A single file or a short excerpt may include 300-1200 words of key excerpts.
   - Multi-chapter/volume/book reviews must be batched: split by chapter or file group, each batch outputs its own findings, then synthesize.
   - **Cross-batch continuity (mandatory when batching)**: before each batch, read `tracking/foreshadowing.md` for open items marked "planted, not yet collected / not yet planted" whose planned collection chapter <= this batch's last chapter; inject them together with the previous batch's findings summary as "inherited open items" into this batch's reviewer / consistency-checker prompts (alongside the known characters) — so reviewing chapters 200-300 can see hooks/foreshadowing planted in 1-200 that this batch was supposed to pay off but left hanging; continuity survives across batches. After the review, register open hooks newly found in this batch that are not in `foreshadowing.md` back into `tracking/foreshadowing.md` (reviewers often find hooks before the writer during continuation/import work).
   - **Out-of-order / overlapping review reminder**: if a later range was reviewed first (e.g., 300-400 first), then an earlier range (200-300) is reviewed, only when this batch **adds or changes an open item whose planned payoff chapter falls inside the already-reviewed later range** should you tell the user "changes in 200-300 may affect the already-reviewed 300-400" and let them choose: re-review affected chapters / full re-review / just log as a todo — **default to logging as a todo; never blindly re-run everything**. No cross-range dependency, no reminder.
3. **Read supporting material**: prose, related setting, character sheets, outline, tracking/context, foreshadowing files; mark evidence gaps in the report when missing.
4. **Identify the target platform and load the rubric**:
   - Prefer the platform the user explicitly stated.
   - Otherwise read the `Target platform` / `Platform` fields in project documents, e.g. `setting/genre-positioning.md`, `outline/`, `teardown-report`.
   - Do not treat `.active-book` as a platform source; it only locates the current book directory.
   - Royal Road -> prefer `story-review/references/rubrics/royal-road.md`; if unreadable use the built-in Royal Road fallback summary.
   - Webnovel (webnovel.com) -> prefer `story-review/references/rubrics/webnovel.md`; if unreadable use the built-in Webnovel fallback summary.
   - Kindle / KU -> prefer `story-review/references/rubrics/kindle.md`; if unreadable use the built-in Kindle fallback summary.
   - Platform unrecognized -> prefer `story-review/references/quality-rubric.md`; if unreadable use the built-in generic web-fiction content rubric and report `Rubric: generic web-fiction` plus `Rubric Source: file | embedded fallback`.
5. **Form the review standards package summary**: compress the loaded file content or the built-in fallback summary into 5-12 review standards; solo and all sub-agents must use this summary. The summary must keep one sentence-rhythm standard: narration defaults to comma-linked mid-length sentences; fragments and telegraphic style are treated the same class as AI voice; "short" is not a pass.
6. **Deterministic prechecks (report only, no modification)**: when the scope includes local prose file paths, run this skill's own scripts:
   ```bash
   node scripts/normalize-punctuation.js --check <prose files...>
   node scripts/check-ai-patterns.js --check --fail-on=blocking <prose files...>
   node scripts/check-degeneration.js --check <prose files...>
   ```
   - Merge `ellipsis`, `double-hyphen`, `markdown-divider` results into the report as `format` findings. For `em-dash`, take only `check-ai-patterns.js`'s semantic rewrite suggestions (next bullet); drop and dedupe the same-position `em-dash` report from `normalize-punctuation.js` to avoid two conflicting findings ("mechanical replacement" vs "rewrite by function") at the same spot. Also manually check whether punctuation rhythm is whole-text period-flattened or randomly stacked; scripts do not replace tone judgment.
   - Merge `check-ai-patterns.js` findings into `prose`: severity=blocking categories are always S2 (currently `not-is-comparison` / `em-dash` / `voice-contrast` / `negation-parade` / `reverse-not-is` / `trailer-ending` / `trailer-summary`); the fix uses the detector's own suggestions (cut negation setups / contrast voice / negation parades / chapter-end trailer voice / chapter-end state summaries — write the direct statement or a concrete action; dashes become action/short sentence/comma/colon by function).
   - Other prose findings are uniformly S4: they only flag read-feel risk and do not replace human judgment; functional writing is marked `[needs review]` and kept. Full categories and fixes live in `anti-ai-writing.md`.
   - `check-degeneration.js` reports model degeneration (verbatim re-reading / truncation / placeholders / engineering-word leakage), each item with `severity: blocking|advisory`: blocking (re-reading / truncation / tier1 engineering words) becomes S1/S2 `prose` findings with the fix "regenerate that passage, not rewrite it"; advisory (tier2 chapter/ambiguous words) becomes S4.
   - `story-review` never modifies files; for auto-fix, suggest `/story-deslop`.
   - Default `--quote-mode keep`; curly/straight quote style is not a problem by itself — only check a conversion suggestion when the project explicitly specifies a quote style.
   - These scripts are story-review's local copies; they do not reference other skills' files.

**story-explorer pre-query (optional)**: only when `Effective Mode` is still `full`/`lean`, spawning is allowed, and the Agent/Task tool is available may you check the agent directories (prefer `.claude/agents/`, then `.opencode/agents/`, then `.codex/agents/`) for `story-explorer.md` / `story-explorer.toml` and spawn `story-explorer` for a setting summary pre-query; in `solo` or subagent-recursion-guard scenarios you must not spawn — use Read/Grep directly. Example prompt:

```text
Project directory: {dir}
Query type: setting_appearances
Query parameters: {setting keywords involved in this review}
```

This step is optional; skipping it does not affect the review flow.

---

## Unified Findings Schema (all modes must use it)

Every reviewer (including solo) must output problems in the unified structure so synthesis can sort them. `location` must use the original file line numbers from the tool read result; do not delete blank lines and renumber.

For `consistency` / `factual` / `causal` / `rule_boundary` findings, the `fix` field only states the fact-unification direction (e.g., "unify to left-arm old injury and sync conflicting spots in prose/setting" or "a source must be adjudicated between timelines A/B") — no creative-writing suggestions.

```yaml
- severity: S1 | S2 | S3 | S4
  category: structure | character | prose | consistency | platform | factual | format | causal | rule_boundary
  location: file path:line or chapter/paragraph description
  evidence: "quote the original text or concrete evidence"
  issue: "problem description"
  fix: "actionable fix suggestion"
```

Severity definitions:
- **S1**: breaks the main line, character motivation, world rules, or reader trust; fix first.
- **S2**: clearly hurts chapter effect, retention, pacing, or character credibility; fix this round.
- **S3**: local quality issues (wording, minor format, local pacing); can be scheduled.
- **S4**: suggestion or style tweak; does not block release.

---

## Phase 2: Parallel agent spawning (full/lean modes)

Use the Agent/Task tool for parallel calls (Codex native subagents use `agent_type`; Claude Code compatible surface uses `subagent_type`; the actual field follows the current CLI's exposed tool). Each agent inherits no parent context; prompts must be self-contained with project path, review scope, file paths, necessary excerpts, the review standards package summary, Rubric Source, and the unified Findings Schema.

**Calling rules**: after Phase 0, only spawn when the effective mode is still full/lean. Never spawn missing agents.

**Agent 1: story-architect** (subagent_type: story-architect)
- Called in full/lean.
- Review perspective: theme alignment, outline structure, hook/reversal quality, scope control, platform expectations.
- Prompt:
  ```
  You are story-architect, reviewing the following from the story-architecture level.
  Your task is to FIND PROBLEMS, not validate correctness. Use the most stringent standards.
  Project path: {project root}
  Review scope: {file paths/chapters/necessary excerpts}
  Review standards package summary: {rubric/fallback summary from Phase 1, must be inline}
  Rubric Source: file | embedded fallback
  Related file paths: {setting/outline/chapter-outline paths}
  Inherited open items (mandatory when batching; write "none" if absent): {open hooks/foreshadowing from tracking/foreshadowing.md whose planned collection chapter <= this batch's last chapter, plus the previous batch's findings summary}
  Optional supplementary reference: this skill's own `story-review/references/quality-checklist.md`, `story-review/references/plot-core-methods.md`; unreadable ones do not block the review.
  Check items:
  1. Does this chapter advance the story theme?
  2. Is the outline structure complete (hooks/payoffs/suspense)?
  3. Is the emotional pacing sound?
  4. Quality of hook and reversal design?
  5. Scope control: any character/setting bloat?
  6. Does a repeatable plot loop exist? (per the plot-loop principle in the standards package summary)
  7. Do climax scenes use energy-build -> false-win -> collapse structure? (per the climax-construction principle in the standards package summary)
  8. Is foreshadowing density, serialization anticipation, and structural information load reasonable? (density is usually only an S4 structural risk unless it already breaks comprehension)
  9. Check item by item against the platform rubric or generic content rubric; mark PASS/FAIL.
  10. Among the inherited open items, did any hook/foreshadowing this batch was supposed to pay off fall flat?
  11. Opening homogeneity (only when this chapter is the book's opening/first 3): is the opening cut the genre's default template (transmigration-with-divorce, system-binding, apocalypse-day-one, instant comeuppance, etc.), swappable onto any comparable book? "Has a hook / not a weather opening" does not equal non-homogeneous. Check against references/plot-core-methods.md's hook classification and opening flow — swappable wholesale onto a comparable book = homogeneous (genre-template collision at least S2; templated but with concrete character/situation micro-differences S3).
  12. Ending summary: does the chapter end with a summary/elevation/replay close ("and that was that..." / "he finally understood..." / "this night would be remembered..."), or land on action/image/suspense? Detector-flagged blocking (`trailer-summary`) is handled per the "blocking is always S2" rule above — do not re-grade; detector-uncovered summary/elevation/replay closes are S2/S3 by impact (rewrites go through /story-deslop Gate F; this skill only flags, never rewrites).

  Output format:
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: must use the unified Findings Schema; severity must be S1/S2/S3/S4.
  INHERITED_ITEMS: list each inherited open item + checked / could not check; items this batch should have paid off but left hanging become findings.
  RECOMMENDATIONS: [fix suggestions]
  ```

**Agent 2: character-designer** (subagent_type: character-designer)
- Called in full mode.
- Review perspective: character voice consistency, dialogue quality, character arcs, relationship advancement.
- Prompt:
  ```
  You are character-designer, reviewing the following from the character and dialogue level.
  Your task is to FIND PROBLEMS, not validate correctness. Use the most stringent standards.
  Project path: {project root}
  Review scope: {file paths/chapters/necessary excerpts}
  Review standards package summary: {rubric/fallback summary from Phase 1, must be inline}
  Rubric Source: file | embedded fallback
  Related character files: {character sheet file paths}
  Optional supplementary reference: this skill's own `story-review/references/character-relations.md`, `story-review/references/dialogue-mastery.md`; unreadable ones do not block the review.
  Check items:
  1. Does the character's language style match the style profile?
  2. Is dialogue samey or overloaded with information?
  3. Is the character arc coherent?
  4. Does character behavior follow motivation?
  5. Does dialogue carry subtext and information control?
  6. Do romance-line affinity and CP behavior match? (per the standards package summary or this skill's character-relations reference)
  7. Is affinity progress perceptible?
  8. Three dialogue symptoms (optional self-check via `story-review/references/dialogue-mastery.md`): (a) mechanical dialogue / Q&A form / no emotional carry between lines; (b) a character as "lecture mouth" explaining whole settings in one block (Gate G applies to dialogue too); (c) tone-deaf lines (jokes, catchphrases, riffing during high-pressure/life-death beats). Hits are S2/S3 with a specific quote + fix.

  Output format:
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: must use the unified Findings Schema; severity must be S1/S2/S3/S4.
  RECOMMENDATIONS: [fix suggestions]
  ```

**Agent 3: narrative-writer** (subagent_type: narrative-writer)
- Called in full mode.
- Review perspective: AI-flavor detection (incl. explainer voice / god-feel / arranged feel = Pattern 8), emotional intensity (payoff strong enough / too conservative), format compliance, rhythm uniformity, prose naturalness.
- Prompt:
  ```
  You are narrative-writer, reviewing the following from the prose-quality level.
  Your task is to FIND PROBLEMS, not validate correctness. Use the most stringent standards.
  Project path: {project root}
  Review scope: {file paths/chapters/necessary excerpts}
  Review standards package summary: {rubric/fallback summary from Phase 1, must be inline}
  Rubric Source: file | embedded fallback
  AI-flavor / banned-words summary: {extracted from anti-ai-writing, banned-words, or the built-in fallback; must be inline}
  Optional supplementary reference: this skill's own `story-review/references/anti-ai-writing.md`, `story-review/references/banned-words.md`, `story-review/references/quality-checklist.md`; unreadable ones do not block the review.
  Check items:
  1. Any banned words/templates/cliches, or simile sheets ("like/as if/as though")?
  2. Any AI writing fingerprints, the AI writing patterns (incl. Pattern 8 explainer voice / god view / arranged feel), or chapter-end summary body?
  3. Format compliant (paragraphs broken by dramatic unit/shot, no mechanical word-count splitting, no blank lines, dialogue on its own lines, natural subject rhythm)?
  4. Punctuation rhythm matches tone/character voice: whole-text period flattening, random `?`/`!` stacking, or leftover `...`/`--` manufactured pauses? Dashes in prose (incl. dialogue) cleaned?
  5. Concrete word-count expressions in prose ("these five words / the three-word reply / eight words hitting the ground")? If the counting basis is unclear, no machine-verification result exists, or no narrative necessity, flag it and suggest non-numeric phrasing.
  6. Rhythm uniform (no multi-section runs without emotional change)?
  7. Task blockers/procedure details that could be deleted with zero loss? Water/local pacing = S3; clearly dragging the main line = S2.
  8. Does the same body-part word exceed 5 occurrences?
  9. AI-flavor level (light/medium/heavy) + evidence.
  10. De-AI supplementary re-check: author explanation summaries / meaning tails; chains of polished dramatic-reaction phrases; existing phone/screen/notice/rule/evidence carriers rewritten into narrator explanation; task blockers used as fake naturalness or word-count padding; mechanically deleted functional life-like/character-bound metaphors or short-fiction subjective verdicts.

  Output format:
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: must use the unified Findings Schema; severity must be S1/S2/S3/S4; the AI-flavor level goes in issue or category.
  RECOMMENDATIONS: [fix suggestions]
  ```

**Agent 4: consistency-checker** (subagent_type: consistency-checker)
- Called in full/lean.
- Review perspective: grep-first + reasoning-based consistency detection, output an S1-S4 report.
- Prompt:
  ```
  You are consistency-checker, detecting factual contradictions with grep-first + reasoning-based consistency review.
  Your task is to FIND factual contradictions, state discontinuities, and setting-logic conflicts that need inference; no creative judgment, no literary-quality evaluation, no creative fix suggestions.
  Project path: {project root}
  Review scope: {file paths/chapters/necessary excerpts}
  Known characters: {character list extracted from setting files}
  Inherited open items (mandatory when batching; write "none" if absent): {open hooks/foreshadowing from tracking/foreshadowing.md whose planned collection chapter <= this batch's last chapter, plus the previous batch's findings summary}
  Review standards package summary: {rubric/fallback summary from Phase 1, must be inline}
  Rubric Source: file | embedded fallback
  Optional supplementary reference: this skill's own `story-review/references/quality-checklist.md`; unreadable ones do not block the factual-conflict scan.
  Check items:
  1. Are character attributes consistent across appearances?
  2. Are world rules violated?
  3. Are foreshadowing states consistent (planted / planned collection / collected / broken)?
  4. Is the timeline self-consistent?
  5. Are terms, identities, locations, and ability boundaries consistent?
  6. Among the inherited open items, is anything this batch should have collected still hanging?

  Output format:
  VERDICT: APPROVE / CONCERNS / REJECT
  FINDINGS: must use the unified Findings Schema; severity must be S1/S2/S3/S4; category may only be consistency / factual / format / causal / rule_boundary.
  INHERITED_ITEMS: list each inherited open item + checked / could not check; open hooks newly found in this batch that are not in foreshadowing.md are listed separately for the main session to write back into tracking/foreshadowing.md.
  FACTUAL_RECONCILIATION: [list only the factual sources to unify or items needing human adjudication; no creative suggestions]
  REASONING_CHAINS: [list only reasoning-type findings: premise/rule -> triggering event -> contradiction -> question to adjudicate]
  ```

---

## Phase 3: Synthesis and verdict

1. Collect the executed reviewers' VERDICTs and FINDINGS.
2. Merge and dedupe: sort by `severity` (S1 > S2 > S3 > S4), then by impact scope within the same level.
3. **Optional fact-check**: only when the review touches external facts needing verification (historical dates, geography, profession details, etc.), `Effective Mode` is still `full`/`lean`, the current context is not a subagent, the Agent/Task tool is available, and `story-researcher.md` / `story-researcher.toml` is deployed in the agent directories (prefer `.claude/agents/`, then `.opencode/agents/`, then `.codex/agents/`) may you additionally spawn `story-researcher` to search and verify; in `solo`, missing/malformed/stale/spawn-failed degradation, or subagent-recursion-guard scenarios you must not spawn — mark "needs human fact-check" in the report instead.
4. **Present disagreements**: if reviewers conflict, present the disagreement explicitly for the user to adjudicate; do not auto-compromise.
5. Output the consolidated review report. The report must state the effective mode, fallback reason, rubric used, Rubric Source, review scope, and evidence gaps.

---

## Phase 4: Report output (full / lean modes)

Use this template only when `Effective Mode` is actually `full` or `lean`; if Phase 0 or runtime failure degraded to `solo`, use the solo template instead.

Note: the five English keys `Requested Mode`, `Effective Mode`, `Fallback`, `Rubric`, `Rubric Source` below must be preserved verbatim; do not change them into Chinese keys.

```md
=== Story Review Report ===
Requested Mode: full | lean
Effective Mode: full | lean
Fallback: none
Rubric: royal-road | webnovel | kindle | generic web-fiction
Rubric Source: file | embedded fallback
Review scope: {chapters/files/batches}

## Verdict Summary
- story-architect: APPROVE / CONCERNS(n) / REJECT / NOT_RUN
- character-designer: APPROVE / CONCERNS(n) / REJECT / NOT_RUN
- narrative-writer: APPROVE / CONCERNS(n) / REJECT / NOT_RUN
- consistency-checker: APPROVE / CONCERNS(n) / REJECT / NOT_RUN

> `NOT_RUN` is only for reviewers excluded by lean mode or optional reviewers; if a required full/lean reviewer is missing or failed to spawn, degrade to solo instead of marking NOT_RUN in a full/lean report and continuing synthesis.

## Severity Counts
- S1: n
- S2: n
- S3: n
- S4: n

## Overall Verdict
APPROVE / CONCERNS / REJECT

## Findings
{all problems listed per the unified Findings Schema or an equivalent table}

## Agent Disagreements (if any)
{conflicting reviewer opinions and evidence}

## Insufficient Evidence / Needs Supplement
{missing setting, missing outline, unverifiable facts, etc.}

## Fix Suggestions
{ordered by S1->S4 priority}
```

---

## Lean mode

lean mode spawns only `story-architect` + `consistency-checker`. If either is missing, degrade to solo per Phase 0. Everything else runs like full.

---

## Solo mode

No agent spawning. First identify the target platform per Phase 1 step 4 and load the matching rubric; even solo must calibrate judgment with the platform rubric, `story-review/references/quality-rubric.md`, or the built-in review standards package.

solo must run the base checks:
1. Format compliance (paragraphs broken by dramatic unit/shot, no mechanical word-count splitting, no blank lines, dialogue format, subject/character-name rhythm).
2. Simple setting-consistency grep (character names, attributes, key settings, foreshadowing keywords) + reasoning-based consistency checks (rule boundaries, setting hierarchy, cross-chapter causal chains, abusable loopholes, cost consistency).
3. AI-flavor and banned-words check (prefer `story-review/references/banned-words.md` and `story-review/references/anti-ai-writing.md`; use the built-in AI-flavor / banned-words fallback quick ref when unreadable).
4. Generic web-fiction content scoring (prefer `story-review/references/quality-rubric.md`; use the built-in generic web-fiction content rubric when unreadable).
5. Output a simplified report per the unified Findings Schema.

### Solo mode output format

Note: the five English keys `Requested Mode`, `Effective Mode`, `Fallback`, `Rubric`, `Rubric Source` below must be preserved verbatim; do not change them into Chinese keys.

```md
=== Story Review Report (solo) ===
Requested Mode: {full | lean | solo}
Effective Mode: solo
Fallback: none | missing agents -> solo | malformed agents -> solo | stale agents -> solo | agent tool unavailable -> solo | spawn failed -> solo | subagent recursion guard -> solo
Rubric: royal-road | webnovel | kindle | generic web-fiction
Rubric Source: file | embedded fallback
Review scope: {chapters/files}

## Base Check Results

### Format Compliance
- [{x| }] Paragraphs break naturally at dramatic unit/shot/one completed thing, not mechanically by word count; an occasional longer complete reasoning/atmosphere/emotion chain is not a violation; whole-text uniform-threshold splitting or outline-shattering counts: pass/fail; evidence: ...
- [{x| }] Subject/character-name rhythm natural: sentence/section openings establish the subject, mid-passage pronouns/ellipsis, names return at key turns; continuous unnecessary repetition of the same protagonist name across sentences/paragraphs counts as subject overload: pass/fail; evidence: ...
- [{x| }] No blank lines between paragraphs: pass/fail; evidence: ...
- [{x| }] Dialogue on its own lines: pass/fail; evidence: ...
- [{x| }] Concrete word-count expressions confirmed correct and narratively necessary; otherwise changed to non-numeric phrasing: pass/fail; evidence: ...
- Violation locations: {list}

> checklist convention: `[x]` only means pass, `[ ]` means fail; never write "[x] ... fail".

### Setting Consistency (grep + reasoning scan)
- Literal factual conflicts: {contradictions or insufficient evidence found}
- Reasoning-based consistency: {findings on rule boundaries/setting hierarchy/cross-chapter causality/abusable loopholes/cost consistency; "none found" if clean}

### AI Flavor / Banned Words
- {list problems; evidence mandatory}

### Findings
{listed per the unified Findings Schema or an equivalent table; severity must be S1/S2/S3/S4}

### Fix Suggestions
{ordered by priority}
```

---

## Pipeline handoff

**Pipeline:** generic
**Position:** review (after writing)

| When | Jump to | Command |
|------|---------|---------|
| Fix the found problems | story-long-write / story-short-write | return to the matching writing skill |
| AI flavor needs cleaning | story-deslop | `/story-deslop` |
| Re-teardown a benchmark book | story-long-analyze / story-short-analyze | `/story-long-analyze` or `/story-short-analyze` |

---

## Language

- Follow the user's language.
- English prose follows the house style rules in the skill's `references/` files
  (especially `anti-ai-writing.md`); keep sentences conversational, concrete,
  and free of AI-flavor patterns.
