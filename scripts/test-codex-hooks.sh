#!/usr/bin/env bash
# test-codex-hooks.sh — synthetic Codex hook contract tests.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# Probe a working python interpreter (Windows python3 may be the Store stub).
PYBIN=""
for c in python3 python py; do "$c" -c "" >/dev/null 2>&1 && { PYBIN="$c"; break; }; done
[ -z "$PYBIN" ] && { echo "test-codex-hooks: no python interpreter, skipped."; exit 0; }

HOOKS_SRC="$REPO_ROOT/skills/story-setup/references/codex/hooks"
HOOK_SRC="$HOOKS_SRC/story_codex_hook.py"
ROOT="$TMP_DIR/story-project"
HOOK="$ROOT/.codex/hooks/story_codex_hook.py"
mkdir -p "$ROOT/.codex/hooks"
cp "$HOOK_SRC" "$HOOK"
cp "$HOOKS_SRC/run-story-hook.sh" "$HOOKS_SRC/run-story-hook.cmd" "$ROOT/.codex/hooks/"
chmod +x "$HOOK"

git -C "$ROOT" init -q
git -C "$ROOT" config user.email codex-hook@example.invalid
git -C "$ROOT" config user.name codex-hook-test

run_hook() {
  local event="$1" payload="$2"
  (cd "$ROOT" && printf '%s' "$payload" | CODEX_PROJECT_DIR="$ROOT" "$PYBIN" "$HOOK" "$event")
}

# Read the hook's stdout as UTF-8 bytes (not locale-decoded text): the hook emits
# UTF-8 deny reasons, and Windows Python defaults stdin to the ANSI code page,
# which would raise UnicodeDecodeError here even when the hook output is correct.
assert_json() {
  "$PYBIN" -c 'import json,sys; json.loads(sys.stdin.buffer.read().decode("utf-8"))' >/dev/null
}

assert_denied() {
  local out="$1" label="$2"
  printf '%s' "$out" | assert_json || fail "$label did not emit valid JSON: $out"
  printf '%s' "$out" | "$PYBIN" -c 'import json,sys; o=json.loads(sys.stdin.buffer.read().decode("utf-8")); h=o.get("hookSpecificOutput",{}); assert h.get("hookEventName")=="PreToolUse" and h.get("permissionDecision")=="deny" and h.get("permissionDecisionReason")' || fail "$label was not denied: $out"
}

assert_additional_context() {
  local out="$1" label="$2"
  printf '%s' "$out" | assert_json || fail "$label did not emit valid JSON: $out"
  printf '%s' "$out" | "$PYBIN" -c 'import json,sys; o=json.loads(sys.stdin.buffer.read().decode("utf-8")); h=o.get("hookSpecificOutput",{}); assert h.get("additionalContext")' || fail "$label missing additionalContext: $out"
}

assert_empty() {
  local out="$1" label="$2"
  [ -z "$out" ] || fail "$label expected empty allow output, got: $out"
}

echo "Codex hook synthetic tests"
echo "=========================="
echo "Fixture: $ROOT"

mkdir -p "$ROOT/book/prose" "$ROOT/book/outline" "$ROOT/book/setting"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"cat > book/prose/chapter_001_beginning.md <<EOF\nprose\nEOF"}}')"
assert_denied "$out" "long prose without outline"
: > "$ROOT/book/outline/outline_chapter_001.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"cat > book/prose/chapter_001_beginning.md <<EOF\nprose\nEOF"}}')"
assert_empty "$out" "long prose with outline"

mkdir -p "$ROOT/bare/prose" "$ROOT/cwd-book/prose" "$ROOT/cwd-book/outline"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"bare/prose/chapter_001_first.md"}}')"
assert_denied "$out" "bare long project without scaffolding"
relative_payload="$("$PYBIN" - "$ROOT/cwd-book" <<'PY'
import json, sys
from pathlib import Path
payload = {"cwd": str(Path(sys.argv[1]).resolve()), "tool_name": "Write", "tool_input": {"file_path": "prose/chapter_008_relative.md"}}
sys.stdout.buffer.write(json.dumps(payload, ensure_ascii=False).encode("utf-8"))
PY
)"
out="$(run_hook pre-tool-prose-guard "$relative_payload")"
assert_denied "$out" "relative prose target from hook cwd"
printf '%s' "$out" | grep -q 'cwd-book/outline' || fail "relative target was not resolved from hook cwd: $out"
: > "$ROOT/cwd-book/outline/outline_chapter_008.md"
out="$(run_hook pre-tool-prose-guard "$relative_payload")"
assert_empty "$out" "relative prose target with cwd-local outline"

out="$(run_hook pre-tool-prose-guard '{"tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Add File: book/prose/chapter_002_new_game.md\n+prose\n*** End Patch\n"}}')"
assert_denied "$out" "apply_patch long prose without outline"
: > "$ROOT/book/prose/chapter_009_existing.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_009_existing.md","content":"rewrite"}}')"
assert_empty "$out" "existing prose rewrite"

mkdir -p "$ROOT/short"
: > "$ROOT/short/setting.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"short/prose.md","content":"prose"}}')"
assert_denied "$out" "short prose without outline"
: > "$ROOT/short/section-outline.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"short/prose.md","content":"prose"}}')"
assert_empty "$out" "short prose with outline"

mkdir -p "$ROOT/impbook/prose" "$ROOT/teardown-lib/impbook"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"impbook/prose/chapter_001_import.md","content":"prose"}}')"
assert_empty "$out" "story-import long migration"

echo "  OK outline-before-prose guard"

# A Bash command that only MENTIONS a prose path (grep / echo arg / doc) must not be treated
# as a write target; only real write ops (redirection / tee / touch / cp|mv dest) count.
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"grep -n book/prose/chapter_007_x.md notes.md"}}')"
assert_empty "$out" "command merely mentioning prose path is not denied"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"echo book/prose/chapter_007_x.md >> changelog.md"}}')"
assert_empty "$out" "prose path as echo arg before non-prose redirect is not denied"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"echo x | tee book/prose/chapter_007_x.md"}}')"
assert_denied "$out" "tee write to prose without outline is still denied"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"touch book/prose/chapter_007_x.md"}}')"
assert_denied "$out" "touch write to prose without outline is denied"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"cp draft.md book/prose/chapter_007_x.md"}}')"
assert_denied "$out" "cp write to prose without outline is denied"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"cp draft.md book/prose/chapter_007_x.md 2>/dev/null"}}')"
assert_denied "$out" "cp write with trailing redirect is denied (dest still parsed)"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"cp book/prose/chapter_001_beginning.md backup.md"}}')"
assert_empty "$out" "cp FROM a prose file (source, not dest) is not denied"

echo "  OK prose command-scan precision"

cat > "$ROOT/book/prose/chapter_001_attribute.md" <<'TXT'
age: 18
TXT
cat > "$ROOT/short/prose.md" <<'TXT'
height: 180
TXT
git -C "$ROOT" add book/prose/chapter_001_attribute.md short/prose.md
out="$(run_hook pre-tool-commit-advisory '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"}}')"
assert_additional_context "$out" "commit advisory"
echo "$out" | grep -q 'prose hardcodes character attributes' || fail "commit advisory did not inspect staged markdown"
echo "$out" | grep -q 'short/prose.md' || fail "commit advisory missed short prose"
out="$(run_hook pre-tool-commit-advisory '{"tool_name":"Bash","tool_input":{"command":"echo git commit docs"}}')"
assert_empty "$out" "non-commit bash command"

echo "  OK commit advisory"

mkdir -p "$ROOT/book/tracking"
cat > "$ROOT/.story-deployed" <<'TXT'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 23
setup_skill_version: 1.3.0
target_cli: codex
resolver_strategy: project-local-skill-reference
references_dir: .codex/skills/story-setup/references/agent-references
TXT
printf 'book\n' > "$ROOT/.active-book"
printf '# Context\n' > "$ROOT/book/tracking/context.md"
out="$(run_hook session-start '{"hook_event_name":"SessionStart"}')"
assert_additional_context "$out" "session-start context"
echo "$out" | grep -q 'Active book' || fail "session-start did not mention active book"
out="$(run_hook pre-compact '{"hook_event_name":"PreCompact"}')"
printf '%s' "$out" | assert_json || fail "pre-compact invalid JSON: $out"
echo "$out" | grep -q 'Story Compact Summary' || fail "pre-compact missing summary"
out="$(run_hook post-compact '{"hook_event_name":"PostCompact"}')"
printf '%s' "$out" | assert_json || fail "post-compact invalid JSON: $out"
out="$(run_hook stop '{"hook_event_name":"Stop"}')"
printf '%s' "$out" | assert_json || fail "stop invalid JSON: $out"

echo "  OK session/compact/stop JSON"

# ── Stop content sweep: Codex has no PostToolUse; hard signals are rescanned on
# this turn's git-changed prose at the Stop event. A newly written chapter with
# truncation, left as a git change (untracked) → stop must name it and flag the
# truncation; unchanged files must not be rescanned.
PAD6='Jiang Chen clenched his fists and walked slowly toward the door, weighing every move. '  # bash string padding, no python stdout involved
printf '# Chapter 6\n\n%s\nHe rushed forward and swung at' "$PAD6$PAD6$PAD6$PAD6$PAD6$PAD6" > "$ROOT/book/prose/chapter_006_truncated.md"
out="$(run_hook stop '{"hook_event_name":"Stop"}')"
printf '%s' "$out" | assert_json || fail "stop content-sweep invalid JSON: $out"
echo "$out" | grep -q 'suspected truncation' || fail "stop did not flag truncated git-changed prose: $out"
echo "$out" | grep -q 'chapter_006_truncated.md' || fail "stop did not name the changed prose file: $out"
# Already committed (no git change) chapters must not be rescanned — only this
# turn's change set is swept.
git -C "$ROOT" add -A && git -C "$ROOT" commit -qm wip >/dev/null 2>&1
out="$(run_hook stop '{"hook_event_name":"Stop"}')"
printf '%s' "$out" | "$PYBIN" -c 'import json,sys; o=json.loads(sys.stdin.buffer.read().decode("utf-8")); assert "suspected truncation" not in o.get("systemMessage","")' || fail "stop re-flagged already-committed prose: $out"
echo "  OK stop content sweep (git-changed only)"

# ── SessionStart continuity: tracking staleness (chapters written but context.md
# not updated) + duplicate chapter titles ──
mkdir -p "$ROOT/contbook/prose" "$ROOT/contbook/tracking"
printf 'old context\n' > "$ROOT/contbook/tracking/context.md"
sleep 1
printf '# Chapter 1 Final Battle\nprose.\n' > "$ROOT/contbook/prose/chapter_001_final_battle.md"
printf '# Chapter 2 Final Battle\nprose.\n' > "$ROOT/contbook/prose/chapter_002_final_battle.md"
out="$(run_hook session-start '{"hook_event_name":"SessionStart"}')"
assert_additional_context "$out" "session-start continuity"
echo "$out" | grep -q 'prose is ahead of tracking' || fail "session-start missed tracking staleness: $out"
echo "$out" | grep -q 'share the title' || fail "session-start missed dup-title: $out"
echo "  OK session-start continuity (tracking staleness + dup-title)"

nested="$ROOT/nested/a/b"
mkdir -p "$nested"
out="$(cd "$TMP_DIR" && printf '{"cwd":"%s","tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_003_nested.md","content":"prose"}}' "$nested" | "$PYBIN" "$HOOK" pre-tool-prose-guard)"
assert_denied "$out" "cwd-based root resolution"

echo "  OK cwd-based root resolution"

# __file__ self-location (the Windows-critical resolver) on ALL platforms: with a bogus
# CODEX_PROJECT_DIR (env skipped) and an unrelated cwd, the hook must resolve root from its own
# .codex/hooks/ location. Discriminating: the chapter outline exists at the true root, so a
# wrong root → deny; only __file__-derived root → allow. (The valid-env tests above let env
# win and never hit this.)
: > "$ROOT/book/outline/outline_chapter_008.md"
out="$(cd "$TMP_DIR" && CODEX_PROJECT_DIR="$TMP_DIR/does-not-exist" "$PYBIN" "$HOOK" pre-tool-prose-guard <<'JSON'
{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_008_x.md","content":"x"}}
JSON
)"
assert_empty "$out" "__file__ self-location resolves root when env is bogus and cwd unrelated"
rm -f "$ROOT/book/outline/outline_chapter_008.md"

echo "  OK __file__ self-location (all platforms)"

NON_GIT="$TMP_DIR/non-git-story-project"
NON_GIT_HOOK="$NON_GIT/.codex/hooks/story_codex_hook.py"
mkdir -p "$NON_GIT/.codex/hooks" "$NON_GIT/book/prose" "$NON_GIT/book/outline" "$NON_GIT/nested/a/b"
cp "$HOOK_SRC" "$NON_GIT_HOOK"
cp "$HOOKS_SRC/run-story-hook.sh" "$HOOKS_SRC/run-story-hook.cmd" "$NON_GIT/.codex/hooks/"
cp "$REPO_ROOT/skills/story-setup/references/codex/hooks/hooks.json" "$NON_GIT/.codex/hooks.json"
launcher_cmd="$(
  NON_GIT="$NON_GIT" "$PYBIN" - <<'PY'
import json, os
from pathlib import Path
hooks = json.loads((Path(os.environ["NON_GIT"]) / ".codex/hooks.json").read_text(encoding="utf-8"))
print(hooks["hooks"]["PreToolUse"][0]["hooks"][0]["command"])
PY
)"
out="$(
  cd "$NON_GIT/nested/a/b"
  printf '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_004_ng.md","content":"prose"}}' | eval "$launcher_cmd"
)"
assert_denied "$out" "non-git deployment launcher root search"

echo "  OK non-git deployment launcher root search"

# Root propagation: non-git project, outline PRESENT at the true root, triggered from a nested
# cwd → must ALLOW. The launcher resolves the root in shell; it must reach the Python hook
# (via CODEX_PROJECT_DIR and/or the hook self-locating from __file__) instead of Python falling
# back to the nested cwd and wrongly denying. This case also exercises Windows (Git Bash MSYS
# path passed to native Python), which is exactly where naive env/cwd propagation breaks.
: > "$NON_GIT/book/outline/outline_chapter_004.md"
out="$(cd "$NON_GIT/nested/a/b"; unset CODEX_PROJECT_DIR CLAUDE_PROJECT_DIR; printf '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_004_ng.md","content":"prose"}}' | eval "$launcher_cmd")"
assert_empty "$out" "non-git nested cwd + outline present allows (root reaches Python hook)"
rm -f "$NON_GIT/book/outline/outline_chapter_004.md"

echo "  OK non-git nested root propagation"

case "$(uname -s 2>/dev/null || true)" in
  MINGW*|MSYS*|CYGWIN*)
    NON_GIT="$NON_GIT" "$PYBIN" - <<'PY'
import json
import os
import subprocess
from pathlib import Path

root = Path(os.environ["NON_GIT"])
hooks = json.loads((root / ".codex/hooks.json").read_text(encoding="utf-8"))["hooks"]
command = hooks["PreToolUse"][0]["hooks"][0]["commandWindows"]
# bytes literals must be ASCII (b'\u4e2d\u6587' is a SyntaxError); build the str, then encode to UTF-8.
payload = '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_004_ng.md","content":"prose"}}'.encode("utf-8")
completed = subprocess.run(
    command,
    cwd=root / "nested/a/b",
    input=payload,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    shell=True,
    timeout=20,
)
assert completed.returncode == 0, completed.stderr.decode("utf-8", "replace")
output = completed.stdout.decode("utf-8")
data = json.loads(output)
specific = data.get("hookSpecificOutput", {})
assert specific.get("permissionDecision") == "deny", output
PY
    echo "  OK commandWindows nested root + interpreter launcher"
    ;;
esac

# Missing deployment: a cwd whose ancestors have no .codex/hooks/story_codex_hook.py → the
# launcher must no-op (exit 0) silently, NOT run "//.codex/hooks/story_codex_hook.py" (which
# happens if it treats "/" as the project root after an exhausted upward search).
NO_DEPLOY="$TMP_DIR/no-deploy/x/y"
mkdir -p "$NO_DEPLOY"
out="$(cd "$NO_DEPLOY"; unset CODEX_PROJECT_DIR CLAUDE_PROJECT_DIR; printf '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_001_beginning.md","content":"prose"}}' | eval "$launcher_cmd" 2>&1)"
assert_empty "$out" "missing deployment launcher no-ops silently"
case "$out" in *//.codex*) fail "launcher executed //.codex/... on missing deployment: $out";; esac

echo "  OK missing-deployment launcher no-op"
echo ""
echo "OK: Codex hook synthetic tests passed"
