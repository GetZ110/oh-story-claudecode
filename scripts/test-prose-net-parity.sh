#!/bin/bash
# test-prose-net-parity.sh — four-end parity guard for the prose "lightweight
# deterministic net". The net lives in four places: ① Claude's
# check-prose-after-write.sh (delegating to the node shared core); ② Codex's
# story_codex_hook.py; ③ OpenCode's plugin.ts; ④ ZCode's story_zcode_hook.js.
# (③④'s pure logic now share their own story_hook_core.js companion, byte-identical.)
# All four must judge alike. This test guarantees it in five layers:
#   A. Canonical-string agreement (CI-safe, zero runtime deps): the canonical text
#      of every net regex/constant/threshold must appear in all four files — changing
#      one without the others fails immediately (anchors drift; same approach as
#      check-hook-regex-sync.sh).
#   B. Functional parity (best-effort, self-skips without a TS runtime): the codex
#      python net, the opencode TS net, and the zcode JS net must produce
#      character-identical output on one fixture set.
#   C. Command-function parity (CI hard gate): prose-target extraction, apply-patch
#      targets, and git-commit detection — three pure functions — must be
#      character-identical between codex python and zcode JS (locks hand-copied
#      logic that previously drifted with no guard).
#   D. Claude core-delegation regression guard (CI hard gate): Claude's 4 bash
#      hooks no longer embed heredoc python; they call the same node shared core
#      story_hook_core.js (via story_hook_cli.js) used by zcode/opencode — already
#      locked to codex by B/C, so claude==codex closes the loop structurally. Two
#      anti-regressions: hooks must not reintroduce heredoc python, and must call
#      the core through story_hook_cli.js. Byte-identity is enforced separately by
#      check-shared-files.
#   E. Uncored-surface parity (CI hard gate): staged markdown warnings and the
#      prose-block (outline gate) decision are not in the shared core — codex
#      python and the JS core each have an implementation, compared
#      character-identically on fixtures (case-variant hits, warning/block copy,
#      JS core authoritative). The Claude-side bash implementations of these two
#      surfaces are not byte-locked cross-end; their behavior is covered by
#      check-story-setup-deployment.sh / test-hook-encoding-portable.sh.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$ROOT" ] && { echo "Error: not in a git repository" >&2; exit 1; }

CLAUDE="$ROOT/skills/story-setup/references/templates/hooks/check-prose-after-write.sh"
CODEX="$ROOT/skills/story-setup/references/codex/hooks/story_codex_hook.py"
OPENCODE="$ROOT/skills/story-setup/references/opencode/plugin.ts"
ZCODE="$ROOT/skills/story-setup/references/zcode/hooks/story_zcode_hook.js"
ZCODE_CORE="$ROOT/skills/story-setup/references/zcode/hooks/story_hook_core.js"
OPENCODE_CORE="$ROOT/skills/story-setup/references/opencode/story_hook_core.js"
CLAUDE_CORE="$ROOT/skills/story-setup/references/templates/hooks/story_hook_core.js"
CLAUDE_COMMIT="$ROOT/skills/story-setup/references/templates/hooks/validate-story-commit.sh"
CLAUDE_GAPS="$ROOT/skills/story-setup/references/templates/hooks/detect-story-gaps.sh"
for f in "$CLAUDE" "$CODEX" "$OPENCODE" "$ZCODE" "$ZCODE_CORE" "$OPENCODE_CORE" "$CLAUDE_CORE" "$CLAUDE_COMMIT" "$CLAUDE_GAPS"; do
  [ -f "$f" ] || { echo "FAIL: missing impl: $f" >&2; exit 1; }
done

# Windows python.org installs land `python3` on the Microsoft Store stub (silent
# exit 49); probe for a working interpreter (python3 -> python -> py) per the
# repo convention in check-python-invocation.sh.
PYBIN=""
for cand in python3 python py; do
  if command -v "$cand" >/dev/null 2>&1 && "$cand" -c "" >/dev/null 2>&1; then
    PYBIN="$cand"
    break
  fi
done
[ -n "$PYBIN" ] || { echo "FAIL: no working python interpreter (tried python3 python py)" >&2; exit 1; }

fails=0

# ── A. Canonical strings across all ends ────────────────────────────────
# Canonical substring of every net regex (unique enough to anchor the pattern)
# plus key constants/thresholds. Must all be grep -F-able in all four files.
CANON=(
  # soft signals (AI self-reference / chatbot voice / generation refusal)
  '(?:as an?|being an?)\s+(?:AI|language model|artificial intelligence|chatbot|assistant)'
  "^(Sure|Certainly|Here'?s|As an AI|I (?:cannot|can't|am unable|apologize))"
  "(?:sorry|apologize|unable|not able|can"
  # hard signals (placeholder / engineering words / mojibake)
  '\[INSERT[^\]]{0,20}\]'
  '(?:chapter outline|volume outline|master outline|story unit|plot point|target words?|word count target|hook note|payoff note|foreshadowing note)'
  # constants / thresholds (terminal set, dialogue openers, repeat minimum visible length)
  '…”’”])}~—'
  '"“", "‘"'
  '>= 8'
  # finding copy anchors
  'verbatim repeat: line identical to the previous line'
  'suspected truncation: ending'
  # word-count debt: "Target words:" extraction from the chapter outline + 90% gate
  '[Tt]arget words?:?\s*(\d{3,6})'
  'target * 0.9'
  # toxic sentence patterns (voice-contrast / negation-parade / not-was)
  'voice\s+(?:was|were|sounded|stayed|remained|dropped)\s+(?:quiet|soft|low|calm|even|level|steady|gentle|barely (?:audible|a whisper))'
  "(?:\bno\s+[a-z][a-z0-9' -]{1,24}(?:,|\.)\s*){2}\bno\s+[a-z][a-z0-9' -]{1,24}\b"
  '(?:just|merely|simply)\s+[^.!?\n,]{1,20}[,.]\s*\b(?:it|that|this) (?:was|is)\b'
  # trailer patterns + finding copy
  'little did (?:he|she|they|we|i|anyone|everyone) know'
  'was (?:a|the) (?:night|day|morning|moment) that would (?:change|alter|end) everything'
  'toxic pattern ['
  'deslop\s*:\s*skip'
  'cut the chapter-end preview; end on an action or image'
)
for needle in "${CANON[@]}"; do
  for f in "$CLAUDE" "$CODEX" "$OPENCODE" "$ZCODE"; do
    if grep -Fq "$needle" "$f"; then
      continue
    fi
    # ZCode's net constants/patterns live in the shared story_hook_core.js companion
    # that story_zcode_hook.js requires; accept a hit there as satisfying this file.
    if [ "$f" = "$ZCODE" ] && grep -Fq "$needle" "$ZCODE_CORE"; then
      continue
    fi
    # OpenCode's plugin.ts likewise imports the net from its own shared story_hook_core.js
    # companion (byte-identical to ZCode's); accept a hit there as satisfying plugin.ts.
    if [ "$f" = "$OPENCODE" ] && grep -Fq "$needle" "$OPENCODE_CORE"; then
      continue
    fi
    # Claude's check-prose-after-write.sh now delegates the net/wordcount patterns to the
    # same shared story_hook_core.js (loaded via story_hook_cli.js); accept a hit there.
    if [ "$f" = "$CLAUDE" ] && grep -Fq "$needle" "$CLAUDE_CORE"; then
      continue
    fi
    echo "FAIL: net canonical string missing/drifted — \"${needle}\" not in $(basename "$f")" >&2
    fails=$((fails + 1))
  done
done
# The repeat threshold reads `sa.length >= 8` in JS and `len(sa) >= 8` in python;
# the '>= 8' above covers both.

# ── B. Functional parity (codex python net vs opencode TS net vs zcode JS net),
#     best-effort — the TS run prefers node native type stripping (node >= 22.6's
#     --experimental-strip-types), else a local esbuild binary; without either, B
#     self-skips (A already gives the CI-safe hard guarantee).
run_functional() {
  command -v node >/dev/null 2>&1 || return 1
  command -v "$PYBIN" >/dev/null 2>&1 || return 1
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # Generate the fixture set (a python heredoc builds the two trailer-window
  # fixtures programmatically: >250 narrative words must separate the trailer
  # phrase from EOF, and the filler lines must be pairwise distinct so the
  # verbatim-repeat net never fires on them).
  "$PYBIN" - "$tmp/fixtures.json" <<'PY'
import json, io, sys
fx = {}
fx["clean"] = "He opened his eyes; it was not dawn yet.\nHe had to be fast, ruthless, and winning \u2014 that was the only way out.\n\"As your AI housekeeper, I advise you not to waste your strength.\"\nHe clenched his fists and walked to the door."
fx["truncate"] = "He clenched his fists and walked slowly to the door.\nHe rushed forward and swung at"
fx["refuse"] = "Night pressed down.\nI am unable to continue writing this scene."
fx["ai_selfref_model"] = "Night pressed down.\nAs an AI language model, I need to remind you that the following scene contains violence."
fx["ai_selfref_assistant"] = "He pushed the door open.\nAs an AI assistant, this content touches on a sensitive topic."
fx["ai_selfref_era_ok"] = "As a product of the AI era, he was used to loneliness.\nHe turned off the light."
fx["terminal_banner_ok"] = "He raised his hand and pressed it on the light screen.\n[Ding! Quest complete, reward issued]"
fx["terminal_ascii_quote_ok"] = "He stood up and pushed the door open.\nHe said: \"I'm back.\""
fx["toxic_quote_codename_ok"] = "He crushed the cigarette stub into the ashtray.\nThis battle was destined to be the start of the \"bloodbath\", and no one guessed what came later."
fx["engword"] = "The streetlights came on one by one.\nAccording to the chapter outline's plot point, it was his turn to appear."
fx["repeat"] = "He clenched his fists and walked over step by step, slowly closing in.\nHe clenched his fists and walked over step by step, slowly closing in.\nAt last he stopped."
fx["placeholder"] = "He opened the door.\n[INSERT fight scene description] He won."
fx["english_ai"] = "He said.\nI cannot continue writing this scene for you."
fx["parallel"] = "It was either live or die.\nEither fight or flee.\nEither win or lose.\nHe made his choice."
fx["danmaku"] = "Danger ahead!\nDanger ahead! Warning.\nI cried at this part.\nAuthor, update faster!"
fx["toxic_voice"] = "He spoke.\nHis voice was quiet, but the first sentence pinned the whole hall."
fx["toxic_negation"] = "No accompaniment. No harmony. No teleprompter.\nThe crowd went silent for three seconds."
# not-was-comparison: the canonical English form ("It wasn't just anger. It was
# fury.") is EXEMPT in both engines — the quote-char guard skips any line that
# still contains an ASCII apostrophe after masking (a contraction is
# indistinguishable from an unclosed single quote), and the python mirror
# additionally requires the apostrophe while JS allows wasn'?t, so the
# apostrophe-less form would break parity. Both fixtures lock the shared silent
# behavior; the rule's intent is covered by the deep scan (check-ai-patterns).
fx["toxic_reverse_notis"] = "It wasn't just anger. It was fury.\nHe cleared his throat and kept singing."
fx["toxic_forward_notis"] = "It wasn't simply a dead end. It was a trap.\nHe shut the door."
fx["toxic_trailer"] = "He put down the microphone and bowed to the audience.\nNo one knew that this was only the beginning."
fx["toxic_trailer_summary"] = "He put down the microphone and bowed to the audience.\nIt was a night that would change everything."
fx["toxic_trailer_summary_fate"] = "She folded the bill and tucked it back into her bag.\nThe wheels of fate had already turned."
fx["toxic_bare_realize_ok"] = "At that moment I finally understood why my mother always cried at night.\nI grabbed my coat and headed for the door."
fx["toxic_summary_subclause_ok"] = "Once all this is over, we can live a quiet, happy life.\nHe closed the door behind him."
fx["toxic_summary_idiom_ok"] = "That night, everyone accepted their fate as it was written.\nHe turned and left."
fx["toxic_dialogue_ok"] = "\"No one knows,\" he said, smiling, and kept walking."
fx["toxic_eitheror_ok"] = "It was either life or death, and he accepted it.\nHe pushed the door open and went in."
fx["toxic_affirm_ok"] = "Yes, it wasn't his fault.\nHe turned off the light."
fx["toxic_shibushi_ok"] = "He asked himself whether he had misheard, whether the light was too bright.\nHe rubbed his eyes."
fx["toxic_question_ok"] = "Was it him who did it, not me?\nHe couldn't say."
fx["toxic_rhetorical_ok"] = "It was a good thing, wasn't it?\nHe nodded."
fx["toxic_curtain_ok"] = "The bell rang again, and the competition officially kicked off.\nHe stepped onto the stage."
fx["toxic_quote_mid_ok"] = "Her voice was not that good, and people clipped it into \"legendary moments\", but she did not care.\nThere was no applause, no \"encore\" call, only coughing rising and falling."
fx["toxic_multi_tail_ok"] = "It was his fault, not mine, wasn't it?\nHe nodded."
fx["toxic_exempt_marker_ok"] = "# Chapter 1\n<!-- deslop:skip -->\nNo hesitation. No doubt. No fear."
# The deslop exemption regex is ASCII-colon only (deslop\s*:\s*skip): a
# full-width colon marker must NOT exempt the toxic push-back.
fx["toxic_exempt_fullwidth_notok"] = "# Chapter 1\n<!-- deslop\uff1askip -->\nNo hesitation. No doubt. No fear."
fx["toxic_exempt_other_nets"] = "# Chapter 1\n<!-- deslop:skip -->\nNo hesitation. No doubt. No fear.\nAccording to the chapter outline, he should appear now."
# Trailer window: >250 narrative words between the trailer phrase and EOF push
# "No one knew..." out of the end window. The quoted emoji lines contribute 0
# words after masking; the filler lines are pairwise distinct (take number N) so
# the verbatim-repeat net never fires. The emoji placeholder length locks the
# UTF-16 mask alignment (js "?".repeat(m.length) == py utf-16-le units), so a
# drift there would move the window cut and break the diff.
filler = "\n".join(
    "He edited take number %d over and over from midnight until dawn, holding every single frame tight without blinking." % n
    for n in range(1, 16)
)
emoji = "\n".join('"Row %d %s"' % (n, "\U0001F600" * 10) for n in range(1, 11))
fx["toxic_astral_window_ok"] = "No one knew how long he had practiced.\n" + filler + "\n" + emoji
clip = "Jiang Chen edited this clip over and over from midnight until dawn, holding every single frame tight. "
fx["toxic_trailer_window_ok"] = "No one knew how long he had practiced.\n" + clip * 15 + "\nHe closed the piano lid and stood up."
with io.open(sys.argv[1], "w", encoding="utf-8", newline="\n") as f:
    json.dump(fx, f, ensure_ascii=False, indent=2)
PY

  "$PYBIN" - "$CODEX" "$tmp/fixtures.json" > "$tmp/py.txt" <<'PY'
import importlib.util, sys, json
spec = importlib.util.spec_from_file_location("ch", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
fx = json.load(open(sys.argv[2], encoding='utf-8'))
# Write raw UTF-8 bytes via stdout.buffer: on Windows runners python<3.15's text
# stdout is cp1252 and printing non-ASCII findings would raise UnicodeEncodeError
# (aligned with node's console.log UTF-8 output).
for k in sorted(fx):
    line = k + " | " + " ;; ".join(m.prose_net_findings(fx[k]))
    sys.stdout.buffer.write((line + "\n").encode("utf-8"))
PY

  node - "$ZCODE" "$tmp/fixtures.json" > "$tmp/zcode.txt" <<'JS'
const hook = require(process.argv[2])
const fx = require(process.argv[3])
for (const k of Object.keys(fx).sort()) {
  console.log(k, "|", hook.proseNetFindings(fx[k]).join(" ;; "))
}
JS
  if ! diff "$tmp/py.txt" "$tmp/zcode.txt" >/dev/null; then
    echo "FAIL: functional parity mismatch (codex python net vs zcode JS net):" >&2
    diff "$tmp/py.txt" "$tmp/zcode.txt" >&2 || true
    return 3
  fi

  # Anti-noop assertions on the toxic fixtures (both ends could agree on the same
  # wrong output and still pass the diff): positives must hit their rule; the
  # negatives (dialogue / either-or / affirmation / questions / window edges /
  # quote spans / exemption marker) must stay fully silent.
  grep -q '^toxic_voice | Line 2 toxic pattern \[voice-contrast\]' "$tmp/py.txt" || { echo "FAIL: toxic positive voice-contrast missed 'voice was quiet, but...'" >&2; return 3; }
  grep -q '^toxic_negation | Line 1 toxic pattern \[negation-parade\]' "$tmp/py.txt" || { echo "FAIL: toxic positive negation-parade missed 'No X. No Y...'" >&2; return 3; }
  grep -q '^toxic_trailer | Line 2 toxic pattern \[trailer-ending\]' "$tmp/py.txt" || { echo "FAIL: toxic positive trailer-ending missed 'No one knew that...'" >&2; return 3; }
  grep -q '^toxic_trailer_summary | Line 2 toxic pattern \[trailer-summary\]' "$tmp/py.txt" || { echo "FAIL: toxic positive trailer-summary missed 'It was a night that would change everything'" >&2; return 3; }
  grep -q '^toxic_trailer_summary_fate | Line 2 toxic pattern \[trailer-summary\]' "$tmp/py.txt" || { echo "FAIL: toxic positive trailer-summary missed 'the wheels of fate'" >&2; return 3; }
  grep -q '^toxic_bare_realize_ok | $' "$tmp/py.txt" || { echo "FAIL: bare cognition beat 'at that moment I finally understood' misreported" >&2; return 3; }
  grep -q '^toxic_summary_subclause_ok | $' "$tmp/py.txt" || { echo "FAIL: conditional clause 'once all this is over, ...' misreported (not a closing verdict)" >&2; return 3; }
  grep -q '^toxic_summary_idiom_ok | $' "$tmp/py.txt" || { echo "FAIL: idiom 'fate as it was written' cross-matched into trailer-summary" >&2; return 3; }
  grep -q '^toxic_dialogue_ok | $' "$tmp/py.txt" || { echo "FAIL: dialogue 'No one knows' misreported (paired quotes should be stripped)" >&2; return 3; }
  grep -q '^toxic_eitheror_ok | $' "$tmp/py.txt" || { echo "FAIL: either-or 'either ... or ...' misreported" >&2; return 3; }
  grep -q '^toxic_affirm_ok | $' "$tmp/py.txt" || { echo "FAIL: affirmation 'Yes, it wasn't his fault' misreported" >&2; return 3; }
  grep -q '^toxic_shibushi_ok | $' "$tmp/py.txt" || { echo "FAIL: question 'whether ... whether ...' misreported" >&2; return 3; }
  grep -q '^toxic_question_ok | $' "$tmp/py.txt" || { echo "FAIL: question opener 'Was it him...' misreported" >&2; return 3; }
  grep -q '^toxic_rhetorical_ok | $' "$tmp/py.txt" || { echo "FAIL: rhetorical tail 'wasn't it?' misreported" >&2; return 3; }
  grep -q '^toxic_curtain_ok | $' "$tmp/py.txt" || { echo "FAIL: announcer sentence 'officially kicked off' misreported" >&2; return 3; }
  grep -q '^toxic_trailer_window_ok | $' "$tmp/py.txt" || { echo "FAIL: 'No one knew' outside the 250-word end window misreported" >&2; return 3; }
  grep -q '^toxic_quote_mid_ok | $' "$tmp/py.txt" || { echo "FAIL: mid-line quoted spans not truncated by equal-length placeholders; a rule stitched a false hit across quotes" >&2; return 3; }
  grep -q '^toxic_multi_tail_ok | $' "$tmp/py.txt" || { echo "FAIL: rhetorical tail with a middle contrast item 'wasn't it?' misreported" >&2; return 3; }
  grep -q '^toxic_exempt_marker_ok | $' "$tmp/py.txt" || { echo "FAIL: prose marked deslop:skip was not exempted from the toxic push-back" >&2; return 3; }
  grep -q '^toxic_exempt_fullwidth_notok | Line 3 toxic pattern \[negation-parade\]' "$tmp/py.txt" || { echo "FAIL: full-width colon 'deslop：skip' wrongly exempted (the exemption regex is ASCII-colon only)" >&2; return 3; }
  grep -q '^toxic_exempt_other_nets | Line 4 engineering-word leakage' "$tmp/py.txt" || { echo "FAIL: the exemption marker must not disable nets other than toxic (engineering word missed)" >&2; return 3; }
  grep '^toxic_exempt_other_nets' "$tmp/py.txt" | grep -q 'toxic pattern' && { echo "FAIL: toxic push-back still active while the exemption marker is present" >&2; return 3; }
  grep -q '^toxic_astral_window_ok | $' "$tmp/py.txt" || { echo "FAIL: emoji placeholder length not aligned on UTF-16 code units; trailer window cut drifted" >&2; return 3; }
  grep -q '^toxic_quote_codename_ok | $' "$tmp/py.txt" || { echo "FAIL: quoted codename placeholder landed on a rule acceptance position and forged a finding" >&2; return 3; }
  grep -q '^toxic_reverse_notis | $' "$tmp/py.txt" || { echo "FAIL: apostrophe-form not-was fixture should be exempt by the quote-char guard in both engines" >&2; return 3; }
  grep -q '^toxic_forward_notis | $' "$tmp/py.txt" || { echo "FAIL: apostrophe-form not-was fixture should be exempt by the quote-char guard in both engines" >&2; return 3; }

  # AI self-reference (soft signal) anti-noop: the typical degenerate openings with
  # a model-type suffix must hit without any refusal language (previously the
  # refusal rule caught them and the AI self-reference rule had zero coverage);
  # compound nouns must not false-positive.
  grep -q '^ai_selfref_model | Line 2 meta leakage (AI self-reference)' "$tmp/py.txt" || { echo "FAIL: AI self-reference missed 'As an AI language model' (no refusal words)" >&2; return 3; }
  grep -q '^ai_selfref_assistant | Line 2 meta leakage (AI self-reference)' "$tmp/py.txt" || { echo "FAIL: AI self-reference missed 'As an AI assistant'" >&2; return 3; }
  grep -q '^ai_selfref_era_ok | $' "$tmp/py.txt" || { echo "FAIL: compound noun 'product of the AI era' false-positived as AI self-reference" >&2; return 3; }

  # Truncation terminal set: ] (chapter-end system banner closer) and ASCII "
  # (closing quote in ascii quote mode) both count as closers, aligned with the
  # deep-scan oracle check-degeneration.js findTruncation; real truncation is
  # locked by the truncate fixture.
  grep -q '^terminal_banner_ok | $' "$tmp/py.txt" || { echo "FAIL: chapter-end banner ending in ] misreported as suspected truncation" >&2; return 3; }
  grep -q '^terminal_ascii_quote_ok | $' "$tmp/py.txt" || { echo "FAIL: dialogue ending in ASCII closing quote misreported as suspected truncation" >&2; return 3; }
  grep -q '^truncate | Line 2 suspected truncation' "$tmp/py.txt" || { echo "FAIL: real truncation (no terminal punctuation) not detected" >&2; return 3; }
  grep -q '^repeat | Line 2 verbatim repeat' "$tmp/py.txt" || { echo "FAIL: back-to-back identical line not flagged as verbatim repeat" >&2; return 3; }
  grep -q '^engword | Line 2 engineering-word leakage' "$tmp/py.txt" || { echo "FAIL: engineering-word leakage not flagged" >&2; return 3; }

  # Transpile the TS: type stripping suffices (the net functions only use
  # RegExp/String/Set/Array). Prefer node native type stripping (node >= 22.6's
  # --experimental-strip-types), else a locally installed esbuild binary. Never
  # `npx --yes esbuild`: CI runs node 20 on all platforms and downloading on every
  # run is slow and fragile — B is a dev-time confirmation, CI determinism is
  # carried by A (canonical strings); without a TS runtime, B self-skips.
  cp "$OPENCODE" "$tmp/p.ts"
  # plugin.ts imports the core from ./lib/story_hook_core.js (the deploy target — a
  # lib/ subdir escapes OpenCode's single-level .opencode/plugins/*.js plugin
  # auto-discovery); mirror that layout here so the copied plugin's import resolves.
  mkdir -p "$tmp/lib"
  cp "$OPENCODE_CORE" "$tmp/lib/story_hook_core.js"
  # plugin.ts imports the net from ./lib/story_hook_core.js; re-export it from that
  # companion so the type-stripped module exposes the exact function OpenCode runs
  # at deploy time.
  printf "\nexport { proseNetFindings as _net } from './lib/story_hook_core.js'\n" >> "$tmp/p.ts"
  local ran=0
  # Run inside $tmp with relative paths: on Windows the tmp dir is an MSYS path
  # that node cannot resolve, while a cd + relative import works everywhere.
  if node --experimental-strip-types -e '' >/dev/null 2>&1; then
    ( cd "$tmp" && node --experimental-strip-types --input-type=module -e "
      import { _net } from './p.ts';
      import fs from 'node:fs';
      const fx = JSON.parse(fs.readFileSync('./fixtures.json','utf-8'));
      for (const k of Object.keys(fx).sort()) console.log(k, '|', _net(fx[k]).join(' ;; '));
    " ) > "$tmp/ts.txt" 2>/dev/null && ran=1
  fi
  if [ "$ran" -eq 0 ] && command -v esbuild >/dev/null 2>&1; then
    if esbuild "$tmp/p.ts" --format=esm --platform=node --log-level=silent --outfile="$tmp/p.mjs" >/dev/null 2>&1; then
      ( cd "$tmp" && node --input-type=module -e "
        import { _net } from './p.mjs';
        import fs from 'node:fs';
        const fx = JSON.parse(fs.readFileSync('./fixtures.json','utf-8'));
        for (const k of Object.keys(fx).sort()) console.log(k, '|', _net(fx[k]).join(' ;; '));
      " ) > "$tmp/ts.txt" 2>/dev/null && ran=1
    fi
  fi
  [ "$ran" -eq 0 ] && return 2

  if ! diff "$tmp/py.txt" "$tmp/ts.txt" >/dev/null; then
    echo "FAIL: functional parity mismatch (codex python net vs opencode TS net):" >&2
    diff "$tmp/py.txt" "$tmp/ts.txt" >&2 || true
    return 3
  fi
  return 0
}

# ── C. Command-function parity (codex python vs zcode JS), CI hard gate ────────
# Prose-target extraction (redirection / tee / touch / cp·mv), apply-patch targets,
# and git-commit detection — three pure functions (command string -> values) — must
# be character-identical on the fixtures below. They were previously hand-copied
# py/js with no guard and drifted (cp·mv arity, git control words then/do/else/elif,
# subshell parens). node+python3 exist on all CI platforms, so this is a hard gate.
# Note: the fixtures take the converged subset; quoted separators inside quotes
# (echo "a; git commit") and command substitution ($(git commit)) legitimately
# differ between ends (py uses shlex and respects quotes, js splits raw) — not this
# net's concern and only advisory, never blocking.
run_cmd_parity() {
  command -v node >/dev/null 2>&1 || return 1
  command -v "$PYBIN" >/dev/null 2>&1 || return 1
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  cat > "$tmp/cmd.json" <<'EOF'
{
  "redirect": "echo x > book/prose/chapter_1.md",
  "append": "cat a >> prose.md",
  "tee": "echo x | tee book/prose/chapter_2.md",
  "tee_a": "printf y | tee -a prose.md",
  "touch": "touch book/prose/chapter_3.md",
  "cp": "cp src.md book/prose/chapter_4.md",
  "mv2": "mv prose.md",
  "cp_flag": "cp -f a.md prose.md",
  "mention": "grep -n book/prose/chapter_1.md notes.md",
  "redirect_quoted_space": "cat draft.md > \"my book/prose/chapter_1_x.md\"",
  "redirect_fullwidth_space": "cat draft.md > book/prose/chapter_003　prologue.md",
  "tee_quoted_space": "printf x | tee 'my book/prose/chapter_1_x.md'",
  "cp_quoted_space": "cp draft.md \"my book/prose/chapter_1_x.md\"",
  "cp_quoted_operator": "cp draft.md \"book|archive/prose/chapter_11.md\"",
  "patch_add": "*** Begin Patch\n*** Add File: book/prose/chapter_5.md\n+prose\n*** End Patch",
  "patch_move": "*** Begin Patch\n*** Update File: draft.md\n*** Move to: book/prose/chapter_6.md\n+prose\n*** End Patch",
  "patch_move_delete": "*** Begin Patch\n*** Delete File: draft.md\n*** Move to: book/prose/chapter_7.md\n*** End Patch",
  "patch_move_out": "*** Begin Patch\n*** Update File: book/prose/chapter_8.md\n*** Move to: draft.md\n+x\n*** End Patch",
  "patch_delete_only": "*** Begin Patch\n*** Delete File: book/prose/chapter_9.md\n*** End Patch",
  "patch_multi_move": "*** Begin Patch\n*** Add File: notes.md\n+x\n*** Update File: draft.md\n*** Move to: book/prose/chapter_10.md\n+prose\n*** End Patch",
  "patch_context_move": "*** Begin Patch\n*** Update File: book/prose/chapter_12.md\n@@\n *** Move to: notes.md\n+prose\n*** End Patch",
  "commit_plain": "git commit -m x",
  "commit_chain": "git add . && git commit -m x",
  "commit_if": "if true; then git commit -m x; fi",
  "commit_for": "for f in *; do git commit -am x; done",
  "commit_subshell": "(cd sub && git commit)",
  "commit_env": "FOO=1 git commit",
  "commit_config": "git -c user.name=x commit",
  "commit_C": "git -C sub commit -m y",
  "noncommit_echo": "echo git commit docs",
  "noncommit_status": "git status && echo done"
}
EOF
  "$PYBIN" - "$CODEX" "$tmp/cmd.json" > "$tmp/cpy.txt" <<'PY'
import importlib.util, sys, json
spec = importlib.util.spec_from_file_location("ch", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
fx = json.load(open(sys.argv[2], encoding='utf-8'))
for k in sorted(fx):
    c = fx[k]
    line = f"{k} :: pros=[{'|'.join(m.extract_prose_targets_from_command(c))}] patch=[{'|'.join(m.extract_apply_patch_targets(c))}] commit={'1' if m.is_git_commit_command(c) else '0'}"
    sys.stdout.buffer.write((line + "\n").encode("utf-8"))
PY
  node - "$ZCODE" "$tmp/cmd.json" > "$tmp/cjs.txt" <<'JS'
const h = require(process.argv[2])
const fx = require(process.argv[3])
for (const k of Object.keys(fx).sort()) {
  const c = fx[k]
  console.log(`${k} :: pros=[${h.extractProseTargets(c).join("|")}] patch=[${h.extractPatchTargets(c).join("|")}] commit=${h.isGitCommitCommand(c) ? "1" : "0"}`)
}
JS
  if ! diff "$tmp/cpy.txt" "$tmp/cjs.txt" >/dev/null; then
    echo "FAIL: command-function parity mismatch (codex python vs zcode JS):" >&2
    diff "$tmp/cpy.txt" "$tmp/cjs.txt" >&2 || true
    return 3
  fi
  # Anti-noop: quoted targets with spaces / full-width spaces must be taken whole
  # (both ends could agree on the same wrong output and still pass the diff). A
  # char class that uses \s would cut "chapter_003　prologue.md" at the full-width
  # space, and excluding quotes from the class would drop quoted paths entirely —
  # silently letting the prose guard pass.
  grep -q 'redirect_quoted_space :: pros=\[my book/prose/chapter_1_x.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: quoted redirection target with a space not taken whole (quotes not respected)" >&2; return 3; }
  grep -q 'redirect_fullwidth_space :: pros=\[book/prose/chapter_003　prologue.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: full-width-space chapter name truncated by \\s (U+3000 is not a shell word splitter)" >&2; return 3; }
  grep -q 'tee_quoted_space :: pros=\[my book/prose/chapter_1_x.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: quoted tee target with a space not taken whole" >&2; return 3; }
  grep -q 'cp_quoted_space :: pros=\[my book/prose/chapter_1_x.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: cp quoted target chopped on whitespace; the last word resolved to another book's path" >&2; return 3; }
  grep -q 'cp_quoted_operator :: pros=\[book|archive/prose/chapter_11.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: | inside a cp quoted target treated as a shell pipe; the prose guard would silently pass" >&2; return 3; }
  # Anti-noop (apply_patch move form): `*** Move to:` is a sub-directive of the
  # Update/Delete File section; the written path is the *destination*. Only
  # recognizing Add/Update File would take the source draft.md for
  # "Update draft.md + Move to book/prose/chapter_N.md" — the outline gate would
  # pass wholesale and the after-write net would scan a source that no longer
  # exists (both ends could agree and the diff still pass).
  grep -q 'patch_move :: pros=\[\] patch=\[book/prose/chapter_6.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: apply_patch *** Move to: destination not in the target table (source is moved away, only the destination lands)" >&2; return 3; }
  grep -q 'patch_move_delete :: pros=\[\] patch=\[book/prose/chapter_7.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: *** Delete File: + *** Move to: destination not in the target table" >&2; return 3; }
  grep -q 'patch_move_out :: pros=\[\] patch=\[draft.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: when moving out of prose/, the source is still judged as a write target (source no longer exists; only the destination should be judged)" >&2; return 3; }
  grep -q 'patch_delete_only :: pros=\[\] patch=\[\]' "$tmp/cpy.txt" \
    || { echo "FAIL: a bare *** Delete File: must not enter the target table (deletion is not a write; accepting it would misfire on deletions)" >&2; return 3; }
  grep -q 'patch_multi_move :: pros=\[\] patch=\[notes.md|book/prose/chapter_10.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: Add and Move sections in one patch not both taken (Move must only replace the same section's source)" >&2; return 3; }
  grep -q 'patch_context_move :: pros=\[\] patch=\[book/prose/chapter_12.md\]' "$tmp/cpy.txt" \
    || { echo "FAIL: a literal *** Move to inside a patch context line treated as a control directive, dropping the real prose target" >&2; return 3; }

  # ReDoS regression (shellWords): callers split on [;&|\n] first, which splits a
  # | inside quotes and leaves an unclosed quote. The old
  # /"(?:\\.|[^"])*"|'[^']*'|[^\s]+/ let both \\. and [^"] eat backslashes, doubling
  # the search space per backslash — a ~130-char commit command measured tens of
  # seconds of CPU (killed by zcode hooks.json's timeoutMs 15000). The linear
  # hand-rolled splitter must decide in milliseconds, so allow a 2s budget (the
  # python side's shlex is linear; timed too, to catch drift).
  node - "$ZCODE" > "$tmp/redos.txt" <<'JS' || return 3
const h = require(process.argv[2])
const cmd = 'git commit -m "fix: regex escaping ' + Array.from({ length: 18 }, () => "\\\\x").join(" ") + ' covered | see README"'
const t0 = Date.now()
const hit = h.isGitCommitCommand(cmd)
const ms = Date.now() - t0
if (!hit) { console.error("FAIL: git commit detection missed a commit command with escapes and a pipe"); process.exit(3) }
if (ms > 2000) { console.error(`FAIL: shellWords backtracking blowup (${ms}ms > 2000ms); the host hook would be killed by its timeout`); process.exit(3) }
console.log(`redos_budget :: ${ms}ms`)
JS
  "$PYBIN" - "$CODEX" >> "$tmp/redos.txt" <<'PY' || return 3
import importlib.util, sys, time
spec = importlib.util.spec_from_file_location("ch", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cmd = 'git commit -m "fix: regex escaping ' + " ".join([r"\\x"] * 18) + ' covered | see README"'
t0 = time.time()
hit = m.is_git_commit_command(cmd)
ms = int((time.time() - t0) * 1000)
# Failure copy goes through stderr.buffer as raw UTF-8 bytes: Windows python's
# text stderr is cp1252 and non-ASCII would raise UnicodeEncodeError.
if not hit:
    sys.stderr.buffer.write("FAIL: py git commit detection missed a commit command with escapes and a pipe\n".encode("utf-8")); sys.exit(3)
if ms > 2000:
    sys.stderr.buffer.write(f"FAIL: py git commit detection became nonlinear ({ms}ms > 2000ms)\n".encode("utf-8")); sys.exit(3)
PY
  return 0
}

# ── D. Claude core-delegation regression guard (CI hard gate) ──────────────
# Claude's 4 bash hooks (check-prose-after-write / guard-outline-before-prose /
# validate-story-commit / detect-story-gaps) no longer embed heredoc python; they
# call the same node shared core story_hook_core.js (via story_hook_cli.js) — the
# prose net / word count / outline guard / git-commit detection / continuity. That
# core is the same file OpenCode/ZCode use (byte-identity enforced by
# check-shared-files) and is already locked to codex by Parts B/C, so
# claude==codex closes structurally without re-running extracted heredocs. Two
# anti-regressions: ① the 4 hooks must not reintroduce heredoc python (someone
# hand-copying back a 5th implementation); ② they must call the core through
# story_hook_cli.js.
run_claude_core_check() {
  local hooks_dir cli bad=0 hook
  hooks_dir="$(dirname "$CLAUDE")"
  cli="$hooks_dir/story_hook_cli.js"
  [ -f "$cli" ] || { echo "FAIL: missing story_hook_cli.js (Claude's bridge to the shared core)" >&2; return 3; }
  [ -f "$hooks_dir/story_hook_core.js" ] || { echo "FAIL: missing story_hook_core.js (Claude shared-core copy)" >&2; return 3; }
  if command -v node >/dev/null 2>&1; then
    node --check "$cli" >/dev/null 2>&1 || { echo "FAIL: story_hook_cli.js node syntax error" >&2; return 3; }
  fi
  for hook in check-prose-after-write guard-outline-before-prose validate-story-commit detect-story-gaps; do
    if grep -q "<<'PY'" "$hooks_dir/$hook.sh"; then
      echo "FAIL: $hook.sh embedded heredoc python again (should call the node shared core via story_hook_cli.js)" >&2; bad=1
    fi
    grep -q 'story_hook_cli\.js' "$hooks_dir/$hook.sh" || { echo "FAIL: $hook.sh does not call the shared core via story_hook_cli.js" >&2; bad=1; }
  done
  [ "$bad" -eq 0 ] || return 3
  return 0
}

# ── E. Uncored-surface parity (codex python vs JS core), CI hard gate ────────
# staged markdown warnings and the prose-block decision are not in the shared
# core: codex python (staged_markdown_warnings / prose_block_reason) and the JS
# core (stagedMarkdownWarnings / proseBlockReason) each carry an implementation;
# semantics and copy are JS-core authoritative, compared character-identically on
# fixtures to prevent drift. The Claude-side pure-bash implementations are not
# byte-locked here; runtime behavior is covered by check-story-setup-deployment.sh
# / test-hook-encoding-portable.sh.
# Fixture coverage: ① name-field case variants (NAME / full-width-space padding)
# hit identically — a present field never warns; ② missing field / hardcoded
# attributes warn with identical copy (frame lines included); ③ long-form missing
# outline / outline present, short-form missing section-outline / no setting
# signal — 4 block decisions with identical copy; ④ toxic-debt gate: debt blocks,
# the deslop:skip marker (ASCII colon) exempts, the full-width-colon variant does
# NOT (the exemption regex is ASCII-colon only), and a previous chapter with a bad
# byte still decodes with replacement and keeps scanning.
run_uncored_parity() {
  command -v node >/dev/null 2>&1 || return 1
  command -v "$PYBIN" >/dev/null 2>&1 || return 1
  command -v git >/dev/null 2>&1 || return 1
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # E1: staged markdown warnings — build a standalone git repo and stage a fixed file set
  local repo="$tmp/repo"
  mkdir -p "$repo/book/prose" "$repo/setting"
  git -C "$repo" init -q
  printf 'height: 180\nHe pushed the door open.\nage : 18\n' > "$repo/book/prose/chapter_1.md"
  printf 'NAME: Lin Yuan\n' > "$repo/setting/protagonist.md"     # case variant: field present, no warning
  printf '　NAME　: Su Li\n' > "$repo/setting/side_character.md" # full-width-space padding: field present, no warning
  printf 'Bio: no name field\n' > "$repo/setting/villain.md"     # missing field: warns
  # Character-sheet narrowing: only files under a setting/characters|people
  # subdirectory + flat character cards directly under setting/ get the name-field
  # check; project-level setting files (relationships/style/…) and non-character
  # subdirectories are skipped. All ends (bash/OpenCode/JS/py) share this scope;
  # py↔js is locked here so neither end can regress to the "whole setting/ tree"
  # false-warning version.
  mkdir -p "$repo/setting/characters" "$repo/setting/worldview"
  printf 'Bio: no name field\n' > "$repo/setting/characters/rookie.md" # character subdir: missing field, warns
  printf '# Character Relationship Map\n' > "$repo/setting/relationships.md" # project-level file: no warning
  printf '# Style\n' > "$repo/setting/style.md"                           # project-level file: no warning
  printf '# Geography\n' > "$repo/setting/worldview/geography.md"          # non-character subdir: whole dir skipped
  git -C "$repo" add -A

  "$PYBIN" - "$CODEX" "$repo" > "$tmp/spy.txt" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("ch", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
out = m.staged_markdown_warnings(Path(sys.argv[2]))
sys.stdout.buffer.write((out + "\n").encode("utf-8"))
PY
  node - "$CLAUDE_CORE" "$repo" > "$tmp/sjs.txt" <<'JS'
const core = require(process.argv[2])
console.log(core.stagedMarkdownWarnings(process.argv[3]))
JS
  # The python mirror's frame header still uses full-width parentheses
  # ("=== Story Commit Warnings（advisory only）===") — a pre-existing cosmetic
  # drift from the English migration; the JS core's ASCII header is authoritative.
  # Compare every body line byte-for-byte (headers dropped), and pin the body copy
  # with the greps below.
  if ! diff <(tail -n +2 "$tmp/spy.txt") <(tail -n +2 "$tmp/sjs.txt") >/dev/null; then
    echo "FAIL: staged warnings parity mismatch (codex python vs JS core):" >&2
    diff "$tmp/spy.txt" "$tmp/sjs.txt" >&2 || true
    return 3
  fi
  # Anti-noop (both ends outputting empty would pass the diff): pin the hits/misses
  # and the unified copy.
  grep -q 'prose hardcodes character attributes; reference the setting file instead' "$tmp/spy.txt" || { echo "FAIL: staged warnings did not flag hardcoded attributes with the unified copy" >&2; return 3; }
  grep -q 'villain.md: setting file is missing the required name field.' "$tmp/spy.txt" || { echo "FAIL: staged warnings did not flag the missing name field with the unified copy" >&2; return 3; }
  grep -q 'protagonist.md' "$tmp/spy.txt" && { echo "FAIL: uppercase NAME: should count as the field present (case-insensitive)" >&2; return 3; }
  grep -q 'side_character.md' "$tmp/spy.txt" && { echo "FAIL: full-width-space padded NAME : should count as the field present" >&2; return 3; }
  grep -q 'setting/characters/rookie.md: setting file is missing the required name field.' "$tmp/spy.txt" || { echo "FAIL: a character card under setting/characters should still be checked for the name field" >&2; return 3; }
  grep -q 'relationships.md' "$tmp/spy.txt" && { echo "FAIL: project-level setting file relationships.md must not be name-checked" >&2; return 3; }
  grep -q 'style.md' "$tmp/spy.txt" && { echo "FAIL: project-level setting file style.md must not be name-checked" >&2; return 3; }
  grep -q 'geography.md' "$tmp/spy.txt" && { echo "FAIL: non-character subdirs under setting/ must be skipped wholesale" >&2; return 3; }

  # E2: prose-block decision — 9 decisions: long-form missing outline (block) /
  # outline present (pass); short-form missing section-outline (block) / no setting
  # signal (pass); the toxic-debt gate (previous chapter has debt -> block; the
  # deslop:skip marker -> exempt/pass; the full-width-colon marker -> NOT exempt,
  # still blocks; previous chapter with a bad byte decodes with replacement and
  # still scans); and a brand-new book with no scaffolding must still build the
  # chapter outline first (fail closed).
  local blk="$tmp/blk"
  mkdir -p "$blk/long/prose" "$blk/long/outline" "$blk/short" "$blk/short2" \
    "$blk/long2/prose" "$blk/long2/outline" "$blk/long3/prose" "$blk/long3/outline"
  : > "$blk/long/outline/outline_chapter_2.md"
  : > "$blk/short/setting.md"
  : > "$blk/short2/other.md"
  : > "$blk/long2/outline/outline_chapter_2.md"
  printf '%s\n' '# Chapter 1 Old' '' 'His voice was quiet, but it carried an edge.' > "$blk/long2/prose/chapter_1_old.md"
  : > "$blk/long3/outline/outline_chapter_2.md"
  printf '%s\n' '# Chapter 1 Old' '<!-- deslop:skip -->' 'His voice was quiet, but it carried an edge.' > "$blk/long3/prose/chapter_1_old.md"
  mkdir -p "$blk/long4/prose" "$blk/long4/outline" "$blk/long5/prose" "$blk/long5/outline"
  : > "$blk/long4/outline/outline_chapter_2.md"
  printf '%s\n' '# Chapter 1 Old' '<!-- deslop：skip -->' 'His voice was quiet, but it carried an edge.' > "$blk/long4/prose/chapter_1_old.md"
  : > "$blk/long5/outline/outline_chapter_2.md"
  { printf '%s\n' '# Chapter 1 Old' 'His voice was quiet, but it carried an edge.'; printf '\xff\n'; } > "$blk/long5/prose/chapter_1_old.md"
  # canonical case: an agent first-writes {book}/prose/chapter_N.md before any
  # outline/tracking/setting scaffolding exists — must fail closed; cwd semantics
  # for relative targets belong to each host adapter, not to weakening this
  # canonical guard.
  mkdir -p "$blk/bare/prose"

  "$PYBIN" - "$CODEX" "$blk" > "$tmp/bpy.txt" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("ch", sys.argv[1]); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
root = Path(sys.argv[2])
for rel in ["long/prose/chapter_1_begin.md", "long/prose/chapter_2_continue.md", "short/prose.md", "short2/prose.md", "long2/prose/chapter_2_new.md", "long3/prose/chapter_2_new.md", "long4/prose/chapter_2_new.md", "long5/prose/chapter_2_new.md", "bare/prose/chapter_1_begin.md"]:
    reason = m.prose_block_reason(root, root / rel)
    sys.stdout.buffer.write((f"{rel} :: {reason if reason else '-'}\n").encode("utf-8"))
PY
  node - "$CLAUDE_CORE" "$blk" > "$tmp/bjs.txt" <<'JS'
const path = require("node:path")
const core = require(process.argv[2])
const root = process.argv[3]
for (const rel of ["long/prose/chapter_1_begin.md", "long/prose/chapter_2_continue.md", "short/prose.md", "short2/prose.md", "long2/prose/chapter_2_new.md", "long3/prose/chapter_2_new.md", "long4/prose/chapter_2_new.md", "long5/prose/chapter_2_new.md", "bare/prose/chapter_1_begin.md"]) {
  const reason = core.proseBlockReason(root, path.join(root, rel))
  console.log(`${rel} :: ${reason || "-"}`)
}
JS
  if ! diff "$tmp/bpy.txt" "$tmp/bjs.txt" >/dev/null; then
    echo "FAIL: prose-block parity mismatch (codex python vs JS core):" >&2
    diff "$tmp/bpy.txt" "$tmp/bjs.txt" >&2 || true
    return 3
  fi
  grep -q 'chapter_1_begin.md :: ⛔' "$tmp/bpy.txt" || { echo "FAIL: long-form missing chapter outline not blocked" >&2; return 3; }
  grep -q 'chapter_2_continue.md :: -' "$tmp/bpy.txt" || { echo "FAIL: long-form with outline present falsely blocked" >&2; return 3; }
  grep -q 'short/prose.md :: ⛔' "$tmp/bpy.txt" || { echo "FAIL: short-form missing section-outline.md not blocked" >&2; return 3; }
  grep -q 'short2/prose.md :: -' "$tmp/bpy.txt" || { echo "FAIL: prose.md without a setting signal falsely blocked" >&2; return 3; }
  grep -q 'uncleared toxic patterns' "$tmp/bpy.txt" || { echo "FAIL: previous chapter with toxic debt not blocked by the debt gate" >&2; return 3; }
  grep -q 'long3/prose/chapter_2_new.md :: -' "$tmp/bpy.txt" || { echo "FAIL: previous chapter marked deslop:skip still blocked by the debt gate" >&2; return 3; }
  grep -q 'long4/prose/chapter_2_new.md :: ⛔' "$tmp/bpy.txt" || { echo "FAIL: full-width-colon 'deslop：skip' wrongly exempted (the exemption regex is ASCII-colon only)" >&2; return 3; }
  grep -q 'long5/prose/chapter_2_new.md :: ⛔' "$tmp/bpy.txt" || { echo "FAIL: previous chapter with a bad byte must decode with replacement and keep scanning (no wholesale pass)" >&2; return 3; }
  grep -q 'bare/prose/chapter_1_begin.md :: ⛔' "$tmp/bpy.txt" || { echo "FAIL: a brand-new book with no outline/tracking/setting scaffolding must fail closed" >&2; return 3; }
  return 0
}

set +e
run_functional
rc=$?
set -e
case "$rc" in
  0) echo "Functional parity: codex python net == opencode TS net == zcode JS net (39 fixtures character-identical, incl. toxic positives/negatives, AI self-reference, truncation terminals, and the exemption marker)." ;;
  2) echo "Functional parity: skipped (no TS runtime; canonical-string check gives the CI-safe guarantee)." ;;
  *) fails=$((fails + 1)) ;;
esac

set +e
run_cmd_parity
rc_cmd=$?
set -e
case "$rc_cmd" in
  0) echo "Command-function parity: codex python == zcode JS (31 fixtures: prose extraction / apply-patch / git-commit detection character-identical, incl. quoted operators/spaces/full-width-space targets, apply_patch moves and context pseudo-directives, ReDoS budget)." ;;
  1) echo "Command-function parity: skipped (no node/python3 runtime)." ;;
  *) fails=$((fails + 1)) ;;
esac

set +e
run_claude_core_check
rc_claude=$?
set -e
case "$rc_claude" in
  0) echo "Claude core-delegation regression: the 4 bash hooks have no embedded python and all call the shared core via story_hook_cli.js (same core as OpenCode/ZCode, locked to codex by B/C)." ;;
  *) fails=$((fails + 1)) ;;
esac

set +e
run_uncored_parity
rc_uncored=$?
set -e
case "$rc_uncored" in
  0) echo "Uncored-surface parity: codex python == JS core (staged warnings case variants + copy; 9 prose-block decisions incl. the toxic-debt gate, full-width-colon non-exemption, bad-byte decode, and no-scaffolding fail-closed; copy character-identical)." ;;
  1) echo "Uncored-surface parity: skipped (no node/python3/git runtime)." ;;
  *) fails=$((fails + 1)) ;;
esac

if [ "$fails" -ne 0 ]; then
  echo "Prose net parity tests FAILED ($fails)." >&2
  exit 1
fi
echo "Prose net parity tests passed."
