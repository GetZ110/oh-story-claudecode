#!/bin/bash
# check-hook-regex-sync.sh — behavior-level validation of detect-story-gaps.sh's
# foreshadow-status detection, plus the js<->py canonical-string lock for the
# toxic-pattern net.
#
# Design intent: the SessionStart hook only flags overdue or abnormal
# foreshadowing entries, so normal open states (unplanted/planted) never trigger
# a full foreshadowing audit in the daily flow. This script runs the real hook on
# fixtures and verifies normal states stay silent while expired/abnormal states
# warn.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_FILE="$REPO_ROOT/skills/story-setup/references/templates/hooks/detect-story-gaps.sh"
COMMON_FILE="$REPO_ROOT/skills/story-setup/references/templates/hooks/lib/common.sh"
PROTOCOL_FILE="$REPO_ROOT/skills/story-long-write/references/artifact-protocols.md"

for file in "$HOOK_FILE" "$COMMON_FILE" "$PROTOCOL_FILE"; do
  if [ ! -f "$file" ]; then
    echo "FAIL: required file not found: $file"
    exit 1
  fi
done

STATUS_ENUM=$(grep -oE 'Status\{[^}]+\}' "$PROTOCOL_FILE" 2>/dev/null | head -1 | sed 's/Status{//;s/}//' || true)
if [ -z "$STATUS_ENUM" ]; then
  echo "FAIL: No foreshadow status enum found in protocol file"
  exit 1
fi

echo "Protocol defines status values: $STATUS_ENUM"

TMP_DIR=$(mktemp -d)
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

setup_fixture() {
  local name="$1"
  local foreshadow_body="$2"
  local root="$TMP_DIR/$name"
  mkdir -p "$root/.claude/hooks/lib" "$root/book/tracking" "$root/book/prose" "$root/book/setting" "$root/book/outline"
  cp "$HOOK_FILE" "$root/.claude/hooks/detect-story-gaps.sh"
  cp "$COMMON_FILE" "$root/.claude/hooks/lib/common.sh"
  chmod +x "$root/.claude/hooks/detect-story-gaps.sh"
  touch "$root/.story-deployed"
  cat > "$root/book/tracking/context.md" <<'CTX'
# Writing progress
## Current position
- Chapter: Chapter 1
CTX
  # The header status enum expands from $STATUS_ENUM instead of being copied again:
  # adding a status to the protocol changes the fixture too, otherwise a new status
  # would never be exercised by the behavior fixtures (the header row itself is
  # skipped by the hook's ^Status\{ branch).
  cat > "$root/book/tracking/foreshadowing.md" <<EOF_FORESHADOW
# Foreshadowing tracking

## Foreshadowing state table

| ID | Foreshadowing | Planted chapter | Expected collection | Status{$STATUS_ENUM} | Importance{high/mid/low} |
|----|---------|---------|-------------|-----------------------------|----------------|
$foreshadow_body
EOF_FORESHADOW
  printf '%s' "$root"
}

run_hook() {
  local root="$1"
  (cd "$root" && bash .claude/hooks/detect-story-gaps.sh)
}

assert_no_foreshadow_warn() {
  local case_name="$1"
  local body="$2"
  local root output
  root=$(setup_fixture "$case_name" "$body")
  output=$(run_hook "$root" || true)
  if echo "$output" | grep -q 'foreshadowing'; then
    echo "FAIL: $case_name should not emit foreshadow warning"
    echo "Output:"
    echo "$output"
    exit 1
  fi
  echo "  OK no warn: $case_name"
}

assert_foreshadow_warn() {
  local case_name="$1"
  local body="$2"
  local root output
  root=$(setup_fixture "$case_name" "$body")
  output=$(run_hook "$root" || true)
  if ! echo "$output" | grep -q 'expired or abnormal entries'; then
    echo "FAIL: $case_name should emit overdue/abnormal foreshadow warning"
    echo "Output:"
    echo "$output"
    exit 1
  fi
  echo "  OK warn: $case_name"
}

assert_no_foreshadow_warn "header-only" ""

plain_header_root="$TMP_DIR/plain-header"
mkdir -p "$plain_header_root/.claude/hooks/lib" "$plain_header_root/book/tracking" "$plain_header_root/book/prose" "$plain_header_root/book/setting" "$plain_header_root/book/outline"
cp "$HOOK_FILE" "$plain_header_root/.claude/hooks/detect-story-gaps.sh"
cp "$COMMON_FILE" "$plain_header_root/.claude/hooks/lib/common.sh"
chmod +x "$plain_header_root/.claude/hooks/detect-story-gaps.sh"
cat > "$plain_header_root/book/tracking/foreshadowing.md" <<'EOF_PLAIN_HEADER'
# Foreshadowing tracking

| ID | Name | Planted | Collected | Status | Note |
|----|------|------|------|------|------|
| F001 | jade pendant | Chapter 1 | Chapter 20 | unplanted | ok |
EOF_PLAIN_HEADER
plain_header_output=$(run_hook "$plain_header_root" || true)
if echo "$plain_header_output" | grep -q 'foreshadowing'; then
  echo "FAIL: plain-header should not emit foreshadow warning"
  echo "Output:"
  echo "$plain_header_output"
  exit 1
fi
echo "  OK no warn: plain-header"

assert_no_foreshadow_warn "planned-unplanted" "| F001 | planned for later | Chapter 5 | Chapter 10 | unplanted | mid |"
assert_no_foreshadow_warn "normal-open-planted" "| F002 | normal open thread | Chapter 1 | Chapter 20 | planted | high |"
assert_no_foreshadow_warn "closed-recovered" "| F003 | collected thread | Chapter 1 | Chapter 3 | recovered | low |"
assert_foreshadow_warn "overdue" "| F004 | overdue thread | Chapter 1 | Chapter 2 | expired | high |"
assert_foreshadow_warn "unknown-status" "| F005 | abnormal thread | Chapter 1 | Chapter 2 | damaged | high |"

# Guard against reverting to the old broad regex or warning wording.
if grep -q '状态' "$HOOK_FILE"; then
  echo "FAIL: legacy Chinese foreshadow regex is still present in hook"
  exit 1
fi
if grep -q 'Open foreshadowing[[:space:]]threads' "$HOOK_FILE"; then
  echo "FAIL: old open-foreshadow warning wording is still present in hook"
  exit 1
fi

# Ensure every protocol status is explicitly classified by the hook's awk classifier:
# either an explicit warn state (status == "X") or an explicit normal state
# (status != "X"). The protocol and the hook disagree on the closed-status name —
# the protocol says "collected" while the hook classifies "recovered" (a
# pre-existing drift inside skills/, out of this script's scope; the behavior
# fixtures above lock the hook's actual vocabulary). Map that one alias so the
# loop still catches any NEW status added to the protocol without teaching the
# hook: an untaught status falls into the classifier's else branch and is
# reported as abnormal on every SessionStart — that drift must turn this check
# red.
normalize_status() {
  case "$1" in
    collected) echo "recovered" ;;
    *) echo "$1" ;;
  esac
}
for raw_state in $(echo "$STATUS_ENUM" | tr '/' ' '); do
  state="$(normalize_status "$raw_state")"
  if ! grep -qF "status == \"$state\"" "$HOOK_FILE" \
    && ! grep -qF "status != \"$state\"" "$HOOK_FILE"; then
    echo "FAIL: protocol status not classified by hook: $state (protocol wrote \"$raw_state\")"
    echo "  add status == \"$state\" (warn) or status != \"$state\" (normal) to the foreshadowing awk in $HOOK_FILE"
    exit 1
  fi
done

echo ""
echo "OK: hook foreshadow detection warns only on overdue/abnormal states"

# ── Toxic-pattern js<->py sync lock ─────────────────────────────────────────
# The after-write net's deterministic toxic sentence rules have two isomorphic
# implementations: the JS shared core story_hook_core.js (Claude/OpenCode/ZCode
# copies byte-identical, enforced by check-shared-files.sh) and codex
# story_codex_hook.py (turn-end rescan at the Stop event). The canonical text of
# every regex/constant/copy line must appear verbatim in both — changing one
# without the other fails immediately. Complements the fixture-level functional
# parity of test-prose-net-parity.sh (this locks source text, that locks behavior
# output).
JS_CORE="$REPO_ROOT/skills/story-setup/references/templates/hooks/story_hook_core.js"
PY_HOOK="$REPO_ROOT/skills/story-setup/references/codex/hooks/story_codex_hook.py"
for file in "$JS_CORE" "$PY_HOOK"; do
  if [ ! -f "$file" ]; then
    echo "FAIL: required file not found: $file"
    exit 1
  fi
done

TOXIC_SYNC=(
  # regexes (common text of the js literal and the py raw string)
  'voice\s+(?:was|were|sounded|stayed|remained|dropped)\s+(?:quiet|soft|low|calm|even|level|steady|gentle|barely (?:audible|a whisper))'
  "(?:,|\.)\s*){2}\bno\s+[a-z][a-z0-9' -]{1,24}\b"
  '(?:just|merely|simply)\s+[^.!?\n,]{1,20}[,.]\s*\b(?:it|that|this) (?:was|is)\b'
  'little did (?:he|she|they|we|i|anyone|everyone) know'
  'fate had other plans'
  'was (?:a|the) (?:night|day|morning|moment) that would (?:change|alter|end) everything'
  'be the same (?:again)?'
  'the wheels? of fate'
  '“[^”]*”'
  # constants (end window, clause boundary, not-was exclusion window)
  'TRAILER_WINDOW_WORDS = 250'
  '.!?;:…—~ \t'
  'start - 12'
  # copy (finding line format, rule fixes, clearance requirement + full-scan hint;
  # must match verbatim on both ends)
  ' toxic pattern ['
  'write the concrete effect the voice lands on the room'
  'denial list to one or none; write what is actually present'
  'write the positive term directly, or show it through action/detail'
  'cut the chapter-end preview; end on an action or image that is happening now'
  'cut the chapter-end state verdict; the ending state is outline planning language'
  'Toxic patterns are deterministic AI fingerprints: clear this chapter before continuing'
  'uncleared toxic patterns'
  'clear them before writing chapter'
  'deslop\s*:\s*skip'
  '\r?\n'
)
toxic_fail=0
for needle in "${TOXIC_SYNC[@]}"; do
  for file in "$JS_CORE" "$PY_HOOK"; do
    if ! grep -Fq -- "$needle" "$file"; then
      echo "FAIL: toxic-pattern canonical string missing/drifted — \"${needle}\" not in $(basename "$file")"
      toxic_fail=1
    fi
  done
done

# The debt gate has a separate bash-side implementation in
# guard-outline-before-prose.sh (previous-chapter discovery + first-6-lines
# exemption window + block copy; the toxic scan itself goes through the shared
# core). The exemption marker and gate copy must stay in sync across all three.
GUARD_SH="$REPO_ROOT/skills/story-setup/references/templates/hooks/guard-outline-before-prose.sh"
GATE_SYNC=(
  'uncleared toxic patterns'
  'deslop:skip'
  'To exempt explicitly, add <!-- deslop:skip -->'
)
for needle in "${GATE_SYNC[@]}"; do
  for file in "$JS_CORE" "$PY_HOOK" "$GUARD_SH"; do
    if ! grep -Fq -- "$needle" "$file"; then
      echo "FAIL: debt-gate canonical string missing/drifted — \"${needle}\" not in $(basename "$file")"
      toxic_fail=1
    fi
  done
done
if [ "$toxic_fail" -ne 0 ]; then
  exit 1
fi

echo "OK: toxic-pattern regexes/constants/copy js<->py verbatim sync (debt-gate marker/copy sync across the bash gate too)"
