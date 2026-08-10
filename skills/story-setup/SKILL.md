---
name: story-setup
version: 1.3.0
description: "Web-novel writing toolkit infrastructure deployment. Provides built-in adapters for Claude Code / OpenCode / Codex / ZCode / OpenClaw / Reasonix; Web AI / generic agents can use the skills + AGENTS.md file mode. Triggers: /story-setup, $story-setup, 'get ready to write a book', 'help me set up the environment', 'configure a writing project'."
metadata: {"openclaw":{"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# story-setup: Web-Novel Writing Toolkit Infrastructure Deployment

You are the writing-infrastructure deployer. Deploy the web-novel writing toolkit into the user's project directory: adapted CLIs get dedicated hooks/agents/config; NarraFork, Web AI, custom agents, and similar environments get the generic file mode.

**Hard rule: never overwrite the user's existing configuration — merge, never replace.**

---

## Phase 1: Detect the Project State

1. Check whether the current directory has already been deployed (`.story-deployed` exists)
   - `agents_version` missing, non-integer, or less than `23` → mark as pending update and continue with the current deployment
   - `agents_version: 23` → use AskUserQuestion to confirm whether to redeploy
   - `agents_version` greater than `23` → the current story-setup is older than the project's deployment; stop to avoid downgrade-overwriting, prompt updating oh-story-claudecode first, and write no deployment files
2. Check whether a book-title directory exists (a directory containing a `tracking/` subdirectory, or a user-customized structure)
   - Yes → identify as a long-form project and show the current project info
   - No → identify as a new project or a short-form project
3. Check whether `.claude/settings.local.json` exists
   - Exists → read the existing config and merge into it later
   - Absent → create a new file later
4. Check whether the `.active-book` file exists
   - Exists → show the current active book
   - Absent → skip
5. Check whether `opencode.json` or `.opencode/` exists
   - Exists → identify as an opencode project, `target_cli = opencode`
   - Absent → skip
6. Check `.codex/`, `.codex/config.toml`, `.codex/agents/`, `.codex/hooks.json`, and the Codex section in `AGENTS.md`
   - Exists → identify as a Codex project, `target_cli = codex`
   - Absent → skip
7. Check `.zcode/`, `.zcode/config.json`, `zcode.json`, `.zcode/skills/`, `.zcode/commands/`, and the ZCode section in `AGENTS.md`
   - Exists → identify as a ZCode project, `target_cli = zcode`
   - Absent → skip
8. Check `openclaw.json`, `.openclaw/`, `.agents/skills/`, the OpenClaw section in `AGENTS.md`, or `metadata.openclaw` in `skills/*/SKILL.md`
   - Exists → identify as an OpenClaw project, `target_cli = openclaw`
   - Absent → skip
9. Check `.reasonix/`, `reasonix-plugin.json`, and `REASONIX.md` for Reasonix markers (Reasonix shares `.agents/skills` with Codex/OpenClaw, so `.agents/skills` alone never identifies Reasonix — only Reasonix-specific markers count)
   - Exists → identify as a Reasonix project, `target_cli = reasonix`
   - Absent → skip
10. If `.claude/` or `CLAUDE.md` markers coexist with OpenCode, Codex, ZCode, OpenClaw, and Reasonix markers → use AskUserQuestion to let the user choose the target environment (options: Claude Code / OpenCode / Codex / ZCode / OpenClaw / Reasonix / generic Web AI or other agent / any combination)
11. If none of the six built-in CLI markers exist (brand-new project or Web AI project) → use AskUserQuestion to let the user choose the target environment
    - The user picks opencode → `target_cli = opencode`; create `opencode.json` and `.opencode/` at deployment
    - The user picks claude-code → handle per the existing logic
    - The user picks codex → `target_cli = codex`; create `.codex/` at deployment
    - The user picks zcode → `target_cli = zcode`; create `.zcode/`, merge the root `AGENTS.md`, and do not create project custom agents
    - The user picks openclaw → `target_cli = openclaw`; copy the OpenClaw-compatible skills into the project `skills/`
    - The user picks reasonix → `target_cli = reasonix`; copy skills into the project `skills/`, write the Reasonix `AGENTS.md`, and do not create project custom agents/hooks
    - The user picks generic Web AI / other agent → `target_cli = generic`; deploy the generic `AGENTS.md` and project-local `skills/`; write no platform-specific hooks/agents
    - The user picks multiple CLIs → `target_cli` is the subset of `claude-code,opencode,codex,zcode,openclaw,reasonix,generic` containing only the chosen CLIs

## Phase 2: Deploy the Infrastructure

After the deployment target is confirmed with AskUserQuestion, run the following steps in order.

### Step 1: Deployment manifest (mechanically checkable)

| Source path | Target path | Owner class | Merge mode | Validation check |
|-------------|-------------|-------------|------------|------------------|
| `skills/story-setup/references/templates/CLAUDE.md.tmpl` | `CLAUDE.md` | user+managed | marker/section merge | contains story skill routing sections |
| `skills/story-setup/references/templates/hooks/` | `.claude/hooks/` | story-setup managed | recursive replace | `session-*.sh`, `detect-story-gaps.sh`, `validate-story-commit.sh`, `guard-outline-before-prose.sh`, `check-prose-after-write.sh`, `story_hook_core.js`, `story_hook_cli.js`, `lib/common.sh`, `lib/sentinel.sh` all exist; `story_hook_core.js` byte-identical to the OpenCode/ZCode copies |
| `skills/story-setup/references/templates/rules/*.md` | `.claude/rules/*.md` | story-setup managed | replace | every rule contains `paths` frontmatter |
| `skills/story-setup/references/templates/agents/*.md` | `.claude/agents/*.md` | story-setup managed | replace | 7 agent files exist |
| `skills/story-setup/references/agent-references/*.md` | `.claude/skills/story-setup/references/agent-references/*.md` | story-setup managed | replace | every `story-setup/references/agent-references/*.md` reference resolves |
| `skills/story-setup/references/templates/settings-hooks.json` | `.claude/settings.local.json` | user+managed | merge by hook command | hook JSON valid and registered commands deduped |
| JSON tracking authority generated by `tracking_commit.py` | `{BookTitle}/tracking/context.md` | managed state | deterministic derived view | never edit the derived view directly |
| generated sentinel | `.story-deployed` | story-setup managed | replace | contains `agents_version`, `setup_skill_version`, `target_cli`, `resolver_strategy`, `references_dir` |
| `skills/story-setup/references/opencode/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains story skill routing sections | target_cli includes opencode |
| `skills/story-setup/references/opencode/agents/` | `.opencode/agents/` | story-setup managed | replace | 7 agent files exist (before the replace, cache existing `model:` per "Preserve existing model config" in "Configure OpenCode agent models" so user-configured models are not overwritten) | target_cli includes opencode |
| `skills/story-setup/references/opencode/plugin.ts` | `.opencode/plugins/story-hooks.ts` | story-setup managed | replace | TypeScript plugin file exists | target_cli includes opencode |
| `skills/story-setup/references/opencode/story_hook_core.js` | `.opencode/plugins/lib/story_hook_core.js` | story-setup managed | replace | Node syntax valid; byte-identical to the ZCode copy; imported by story-hooks.ts | target_cli includes opencode |
| `skills/story-setup/references/opencode/commands/` | `.opencode/commands/` | story-setup managed | replace | 13 command files exist | target_cli includes opencode |
| `skills/story-setup/references/opencode/opencode.json.patch` | merge into `opencode.json` | user+managed | merge by plugin/permission key | plugin entry registered | target_cli includes opencode |
| `skills/story-setup/references/agent-references/` | `skills/story-setup/references/agent-references/` | story-setup managed | replace | every reference resolves | target_cli includes opencode |
| `skills/story-setup/references/opencode/pre-commit.sh` | `.git/hooks/pre-commit` | user+managed | append or create | file exists and is executable; if it contains the marker block, replace just that block, otherwise detect an `exit 0` position and insert smartly | target_cli includes opencode |
| `skills/story-setup/references/codex/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains Codex story skill routing sections | target_cli includes codex |
| `skills/story-setup/references/codex/agents/` | `.codex/agents/` | story-setup managed | replace | 7 TOML agent files parse and contain `name`/`description`/`developer_instructions` | target_cli includes codex |
| `skills/story-setup/references/codex/hooks/hooks.json` | `.codex/hooks.json` | user+managed | replace managed registrations by stable hook identity | hook JSON valid; all stale direct/launcher registrations removed, current 6 registrations present exactly once | target_cli includes codex |
| `skills/story-setup/references/codex/hooks/{story_codex_hook.py,run-story-hook.sh,run-story-hook.cmd}` | `.codex/hooks/` same-named files | story-setup managed | replace | Python/shell/cmd launcher files all present | target_cli includes codex |
| `skills/story-setup/scripts/merge-codex-hooks.py` | executed at deployment time, not copied to the project | story-setup helper | execute | replaces known managed registrations, keeps user hooks and unknown top-level fields, idempotent result | target_cli includes codex |
| `skills/story-setup/references/agent-references/` | `.codex/skills/story-setup/references/agent-references/` | story-setup managed | replace | every reference resolves | target_cli includes codex |
| `skills/story-setup/references/zcode/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains ZCode `$story-*` routing and solo fallback | target_cli includes zcode |
| repository `skills/{browser-cdp,story*}/` | `.zcode/skills/{browser-cdp,story*}/` | story-setup managed for known skill names | replace known skill dirs only | 13 `SKILL.md` files exist and satisfy ZCode frontmatter limits | target_cli includes zcode |
| `skills/story-setup/references/zcode/commands/` | `.zcode/commands/` | story-setup managed for known command names | replace known command files only | 13 commands have valid names/frontmatter | target_cli includes zcode |
| `skills/story-setup/references/zcode/hooks/story_zcode_hook.js` | `.zcode/hooks/story_zcode_hook.js` | story-setup managed | replace | Node syntax valid; hook contract tests pass | target_cli includes zcode |
| `skills/story-setup/references/zcode/hooks/story_hook_core.js` | `.zcode/hooks/story_hook_core.js` | story-setup managed | replace | Node syntax valid; hook contract tests pass | target_cli includes zcode |
| `skills/story-setup/references/zcode/config.json.patch` | merge into `.zcode/config.json` | user+managed | merge by event+matcher+process args | JSON valid; per the hooks mutual-exclusion branch of step 4 of the "ZCode deployment algorithm" — when the oh-story plugin is not installed, `hooks.enabled=true` and only supported events are registered; when the plugin is installed, verify `.zcode/config.json` does not contain (or has removed) this batch of oh-story hook registrations | target_cli includes zcode |
| `skills/story-setup/references/openclaw/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains OpenClaw story skill routing sections | target_cli includes openclaw |
| `skills/story-setup/references/generic/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains generic story skill routing sections | target_cli includes generic |
| `skills/story-setup/references/reasonix/AGENTS.md.tmpl` | `AGENTS.md` | user+managed | marker/section merge | contains Reasonix story skill routing sections and solo/direct fallback | target_cli includes reasonix |
| repository `skills/{browser-cdp,story*}/` | `skills/{browser-cdp,story*}/` | story-setup managed for known skill names | replace known skill dirs only | 13 `SKILL.md` files exist; OpenClaw-compatible frontmatter | target_cli includes openclaw or generic or reasonix |
| `skills/story-setup/references/agent-references/` | `skills/story-setup/references/agent-references/` | story-setup managed | replace via full skill copy | every reference resolves | target_cli includes openclaw or generic or reasonix |

### opencode.json merge algorithm

When deploying `opencode.json.patch`, merge per the following rules:

1. Read the existing `opencode.json` (if present) and parse the JSON
2. Merge the `plugin` array: add `./.opencode/plugins/story-hooks.ts` to the array, deduplicated
3. Keep the user's other existing config fields (`permission`, `model`, `provider`, etc.) without overwriting
4. Write the merged `opencode.json`

### Step 2: Deploy CLAUDE.md

- Read `skills/story-setup/references/templates/CLAUDE.md.tmpl`
- Replace the placeholders (see "Template placeholders" below)
- Write `CLAUDE.md` in the project root (if it already exists, follow the "CLAUDE.md merge strategy")

### Step 3: Deploy Hooks

- **Recursively copy the full directory tree**: copy `skills/story-setup/references/templates/hooks/` to the user's project `.claude/hooks/`
- Must keep the `lib/` subdirectory, where:
  - `lib/common.sh` provides `project_root`, `discover_active_book`, `discover_all_books`
  - `lib/sentinel.sh` reads the `.story-deployed` fields
- Only `.claude/hooks/*.sh` needs the executable bit (`chmod +x`); `lib/*.sh` is `source`d by hooks and does not require the executable bit

### Step 4: Deploy Rules

- Read every `.md` file under `skills/story-setup/references/templates/rules/`
- Copy them into the user's project `.claude/rules/` directory

### Step 5: Deploy Agents

- Read every `.md` file under `skills/story-setup/references/templates/agents/`
- Copy them into the user's project `.claude/agents/` directory
- Agent files are story-setup-managed files and can be safely overwritten; on version upgrades, redeploy per the version-detection results in `UPGRADING.md`
- **You must start a new session after deployment**: agents register only at session start; the reason and the mandatory report wording are under "Output the installation report" in "Verify the installation"

#### Agent compatibility handling

- Agent frontmatter is authored primarily for Claude Code; OpenCode is generated by `scripts/sync-opencode.py` into `.opencode/agents/*.md`; Codex by `scripts/generate-codex-agents.py` into `.codex/agents/*.toml`.
- **ZCode 3.3.4 does not deploy project agents**: its custom subagents only support user-level `~/.zcode/agents/`, and the `agents` field in plugin manifests is not executed at present. Do not create `.zcode/agents/` or modify the user's home; skills that need agents must go solo/direct and report the fallback.
- **OpenClaw Phase 1 does not deploy agents**: OpenClaw only deploys skills; agent-dependent skills must degrade to solo/direct per the existing fallback rules, and Claude/OpenCode agent frontmatter must not be copied verbatim as OpenClaw agents.
- After deployment, reference material used inside agents must come from the in-skill copy path `story-setup/references/agent-references/*.md`; do not cross-reference other skills' references. Each adapter uses only its current canonical prefix: Claude Code `.claude/skills/`, OpenCode / OpenClaw / Reasonix / generic `skills/`, Codex `.codex/skills/`, ZCode `.zcode/skills/`; do not traverse legacy fallback paths at runtime.

#### Deploy agent references

- Copy every `.md` under `skills/story-setup/references/agent-references/` into the project's `.claude/skills/story-setup/references/agent-references/`
- Verify: whenever `story-setup/references/agent-references/<file>.md` appears in an agent or reference, `<file>.md` must exist in both the source package and the target package

#### Deploy Codex agents (when target_cli includes codex)

- Read every `.toml` file under `skills/story-setup/references/codex/agents/` and copy it into the user's project `.codex/agents/`
- Agent files are story-setup-managed files and can be safely overwritten; the source is deterministically generated from the Claude agent templates by `scripts/generate-codex-agents.py`
- Verify every TOML parses and contains the Codex-required fields: `name`, `description`, `developer_instructions`
- Read-only-duty agents (`chapter-extractor`, `consistency-checker`, `story-explorer`) must keep `sandbox_mode = "read-only"`
- **After deployment, the `.codex/` layer must be trusted and a new Codex session started** (report wording and fallback rules: see "Verify the Codex deployment"); if the runtime returns `unknown agent_type`, the caller must fall back to solo/direct and report the fallback.
- Also copy `skills/story-setup/references/agent-references/` into `.codex/skills/story-setup/references/agent-references/` as the primary in-project reference path for Codex agents

#### Configure OpenCode agent models

> Only runs when `target_cli` includes `opencode`. OpenCode subagents that do not specify a model inherit the main model, so low-cost agents would burn main-model quota. This step auto-detects the user's models and writes them into the `model:` field.

##### Step 1: Preserve existing model config (must run before the `.opencode/agents/` replace)

OpenCode agent deployment is a `replace` that would overwrite the `model:` written last time. So **before** that replace runs, scan the existing `.opencode/agents/*.md` and cache each agent's `model:` (agent name → model ID). When a later detection fails/times out or the user skips a tier, backfill from the cache so the user's previously configured low-cost models are not wiped to the main model. If the replace already happened and the cache is empty, treat it as a fresh deployment and note in the installation report that "the previous model configuration could not be preserved".

##### Step 2: Fetch the model list

Prefer `opencode models --verbose`, whose output includes metadata with cost (input/output/cache unit prices), context, and capabilities; if unavailable or unparseable, fall back to plain-text `opencode models` (one `provider/model` per line). Both run with a 60000 ms (60 s) timeout, because the first run loads the models.dev cache.

- Success → proceed to "Model tiering"
- Timeout → retry once (the cache may not be warmed); if it still times out, backfill existing `model:` values from the "Preserve existing model config" cache, skip automatic configuration, and output the manual configuration guide in the installation report
- Failure (command missing, empty output, etc.) → same as above: backfill from the "Preserve existing model config" cache, skip automatic configuration, and output the manual configuration guide

##### Step 3: Model tiering

**Tier by cost first (with `--verbose`)**: bucket models by their actual cost from low to high — the budget tier takes the cheapest/free bucket, the mid tier the mid-price bucket, the high tier the priciest or the strongest-context/capability bucket. Free models land in the budget tier by their real cost of 0, **not by marketing words in the name** (e.g., `nemotron-3-ultra-free` contains `ultra` but costs 0, so it belongs in the budget tier). Models without cost data still enter the candidates and are not dropped.

**Fallback keyword tiering (without `--verbose` or cost data)**: split the model name after the last `/` into segments by `-`, `.`, and `_`, and match keywords exactly per segment (case-insensitive). For example, `minimax-m3` splits to `[minimax, m3]` and matches neither `mini` nor `max`; `claude-haiku-4.5` splits to `[claude, haiku, 4, 5]` and matches `haiku`. Keyword tiering is heuristic; the installation report marks it `Tiering basis: keywords (heuristic)`.

| Tier | Matching keywords | Agents |
|------|-------------------|--------|
| Budget | `haiku`, `flash`, `mini`, `nano`, `lite` | chapter-extractor, consistency-checker, story-explorer |
| Mid | `sonnet`, `plus` | story-researcher, narrative-writer, character-designer |
| High | `opus`, `pro`, `ultra`, `max` | story-architect |

- A model may match keywords in multiple tiers; take the highest tier
- In keyword fallback, models that match no keyword are still listed as additional candidate suggestions (under cost tiering everything is included) and appear in the installation report with the note "available via custom input"
- Within a tier, when multiple providers are present, list models from well-known providers (anthropic, openai, google, deepseek) first

##### Step 4: Interactive per-tier selection

In budget → mid → high order, let the user choose each tier with AskUserQuestion.

**Budget-tier option structure:**

```
Question: "Choose models for the low-cost agents (chapter-extractor, consistency-checker, story-explorer):"
Options:
  - provider/model-id
  - provider/model-id
  - Custom input (type the full model ID by hand; typos only surface at runtime)
  - Skip, use the main model (may be more expensive)
```

**Mid-tier option structure:**

```
Question: "Choose models for the writing-quality-critical agents (narrative-writer, character-designer, story-researcher):"
Options:
  - provider/model-id
  - provider/model-id
  - Custom input (do not use budget-tier models; they will hurt prose quality; typos only surface at runtime)
  - Skip, use the main model (the main model's quality is usually sufficient)
```

**High-tier option structure:**

```
Question: "Choose a model for the lead agent (story-architect):"
Options:
  - provider/model-id
  - provider/model-id
  - Custom input (type the full model ID by hand; typos only surface at runtime)
  - Skip, use the main model (may be more expensive)
```

Rules:
- Show at most 5 candidates; if there are more, truncate and note "use custom input for more models". **Regardless of whether a tier has zero candidates, always pop up AskUserQuestion**, with options at least including: candidate models (if any), `custom input`, `keep existing model` (the model cached for this agent by "Preserve existing model config"; hide this option when there is none), and `skip, use main model`. Even with zero candidates, still show the dialog, give the corresponding warning in the question text, and list unclassified/unregistered models for reference — never silently skip the interaction (otherwise the user cannot reach custom input).
- `Custom input`: the user enters the full `provider/model-id`; before writing, validate it is a single line, free of control characters, and matches `^[A-Za-z0-9._-]+/[A-Za-z0-9._:+-]+$`; if it fails, prompt them to re-enter or switch to skip instead.
- `Keep existing model`: writes back the model cached for this agent by "Preserve existing model config" (keeping the user's last configuration on redeploy); this does not count as "skip".
- `Skip, use main model`: explicitly clears — no `model:` is written for this agent and it inherits the main model. Choose `keep existing model` if you want to keep the last configuration.
- When a tier has zero candidates, include the corresponding warning in the question text:
  - Budget: "No low-cost models detected; these 3 agents will use the main model, which may be more expensive"
  - Mid: "No matching mid-tier model detected. narrative-writer, character-designer, and story-researcher will use the main model. This is reasonable if the main model's quality suffices; to cut cost, use custom input to specify a mid-tier model of at least main-model quality, or pick from the unclassified models below."
  - High: "No high-tier model detected; story-architect will use the main model"

##### Step 5: Write the model field

For each agent file corresponding to the user's choices (`.opencode/agents/*.md`, already deployed by the OpenCode agents step of the deployment manifest before this step), insert `model:` as a **top-level field with zero indentation** at the end of the frontmatter, before the closing `---` (do not insert it inside the indented block of a multi-line map such as `permission:`). Quote the value when it contains YAML special characters, so the frontmatter stays valid:

```yaml
---
description: ...
mode: subagent
permission:
  read: allow
  edit: deny
steps: 12
model: provider/model-id
---
```

- If the agent file already has a `model:` field (redeploy scenario), replace the value of that top-level `model:`; do not add a duplicate key
- `Keep existing model`: write back the model cached for this agent by "Preserve existing model config"
- `Skip, use main model`: do not write a `model:` field
- On detection failure/timeout or tiers that did not reach this step: backfill `model:` from the "Preserve existing model config" cache, so the replace never wipes the user's last configuration

### Step 6: Initialize the Session State

- Run `tracking_commit.py init` for a long-form book after validating the import input.
- The transaction tool generates `tracking/context.md` from the JSON authority; never create or overwrite it from a manual template.
- Short-form projects must not cause a `tracking/` directory to be created.

### Step 7: Merge Hook Registrations into settings.local.json

- Read `skills/story-setup/references/templates/settings-hooks.json`
- Read the user's project `.claude/settings.local.json` (if present)
- Merge the hook config (per the "settings-hooks.json merge algorithm")
- Write `.claude/settings.local.json`

### Codex hooks.json merge algorithm (when target_cli includes codex)

Codex project hooks deploy to `.codex/hooks.json`; the runner scripts deploy to `.codex/hooks/story_codex_hook.py`, `run-story-hook.sh`, `run-story-hook.cmd`. The JSON only locates the project root and passes the event; interpreter detection is handled uniformly by the platform launchers.

1. Locate the current story-setup skill directory, read `references/codex/hooks/hooks.json` as the single current template, and read the project's `.codex/hooks.json` (treated as an empty object when absent).
2. Probe for a usable Python per the existing cross-platform rule: `for PYBIN in python3 python py; do "$PYBIN" -c "" 2>/dev/null && break; done`; if no interpreter is available, stop — do not hand-write or simplify the JSON merge.
3. Invoke `"$PYBIN" "{story-setup skill dir}/scripts/merge-codex-hooks.py" --existing "{project}/.codex/hooks.json" --template "{story-setup skill dir}/references/codex/hooks/hooks.json" --output "{project}/.codex/hooks.json"`. The helper recognizes three managed identities — the legacy direct `story_codex_hook.py` call, the current `run-story-hook.sh`, and `run-story-hook.cmd` — removes all known managed registrations first, then appends the current template.
4. Keep the user's existing non-story-setup hooks, matcher blocks, and unknown top-level fields. Re-running must be idempotent; deduplication by the raw `command` string is forbidden — otherwise the v17 direct call would double-register with the v18 launcher.
5. After writing, parse the JSON to verify: 0 legacy direct `story_codex_hook.py` commands, each of the template's 6 registrations present exactly once, and the user's hooks and unknown top-level fields still present. Then tell the user: the project `.codex/` layer must be trusted by Codex, and non-managed command hooks additionally need review/trust in `/hooks` before they run; on Windows the `commandWindows` path is used, and the launcher locates the project `.codex/hooks/` upward from the current directory, matching the nested-directory behavior of the POSIX path.

### ZCode deployment algorithm (when target_cli includes zcode)

The first ZCode release deploys Skills, Commands, AGENTS.md, and Hooks on supported events; `.zcode/agents` and `.zcode/rules` are not deployed.

1. Copy the 13 directories under the repository's current `skills/` that contain `SKILL.md` into `.zcode/skills/{skill-name}/`; replace only these known directories and keep the user's other Skills.
2. Copy `references/zcode/commands/*.md` into `.zcode/commands/`; replace only the 13 same-named commands and keep the user's other Commands.
3. Copy `references/zcode/hooks/story_zcode_hook.js` and `references/zcode/hooks/story_hook_core.js` into `.zcode/hooks/`.
4. Read `references/zcode/config.json.patch` and the existing `.zcode/config.json` (if only a root `zcode.json` exists, still create `.zcode/config.json` to carry the oh-story project hooks; do not rewrite the root file):
   - Preserve all user unknown fields, MCP, plugins, and skills/commands disable overrides;
   - **Hooks mutual exclusion (avoid double firing)**: if this project runs through an installed oh-story plugin (marketplace install; the `hooks.json` in the repo-root `.zcode-plugin/plugin.json` already registers SessionStart/PreToolUse/PostToolUse globally), then **skip** merging the `hooks` block of `config.json.patch` into `.zcode/config.json` — the plugin manifest already registered this batch, and merging again would run every event twice (PreToolUse intercepts twice, PostToolUse injects twice). Merge hooks only when the plugin is not installed (direct clone / manually imported references). When unsure, decide by "has ZCode already registered this hook set through the plugin"; the skills/commands/hook files/AGENTS and the non-hook config fields deploy normally on both paths.
   - Merge hooks (only when the plugin is not installed): set `hooks.enabled: true`; keep the user's larger `timeoutMs` when present, otherwise take the template value; for SessionStart, PreToolUse, and PostToolUse in `hooks.events`, append deduplicated by `event + matcher + process command + args`; do not copy PreCompact, PostCompact, SessionEnd, SubagentStop, or Notification, which ZCode does not support.
5. Write `references/zcode/AGENTS.md.tmpl` into the root `AGENTS.md` per the "AGENTS.md merge strategy".
6. Write `zcode` or the multi-CLI combination into `.story-deployed`'s `target_cli`, and `.zcode/skills/story-setup/references/agent-references` into `references_dir`.
7. The installation report must state clearly: ZCode 3.3.4 does not run project/plugin custom agents, so all specialist roles go solo/direct; the system needs a working `node` command to run the project hook.

Plugin installs bypass this algorithm: the repo-root `.zcode-plugin/plugin.json` exposes the same Skills/Commands/Hooks directly. Plugin skills rank below workspace `.zcode/skills`; when both exist the project snapshot wins, and refreshing the project snapshot requires re-running `$story-setup`. **Hooks may be registered only once**: the plugin manifest and the workspace `.zcode/config.json` register the same events, so once the plugin is installed, do not merge `config.json.patch`'s hooks into `.zcode/config.json` (see the hooks mutual exclusion in step 4 of the algorithm above) or PreToolUse/PostToolUse will double-fire; when the plugin is present, the plugin manifest is the sole registration source for hooks.

### OpenClaw skills-only deployment algorithm (when target_cli includes openclaw)

OpenClaw Phase 1 deploys skills only — no OpenClaw agents/hooks/plugin.

1. Read every story skill directory under the repository's current `skills/` that contains `SKILL.md` (13 total: `browser-cdp` plus the `story*` skills).
2. Write them into the target project's `skills/{skill-name}/`, replacing only these story-setup-managed known skill directories; keep the user's other directories under `skills/`.
3. Every `SKILL.md` must satisfy the OpenClaw frontmatter constraints: `name` / `description` are single-line key-values, and `metadata` is a single-line JSON object containing `metadata.openclaw`.
4. Copy `skills/story-setup/references/openclaw/AGENTS.md.tmpl` to the project's `AGENTS.md`, merged per the "AGENTS.md merge strategy".
5. Write `openclaw` or the multi-CLI combination into `.story-deployed`'s `target_cli`; for OpenClaw, write `skills/story-setup/references/agent-references` into `references_dir`.
6. Installation-report notices: see Phase 3, step 10.

### Reasonix skills-only deployment algorithm (when target_cli includes reasonix)

Reasonix (DeepSeek-Reasonix CLI) currently deploys only skills and `AGENTS.md`, not Reasonix hooks/custom agents (without a verifiable real CLI for hook I/O contracts and subagent behavior, those are deferred to a later phase).

1. Read every story skill directory under the repository's current `skills/` that contains `SKILL.md` (13 total: `browser-cdp` plus the `story*` skills) into the target project's `skills/{skill-name}/`; replace only these story-setup-managed known skill directories and keep the user's other directories.
2. Create a relative `.agents/skills → ../skills` symlink at the project root (the skill root shared with Codex), so Reasonix's native scan of `.agents/skills` finds these skills; keep it if it already points at `skills/`, and if the path is occupied by a regular directory, do not overwrite it and note this in the installation report. On Windows without symlinks enabled, skip this step and use `reasonix plugin install` from the root `reasonix-plugin.json` instead.
3. Copy `skills/story-setup/references/reasonix/AGENTS.md.tmpl` to the project's `AGENTS.md`, merged per the "AGENTS.md merge strategy".
4. Copy `skills/story-setup/references/agent-references/` to `skills/story-setup/references/agent-references/`, so the reference paths in role instructions such as narrative-writer / story-architect resolve.
5. Write `reasonix` or the multi-CLI combination into `.story-deployed`'s `target_cli`; for Reasonix, write `skills/story-setup/references/agent-references` into `references_dir`.
6. Installation-report notices: see Phase 3, step 12.

### Generic Web AI / other agent deployment algorithm (when target_cli includes generic)

The generic path targets environments that can read project files, such as NarraFork, Web AI, and custom agents; it deploys only generic files and claims no platform-native hooks/agents capability.

1. Copy every story skill directory under the repository's current `skills/` that contains `SKILL.md` (13 total: `browser-cdp` plus the `story*` skills) into the target project's `skills/{skill-name}/`; replace only these story-setup-managed known skill directories and keep the user's other directories.
2. Copy `skills/story-setup/references/generic/AGENTS.md.tmpl` to the project's `AGENTS.md`, merged per the "AGENTS.md merge strategy".
3. Copy `skills/story-setup/references/agent-references/` to `skills/story-setup/references/agent-references/`, so the reference paths in role instructions such as narrative-writer / story-architect resolve.
4. Write `generic` or the multi-CLI combination into `.story-deployed`'s `target_cli`; for generic, write `skills/story-setup/references/agent-references` into `references_dir`.
5. Installation-report notices: see Phase 3, step 11.

### Step 8: Create the Deployment Sentinel

- Create the `.story-deployed` file (sentinel file)
- Write the following fields (YAML `key: value` format; read by hooks via `references/templates/hooks/lib/sentinel.sh`):
  ```
  deployed_at: <date -u +"%Y-%m-%dT%H:%M:%SZ">
  agents_version: 23
  setup_skill_version: 1.3.0
  target_cli: claude-code (or opencode, codex, zcode, openclaw, reasonix, generic, or any combination of them)
  resolver_strategy: project-local-skill-reference
  references_dir: .claude/skills/story-setup/references/agent-references (Codex writes .codex/skills/...; ZCode writes .zcode/skills/...; OpenClaw / Reasonix / generic write skills/...; multi-CLI uses comma separation)
  ```
- This file lets session-start.sh and the writing skills detect the deployment state and avoid repeated prompts
- When `target_cli` includes claude-code, also create the one-time marker file `.claude/.agents-pending-restart` (an empty file suffices). At the next session start, session-start.sh uses it to confirm the agents were registered with the new session and removes the marker automatically — this is how the user is confirmed that "the restart took effect". ZCode does not create this marker because it does not deploy project agents.
- If `.story-deployed` already exists but `agents_version` is missing, non-integer, or less than `23`, update the hooks/agents/rules/reference bundle per this flow (see `UPGRADING.md` for the concrete changes); if greater than `23`, Phase 1 already stopped and downgrade-overwriting is forbidden

## Phase 3: Verify the Installation

1. Verify hook registration:
   - Check the hooks fields in `.claude/settings.local.json` are correct
   - Check the scripts under `.claude/hooks/` exist and have the executable bit
   - Check `.claude/hooks/lib/common.sh` and `.claude/hooks/lib/sentinel.sh` exist
2. Verify the rules path:
   - Check the rule files under `.claude/rules/` exist and contain `paths` frontmatter
3. Verify agents:
   - Check the 7 agent definition files under `.claude/agents/` exist
4. Verify the agent reference bundle:
   - Check the reference files under `.claude/skills/story-setup/references/agent-references/` are complete
   - Check every `story-setup/references/agent-references/<file>.md` resolves into the deployed bundle
5. Verify the deployment sentinel:
   - Check `.story-deployed` exists and contains the timestamp, `agents_version: 23`, `setup_skill_version: 1.3.0`, `target_cli`, `resolver_strategy`, and `references_dir`
6. Output the installation report:
   - List every deployed file
   - List points requiring attention (e.g., existing config that was merged)
   - **Restart notice (must be prominent)**: this deployment wrote `.claude/agents/`, but these custom agents are only registered by Claude Code as `subagent_type` at **session start**. **Start a new Claude Code session before writing**; otherwise, when story-review / story-long-write in the current session try to spawn `story-architect`, `narrative-writer`, etc., they get "subagent_type unavailable" and fall back to solo (single perspective, losing multi-agent collaboration). How to confirm it took effect: run `/story-review` in the new session — a report header of `Effective Mode: full/lean` means registration succeeded; `Fallback: ... -> solo` means you are still in an old session or the agents were not registered.
   - After the restart, `/story-long-write` or `/story-short-write` are available
   - If "Configure OpenCode agent models" ran, output the agent model configuration summary:
     ```
     Agent model configuration:
       story-architect          → <high-tier model> (provider/model-id)
       narrative-writer         → <mid-tier model> (provider/model-id)
       character-designer       → <mid-tier model> (provider/model-id)
       story-researcher         → <mid-tier model> (provider/model-id)
       chapter-extractor        → <budget-tier model> (provider/model-id)
       consistency-checker      → <budget-tier model> (provider/model-id)
       story-explorer           → <budget-tier model> (provider/model-id)
     ```
   - If auto-detection failed (`opencode models` unavailable), output the manual configuration guide:
     ```
     Could not auto-detect the model list. These agents have no model configured and will use the main model, which may be more expensive:
       - chapter-extractor (a low-cost model is recommended)
       - consistency-checker (a low-cost model is recommended)
       - story-explorer (a low-cost model is recommended)

     To configure manually, edit .opencode/agents/{agent-name}.md and add to the frontmatter:
       model: provider/model-id

     List available models and costs with `opencode models --verbose` (output includes per-model cost/context).
     Model catalog and pricing: OpenCode's official model source https://models.dev/.
     ```
7. Verify the opencode deployment (only when target_cli includes opencode):
   - Check the 7 agent definition files under `.opencode/agents/` exist and their frontmatter contains `mode: subagent` and a `permission` field
   - Check `.opencode/plugins/story-hooks.ts` exists
   - Check `.opencode/plugins/lib/story_hook_core.js` exists and passes `node --check` (imported by story-hooks.ts; the shared prose-guard core, byte-identical to the `.zcode` copy; kept in the `lib/` subdirectory so it escapes OpenCode's single-level `.opencode/plugins/*.js` auto-discovery)
   - Check the 13 command files under `.opencode/commands/` exist
   - Check the reference files under `skills/story-setup/references/agent-references/` are complete and match the source directory count
   - Check the `plugin` array of `opencode.json` contains the story-hooks entry
   - Check `.git/hooks/pre-commit` exists and has the executable bit (skip the executable-bit check on Windows)
   - Verify the agent file frontmatter under `.opencode/agents/` parses as YAML and `model:` (when configured) is a valid top-level scalar, not merely a grep hit on a `model:` substring
8. Verify the Codex deployment (only when target_cli includes codex):
   - Check `AGENTS.md` contains the Codex story skill routing sections
   - Check the 7 `.toml` agent definition files under `.codex/agents/` exist and parse
   - Check `.codex/hooks.json` exists and is valid JSON; on Unix `command` runs only via `run-story-hook.sh`, on Windows `commandWindows` only via `run-story-hook.cmd`; no direct `story_codex_hook.py` registration remains
   - Check `.codex/hooks/story_codex_hook.py`, `run-story-hook.sh`, and `run-story-hook.cmd` exist, the Python syntax is valid, and the POSIX/Windows launchers can locate the project root from a nested cwd
   - Check the reference files under `.codex/skills/story-setup/references/agent-references/` are complete and match the source directory count
   - The installation report must note: Codex needs the project `.codex/` config layer trusted, and non-managed hooks reviewed/trusted in `/hooks`; start a new Codex session after deployment for custom agents to take effect; if the runtime still returns `unknown agent_type`, fall back to solo/direct per each skill's fallback rules
9. Verify the ZCode deployment (only when target_cli includes zcode):
   - Check the root `AGENTS.md` contains ZCode `$story-*` routing, the outline guard, and solo/direct fallback
   - Verify the 13 Skills under `.zcode/skills/` and 13 Commands under `.zcode/commands/`, checking frontmatter and naming
   - Check `.zcode/hooks/story_zcode_hook.js` and `.zcode/hooks/story_hook_core.js` exist and pass `node --check`
   - Check `.zcode/config.json` is valid JSON and verify per the hooks mutual-exclusion branch of step 4 of the "ZCode deployment algorithm": when the oh-story plugin is not installed, `hooks.enabled=true`, only ZCode-supported events are registered, and all `process` args point at the project hook; when the oh-story plugin is installed (`.zcode-plugin/plugin.json` registered this batch globally), instead verify `.zcode/config.json` does not contain (or has removed) this batch of oh-story hook registrations — **never** re-merge `config.json.patch`'s hooks block just to pass the check, or the same events would double-fire
   - Check `.zcode/skills/story-setup/references/agent-references/` is complete and every reference path resolves
   - Call SessionStart, PreToolUse deny/allow, and PostToolUse with fixtures, confirming stdout is empty when nothing is found and conforms to ZCode's strict JSON when there is output
   - The installation report must note: ZCode 3.3.4 does not run project/plugin custom agents, so full/lean multi-agent requests reliably degrade to solo/direct; the Hook relies on `node` in PATH; start a new ZCode session after deployment to refresh Skills/Commands/AGENTS.md
10. Verify the OpenClaw deployment (only when target_cli includes openclaw):
    - Check `AGENTS.md` contains the OpenClaw story skill routing sections
    - Check the 13 story skill directories under `skills/` exist and every `SKILL.md` has a single-line `name`, a single-line `description`, and a single-line JSON `metadata.openclaw`
    - Check the reference files under `skills/story-setup/references/agent-references/` are complete and match the source directory count
    - The installation report must note: OpenClaw Phase 1 is skills-only; no OpenClaw agents/hooks are deployed, runtime hard interception is unavailable, and the pre-prose outline guard, commit reminders, and session/compact auto-injection act only as soft constraints inside the skills; OpenClaw snapshots eligible skills at session start, so if commands/skills do not appear after deployment, start a new OpenClaw session or wait for the skills watcher to refresh
11. Verify the generic Web AI / other agent deployment (only when target_cli includes generic):
    - Check `AGENTS.md` contains the generic story skill routing sections
    - Check the 13 story skill directories under `skills/` exist and every `SKILL.md` is readable
    - Check the reference files under `skills/story-setup/references/agent-references/` are complete and match the source directory count
    - The installation report must note: generic deploys no platform-specific hooks/custom agents; hard interception such as the outline guard, commit reminders, and session/compact injection, as well as multi-agent collaboration, run as soft constraints inside the skills or as solo/direct fallbacks
12. Verify the Reasonix deployment (only when target_cli includes reasonix):
    - Check `AGENTS.md` contains the Reasonix story skill routing sections and solo/direct fallback notes
    - Check the 13 story skill directories under `skills/` exist and every `SKILL.md` is readable
    - Check the project's `.agents/skills` is a symlink to `skills/` (POSIX; lets Reasonix's native scan find the skills); on Windows without a symlink, instead confirm the root `reasonix-plugin.json` supports `reasonix plugin install`
    - Check the reference files under `skills/story-setup/references/agent-references/` are complete and match the source directory count
    - The installation report must note: Reasonix is currently skills-only; no Reasonix hooks/custom agents are deployed, so the pre-prose outline guard, commit reminders, and session/compact auto-injection act only as soft constraints inside the skills, and skills that call specialist agents run solo/direct fallback; use `reasonix doctor capabilities` to verify skill discovery, and if new skills do not show up after deployment, start a new Reasonix session or use the native plugin install from the root `reasonix-plugin.json`

---

## Template placeholders

| Placeholder | Replacement rule | Example |
|-------------|------------------|---------|
| `{ProjectName}` | the user's project name or directory name | The Way of Kings, The Shadow Guard |
| `{BookTitle}` | the book-title directory name (must match the directory) | same as `{ProjectName}`, or user-customized |
| `{TargetPlatform}` | the target publishing platform | Royal Road, Webnovel, Wattpad, Inkitt |
| `{AuthorName}` | the user's pen name or nickname | "the author" when not specified |

When replacing, strip the curly braces. If the user did not specify a project name, use the current directory name. Placeholders not specified are left untouched.

## CLAUDE.md merge strategy

When the user already has a CLAUDE.md, merge by marker/section:
1. First recognize the story-setup managed-block markers (if an older project already has markers, replace only the content inside the markers)
2. Without markers, read the user's existing CLAUDE.md and split it into a section map by `##` headings
3. Read the template CLAUDE.md.tmpl and split it the same way
4. The template's standard sections (skill routing table, file structure, collaboration rules, restoring context after compact) **overwrite** same-named user sections
5. User-only sections (custom content) are **kept** untouched
6. For unknown conflicts, use AskUserQuestion to let the user choose which version to keep

## AGENTS.md merge strategy (OpenCode / Codex / ZCode / OpenClaw / Reasonix / generic)

When the user already has an AGENTS.md, merge by marker/section:
1. First recognize the story-setup managed-block markers (if an older project already has markers, replace only the content inside the markers)
2. Without markers, read the user's existing AGENTS.md and split it into a section map by `##` headings
3. OpenCode uses `skills/story-setup/references/opencode/AGENTS.md.tmpl`; Codex uses `skills/story-setup/references/codex/AGENTS.md.tmpl`; ZCode uses `skills/story-setup/references/zcode/AGENTS.md.tmpl`; OpenClaw uses `skills/story-setup/references/openclaw/AGENTS.md.tmpl`; Reasonix uses `skills/story-setup/references/reasonix/AGENTS.md.tmpl`; generic Web AI / other agents use `skills/story-setup/references/generic/AGENTS.md.tmpl`
4. The template's standard sections (skill routing table, file structure, collaboration rules, restoring context after compact) overwrite same-named sections; user-only sections are kept
5. When multiple CLIs deploy together, keep only one copy of the generic paragraphs shared by Codex/OpenCode/ZCode/OpenClaw/Reasonix/generic; tool-specific notes are separated into subsections so they cannot overwrite each other

## settings-hooks.json merge algorithm

Hook registration merges deduplicated by the command field:
1. Read the user's existing `.claude/settings.local.json` (if present) and extract the hooks portion
2. Read the `settings-hooks.json` template and extract the hooks to register
3. For each hook event (SessionStart, PreToolUse, etc.):
   - Existing user hook commands → keep, do not add duplicates
   - New hook commands from the template → append to the corresponding event's hooks array
   - Other user-only config (permissions, env, etc.) → keep in full
4. Write the merged full settings.local.json

## Redeployment

- `.story-deployed` absent → fresh install; run all of Phase 2
- `.story-deployed` exists with `agents_version: 23` → note that it is already deployed and use AskUserQuestion to confirm whether to redeploy
- `.story-deployed` exists but `agents_version` is missing, non-integer, or less than `23` → note that an update is needed, re-run Phase 2 to overwrite the agents/hooks/rules/reference bundle, and merge CLAUDE.md / AGENTS.md / settings.local.json / .codex/hooks.json / .zcode/config.json per the merge strategies
- `.story-deployed` exists with `agents_version` greater than `23` → the current skill version is older; stop, prompt updating oh-story-claudecode first, and do not overwrite the project's newer deployment

---

## References

| File | Purpose |
|------|---------|
| references/templates/hooks/ | 8 hook script templates + `story_hook_core.js` (shared implementation of the prose guardrail net / word count / outline guard / continuity / commit detection — the same copy as OpenCode/ZCode) + `story_hook_cli.js` (the node bridge that lets bash hooks call the core) + `lib/common.sh`/`lib/sentinel.sh` (the prose fallback `check-prose-after-write.sh` is limited to PostToolUse Write/Edit; Bash prose writes via `cat>`/`tee` are covered by the Codex Stop end-of-turn git scan, while Claude/OpenCode Bash is only pre-guarded) |
| references/zcode/ | ZCode AGENTS, 13 Commands, workspace config patch, and the strict-JSON hook runner |

---

## Workflow Handoff

**Pipeline:** Deployment
**Position:** Initialization (frontmost)

| When | Jump to | Command |
|------|---------|---------|
| Deployment complete, start writing | story-long-write / story-short-write | `/story-long-write` or `/story-short-write` |
| Import an existing novel for teardown | story-import | `/story-import` |
| Needs browser login state (market scan / teardown source text) | browser-cdp | `/browser-cdp`; generic requires the platform to allow local script or browser control |

Per-CLI invocation syntax: Claude `/name`, Codex/ZCode `$name`, OpenClaw `/skill name`, Reasonix / generic name the skill directly.
