#!/bin/bash
# test-degeneration.sh — regression tests for the model-degeneration detector.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository" >&2
  exit 1
fi

SCRIPT="$REPO_ROOT/skills/story-deslop/scripts/check-degeneration.js"
TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

POS="$TMP_DIR/degen-positive.md"
NEG="$TMP_DIR/degen-negative.md"
OUT="$TMP_DIR/out.json"

# Positive: back-to-back identical line + a long sentence repeated 3x + AI
# self-reference + bracketed placeholder + end-of-file truncation.
cat > "$POS" <<'EOF'
He clenched his fists, slowly got to his feet, his eyes full of frustration.
He clenched his fists, slowly got to his feet, his eyes full of frustration.
She watched the rain that had fallen all night outside the window, feeling hollow inside.
A moment passed.
She watched the rain that had fallen all night outside the window, feeling hollow inside.
Another moment passed.
She watched the rain that had fallen all night outside the window, feeling hollow inside.
As an AI language model, I am unable to continue generating this passage.
[INSERT SCENE HERE]
He turned around and walked slowly toward the door, his hand still
EOF

# Negative: genre-legal "repetition" must not fire — a barrage of identical
# apology lines, a short parallel chant, dialogue refrain, an AI-era product
# noun phrase, and in-story AI dialogue.
cat > "$NEG" <<'EOF'
He stood where he was, staring at the message for a long time without moving.
"I'm sorry."
"I'm sorry."
"I'm sorry."
I wait for you. I wait for you. I wait for you.
The wind was strong, blowing so hard you could barely open your eyes.
As a product of the AI era, he was used to loneliness.
"As an AI, I will always stay with you."
At that moment, he finally understood what it meant to let go.
EOF

set +e
node "$SCRIPT" --json "$POS" > "$OUT"
pos_status=$?
set -e
if [ "$pos_status" -ne 1 ]; then
  echo "FAIL: expected degeneration detector to exit 1 on positive fixture, got $pos_status" >&2
  cat "$OUT" >&2 || true
  exit 1
fi

node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const counts = report.findings.reduce((m, f) => ((m[f.type] = (m[f.type] || 0) + 1), m), {});
const want = { 'verbatim-repeat': 2, 'placeholder-leak': 2, 'truncated': 1 };
if (report.findings.length !== 5) {
  throw new Error(`expected 5 positive findings, got ${report.findings.length}: ${JSON.stringify(report.findings.map((f) => `${f.type}@${f.line}`))}`);
}
for (const [type, n] of Object.entries(want)) {
  if (counts[type] !== n) throw new Error(`expected ${n} ${type}, got ${counts[type] || 0}`);
}
NODE

# Negative fixture must be clean (exit 0). Genre repetition/refrain/dialogue
# barrage is not degeneration.
set +e
neg_out="$(node "$SCRIPT" "$NEG" 2>&1)"
neg_status=$?
set -e
if [ "$neg_status" -ne 0 ]; then
  echo "FAIL: degeneration detector false-positive on legit repetition/refrain prose (exit $neg_status):" >&2
  echo "$neg_out" >&2
  exit 1
fi

# --- AI self-reference (without refusal language): the self-reference rule itself
#     had zero coverage — the most typical degenerate openings with a model-type
#     suffix (AI language model / AI assistant / AI chatbot / AI model) slipped
#     through. This fixture carries self-reference only (no "I cannot"), locked to
#     the label per line.
AI_SELF="$TMP_DIR/ai-selfref.md"
cat > "$AI_SELF" <<'EOF'
As an AI language model, I need to remind you.
As an AI assistant, this content touches on a sensitive topic.
Being an AI chatbot, I can help you keep going.
As an AI model, this scene needs adjustment.
He turned off the light.
EOF
set +e
node "$SCRIPT" --json "$AI_SELF" > "$OUT"
ai_self_status=$?
set -e
if [ "$ai_self_status" -ne 1 ]; then
  echo "FAIL: AI self-reference fixture should exit 1, got $ai_self_status" >&2
  cat "$OUT" >&2 || true
  exit 1
fi
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const leaks = r.findings.filter((f) => f.type === 'placeholder-leak');
if (leaks.length !== 4) {
  throw new Error(`expected 4 AI self-reference findings, got ${leaks.length}: ${JSON.stringify(leaks.map((f) => `${f.line}:${f.excerpt}`))}`);
}
if (!leaks.every((f) => f.message.includes('AI self-reference'))) {
  throw new Error('must be caught by the AI self-reference rule (not the refusal rule): ' + JSON.stringify(leaks.map((f) => f.message)));
}
NODE

# --- Engineering-word leakage meta-leak ---
META_POS="$TMP_DIR/meta-positive.md"
META_NEG="$TMP_DIR/meta-negative.md"

# Positives: pure pipeline terms (chapter outline / plot point) + chapter-structure
# words (this chapter / next chapter, including in dialogue) + author-reference word.
cat > "$META_POS" <<'EOF'
## Chapter 5 The Truth
He clenched his fists, slowly getting to his feet.
This chapter he finally discovered the truth.
"Time to move to the next chapter," he said in a low voice.
According to the chapter outline, he should go find her first.
This plot point had actually been planted long ago.
The author has never explained this rule.
EOF
set +e
node "$SCRIPT" --json "$META_POS" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const meta = report.findings.filter((f) => f.type === 'meta-leak');
if (meta.length !== 5) {
  throw new Error(`expected 5 meta-leak findings (this chapter / next chapter / chapter outline / plot point / the author), got ${meta.length}: ${JSON.stringify(meta.map((f) => f.excerpt))}`);
}
NODE

# Negative: the title line "Chapter N Title" (without a ## prefix) must not count as
# engineering-word leakage; clean prose has 0 hits.
cat > "$META_NEG" <<'EOF'
Chapter 1 A Star of the Propaganda Troupe
He stood on the stage, looking at the dark crowd below.
The wind was strong, and the flag snapped loudly.
He gripped the microphone and took a deep breath.
EOF
set +e
meta_neg_out="$(node "$SCRIPT" "$META_NEG" 2>&1)"
meta_neg_status=$?
set -e
if [ "$meta_neg_status" -ne 0 ]; then
  echo "FAIL: meta-leak false-positive on chapter title line / clean prose (exit $meta_neg_status):" >&2
  echo "$meta_neg_out" >&2
  exit 1
fi

# --- Whole-line quote exemption regression: a mixed line (narration + quoted
#     object) must not be skipped by one quote when it repeats. ---
MIX="$TMP_DIR/mix-repeat.md"
cat > "$MIX" <<'EOF'
He unfolded the note, which said "return", and watched the rain that had fallen all night outside the window, feeling hollow inside.
He unfolded the note, which said "return", and watched the rain that had fallen all night outside the window, feeling hollow inside.
He unfolded the note, which said "return", and watched the rain that had fallen all night outside the window, feeling hollow inside.
EOF
set +e
node "$SCRIPT" --json "$MIX" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const rep = r.findings.filter((f) => f.type === 'verbatim-repeat');
if (rep.length === 0) throw new Error('whole-line quote exemption regression: mixed-line repeat not detected');
if (!rep.every((f) => f.severity === 'blocking')) throw new Error('verbatim-repeat should be severity=blocking');
NODE

# Pure dialogue refrain stays exempt (genre device): three identical lines, no report.
PURE_DLG="$TMP_DIR/pure-dialogue.md"
cat > "$PURE_DLG" <<'EOF'
"I'm not going."
"I'm not going."
"I'm not going."
EOF
set +e
pure_dlg_out="$(node "$SCRIPT" "$PURE_DLG" 2>&1)"
pure_dlg_status=$?
set -e
if [ "$pure_dlg_status" -ne 0 ]; then
  echo "FAIL: pure dialogue refrain misflagged as repetition (exit $pure_dlg_status):" >&2
  echo "$pure_dlg_out" >&2
  exit 1
fi

# --- severity + --fail-on semantics: advisory-only (tier2) exits 1 by default and
#     0 under --fail-on=blocking ---
ADV="$TMP_DIR/advisory-only.md"
cat > "$ADV" <<'EOF'
He flipped through the record, remembering what had happened before this chapter; that foreshadowing had never been mentioned again.
EOF
set +e
node "$SCRIPT" --json "$ADV" > "$OUT"
adv_all_status=$?
node "$SCRIPT" --fail-on=blocking "$ADV" >/dev/null 2>&1
adv_blocking_status=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (r.findings.length === 0) throw new Error('expected tier2 advisory finding');
if (!r.findings.every((f) => f.severity === 'advisory')) {
  throw new Error('tier2-only fixture should be all advisory: ' + JSON.stringify(r.findings.map((f) => f.severity)));
}
NODE
if [ "$adv_all_status" -ne 1 ]; then
  echo "FAIL: advisory-only --fail-on=all should exit 1, got $adv_all_status" >&2
  exit 1
fi
if [ "$adv_blocking_status" -ne 0 ]; then
  echo "FAIL: advisory-only --fail-on=blocking should exit 0, got $adv_blocking_status" >&2
  exit 1
fi

# --- tier1 pipeline terms: blocking in narration; downgraded to advisory in a
#     dialogue line (legal in-story for a writer/editor character) ---
TIER1="$TMP_DIR/tier1-dialogue.md"
cat > "$TIER1" <<'EOF'
"The word count target for today is six thousand," he said, staring at the screen, cigarette after cigarette.
According to the word count target, he still had six thousand words to write.
EOF
set +e
node "$SCRIPT" --json "$TIER1" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const meta = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')).findings.filter((f) => f.type === 'meta-leak');
const dlg = meta.find((f) => f.line === 1);
const nar = meta.find((f) => f.line === 2);
if (!dlg || dlg.severity !== 'advisory') throw new Error('tier1 on a dialogue line should be advisory: ' + JSON.stringify(dlg));
if (!nar || nar.severity !== 'blocking') throw new Error('tier1 on a narration line should be blocking: ' + JSON.stringify(nar));
NODE

# --- wiring: every skill carrying a check-degeneration.js copy must actually call
#     it in its SKILL.md workflow ---
for skill_js in $(find "$REPO_ROOT/skills" -name check-degeneration.js); do
  skill_md="$(dirname "$(dirname "$skill_js")")/SKILL.md"
  if [ -f "$skill_md" ] && ! grep -q 'check-degeneration.js' "$skill_md"; then
    echo "FAIL: $skill_md carries a check-degeneration.js copy but never calls it in its workflow" >&2
    exit 1
  fi
done

echo "Degeneration detector regression tests passed."
