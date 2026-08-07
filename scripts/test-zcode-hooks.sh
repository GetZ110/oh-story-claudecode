#!/usr/bin/env bash
# Synthetic tests for the ZCode 3.3.4 strict hook contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

# Probe a working python interpreter (Windows python3 may be the Store stub).
PYBIN=""
for c in python3 python py; do "$c" -c "" >/dev/null 2>&1 && { PYBIN="$c"; break; }; done
[ -z "$PYBIN" ] && { echo "test-zcode-hooks: no python interpreter, skipped."; exit 0; }

SOURCE="$REPO_ROOT/skills/story-setup/references/zcode/hooks/story_zcode_hook.js"
SOURCE_CORE="$REPO_ROOT/skills/story-setup/references/zcode/hooks/story_hook_core.js"
ROOT="$TMP_DIR/project"
HOOK="$ROOT/.zcode/hooks/story_zcode_hook.js"
mkdir -p "$ROOT/.zcode/hooks"
cp "$SOURCE" "$HOOK"
cp "$SOURCE_CORE" "$ROOT/.zcode/hooks/story_hook_core.js"

run_hook() {
  local event="$1" payload="$2"
  (cd "$ROOT" && printf '%s' "$payload" | ZCODE_PROJECT_DIR="$ROOT" node "$HOOK" "$event")
}

assert_empty() {
  [ -z "$1" ] || fail "$2 expected empty stdout, got: $1"
}

assert_contract() {
  local output="$1" event="$2" label="$3"
  printf '%s' "$output" | "$PYBIN" -c '
import json, sys
obj = json.loads(sys.stdin.buffer.read().decode("utf-8"))
assert set(obj) == {"hookSpecificOutput"}, obj
specific = obj["hookSpecificOutput"]
allowed = {"hookEventName", "additionalContext"}
if sys.argv[1] == "PreToolUse":
    allowed |= {"permissionDecision", "permissionDecisionReason", "updatedInput"}
assert set(specific) <= allowed, specific
assert specific["hookEventName"] == sys.argv[1], specific
' "$event" || fail "$label violates strict ZCode output contract: $output"
}

assert_denied() {
  assert_contract "$1" PreToolUse "$2"
  printf '%s' "$1" | "$PYBIN" -c 'import json,sys; x=json.load(sys.stdin)["hookSpecificOutput"]; assert x["permissionDecision"]=="deny" and x["permissionDecisionReason"]' \
    || fail "$2 did not deny"
}

echo "ZCode hook synthetic tests"
echo "=========================="
echo "Fixture: $ROOT"

mkdir -p "$ROOT/book/prose" "$ROOT/book/outline" "$ROOT/book/setting"
out="$(run_hook pre-tool-prose-guard '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_001_beginning.md"}}')"
assert_denied "$out" "long prose without outline"
: > "$ROOT/book/outline/outline_chapter_001.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_001_beginning.md"}}')"
assert_empty "$out" "long prose with outline"

# A brand-new book with no outline/tracking/setting scaffolding must also fail
# closed; relative targets resolve against the hook cwd — the core guard must not
# be weakened to mask wrong project-root joining.
mkdir -p "$ROOT/bare/prose" "$ROOT/cwd-book/prose" "$ROOT/cwd-book/outline"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"bare/prose/chapter_001_first.md"}}')"
assert_denied "$out" "bare long project without scaffolding"
relative_payload="$(node -e '
const path = require("path")
process.stdout.write(JSON.stringify({
  cwd: path.resolve(process.argv[1]),
  tool_name: "Write",
  tool_input: { file_path: "prose/chapter_008_relative.md" },
}))
' "$ROOT/cwd-book")"
out="$(run_hook pre-tool-prose-guard "$relative_payload")"
assert_denied "$out" "relative prose target from hook cwd"
printf '%s' "$out" | grep -q 'cwd-book/outline' || fail "relative target was not resolved from hook cwd: $out"
: > "$ROOT/cwd-book/outline/outline_chapter_008.md"
out="$(run_hook pre-tool-prose-guard "$relative_payload")"
assert_empty "$out" "relative prose target with cwd-local outline"

# Containment must follow Windows path semantics: path.relative across volumes
# returns an absolute path, and a directory named `..draft` is still in-project.
# Judging with startsWith("..") alone would invert both cases.
node - "$SOURCE" <<'JS' || fail "ZCode cwd containment is not cross-volume safe"
const path = require("path")
const { isPathInside } = require(process.argv[2])
if (isPathInside("C:\\repo", "D:\\elsewhere", path.win32)) {
  throw new Error("different Windows volume must be outside the project")
}
if (!isPathInside("C:\\repo", "C:\\repo\\..draft", path.win32)) {
  throw new Error("an in-project directory named ..draft must remain inside")
}
if (!isPathInside("C:\\repo", "C:\\repo\\sub", path.win32)) {
  throw new Error("ordinary in-project directory must remain inside")
}
JS

out="$(run_hook pre-tool-prose-guard '{"tool_name":"ApplyPatch","tool_input":{"patch":"*** Begin Patch\n*** Add File: book/prose/chapter_002_new_game.md\n+prose\n*** End Patch"}}')"
assert_denied "$out" "ApplyPatch prose without outline"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"echo x | tee book/prose/chapter_003_command.md"}}')"
assert_denied "$out" "Bash prose write without outline"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Bash","tool_input":{"command":"grep -n book/prose/chapter_003_command.md notes.md"}}')"
assert_empty "$out" "Bash mention without write"

mkdir -p "$ROOT/short"
: > "$ROOT/short/setting.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"short/prose.md"}}')"
assert_denied "$out" "short prose without outline"
: > "$ROOT/short/section-outline.md"
out="$(run_hook pre-tool-prose-guard '{"tool_name":"Write","tool_input":{"file_path":"short/prose.md"}}')"
assert_empty "$out" "short prose with outline"
echo "  OK outline-before-prose guard"

printf 'This prose contains a TODO, and the last sentence is truncated' > "$ROOT/short/prose.md"
out="$(run_hook post-tool-prose-check '{"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"short/prose.md"}}')"
assert_contract "$out" PostToolUse "post-write prose check"
printf '%s' "$out" | grep -q 'placeholder' || fail "post-write check missed TODO"
printf '%s' "$out" | grep -q 'suspected truncation' || fail "post-write check missed truncation"
echo "  OK post-write strict JSON + UTF-8 findings"

printf 'Prose written by command with a TODO.' > "$ROOT/short/prose.md"
out="$(run_hook post-tool-prose-check '{"hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"cat input.txt > short/prose.md"}}')"
assert_contract "$out" PostToolUse "post-bash prose check"
printf '%s' "$out" | grep -q 'placeholder' || fail "post-Bash check missed prose target"
echo "  OK Bash write post-check"

cat > "$ROOT/.story-deployed" <<'EOF'
deployed_at: 2026-08-04T00:00:00Z
agents_version: 23
setup_skill_version: 1.3.0
target_cli: zcode
resolver_strategy: project-local-skill-reference
references_dir: .zcode/skills/story-setup/references/agent-references
EOF
printf 'book\n' > "$ROOT/.active-book"
mkdir -p "$ROOT/book/tracking"
printf '# Context\n' > "$ROOT/book/tracking/context.md"
out="$(run_hook session-start '{"hook_event_name":"SessionStart","source":"compact"}')"
assert_contract "$out" SessionStart "session start"
printf '%s' "$out" | grep -q 'Active book' || fail "session start missed active book"
echo "  OK session-start context"

printf '# Old context\n' > "$ROOT/book/tracking/context.md"
sleep 2
printf '# Chapter 1\nprose.\n' > "$ROOT/book/prose/chapter_001_dup.md"
printf '# Chapter 2\nprose.\n' > "$ROOT/book/prose/chapter_002_dup.md"
out="$(run_hook session-start '{"hook_event_name":"SessionStart","source":"resume"}')"
assert_contract "$out" SessionStart "session continuity"
printf '%s' "$out" | grep -q 'prose is ahead of tracking' || fail "session start missed stale tracking context"
printf '%s' "$out" | grep -q 'share the title' || fail "session start missed duplicate chapter title"
echo "  OK session-start continuity guard"

git -C "$ROOT" init -q
git -C "$ROOT" config user.email zcode-hook@example.invalid
git -C "$ROOT" config user.name zcode-hook-test
printf 'age: 18\n' > "$ROOT/book/prose/chapter_010_attribute.md"
git -C "$ROOT" add "$ROOT/book/prose/chapter_010_attribute.md"
out="$(run_hook pre-tool-commit-advisory '{"tool_name":"Bash","tool_input":{"command":"git -C . commit -m test"}}')"
assert_contract "$out" PreToolUse "commit advisory"
printf '%s' "$out" | grep -q 'prose hardcodes character attributes' || fail "commit advisory missed staged prose"
out="$(run_hook pre-tool-commit-advisory '{"tool_name":"Bash","tool_input":{"command":"echo git commit docs"}}')"
assert_empty "$out" "non-commit command"
echo "  OK commit advisory"

out="$(printf 'not-json' | ZCODE_PROJECT_DIR="$ROOT" node "$HOOK" pre-tool-prose-guard)"
assert_empty "$out" "malformed input fail-open"

: > "$ROOT/book/outline/outline_chapter_008.md"
out="$(cd "$TMP_DIR" && printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"book/prose/chapter_008_selfloc.md"}}' | env -u ZCODE_PROJECT_DIR -u CLAUDE_PROJECT_DIR node "$HOOK" pre-tool-prose-guard)"
assert_empty "$out" "deployed __dirname self-location"
echo "  OK malformed input + workspace self-location"

echo ""
echo "OK: ZCode hook synthetic tests passed"
