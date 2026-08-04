# Contributing Guide

Thank you for your interest in the web-fiction writing skill pack. Contributions are welcome.

## Repository Structure

```
skills/
├── story/                   # Toolbox router
├── story-setup/             # Environment deployment
├── story-import/            # Reverse import
├── story-long-write/        # Long-form writing
├── story-long-analyze/      # Long-form deconstruction
├── story-long-scan/         # Long-form market scanning
├── story-short-write/       # Short-form writing
├── story-short-analyze/     # Short-form deconstruction
├── story-short-scan/        # Short-form market scanning
├── story-deslop/            # De-AI-flavoring
├── story-review/            # Multi-perspective review
├── story-cover/             # Cover generation
└── browser-cdp/             # Browser control
scripts/                       # Dev guards / tests / code generation (full index in scripts/README.md)
```

Each skill consists of one `SKILL.md` (entry point) plus a `references/` directory (knowledge base).

## Skill Format

`SKILL.md` must start with frontmatter:

```yaml
---
name: skill-name
description: "One-sentence description. Triggers: /skill-name, trigger phrase 1, trigger phrase 2"
metadata: {"openclaw":{"source":"https://github.com/worldwonderer/oh-story-claudecode"}}
---
```

For OpenClaw compatibility the frontmatter must stay single-line key/value: `description` must not use `|`/`>` blocks and `metadata` must be a single-line JSON object. Longer trigger notes go in the body.

Files in `references/` are loaded on demand by the skill; they are never all injected into context.

## How to Contribute

### Improving an existing skill

1. Fork the repository
2. Create a branch from `main`: `git checkout -b feat/your-feature main`
3. Edit the relevant `SKILL.md` or `references/` files
4. Open a PR describing what changed and why

### Adding a new skill

1. Create a directory under `skills/` containing `SKILL.md` and `references/`
2. Make sure `npx skills validate` passes from the repository root
3. Open a PR

## CI Checks

PRs automatically run `.github/workflows/cross-platform.yml`. The static-check job runs these checks (all mandatory):

- `scripts/static-check.sh` — structured frontmatter parsing, exact Markdown path/anchor checks, agent references and references reachability; cross-skill file references are forbidden except the base `browser-cdp` component
- `python3 scripts/skill-numbering.py check` — workflow-number continuity, reference bindability, and fractional-label guard
- `scripts/check-current-skill-contracts.sh` — validates the current version / Phase / schema / primary artifacts / chapter-outline contract against `scripts/current-contract.json`, and intercepts historical paths and silent-compat branches
- `python3 scripts/test-current-skill-contracts.py` — regression for the current-contract manifest and primary-artifact fail-fast semantics
- `scripts/check-hook-regex-sync.sh` — hook foreshadow-status detection behavior
- `scripts/check-shared-files.sh` — shared runtime-asset manifest + cross-skill reference copy consistency
- `scripts/check-story-setup-deployment.sh` — story-setup deployment completeness
- `scripts/check-claude-adapter.sh` — Claude marketplace and skill mapping checks
- `scripts/check-opencode-adapter.sh` — OpenCode adapter sync, commands/agents/config structure, and plugin real-behavior checks
- `scripts/check-openclaw-skills.sh` — OpenClaw single-line frontmatter, `metadata.openclaw`, and optional real-CLI discovery checks
- `scripts/check-codex-adapter.sh` — Codex repo skills symlink, custom-agent TOML, hook-generation determinism, and launcher contracts
- `scripts/test-codex-hooks.sh` — Codex hooks synthetic-event tests
- `scripts/check-zcode-adapter.sh` — ZCode plugin/marketplace, 13 Skills/Commands, supported hook events, and deployment anchors
- `scripts/test-zcode-hooks.sh` — ZCode strict-JSON hook contract, prose guard, continuity, and cross-platform Node runner tests
- `node --check` syntax validation for the scraper/utility scripts

The list above is representative; **the authoritative mandatory list is `.github/workflows/cross-platform.yml`**, and each script's purpose and trigger timing are documented in [scripts/README.md](scripts/README.md). There is also `.github/workflows/cli-compat.yml` which installs the current official versions on relevant PRs, weekly schedules, and manual triggers, and really runs the unauthenticated smokes of Claude Code, Codex, OpenCode, and OpenClaw.

There are also windows / macos jobs that verify cdp-utils loading and the setup script dry-run.

Before committing, run the Linux-CI mandatory list locally:

```bash
bash scripts/static-check.sh
python3 scripts/test-static-check.py
python3 scripts/skill-numbering.py check
bash scripts/test-skill-numbering.sh
bash scripts/check-current-skill-contracts.sh
python3 scripts/test-current-skill-contracts.py
bash scripts/check-hook-regex-sync.sh
bash scripts/check-shared-files.sh
python3 scripts/test-shared-assets.py
node scripts/test-normalize-punctuation.js
node scripts/test-scan-runtime.js
bash scripts/test-ai-patterns.sh
bash scripts/test-degeneration.sh
bash scripts/test-prose-backstop-hook.sh
bash scripts/test-prose-net-parity.sh
bash scripts/test-story-continuity.sh
bash scripts/check-story-setup-deployment.sh
bash scripts/check-claude-adapter.sh
bash scripts/check-codex-adapter.sh
bash scripts/check-opencode-adapter.sh
bash scripts/check-openclaw-skills.sh
bash scripts/test-codex-hooks.sh
bash scripts/check-python-invocation.sh
bash scripts/check-hook-locale-safety.sh
bash scripts/test-hook-encoding-portable.sh
bash scripts/test-charcount-portable.sh
bash scripts/test-charcount-portable.sh --stub

# Optional real-CLI smokes (each CLI must be installed)
CLAUDE_REAL_CHECK=1 bash scripts/check-claude-adapter.sh
bash scripts/test-codex-cli-e2e.sh
bash scripts/test-opencode-cli-e2e.sh
OPENCLAW_REAL_CHECK=1 bash scripts/check-openclaw-skills.sh
```

## Workflow Numbering Conventions

When adding or adjusting workflow steps, use explicit titles like `Step 1`, `Step 2` with consecutive integers; do not create `Step 1.5` / `Phase 2.1` / `Stage 0.5` to insert steps, and do not use `### 2.1` or `- 2.1` in `SKILL.md` in place of explicit workflow titles. `3.1`-style section/list numbers inside `references/` manuals are not affected by this rule.

Preview before renumbering, then write and re-check:

```bash
python3 scripts/skill-numbering.py audit
python3 scripts/skill-numbering.py fix --dry-run
python3 scripts/skill-numbering.py fix --write
python3 scripts/skill-numbering.py check
```

Auto-fix only renumbers explicit Step titles and references that can be bound unambiguously. Unbindable fractional Step references or one-to-many mappings fail the whole write before landing; Phase, bare-numbered titles, and bullet sub-steps must be named manually by semantics. Full algorithm and partial-path usage are in [scripts/README.md](scripts/README.md#workflow-numbering-maintenance).

Assertions involving agent/skill/plugin/hook protocols must first be checked against the respective official project documentation, then re-verified against real CLI output; do not infer from similar fields of other agents.

## Shared-File Conventions

Some files are shared across skills (e.g. banned-words.md, anti-ai-writing.md); every copy must be synced when they change.

- The single source/targets of runtime scripts are defined in `scripts/shared-assets.json`; edit the `source` first, then run `python3 scripts/sync-shared-assets.py sync`.
- A same-name runtime script may belong to only one canonical group, and every target must keep the source basename; renaming targets to bypass the single owner is forbidden.
- Reference documents are still validated per content group by `check-shared-files.sh`.
- Before committing, always run `bash scripts/check-shared-files.sh`; same-name runtime scripts not registered in the manifest fail outright.

### Knowledge-Base Contributions

The most valuable contribution types:

- **Real-world data**: latest ranking analyses and genre-trend changes on the English platforms
- **New genre frameworks**: new genre writing formulas and structure templates
- **De-AI rules**: new AI-trace patterns and rewrite examples
- **Platform rule updates**: submission requirements and recommendation-mechanism changes

## Quality Requirements

- **Operability**: content must be directly executable by an AI agent — no tutorials
- **Concision**: use tables and templates, not long prose
- **No redundancy**: files may be shared between different skills' `references/` (via path references), but do not duplicate within one skill
- **English**: all content is in English

## Commit Flow

```
fork → branch → commit → PR → review → merge
```

- One PR focuses on one change
- Commit messages are in English, format: `type: short description`
- Types: `feat` (new) / `fix` (fix) / `docs` (documentation) / `refactor` (refactor)

## OpenCode Template Sync

This project supports Claude Code, OpenCode, Codex, ZCode, OpenClaw, and Reasonix (Phase 1). OpenCode agent templates and project-instruction templates are generated automatically from the Claude Code templates by `scripts/sync-opencode.py`.

### When to Sync

Run the sync script after modifying:

- `skills/story-setup/references/templates/agents/*.md` (agent definitions)
- `skills/story-setup/references/templates/CLAUDE.md.tmpl` (project-instruction template)

### Sync Steps

```bash
python3 scripts/sync-opencode.py
python3 scripts/sync-opencode.py --check  # optional: validate only, no writes
bash scripts/check-opencode-adapter.sh
bash scripts/test-opencode-cli-e2e.sh  # optional: requires opencode installed locally
```

The script:
1. Converts the Claude Code agents under `templates/agents/` to opencode format, writing to `opencode/agents/`
2. Copies `CLAUDE.md.tmpl` to `opencode/AGENTS.md.tmpl`, rewriting `.claude/` path references
3. Prints a sync summary
4. Optionally runs a real-CLI smoke that verifies the 13 slash commands, 7 agents, and the `story-hooks.ts` plugin parse and load in a temp project

### CI Detection

When a PR modifies the Claude Code template files, CI automatically detects whether the opencode templates are synced, and additionally checks the `opencode.json.patch`, the 13 commands, the 7 agents' structure, and the plugin's actual guard/backstop behavior. If CI reports an error, run the sync script and `bash scripts/check-opencode-adapter.sh` locally, then commit the results.

### Manually Maintained Parts

These files cannot be auto-generated and must be maintained by hand:

- `skills/story-setup/references/opencode/plugin.ts` — hooks logic
- `skills/story-setup/references/opencode/commands/` — slash commands
- `skills/story-setup/references/opencode/opencode.json.patch` — config fragments

### Known sync-opencode.py Limitations

Manual checks after running the sync script:

- **Path-resolution section**: handled automatically by `fix_path_rules_section()` — no manual fix needed
- **Agent count**: confirm `opencode/agents/` always has exactly 7 files

### OpenCode Key Compatibility Issues

**Glob does not search hidden directories**: opencode's Glob tool does not search `.opencode/` directories, which led to these design decisions:

- **agent-references** deploys to `skills/story-setup/references/agent-references/` (non-hidden), not `.opencode/skills/`
- **agent files** are deployed twice: `.opencode/agents/` (used by the opencode system) + `agents/` (Glob-visible copy)
- **subagent detection**: every skill that spawns agents (story-review, story-long-write, story-deslop, story-import, story-long-analyze, story-short-write) checks in this order: `.claude/agents/` → `.opencode/agents/` → `.codex/agents/`; ZCode 3.3.4 and OpenClaw Phase 1 do not deploy project agents and use solo/direct fallback.

**Plugin output not visible**: the `output.extra.system` field of opencode plugins has been removed (it does not exist in the real API). System-prompt injection instead passes the writing context via `experimental.session.compacting`'s `output.context`.

**session-start system-prompt injection unsupported**: the public OpenCode Plugin API has no `chat.message` or equivalent hook, so deployment-state detection and writing progress cannot be injected into the model context at session start. Users can manually run `/story-setup` to see the status.

**Other hook differences**: the `detect-gaps` plugin was not ported and no session-start prompt is injected (only the compact summary and the pre-prose outline guard remain); `session-end` has no equivalent event in opencode and is unsupported; `validate-commit` uses git's native `pre-commit` hook instead (applies to every CLI).

### OpenCode Usage Notes

- **Restart opencode after first deployment**: slash commands under `.opencode/commands/` deployed by story-setup only take effect after opencode restarts. Exit opencode and re-enter with `opencode -c`.
- **First deployment uses natural language**: a new project has no slash commands; trigger story-setup with natural language (e.g. "use the story-setup skill to deploy the fiction writing environment").
- **opencode config does not hot-reload**: opencode must be restarted after modifying `opencode.json`, agent files, or the plugin.
- **Long-running browser-cdp operations can hang**: opencode has no background-task mechanism; long browser operations require the user to interrupt with `ESC` (the SKILL.md includes a built-in timeout wrapper).

## OpenClaw Adapter Maintenance

OpenClaw currently uses a **Phase 1 skills-only** adapter:

- The canonical source remains the repo-root `skills/`; do not maintain a second copy of any skill for OpenClaw.
- All `SKILL.md` frontmatter must satisfy OpenClaw/AgentSkills constraints: single-line `name`, single-line `description`, single-line JSON `metadata`, with `metadata.openclaw` present.
- `metadata.openclaw.requires.bins/env/config/anyBins` gates OpenClaw load-time visibility; for example `story-cover` controls visibility via `GPT_IMAGE_API_KEY`.
- `story-setup target_cli=openclaw` deploys only the project `skills/` and `references/openclaw/AGENTS.md.tmpl`; no OpenClaw agents/hooks/plugin are deployed.
- OpenClaw snapshots eligible skills at session start; after changes, start a new session or wait for the skills watcher to refresh.

### OpenClaw Check Steps

```bash
bash scripts/check-openclaw-skills.sh
OPENCLAW_REAL_CHECK=1 bash scripts/check-openclaw-skills.sh  # optional when openclaw is installed locally
```

`OPENCLAW_REAL_CHECK=1` creates an isolated agent with a temp profile + temp workspace, confirms the OpenClaw CLI discovers the 13 story skills from the workspace `skills/`, and cleans up the temp profile afterwards.

### OpenClaw Known Boundaries

- **Agents deferred**: OpenClaw's agent/session model differs from Claude/Codex project agents, so OpenClaw Gateway agents are not generated. Skills needing agent collaboration must fall back to solo/direct.
- **Hooks deferred**: the pre-prose outline guard, commit reminders, and session-start/compact injection are not ported to OpenClaw hooks/plugins; under OpenClaw they exist only as soft skill-flow constraints.
- **Package deferred**: OpenClaw can recognize workspace/personal/managed skill roots; no native OpenClaw plugin package is published at this stage.

## ZCode Adapter Maintenance

ZCode uses a dual entry: "native plugin + `story-setup` workspace deployment":

- `.zcode-plugin/plugin.json` and the root `marketplace.json` expose the same set of 13 Skills, 13 Commands, and ZCode Hooks; versions must stay in sync with `skills/story/VERSION`.
- `skills/story-setup/references/zcode/` is the workspace deployment template, containing `AGENTS.md.tmpl`, Commands, `config.json.patch`, and a dependency-free Node hook runner.
- ZCode 3.3.4 supports only `SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, and `Stop`. Do not copy Claude's `PreCompact`, `PostCompact`, `SessionEnd`, `SubagentStop`, or `Notification`.
- Empty hook stdout means pass; any non-empty output must satisfy the strict JSON schema. Diagnostics go to stderr only, exceptions fail open; prefer `process` + `node`, do not introduce cross-platform branches of shell/Python launchers.
- 3.3.4 does not execute project-level or plugin custom agents and does not discover `.zcode/rules`. Do not generate `.zcode/agents/` / `.zcode/rules/` or write to the user home by default; skills needing specialist agents must explicitly report solo/direct fallback.

### ZCode Check Steps

```bash
bash scripts/check-zcode-adapter.sh
bash scripts/test-zcode-hooks.sh
bash scripts/test-prose-net-parity.sh
```

When updating the lightweight deterministic prose net, you must sync all four ends (Claude, OpenCode, Codex, ZCode) and make the parity tests pass.

## Reasonix Adapter Maintenance

Reasonix (DeepSeek-Reasonix CLI) currently supports skills + native plugin manifest + skills-only project-level `story-setup` deployment; hooks and custom agents are left for a later phase (skills needing specialist agents use solo/direct fallback):

- The root `reasonix-plugin.json` is the plugin manifest; `version` must stay in sync with `skills/story/VERSION` (guarded by `check-reasonix-adapter.sh`).
- Reasonix natively scans project skill roots (`.agents/skills` etc., a symlink to `skills/` shared with Codex) and discovers the 13 skills.
- `story-setup`'s `target_cli=reasonix` is a skills-only deployment: it copies the 13 skills into the project `skills/` and writes `references/reasonix/AGENTS.md.tmpl`, without hooks/agents (isomorphic with OpenClaw/generic, guarded by `check-story-setup-deployment.sh`). When changing Reasonix deployment paths or templates, sync that guard.
- The real-CLI check `reasonix doctor capabilities` is not in CI; run it manually before releases.

### Reasonix Check Steps

```bash
bash scripts/check-reasonix-adapter.sh
```

## Codex Adapter Maintenance

This project also supports the Codex CLI (repo skills discovery + `$story-setup` project deployment):

- repo-local skills: `.agents/skills` is a relative symlink to `skills/` (`../skills`, the agentskills.io standard path); Codex scans it to discover skills — don't copy a second copy. It must be a valid relative symlink (guarded by `check-codex-adapter.sh` with target=`../skills`; invalid/absolute breaks discovery, see openai/codex#11314); Windows needs git `core.symlinks=true`. OpenClaw natively scans the workspace `skills/` and does not depend on it.
- project deployment hooks: `skills/story-setup/references/codex/hooks/hooks.json` is aimed at `$story-setup` deployment into writing projects. Both the POSIX `command` and Windows `commandWindows` search upward from the current directory for `.codex/hooks/run-story-hook.*` without depending on a git repo; the shared launcher then handles event allowlisting, interpreter detection, `CODEX_PROJECT_DIR` injection, and Python hook dispatch.
- Windows hooks: Codex launches `commandWindows` with `%COMSPEC% /C` (cmd.exe) on Windows. The registered command uses PowerShell for the upward search, then calls `run-story-hook.cmd`; nested working directories therefore behave like POSIX instead of only supporting the project root. After changing the event manifest or launcher, re-run the generator and the adapter checks; never hand-copy the probe logic into the six registrations.
- custom agents: `skills/story-setup/references/codex/agents/*.toml` are generated from `references/templates/agents/*.md` by `scripts/generate-codex-agents.py`. After modifying a Claude agent template you must regenerate and commit.

### Codex Sync Steps

```bash
python3 scripts/generate-codex-agents.py
python3 scripts/generate-codex-hooks.py
bash scripts/check-codex-adapter.sh
bash scripts/test-codex-hooks.sh
```

### Codex Key Compatibility Issues

- **hooks trust gate**: the Codex project `.codex/` config layer must be trusted; non-managed command hooks additionally require the user to review/trust them in `/hooks` before they run.
- **hook JSON contract**: plain stdout is ignored for `PreToolUse`, `PreCompact`, `PostCompact`; they must output JSON, e.g. `hookSpecificOutput.permissionDecision = "deny"` or `hookSpecificOutput.additionalContext`.
- **PreToolUse is not a complete interception**: Codex's official docs state that shell/edit interception is not a complete security boundary; story hooks are only writing-flow guardrails, not a replacement for version control and human review.
- **agent file format**: Codex custom agents are `.codex/agents/{name}.toml`, requiring `name`, `description`, and `developer_instructions`; read-only agents use `sandbox_mode = "read-only"`.
- **custom-agent runtime registration**: after `$story-setup` writes `.codex/agents/*.toml`, trust the project `.codex/` config layer and start a new Codex session. If the current Codex runtime still returns `unknown agent_type` (reproducible with a local `codex exec 0.141.0` temp-project smoke), the skill must fall back to solo/direct and report the fallback; the automated hard gate is the TOML schema and file-deployment checks.
