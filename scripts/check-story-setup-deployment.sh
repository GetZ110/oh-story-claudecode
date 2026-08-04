#!/bin/bash
# check-story-setup-deployment.sh — story-setup deployment/runtime regression checks
# Covers hook lib deployment, reference bundle integrity, root-aware hooks,
# short-project non-mutation, commit-hook self-gating, and deployed-behavior anchors.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/story-setup"
HOOKS_DIR="$SKILL_DIR/references/templates/hooks"
AGENT_REFS_DIR="$SKILL_DIR/references/agent-references"
SKILL_FILE="$SKILL_DIR/SKILL.md"
SETTINGS_FILE="$SKILL_DIR/references/templates/settings-hooks.json"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [ -f "$1" ] || fail "required file missing: $1"
}

assert_grep() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  grep -Eq "$pattern" "$file" || fail "$message ($file)"
}

assert_no_grep() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  if grep -Eq "$pattern" "$file"; then
    fail "$message ($file)"
  fi
}

# Probe a working python interpreter (Windows python3 may be the Store stub).
PYBIN=""
for c in python3 python py; do "$c" -c "" >/dev/null 2>&1 && { PYBIN="$c"; break; }; done

copy_hooks() {
  local root="$1"
  mkdir -p "$root/.claude"
  cp -R "$HOOKS_DIR" "$root/.claude/hooks"
  chmod +x "$root/.claude/hooks"/*.sh
}

copy_agent_refs() {
  local root="$1"
  mkdir -p "$root/.claude/skills/story-setup/references"
  cp -R "$AGENT_REFS_DIR" "$root/.claude/skills/story-setup/references/agent-references"
}

write_sentinel() {
  local root="$1"
  cat > "$root/.story-deployed" <<'SENTINEL'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 23
setup_skill_version: 1.3.0
target_cli: claude-code
resolver_strategy: project-local-skill-reference
references_dir: .claude/skills/story-setup/references/agent-references
SENTINEL
}

run_from_nested() {
  local root="$1"
  local script="$2"
  local nested="$root/nested/a/b"
  mkdir -p "$nested"
  (cd "$nested" && CLAUDE_PROJECT_DIR="$root" bash "$root/.claude/hooks/$script")
}

run_from_nested_no_project_dir() {
  local root="$1"
  local script="$2"
  local nested="$root/nested/a/b"
  mkdir -p "$nested"
  (cd "$nested" && unset CLAUDE_PROJECT_DIR && bash "$root/.claude/hooks/$script")
}

setup_git_repo() {
  local root="$1"
  git -C "$root" init -q
  git -C "$root" config user.email story-setup@example.invalid
  git -C "$root" config user.name story-setup-test
}

run_commit_hook_command() {
  local root="$1"
  local command_text="$2"
  (cd "$root" && CLAUDE_PROJECT_DIR="$root" STORY_COMMIT_COMMAND="$command_text" bash .claude/hooks/validate-story-commit.sh 2>&1 || true)
}

assert_commit_warns() {
  local root="$1"
  local command_text="$2"
  local label="$3"
  local out
  out="$(run_commit_hook_command "$root" "$command_text")"
  echo "$out" | grep -q 'Story Commit Warnings' || fail "validate-story-commit did not warn for $label: $command_text"
  echo "$out" | grep -q 'prose hardcodes character attributes' || fail "validate-story-commit did not inspect staged markdown for $label"
}

echo "Story setup deployment check"
echo "============================"
echo "Repo: $REPO_ROOT"

# TS1 — Hook dependency completeness
assert_file "$HOOKS_DIR/lib/common.sh"
assert_file "$HOOKS_DIR/lib/sentinel.sh"
runtime_artifacts="$(find "$HOOKS_DIR" -maxdepth 4 \( -path '*/.omc*' -o -name '.DS_Store' -o -name '*.tmp' -o -name '*.log' \) -print 2>/dev/null || true)"
[ -z "$runtime_artifacts" ] || fail "hook templates contain runtime artifacts that would be recursively deployed: $runtime_artifacts"
while IFS= read -r src; do
  [ -n "$src" ] || continue
  case "$src" in
    '$(dirname "$0")/'*)
      rel="${src#'$(dirname "$0")/'}"
      assert_file "$HOOKS_DIR/$rel"
      ;;
    "\$(dirname \"\$0\")/"*)
      rel="${src#"\$(dirname \"\$0\")/"}"
      assert_file "$HOOKS_DIR/$rel"
      ;;
  esac
done < <(grep -RhoE '^source[[:space:]]+"[^"]+"' "$HOOKS_DIR"/*.sh | sed -E 's/^source[[:space:]]+"//;s/"$//' | sort -u)
# The node shared core + CLI bridge: the single implementation of the prose net /
# word count / path extraction / git-commit detection / continuity, called by the
# bash hooks via `node "$(dirname "$0")/story_hook_cli.js"`. The outline-block
# decision and staged markdown warnings are NOT in the core — each end keeps its
# own implementation (Claude pure bash; codex<->core parity locked by
# test-prose-net-parity.sh Part E). These two are not source dependencies, so the
# grep above cannot see them; assert existence + syntax explicitly, otherwise the
# hooks degrade silently (with node absent the hooks exit 0 themselves and
# session-start.sh reminds once; here we validate as if the dev machine has node).
assert_file "$HOOKS_DIR/story_hook_core.js"
assert_file "$HOOKS_DIR/story_hook_cli.js"
if command -v node >/dev/null 2>&1; then
  node --check "$HOOKS_DIR/story_hook_core.js" || fail "story_hook_core.js node syntax invalid"
  node --check "$HOOKS_DIR/story_hook_cli.js" || fail "story_hook_cli.js node syntax invalid"
fi
assert_grep 'recursive' "$SKILL_FILE" "SKILL.md must require recursive hook deployment"
assert_grep 'lib/common\.sh' "$SKILL_FILE" "SKILL.md must mention hooks/lib/common.sh"
assert_grep 'lib/sentinel\.sh' "$SKILL_FILE" "SKILL.md must mention hooks/lib/sentinel.sh"
echo "  OK TS1 hook dependency completeness"

# TS1b — the SessionStart deployment self-check list must cover every hook script
# (prevents a new hook from escaping registration, #195 review). *.js files are
# enumerated too: story_hook_cli.js/story_hook_core.js are the load-bearing shared
# core — deleting them silently degrades the prose backstop/commit detection/
# continuity, so they must be on the self-check list as well.
selfcheck_line="$(grep -E 'for hook in .*; do' "$HOOKS_DIR/session-start.sh" | head -1)"
[ -n "$selfcheck_line" ] || fail "session-start.sh is missing the hook self-check for loop"
# The last hook in the list is followed by `;` rather than a space (a grep hit
# necessarily ends with `; do`), so a naive *" $base "* match would false-flag the
# already-registered final hook. Swap `;` for a space and pad both ends so the
# first and last entries hit the same case, instead of demanding a particular
# ordering.
selfcheck_tokens=" ${selfcheck_line//;/ } "
while IFS= read -r hookfile; do
  base="$(basename "$hookfile")"
  case "$selfcheck_tokens" in
    *" $base "*) : ;;
    *) fail "session-start.sh deployment self-check list misses hook: ${base} (a new hook must join that list)" ;;
  esac
done < <(find "$HOOKS_DIR" -maxdepth 1 \( -name '*.sh' -o -name '*.js' \) -type f)
echo "  OK TS1b session-start self-check lists all hook scripts and node cores"

# TS2 — Deployment checklist/manifest parseability
for header in 'Source path' 'Target path' 'Owner class' 'Merge mode' 'Validation check'; do
  assert_grep "$header" "$SKILL_FILE" "deployment manifest missing column: $header"
done
for group in 'templates/hooks/' 'templates/rules' 'templates/agents' 'agent-references' 'settings-hooks\.json' 'CLAUDE\.md' '\.story-deployed'; do
  assert_grep "$group" "$SKILL_FILE" "deployment manifest missing asset group: $group"
done
assert_file "$SKILL_DIR/references/openclaw/AGENTS.md.tmpl"
assert_file "$SKILL_DIR/references/generic/AGENTS.md.tmpl"
assert_file "$SKILL_DIR/references/reasonix/AGENTS.md.tmpl"
assert_file "$SKILL_DIR/references/zcode/AGENTS.md.tmpl"
assert_file "$SKILL_DIR/references/zcode/config.json.patch"
assert_file "$SKILL_DIR/references/zcode/hooks/hooks.json"
assert_file "$SKILL_DIR/references/zcode/hooks/story_zcode_hook.js"
assert_file "$SKILL_DIR/references/zcode/hooks/story_hook_core.js"
# OpenCode shares the same prose-guard core (byte-identity guarded by check-opencode-adapter.sh);
# it deploys alongside plugin.ts as .opencode/plugins/lib/story_hook_core.js (lib/ subdir so it
# escapes OpenCode's single-level .opencode/plugins/*.js plugin auto-discovery).
assert_file "$SKILL_DIR/references/opencode/story_hook_core.js"
assert_grep 'opencode/story_hook_core\.js' "$SKILL_FILE" "deployment manifest missing OpenCode shared prose-guard core"
assert_grep 'references/openclaw/AGENTS\.md\.tmpl' "$SKILL_FILE" "deployment manifest missing OpenClaw AGENTS template"
assert_grep 'OpenClaw skills-only|target_cli includes openclaw' "$SKILL_FILE" "story-setup must document OpenClaw skills-only deployment"
assert_grep 'references/generic/AGENTS\.md\.tmpl' "$SKILL_FILE" "deployment manifest missing generic AGENTS template"
assert_grep 'generic Web AI|target_cli includes generic' "$SKILL_FILE" "story-setup must document generic Web AI deployment"
assert_grep 'references/reasonix/AGENTS\.md\.tmpl' "$SKILL_FILE" "deployment manifest missing Reasonix AGENTS template"
assert_grep 'Reasonix skills-only|target_cli includes reasonix' "$SKILL_FILE" "story-setup must document Reasonix skills-only deployment"
assert_grep 'references/zcode/AGENTS\.md\.tmpl' "$SKILL_FILE" "deployment manifest missing ZCode AGENTS template"
assert_grep 'target_cli includes zcode|target_cli = zcode' "$SKILL_FILE" "story-setup must document ZCode deployment"
assert_grep '\.zcode/config\.json' "$SKILL_FILE" "story-setup must document ZCode config merge"
assert_grep 'do not create project custom agents|no project custom agents' "$SKILL_FILE" "story-setup must document the ZCode agent boundary"
assert_grep 'references_dir' "$SKILL_FILE" "sentinel references_dir must be documented"
assert_grep 'resolver_strategy' "$SKILL_FILE" "sentinel resolver_strategy must be documented"
assert_grep 'target_cli' "$SKILL_FILE" "sentinel target_cli must be documented"
echo "  OK TS2 deployment manifest"

# TS3 — Agent reference bundle integrity
refs_tmp="$TMP_DIR/deployed-reference-bundle"
copy_agent_refs "$refs_tmp"
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  assert_file "$AGENT_REFS_DIR/$ref"
  assert_file "$refs_tmp/.claude/skills/story-setup/references/agent-references/$ref"
done < <(grep -RhoE 'story-setup/references/agent-references/[A-Za-z0-9_-]+\.md' \
  "$SKILL_DIR/references/templates/agents" "$AGENT_REFS_DIR" "$SKILL_DIR/references/templates/rules" 2>/dev/null \
  | sed 's|.*/||' | sort -u)
echo "  OK TS3 agent reference integrity"

# TS4 — Hook root resolution from nested cwd
root="$TMP_DIR/root-aware"
mkdir -p "$root/book/tracking" "$root/book/prose" "$root/book/setting" "$root/book/outline" "$root/teardown-lib/sample"
setup_git_repo "$root"
copy_hooks "$root"
copy_agent_refs "$root"
write_sentinel "$root"
printf 'book\n' > "$root/.active-book"
cat > "$root/book/tracking/context.md" <<'CTX'
# Writing Progress
## Current Position
- Chapter: Chapter 1
CTX
touch "$root/teardown-lib/sample/_progress.md"
# Negative fixture: a finished teardown must not be reported as unfinished (raw
# counting of _progress.md would misreport it forever).
mkdir -p "$root/teardown-lib/done"
printf '# Deconstruction progress: done\n\n- Final status: completed\n- schema_version: 2\n' > "$root/teardown-lib/done/_progress.md"

out_start="$(run_from_nested "$root" session-start.sh || true)"
echo "$out_start" | grep -q 'Current Position' || fail "session-start did not resolve active book from project root"
echo "$out_start" | grep -q 'unfinished teardowns' || fail "session-start did not resolve teardown-lib from project root"
echo "$out_start" | grep -q 'has 1 unfinished teardowns' || fail "session-start counted a completed teardown as unfinished"
if echo "$out_start" | grep -q 'reference package is missing or empty'; then
  fail "session-start reported a missing reference package after deployed refs were copied"
fi

out_pre="$(run_from_nested "$root" pre-compact.sh || true)"
echo "$out_pre" | grep -q 'Writing context: book/tracking/context.md' || fail "pre-compact did not resolve context from project root"

out_post="$(run_from_nested "$root" post-compact.sh || true)"
echo "$out_post" | grep -q 'Read book/tracking/context.md' || fail "post-compact did not resolve context from project root"

out_gaps="$(run_from_nested "$root" detect-story-gaps.sh || true)"
if [ -n "$out_gaps" ] && echo "$out_gaps" | grep -q "$root/nested"; then
  fail "detect-story-gaps leaked nested cwd paths"
fi
# Same scope as session-start: unfinished must report, completed must not (both
# read teardown-lib/ themselves; each must be pinned).
echo "$out_gaps" | grep -q 'Teardown unfinished: teardown-lib/sample/_progress.md' || fail "detect-story-gaps missed the unfinished teardown"
if echo "$out_gaps" | grep -q 'teardown-lib/done/_progress.md'; then
  fail "detect-story-gaps counted a completed teardown as unfinished"
fi

fallback_root="$TMP_DIR/git-fallback"
mkdir -p "$fallback_root/book/tracking" "$fallback_root/book/prose" "$fallback_root/book/outline"
setup_git_repo "$fallback_root"
copy_hooks "$fallback_root"
copy_agent_refs "$fallback_root"
write_sentinel "$fallback_root"
printf 'book\n' > "$fallback_root/.active-book"
printf '# Writing Progress\n' > "$fallback_root/book/tracking/context.md"
out_fallback="$(run_from_nested_no_project_dir "$fallback_root" pre-compact.sh || true)"
echo "$out_fallback" | grep -q 'Writing context: book/tracking/context.md' || fail "pre-compact did not resolve context via git root fallback without CLAUDE_PROJECT_DIR"

echo "  OK TS4 hook root resolution"

# TS5 — Sentinel / broken deployment diagnostics
broken_root="$TMP_DIR/broken-libs"
mkdir -p "$broken_root"
setup_git_repo "$broken_root"
copy_hooks "$broken_root"
write_sentinel "$broken_root"
rm -f "$broken_root/.claude/hooks/lib/sentinel.sh"
broken_out="$(run_from_nested "$broken_root" session-start.sh 2>&1 || true)"
echo "$broken_out" | grep -q 'story hook library is missing' || fail "session-start did not explain missing hook libraries before sourcing"

bad_sentinel_root="$TMP_DIR/bad-sentinel"
mkdir -p "$bad_sentinel_root"
setup_git_repo "$bad_sentinel_root"
copy_hooks "$bad_sentinel_root"
cat > "$bad_sentinel_root/.story-deployed" <<'SENTINEL'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 23
setup_skill_version: 1.3.0
resolver_strategy: project-local-skill-reference
references_dir: .claude/skills/story-setup/references/agent-references
SENTINEL
bad_sentinel_out="$(run_from_nested "$bad_sentinel_root" session-start.sh 2>&1 || true)"
echo "$bad_sentinel_out" | grep -q 'missing the target_cli field' || fail "session-start did not warn for missing sentinel target_cli"
echo "$bad_sentinel_out" | grep -q 'reference package is missing or empty' || fail "session-start did not warn for missing deployed reference bundle"

stale_previous_root="$TMP_DIR/stale-previous"
mkdir -p "$stale_previous_root/.claude/skills/story-setup/references/agent-references"
setup_git_repo "$stale_previous_root"
copy_hooks "$stale_previous_root"
cat > "$stale_previous_root/.story-deployed" <<'SENTINEL'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 17
setup_skill_version: 1.2.6
target_cli: claude-code
resolver_strategy: project-local-skill-reference
references_dir: .claude/skills/story-setup/references/agent-references
SENTINEL
stale_previous_out="$(run_from_nested "$stale_previous_root" session-start.sh 2>&1 || true)"
echo "$stale_previous_out" | grep -q 'below v23' || fail "session-start did not warn for agents_version 17 under a v23 deployment"

newer_project_root="$TMP_DIR/newer-project"
mkdir -p "$newer_project_root/.claude/skills/story-setup/references/agent-references"
setup_git_repo "$newer_project_root"
copy_hooks "$newer_project_root"
cat > "$newer_project_root/.story-deployed" <<'SENTINEL'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 24
setup_skill_version: 1.3.0
target_cli: claude-code
resolver_strategy: project-local-skill-reference
references_dir: .claude/skills/story-setup/references/agent-references
SENTINEL
newer_project_out="$(run_from_nested "$newer_project_root" session-start.sh 2>&1 || true)"
echo "$newer_project_out" | grep -q 'above the v23 this hook supports' || fail "session-start did not reject agents_version 24 downgrade"
echo "$newer_project_out" | grep -q 'Don'"'"'t downgrade over it' || fail "session-start did not explain future-version safety"

mixed_version_root="$TMP_DIR/mixed-version"
mkdir -p "$mixed_version_root/.claude/skills/story-setup/references/agent-references"
setup_git_repo "$mixed_version_root"
copy_hooks "$mixed_version_root"
touch "$mixed_version_root/.claude/skills/story-setup/references/agent-references/dummy.md"
cat > "$mixed_version_root/.story-deployed" <<'SENTINEL'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 23
setup_skill_version: 1.2.6
target_cli: claude-code
resolver_strategy: project-local-skill-reference
references_dir: .claude/skills/story-setup/references/agent-references
SENTINEL
mixed_version_out="$(run_from_nested "$mixed_version_root" session-start.sh 2>&1 || true)"
# agents_version is the only runtime staleness authority; a lagging
# setup_skill_version must not trigger a redeploy nag (by design).
if echo "$mixed_version_out" | grep -q 'below v23'; then
  fail "session-start incorrectly nagged 'below v23' for a current agents_version=23 just because setup_skill_version lags"
fi
if echo "$mixed_version_out" | grep -q 'above the v23'; then
  fail "session-start incorrectly nagged 'above the v23' for a current agents_version=23 just because setup_skill_version lags"
fi

echo "  OK TS5 sentinel diagnostics"

# TS6 — Short project non-mutation
short_root="$TMP_DIR/short-project"
mkdir -p "$short_root/story"
setup_git_repo "$short_root"
copy_hooks "$short_root"
write_sentinel "$short_root"
printf 'story\n' > "$short_root/.active-book"
cat > "$short_root/story/prose.md" <<'TXT'
prose
TXT
run_from_nested "$short_root" session-end.sh >"$TMP_DIR/story-session-end.out" 2>&1 || true
[ ! -d "$short_root/story/tracking" ] || fail "session-end created tracking/ for short project without opt-in"
(cd "$short_root/nested/a/b" && CLAUDE_PROJECT_DIR="$short_root" STORY_SESSION_LOG=1 bash "$short_root/.claude/hooks/session-end.sh") >"$TMP_DIR/story-session-end-opt.out" 2>&1 || true
[ ! -d "$short_root/story/tracking" ] || fail "session-end created tracking/ for short project even with STORY_SESSION_LOG=1"
echo "  OK TS6 short project non-mutation"

# TS7 — Commit hook self-gating
commit_root="$TMP_DIR/commit-hook"
mkdir -p "$commit_root/book/prose" "$commit_root/book/setting" "$commit_root/short"
setup_git_repo "$commit_root"
copy_hooks "$commit_root"
cat > "$commit_root/book/prose/chapter_001.md" <<'TXT'
age : 18
TXT
cat > "$commit_root/short/prose.md" <<'TXT'
height: 180
TXT
cat > "$commit_root/book/setting/character.md" <<'TXT'
character bio
TXT
git -C "$commit_root" add "book/prose/chapter_001.md" "short/prose.md" "book/setting/character.md"
for cmd in \
  'git commit -m test' \
  'git -c user.name=x commit -m test' \
  "git -C $commit_root commit -m test" \
  'command git commit -m test' \
  'env X=1 git commit -m test' \
  'git add .; git commit -m test' \
  $'git add .\ngit commit -m test' \
  '(git commit -m test)' \
  'if true; then git commit -m test; fi' \
  'noglob git commit -m test'; do
  assert_commit_warns "$commit_root" "$cmd" "$cmd"
done
for cmd in 'echo git commit docs' 'grep "git commit" file'; do
  non_commit_out="$(run_commit_hook_command "$commit_root" "$cmd")"
  [ -z "$non_commit_out" ] || fail "validate-story-commit warned for non-commit command '$cmd': $non_commit_out"
done
stdin_out="$(cd "$commit_root" && unset STORY_COMMIT_COMMAND CLAUDE_TOOL_INPUT && printf '%s' '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}' | CLAUDE_PROJECT_DIR="$commit_root" bash .claude/hooks/validate-story-commit.sh 2>&1 || true)"
echo "$stdin_out" | grep -q 'Story Commit Warnings' || fail "validate-story-commit did not read stdin hook payload"
echo "$stdin_out" | grep -q 'short/prose.md' || fail "validate-story-commit did not inspect short-form prose.md"
echo "$stdin_out" | grep -q 'book/setting/character.md' || fail "validate-story-commit did not inspect staged setting markdown"

mono_root="$TMP_DIR/mono-root"
project_root="$mono_root/story-project"
mkdir -p "$project_root/book/prose"
setup_git_repo "$mono_root"
copy_hooks "$project_root"
cat > "$project_root/book/prose/chapter_001.md" <<'TXT'
height:181
TXT
git -C "$mono_root" add "story-project/book/prose/chapter_001.md"
mono_out="$(cd "$project_root" && CLAUDE_PROJECT_DIR="$project_root" STORY_COMMIT_COMMAND='git commit -m test' bash .claude/hooks/validate-story-commit.sh 2>&1 || true)"
echo "$mono_out" | grep -q 'prose hardcodes character attributes' || fail "validate-story-commit missed staged files when CLAUDE_PROJECT_DIR differs from git root"
echo "  OK TS7 commit hook self-gating"

# TS8 — detect-story-gaps multi-book traversal
multi_root="$TMP_DIR/multi-book"
mkdir -p "$multi_root/long/tracking" "$multi_root/long/prose" "$multi_root/short"
setup_git_repo "$multi_root"
copy_hooks "$multi_root"
printf 'long\n' > "$multi_root/.active-book"
printf 'long prose\n' > "$multi_root/long/prose/chapter_001.md"
printf 'short prose\n' > "$multi_root/short/prose.md"
multi_out="$(run_from_nested "$multi_root" detect-story-gaps.sh || true)"
echo "$multi_out" | grep -q '^Checked: long$' || fail "detect-story-gaps did not inspect the long project when .active-book is set"
echo "$multi_out" | grep -q '^Checked: short$' || fail "detect-story-gaps did not inspect the short project alongside the long project"
long_count="$(printf '%s\n' "$multi_out" | grep -c '^Checked: long$' || true)"
[ "$long_count" -eq 1 ] || fail "detect-story-gaps reported the long project $long_count times; expected exactly once"
echo "  OK TS8 multi-book gap detection"

# TS9 — Settings JSON remains valid
[ -n "$PYBIN" ] || fail "no python interpreter for settings JSON validation"
"$PYBIN" -m json.tool "$SETTINGS_FILE" >/dev/null
echo "  OK TS9 settings JSON"

# TS10 — Version threshold + deployed-behavior anchors
# Anchor only the things that break when running: the agents_version threshold
# must align across files, and the agent templates deployed to users must carry
# the key behavior rules. The old batch of "UPGRADING.md/README must say some
# sentence" doc-completeness assertions (red on any wording change, testing
# wording rather than behavior) was dropped along with
# check-story-long-write-contract.sh; whether a release updates UPGRADING is
# checked by the release checklist and a human, not pinned by CI.
assert_grep 'AGENTS_VERSION.*-lt 23|AGENTS_VERSION" -lt 23' "$HOOKS_DIR/session-start.sh" "session-start must warn for agents_version 22 under a v23 deployment"
assert_grep 'AGENTS_VERSION.*-gt 23|AGENTS_VERSION" -gt 23' "$HOOKS_DIR/session-start.sh" "session-start must reject an agents_version 24 downgrade"
assert_grep 'agents_version.*less than `23`|less than .23' "$SKILL_DIR/SKILL.md" "story-setup redeploy branch must treat agents_version 22 as stale"
assert_grep 'agents_version.*greater than `23`' "$SKILL_DIR/SKILL.md" "story-setup must stop before downgrading a newer deployment"
assert_grep 'agents_version.*less than `22`|less than .22' "$REPO_ROOT/skills/story-review/SKILL.md" "story-review must treat agents_version 21 as stale"
assert_grep 'agents_version.*greater than `22`' "$REPO_ROOT/skills/story-review/SKILL.md" "story-review must not run old contracts against a newer deployment"
assert_grep '^version:[[:space:]]*1\.3\.0$' "$SKILL_FILE" "story-setup frontmatter must match the deployed setup version"
assert_grep 'plot/emotional-beats\.md.*missing_primary_contract|missing_primary_contract.*plot/emotional-beats\.md' "$SKILL_DIR/references/templates/agents/story-explorer.md" "story-explorer must require the current emotion-module artifact"
assert_grep 'plot/pacing\.md.*missing_primary_contract|missing_primary_contract.*plot/pacing\.md' "$SKILL_DIR/references/templates/agents/story-explorer.md" "story-explorer must require the current rhythm artifact"
assert_no_grep 'legacy_deconstruction|contract_version.*legacy|pre-v12' "$SKILL_DIR/references/templates/agents/story-explorer.md" "story-explorer must not keep legacy benchmark branches"
assert_grep 'missing_primary_contract: true|missing_primary_contract": true' "$SKILL_DIR/references/templates/agents/story-explorer.md" "story-explorer must emit missing_primary_contract for broken canonical artifacts"
assert_grep 'repair_action.*Stage 3|Stage 3.*repair_action|re-run /story-long-analyze Stage 3' "$SKILL_DIR/references/templates/agents/story-explorer.md" "story-explorer must provide a repair action instead of silent fallback"
assert_grep 'missing_primary_contract' "$REPO_ROOT/skills/story-long-write/SKILL.md" "story-long-write must not silently fall back for missing primary artifacts"
assert_grep 'Content summary (five-part)|Plot arrangement (multi-line)|Characters and appearance order|Ending and hook' "$SKILL_DIR/references/templates/agents/story-architect.md" "story-architect must output the current chapter blueprint fields"
assert_grep 'Logic line|Relationship changes|Action cost (optional)/benefit recipient|Ending design' "$SKILL_DIR/references/templates/agents/consistency-checker.md" "consistency-checker must consume current outline blueprint fields"
assert_grep 'tone-punctuation spectrum|tone/character voice' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must enforce the current tone-punctuation rules"
assert_grep '……' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must reject ellipsis pause punctuation"
assert_grep '——' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must reject the dialogue dash exception"
assert_grep 'Punctuation tone spectrum|tone/character voice' "$AGENT_REFS_DIR/format-and-structure.md" "agent references must include the current tone-punctuation format rules"
assert_grep '……' "$AGENT_REFS_DIR/format-and-structure.md" "agent references must forbid ellipsis pause punctuation"
assert_grep '——' "$AGENT_REFS_DIR/format-and-structure.md" "agent references must forbid the dialogue dash exception"
assert_grep 'negate-then-affirm' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must hard-ban negate-then-affirm flips"
assert_grep 'check-ai-patterns\.js --check' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must require the detector rescan handoff"
assert_grep 'bare invocation.*do not auto-enter prose|do not auto-enter prose writing.*bare invocation|do not default an existing project to 3 chapters a day' "$REPO_ROOT/skills/story-long-write/SKILL.md" "story-long-write bare invocation must not auto-write prose"
assert_grep 'default stop after outlines, do not auto-write prose|default stop after outlines' "$REPO_ROOT/skills/story-long-write/SKILL.md" "story-long-write opening flow must stop after outlines by default"
assert_grep 'Bare invocation does not enter daily|cap each round at 3 chapters' "$REPO_ROOT/skills/story-long-write/references/workflow-daily.md" "daily workflow must not auto-enter and must stop after a bounded batch"
assert_grep 'outline_underfilled|may not invent plot|outline boundary' "$SKILL_DIR/references/templates/agents/narrative-writer.md" "narrative-writer must enforce the outline boundary and report outline_underfilled"
assert_grep 'outline_underfilled' "$SKILL_DIR/references/opencode/agents/narrative-writer.md" "opencode narrative-writer must inherit the outline_underfilled boundary"
assert_grep 'outline_underfilled' "$SKILL_DIR/references/codex/agents/narrative-writer.toml" "codex narrative-writer must inherit the outline_underfilled boundary"
assert_grep 'import-and-continue entry order|Recommended order' "$REPO_ROOT/skills/story-import/SKILL.md" "story-import must answer the setup-vs-import order before asking for source"
echo "  OK TS10 version + behavior anchors"

# TS11 — Outline-before-prose write guard (BLOCKING PreToolUse hook)
guard_root="$TMP_DIR/outline-guard"
mkdir -p "$guard_root/book/prose" "$guard_root/book/outline" "$guard_root/book/setting" \
         "$guard_root/short" "$guard_root/docs" \
         "$guard_root/impbook/prose" "$guard_root/teardown-lib/impbook" \
         "$guard_root/impshort" "$guard_root/teardown-lib/impshort"
setup_git_repo "$guard_root"
copy_hooks "$guard_root"
assert_file "$guard_root/.claude/hooks/guard-outline-before-prose.sh"

run_guard() {
  # $1 = file_path ; prints the hook exit code (0 allow, 2 block)
  local fp="$1" ec=0
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$fp" \
    | CLAUDE_PROJECT_DIR="$guard_root" bash "$guard_root/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?
  printf '%s' "$ec"
}

# Long-form authorization flow: block on a missing chapter outline / allow with
# one present / tolerate chapter-number zero padding
[ "$(run_guard 'book/prose/chapter_001_beginning.md')" = "2" ] || fail "guard did not BLOCK long prose when the chapter outline is missing"
: > "$guard_root/book/outline/outline_chapter_1.md"
[ "$(run_guard 'book/prose/chapter_001_beginning.md')" = "0" ] || fail "guard wrongly blocked long prose when the chapter outline is present"
[ "$(run_guard 'book/prose/chapter_001_beginning.md')" = "0" ] || fail "guard did not tolerate chapter-number zero padding (chapter_001 vs outline_chapter_1)"
: > "$guard_root/book/outline/outline_chapter_7_storm.md"
[ "$(run_guard 'book/prose/chapter_007_x.md')" = "0" ] || fail "guard did not tolerate a title-suffixed outline (outline_chapter_7_storm.md)"
# Short-form authorization flow: setting.md signal + missing section-outline -> block;
# section-outline present -> allow
: > "$guard_root/short/setting.md"
[ "$(run_guard 'short/prose.md')" = "2" ] || fail "guard did not BLOCK short prose when section-outline.md is missing"
: > "$guard_root/short/section-outline.md"
[ "$(run_guard 'short/prose.md')" = "0" ] || fail "guard wrongly blocked short prose when section-outline.md is present"
# Non-work files / no short-project signal -> allow (miss over false-hit)
[ "$(run_guard 'book/setting/character.md')" = "0" ] || fail "guard wrongly blocked a non-prose file"
[ "$(run_guard 'docs/prose.md')" = "0" ] || fail "guard wrongly blocked a non-story prose.md (no setting.md signal)"
# Existing prose -> allow (continuation/rewrite/de-AI pass)
: > "$guard_root/book/prose/chapter_009_x.md"
[ "$(run_guard 'book/prose/chapter_009_x.md')" = "0" ] || fail "guard wrongly blocked the rewrite of an existing prose file"
# story-import migration flow: teardown-lib/{book}/ source present -> prose may
# migrate before the outline/section-outline exists
[ "$(run_guard 'impbook/prose/chapter_001_x.md')" = "0" ] || fail "guard wrongly blocked story-import LONG prose migration (teardown-lib source present)"
: > "$guard_root/impshort/setting.md"
[ "$(run_guard 'impshort/prose.md')" = "0" ] || fail "guard wrongly blocked story-import SHORT prose migration (teardown-lib source present)"
echo "  OK TS11 outline-before-prose guard"

# TS11b — the blocking guard must fall back to pure bash and still exit 2 when
# node is unavailable (must not fail open). The official install now recommends
# the native Claude Code binary (no Node); only the npm install ships node. The
# old implementation probed node and passed on missing, silently letting
# "write prose with no outline" through (#243 regression). Use a fake node shim
# that always exits non-zero to simulate "node unavailable", keeping the rest of
# the tools (sed/grep/bash) on PATH. If the shim cannot shadow the real node
# (some Windows hosts), skip to avoid an environment-caused false failure.
nonode_shim="$TMP_DIR/nonode-shim"
mkdir -p "$nonode_shim"
printf '#!/bin/sh\nexit 1\n' > "$nonode_shim/node"
chmod +x "$nonode_shim/node"
run_guard_nonode() {
  local fp="$1" ec=0
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$fp" \
    | CLAUDE_PROJECT_DIR="$guard_root" PATH="$nonode_shim:$PATH" \
      bash "$guard_root/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?
  printf '%s' "$ec"
}
if ! PATH="$nonode_shim:$PATH" node -e "" >/dev/null 2>&1; then
  # Missing outline -> still blocked (the bash fallback parses the target path and exits 2)
  [ "$(run_guard_nonode 'book/prose/chapter_123_no_guide.md')" = "2" ] \
    || fail "guard fail-OPEN without node (regression #243): missing outline must still block (bash fallback)"
  : > "$guard_root/book/outline/outline_chapter_123.md"
  # Outline present -> allow (the bash fallback must not false-hit)
  [ "$(run_guard_nonode 'book/prose/chapter_123_no_guide.md')" = "0" ] \
    || fail "guard(no-node) wrongly blocked long prose when the outline is present (bash fallback)"
  # Non-prose target -> allow
  [ "$(run_guard_nonode 'book/setting/character.md')" = "0" ] \
    || fail "guard(no-node) wrongly blocked a non-prose file (bash fallback)"
  echo "  OK TS11b outline guard fail-closed without node"
else
  echo "  SKIP TS11b (fake node shim could not shadow the real node; skipping the no-node regression)"
fi

# TS11c — when node exists but extraction fails (an old node without node:
# prefix support, or a corrupted deployed core that passes the probe and then
# throws), the blocking guard must fall back to pure bash and still exit 2. The
# old implementation used if/else: once the node probe passed it only ran the
# node branch, and an empty extraction passed — the second fail-open face found
# in the #243 review. The shim "node -e '' exits 0, running a real script exits
# non-zero" simulates a broken node; only run when the resolved node IS the shim
# (otherwise the real node would let the assertion pass for the wrong reason).
brokennode_shim="$TMP_DIR/brokennode-shim"
mkdir -p "$brokennode_shim"
printf '#!/bin/sh\n[ "$1" = "-e" ] && exit 0\nexit 1\n' > "$brokennode_shim/node"
chmod +x "$brokennode_shim/node"
run_guard_brokennode() {
  local fp="$1" ec=0
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$fp" \
    | CLAUDE_PROJECT_DIR="$guard_root" PATH="$brokennode_shim:$PATH" \
      bash "$guard_root/.claude/hooks/guard-outline-before-prose.sh" >/dev/null 2>&1 || ec=$?
  printf '%s' "$ec"
}
resolved_node="$(PATH="$brokennode_shim:$PATH" bash -c 'command -v node' 2>/dev/null || true)"
if [ "$resolved_node" = "$brokennode_shim/node" ]; then
  # The node probe passes but CLI extraction throws -> missing outline must still
  # block (the bash fallback parses the target path)
  [ "$(run_guard_brokennode 'book/prose/chapter_124_bad_node.md')" = "2" ] \
    || fail "guard fail-OPEN with broken node (regression #243): node present but extraction fails must fall back to bash and still block"
  : > "$guard_root/book/outline/outline_chapter_124.md"
  # Outline present -> allow (the bash fallback must not false-hit)
  [ "$(run_guard_brokennode 'book/prose/chapter_124_bad_node.md')" = "0" ] \
    || fail "guard(broken-node) wrongly blocked long prose when the outline is present (bash fallback)"
  echo "  OK TS11c outline guard fail-closed when node present-but-broken"
else
  echo "  SKIP TS11c (fake node shim could not shadow the real node; skipping the broken-node regression)"
fi

# TS12 — Agents-pending-restart one-shot confirmation
restart_root="$TMP_DIR/restart-flag"
mkdir -p "$restart_root/.claude"
setup_git_repo "$restart_root"
copy_hooks "$restart_root"
copy_agent_refs "$restart_root"
write_sentinel "$restart_root"
touch "$restart_root/.claude/.agents-pending-restart"
restart_out="$(run_from_nested "$restart_root" session-start.sh || true)"
echo "$restart_out" | grep -q 'are now registered' || fail "session-start did not confirm agents registered after the restart flag"
[ ! -f "$restart_root/.claude/.agents-pending-restart" ] || fail "session-start did not clear the one-shot .agents-pending-restart flag"
echo "  OK TS12 restart-flag confirmation"

echo ""
echo "OK: story-setup deployment checks passed"
