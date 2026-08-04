# scripts/ — repository development script index

These are the **guard / test / code-generation** scripts for developing this repo
(the skill toolkit itself). They are **not** skill runtime scripts — runtime
scripts live under each skill's own `scripts/` (e.g.
`story-deslop/scripts/check-ai-patterns.js`, byte-synced across skills).

- Most run automatically in CI (`.github/workflows/cross-platform.yml`). The full
  local one-shot command before committing is in [CONTRIBUTING.md](../CONTRIBUTING.md)
  under "CI checks".
- **Renaming / moving any script** requires syncing `.github/workflows/*.yml`,
  `CONTRIBUTING.md`, this file, and every sibling script that calls it (see the
  "When it runs" column for call relationships).

## Static guards (check-*)

| Script | What it checks | When it runs |
|---|---|---|
| `static-check.sh` + `static-check.py` | Structured validation of frontmatter, Markdown paths/anchors, agent references, references reachability; forbids cross-skill file references except the base component `browser-cdp` | CI |
| `skill-numbering.py check` | Workflow Step/Phase/Stage numbering policy, reference binding, SKILL.md bare-number / sub-step decimal guards | CI; after workflow-structure changes |
| `check-current-skill-contracts.sh` + `.py` + `current-contract.json` | Validates current version, Phase, schema, primary artifacts and chapter-outline contracts from the structured manifest; keeps the legacy/path guard and blocks silent fallback when primary artifacts are missing | CI |
| `check-shared-files.sh` | Runs `sync-shared-assets.py check` for runtime copies, then byte-compares every same-name shared reference across skills (with the documented intentional-divergence lists) | CI |
| `check-story-setup-deployment.sh` | story-setup deployment/runtime regression (slow, >2min) | CI |
| `check-hook-regex-sync.sh` | `detect-story-gaps.sh` foreshadow-status detection behavior + the js<->py toxic-pattern canonical-string lock | CI |
| `check-hook-locale-safety.sh` | Deployed-hook byte safety under non-UTF-8 locales (LC_ALL=C exports, no full-width chars in bracket classes) | CI |
| `check-python-invocation.sh` | Skill docs must not bare-call `python3` (probe python3→python→py instead) | CI |
| `check-claude-adapter.sh` | One-to-one Claude marketplace ↔ 13 skills mapping; optional real-CLI strict validate | CI (static); `CLAUDE_REAL_CHECK=1` (real CLI) |
| `check-opencode-adapter.sh` | OpenCode adapter sync + commands/agents/config structure + plugin behavior regression | CI + sync CI (calls sync-opencode.py) |
| `check-openclaw-skills.sh` | OpenClaw AgentSkills/frontmatter compatibility | CI |
| `check-codex-adapter.sh` | Codex adapter: repo skills symlink, agent TOML, hooks and cross-platform launcher | CI (calls generate-codex-agents.py to verify generation determinism) |
| `check-zcode-adapter.sh` | ZCode plugin/marketplace, Skills/Commands/Hooks and deployment anchors | CI |
| `check-reasonix-adapter.sh` | Reasonix plugin manifest (schema, 13 Skills, version synced with skills/story/VERSION) | CI |

## Test regressions (test-*)

| Script | What it tests | When it runs |
|---|---|---|
| `test-ai-patterns.sh` | Regression for the deterministic AI-pattern detector `check-ai-patterns.js` | CI |
| `test-degeneration.sh` | Regression for the model-degeneration detector `check-degeneration.js` | CI |
| `test-prose-net-parity.sh` | Claude/OpenCode/Codex/ZCode parity of the prose "lightweight deterministic net" | CI (calls check-hook-regex-sync) |
| `test-prose-backstop-hook.sh` | Regression for `check-prose-after-write.sh` | CI |
| `test-story-continuity.sh` | Cross-batch continuity backstop regression for `detect-story-gaps.sh` | CI |
| `test-codex-hooks.sh` | Codex hook synthetic stdin/stdout contract | CI |
| `test-static-check.py` | Real frontmatter blocks, exact path/anchor checks, cross-skill references, fences, dead references, agent & chapter link fixtures | CI |
| `test-current-skill-contracts.py` | current-contract manifest types/fixed values and primary-artifact fail-fast fixtures | CI |
| `test-shared-assets.py` | Shared-asset manifest drift, sync, path escape, single-owner basenames and unregistered duplicates | CI |
| `test-normalize-punctuation.js` | Punctuation normalizer read-only check, frontmatter/fence, CRLF, quote modes and idempotency | CI |
| `test-scan-runtime.js` | Shared CDP utility `cdp-utils.js`: copy parity, invocation builder (verbatim argv, Windows shim resolution), arg parsing, local date stamp, CLI status gating | CI |
| `test-opencode-plugin.mjs` | Executes the OpenCode TypeScript plugin directly: outline guard, Bash bypass, after-write check and compact restore | Called by `check-opencode-adapter.sh` |
| `test-codex-cli-e2e.sh` | Real Codex CLI discovery of the repo's 13 skills under an isolated HOME | CLI-compatibility CI; requires `codex` installed |
| `test-zcode-hooks.sh` | ZCode strict JSON hooks, prose guard and continuity regression | CI |
| `test-charcount-portable.sh` | Cross-platform character-count command on all three platforms + Windows stub | CI (calls check-python-invocation) |
| `test-hook-encoding-portable.sh` | Deployed-hook encoding robustness under non-UTF-8 locales with UTF-8 book names | CI |
| `test-opencode-cli-e2e.sh` | Real OpenCode CLI load smoke (repo skills discovery / 13 commands / 7 agents / plugin) | CLI-compatibility CI; requires `opencode` installed |
| `test-skill-numbering.sh` | Step renumbering cascade safety, fail-closed anchors, code-block references, zero-write/commit rollback verification, dry-run/write/idempotency | Linux / Windows Git Bash / macOS CI |

## Code generation / sync

| Script | What it does | When it runs |
|---|---|---|
| `sync-opencode.py` | Generates `opencode/agents/` and `AGENTS.md.tmpl` from the Claude agent templates + `CLAUDE.md.tmpl`; `--check` verifies sync read-only | Run manually after changing agent templates; sync CI + called by check-opencode-adapter |
| `generate-codex-agents.py` | Generates Codex `.toml` agents from the Claude agent templates | Run manually after changing agent templates; called by check-codex-adapter to verify determinism |
| `generate-codex-hooks.py` | Generates `hooks.json` from the 6-event manifest; the shared POSIX/Windows launcher handles interpreter probing | After Codex hook-registration changes; called by check-codex-adapter to verify determinism |
| `shared-assets.json` + `sync-shared-assets.py` | Names the single source and targets for duplicated runtime scripts that must deploy independently with each skill | Run `sync` after changing a shared runtime; CI runs `check` |

> After changing `skills/story-setup/references/templates/agents/*.md` or
> `CLAUDE.md.tmpl`, you must re-run both generators and commit the results, or the
> adapter CI turns red. See [CONTRIBUTING.md](../CONTRIBUTING.md) under "OpenCode
> template sync" and "Codex adapter maintenance".

## Workflow numbering maintenance

`skill-numbering.py` by default scans the canonical `skills/**/*.md` files to stop
iterative insertions from accumulating workflow numbers into fractional labels
like `Step 1.3`, `Phase 2.5`.

```bash
python3 scripts/skill-numbering.py audit          # read-only inventory; still exits 0 on findings
python3 scripts/skill-numbering.py check          # CI guard; exits non-zero on findings
python3 scripts/skill-numbering.py fix --dry-run  # preview the full diff, no writes
python3 scripts/skill-numbering.py fix --write    # write once after validation passes
bash scripts/test-skill-numbering.sh              # isolated fixture regression
```

Maintenance policy:

- Only explicit `### Step N` **Step headings** are auto-renumbered; the grouping
  key is "file + heading level + nearest parent heading", each group numbered
  consecutively from 1.
- Headings and uniquely bindable `Step N` references are renumbered together based
  on the old text, including command/example references inside fenced code
  blocks, so a `1.5 → 2` renumber is not followed by a second `2 → 3` cascade.
- When a fractional Step reference has no matching heading in the file, or one
  old label could map to several new labels, `fix` fails before any write.
  Multi-file writes are fully validated/staged first with rollback; half-applied
  results are never accepted.
- Renumbering headings changes GitHub Markdown anchors; whenever a same-file or
  cross-file link in the repo points at the old anchor, `fix` fails closed before
  writing and reports each fragment, asking you to update the links explicitly
  first. Local path patterns scan in-repo inbound links too.
- `Step N.M` / `Phase N.M` / `Stage N.M`, bare fractional headings directly in
  `skills/*/SKILL.md`, and bullet sub-step decimals are reported by `check` but
  never auto-modified by guesswork.
- `references/` handbook `3.1`-style chapter/list numbers are not workflow labels:
  not checked, not rewritten. If a pipeline ID needs an inserted middle stage, use
  a semantic name or `Stage 2A`, not a decimal.
- Pass a file or directory at the end of the command for a scoped audit, e.g.
  `... audit skills/story-cover/SKILL.md`; the default full `check` must still be
  run before merging.
