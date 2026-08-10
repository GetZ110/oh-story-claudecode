#!/bin/bash
# test-ai-patterns.sh — regression tests for the deterministic English AI-pattern detector.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: not in a git repository" >&2
  exit 1
fi

SCRIPT="$REPO_ROOT/skills/story-deslop/scripts/check-ai-patterns.js"
DETECTOR_COPIES=(
  "$REPO_ROOT/skills/story-deslop/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-long-write/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-review/scripts/check-ai-patterns.js"
  "$REPO_ROOT/skills/story-short-write/scripts/check-ai-patterns.js"
)
for detector_copy in "${DETECTOR_COPIES[@]}"; do
  node --check "$detector_copy" >/dev/null
  cmp -s "$SCRIPT" "$detector_copy" || {
    echo "FAIL: detector copy drifted from story-deslop source: $detector_copy" >&2
    exit 1
  }
done
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

FIXTURE="$TMP_DIR/fixture.md"
OUT="$TMP_DIR/out.json"

# --- kind-of construction ("the kind of X that Y", advisory per occurrence) ---
# YAML front matter, fenced blocks, quoted dialogue, and constructions without
# "that/who/which/to" must stay silent.
cat > "$FIXTURE" <<'EOF'
---
title: The Oath
---
It was the kind of smile that never reached her eyes.
She wore the kind of patience that only comes with age.
```
It was the kind of grin that never reached his eyes.
```
She smiled, and the smile stopped at her lips.
"The kind of tired that comes from driving all night is familiar to every courier," he said.
EOF

set +e
node "$SCRIPT" --json "$FIXTURE" > "$OUT"
status=$?
set -e

if [ "$status" -ne 1 ]; then
  echo "FAIL: expected detector to exit 1 for positive findings, got $status" >&2
  cat "$OUT" >&2 || true
  exit 1
fi

node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const findings = report.findings;
const excerpts = findings.map((finding) => finding.excerpt);

if (findings.length !== 2) {
  throw new Error(`expected 2 kind-of findings, got ${findings.length}: ${JSON.stringify(excerpts)}`);
}
for (const type of findings.map((f) => f.type)) {
  if (type !== 'kind-of') throw new Error(`unexpected finding type: ${type}`);
}
for (const excerpt of ['the kind of smile that', 'the kind of patience that']) {
  if (!excerpts.includes(excerpt)) {
    throw new Error(`missing expected excerpt: ${excerpt}; got ${JSON.stringify(excerpts)}`);
  }
}
if (findings.some((f) => f.severity !== 'advisory')) {
  throw new Error('kind-of should be advisory');
}
// Fenced block and quoted dialogue must not count.
for (const marker of ['the kind of grin', 'the kind of tired']) {
  if (excerpts.some((excerpt) => excerpt.includes(marker))) {
    throw new Error(`false positive: "${marker}" was flagged; got ${JSON.stringify(excerpts)}`);
  }
}
NODE

echo "AI pattern detector (kind-of) regression tests passed."

# --- Paragraph-level detection: period stutter / em-dash cluster / long paragraph ---
FIXTURE2="$TMP_DIR/fixture-prose.md"
LONG_PARA="He walked down the long corridor, past one heavy wooden door after another, and then past"
i=0
while [ "$i" -lt 18 ]; do
  LONG_PARA="${LONG_PARA} one more heavy wooden door,"
  i=$((i + 1))
done
LONG_PARA="${LONG_PARA} and stopped at last at the end, staring at the dark red stain for a long time."
{
  # 6 consecutive short narrative sentences -> period stutter
  printf '%s\n' 'He stood up.' 'He walked over.' 'The door opened.' 'Wind came in.' 'He stopped.' 'His heart sank.'
  # 6 short dialogue lines -> must NOT trip period stutter (staccato dialogue is normal genre form)
  printf '%s\n' '"That'"'"'s really fine."' '"Not hard at all."' '"I trust you."' '"Don'"'"'t worry."' '"Okay."' '"Mm."'
  # 2+ em dashes on one line -> em-dash cluster (blocking)
  printf '%s\n' 'She paused — she didn'"'"'t speak — she waited.'
  # single over-long paragraph -> long-paragraph (advisory)
  printf '%s\n' "$LONG_PARA"
} > "$FIXTURE2"

set +e
node "$SCRIPT" --json "$FIXTURE2" > "$OUT"
status=$?
set -e
if [ "$status" -ne 1 ]; then
  echo "FAIL: expected prose detector to exit 1 for positive findings, got $status" >&2
  cat "$OUT" >&2 || true
  exit 1
fi

node - "$OUT" <<'NODE'
const fs = require('fs');
const report = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const counts = report.findings.reduce((m, f) => ((m[f.type] = (m[f.type] || 0) + 1), m), {});

// Exactly one of each prose type, nothing else. The 6 dialogue lines must NOT trip
// period stutter (staccato dialogue is a normal genre form — only narrative runs count).
if (report.findings.length !== 3) {
  throw new Error(`expected 3 prose findings, got ${report.findings.length}: ${JSON.stringify(report.findings.map((f) => `${f.type}@${f.line}`))}`);
}
for (const type of ['period-stutter', 'em-dash-cluster', 'long-paragraph']) {
  if (counts[type] !== 1) throw new Error(`expected exactly 1 ${type}, got ${counts[type] || 0}`);
}
// period stutter must flag the narrative block (line 1), not the dialogue cluster (lines 7-12).
const stutter = report.findings.find((f) => f.type === 'period-stutter');
if (stutter.line !== 1) {
  throw new Error(`period-stutter should start at the narrative block (line 1), got line ${stutter.line}`);
}
const dash = report.findings.find((f) => f.type === 'em-dash-cluster');
if (dash.severity !== 'blocking') throw new Error('em-dash-cluster should be blocking');
NODE

# --- period stutter on a mixed line (narration + quoted object) is NOT exempt by one quote ---
FIXTURE3="$TMP_DIR/fixture-mixed-quote.md"
printf '%s\n' 'He stood. He saw the "door". Wind came in. He turned. The light died. His heart sank.' > "$FIXTURE3"
set +e
node "$SCRIPT" --json "$FIXTURE3" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const st = r.findings.filter((f) => f.type === 'period-stutter');
if (st.length !== 1) throw new Error('mixed narration+quoted line should hit period-stutter: ' + JSON.stringify(r.findings.map((f) => f.type)));
if (st[0].severity !== 'advisory') throw new Error('period-stutter should be advisory');
NODE

# Pure-dialogue short runs stay exempt (genre device).
FIXTURE4="$TMP_DIR/fixture-pure-dialogue.md"
printf '%s\n' '"Go."' '"Quick."' '"Run."' '"Stop."' '"Look."' '"Listen."' > "$FIXTURE4"
set +e
pure_out="$(node "$SCRIPT" "$FIXTURE4" 2>&1)"
pure_status=$?
set -e
if [ "$pure_status" -ne 0 ]; then
  echo "FAIL: pure-dialogue short run misflagged as period stutter (exit $pure_status):" >&2
  echo "$pure_out" >&2
  exit 1
fi

# Markdown structure lines (headings) are not narrative prose: no long-paragraph.
FIXTURE5="$TMP_DIR/fixture-heading.md"
node -e 'process.stdout.write("## " + "word ".repeat(230) + "\n")' > "$FIXTURE5"
set +e
head_out="$(node "$SCRIPT" "$FIXTURE5" 2>&1)"
head_status=$?
set -e
if [ "$head_status" -ne 0 ]; then
  echo "FAIL: markdown heading misflagged as long-paragraph (exit $head_status):" >&2
  echo "$head_out" >&2
  exit 1
fi

# --- severity + --fail-on semantics: advisory-only (long-paragraph) exits 1 by
# default and 0 under --fail-on=blocking ---
FIXTURE6="$TMP_DIR/fixture-advisory.md"
LONG_PARA="He walked down the long corridor, past one heavy wooden door after another, and then past"
i=0
while [ "$i" -lt 18 ]; do
  LONG_PARA="${LONG_PARA} one more heavy wooden door,"
  i=$((i + 1))
done
LONG_PARA="${LONG_PARA} and stopped at last at the end, staring at the dark red stain for a long time."
printf '%s\n' "$LONG_PARA" > "$FIXTURE6"
set +e
node "$SCRIPT" --json "$FIXTURE6" > "$OUT"
adv_all=$?
node "$SCRIPT" --fail-on=blocking "$FIXTURE6" >/dev/null 2>&1
adv_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
if (!r.findings.length) throw new Error('expected long-paragraph finding');
if (!r.findings.every((f) => f.severity === 'advisory')) {
  throw new Error('long-paragraph-only fixture should be all advisory: ' + JSON.stringify(r.findings.map((f) => f.severity)));
}
NODE
[ "$adv_all" -eq 1 ] || { echo "FAIL: advisory-only --fail-on=all should exit 1, got $adv_all" >&2; exit 1; }
[ "$adv_blk" -eq 0 ] || { echo "FAIL: advisory-only --fail-on=blocking should exit 0, got $adv_blk" >&2; exit 1; }

# blocking (em-dash-cluster): severity=blocking, --fail-on=blocking exits 1.
FIXTURE7="$TMP_DIR/fixture-blocking.md"
printf '%s\n' 'She paused — she didn'"'"'t speak — she waited.' > "$FIXTURE7"
set +e
node "$SCRIPT" --json "$FIXTURE7" > "$OUT"
node "$SCRIPT" --fail-on=blocking "$FIXTURE7" >/dev/null 2>&1
blk_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const dash = r.findings.find((f) => f.type === 'em-dash-cluster');
if (!dash || dash.severity !== 'blocking') throw new Error('em-dash-cluster should be blocking: ' + JSON.stringify(dash));
NODE
[ "$blk_blk" -eq 1 ] || { echo "FAIL: em-dash-cluster --fail-on=blocking should exit 1, got $blk_blk" >&2; exit 1; }

echo "Prose pattern (period-stutter / em-dash-cluster / long-paragraph) regression tests passed."

# --- An unclosed opening quote must not swallow following narration: the line with
# an unpaired quote is skipped, but later narration lines are still scanned. ---
FIXTURE_UNCLOSED_QUOTE="$TMP_DIR/fixture-unclosed-quote.md"
printf '%s\n' \
  'She finally spoke: "I don'"'"'t want to talk about this anymore.' \
  'He did not answer.' \
  'He didn'"'"'t understand her. He just stayed silent.' \
  'She lowered her head. "Forget it."' > "$FIXTURE_UNCLOSED_QUOTE"
set +e
node "$SCRIPT" --json "$FIXTURE_UNCLOSED_QUOTE" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const np = r.findings.filter((f) => f.type === 'negation-parade');
if (np.length !== 1) throw new Error('narration after an unclosed quote should hit 1 negation-parade: ' + JSON.stringify(r.findings.map((f) => `${f.type}@${f.line}`)));
if (np[0].line !== 3) throw new Error('negation-parade should land on line 3, got ' + np[0].line);
if (np[0].severity !== 'blocking') throw new Error('negation-parade should be blocking');
NODE

echo "Unclosed-quote handling regression tests passed."

# --- Hedged micro-beat repetition ("smiled slightly / nodded gently", advisory density) ---
FIXTURE8="$TMP_DIR/fixture-micro-tic.md"
printf '%s\n' \
  'His father paused briefly, then retied the rope on the frame.' \
  'He pulled the rope tight and glanced quietly at the leaves stuck to his hand.' \
  'His mother sliced for a while, then stopped; she sighed softly and set the spatula down.' \
  'He wound the thread once, looked carefully at the knot, and nodded gently.' \
  'She leaned slightly against the doorframe, smiled faintly, and whispered quietly.' > "$FIXTURE8"
set +e
node "$SCRIPT" --json "$FIXTURE8" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const mt = r.findings.filter((f) => f.type === 'micro-action-tic');
if (mt.length !== 1) throw new Error('high hedged-beat density should report 1 micro-action-tic: ' + JSON.stringify(r.findings.map((f) => f.type)));
if (mt[0].severity !== 'advisory') throw new Error('micro-action-tic should be advisory');
if (!mt[0].excerpt.includes('paused briefly') || !mt[0].excerpt.includes('sighed softly')) {
  throw new Error('micro-action-tic excerpt should include hedged-beat samples: ' + JSON.stringify(mt[0]));
}
NODE

# advisory does not trigger --fail-on=blocking (hedged beats are a hint, not a blocker).
set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE8" > /dev/null 2>&1
tic_blk=$?
set -e
[ "$tic_blk" -eq 0 ] || { echo "FAIL: micro-action-tic --fail-on=blocking should exit 0, got $tic_blk" >&2; exit 1; }

# Low density (a single hedged beat in clean prose) does not fire; quoted beats don't count.
FIXTURE9="$TMP_DIR/fixture-micro-tic-normal.md"
printf '%s\n' \
  'He got home to find his father tying the rope on the cart frame in the yard, a few bundles of corn stalks piled in the cart.' \
  'He said he was going to Beijing to talk about the observatory; his father'"'"'s hands paused briefly, then retied the rope without a word.' \
  '"Wait a moment. I will fix the chicken coop door; an afternoon passes quickly." His father crouched by the coop, not looking up.' \
  'While packing that evening, he glanced at the stone he had picked up from the dry channel and put it in his coat pocket.' \
  'His mother chopped vegetables in the kitchen; the knife hit the board faster than usual, and he stood at the door listening for a while before going in.' > "$FIXTURE9"
set +e
node "$SCRIPT" --json "$FIXTURE9" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const mt = r.findings.filter((f) => f.type === 'micro-action-tic');
if (mt.length !== 0) throw new Error('low-density/quoted hedged beats should not fire micro-action-tic: ' + JSON.stringify(mt));
NODE

echo "micro-action-tic (hedged micro-beats) regression tests passed."

# --- Surveillance-camera action list (stacked generic verbs in one paragraph, advisory) ---
FIXTURE_ACTION_LIST="$TMP_DIR/fixture-action-list.md"
printf '%s\n' \
  'She picked up the cup, took the medicine bottle, opened the lid, shook out two pills, raised the cup, swallowed, set the cup down, pushed the chair back, turned, and walked to the door.' > "$FIXTURE_ACTION_LIST"
set +e
node "$SCRIPT" --json "$FIXTURE_ACTION_LIST" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const al = r.findings.filter((f) => f.type === 'action-list-tic');
if (al.length !== 1) throw new Error('stacked generic action verbs should report 1 action-list-tic: ' + JSON.stringify(r.findings));
if (al[0].severity !== 'advisory') throw new Error('action-list-tic should be advisory');
if (!al[0].message.includes('Surveillance-camera action list')) throw new Error('action-list-tic message should describe the action list: ' + JSON.stringify(al[0]));
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE_ACTION_LIST" > /dev/null 2>&1
action_list_blk=$?
set -e
[ "$action_list_blk" -eq 0 ] || { echo "FAIL: action-list-tic --fail-on=blocking should exit 0, got $action_list_blk" >&2; exit 1; }

FIXTURE_ACTION_LIST_NORMAL="$TMP_DIR/fixture-action-list-normal.md"
printf '%s\n' \
  'She gripped the bottle. Outside, a voice called her name again; chair legs scraped the tile.' \
  'She stood up, then sat back down, and only after a long while pushed the cup away.' > "$FIXTURE_ACTION_LIST_NORMAL"
set +e
node "$SCRIPT" --json "$FIXTURE_ACTION_LIST_NORMAL" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const al = r.findings.filter((f) => f.type === 'action-list-tic');
if (al.length !== 0) throw new Error('actions buffered with psychology/environment should not fire action-list-tic: ' + JSON.stringify(al));
NODE

echo "action-list-tic (surveillance-camera action list) regression tests passed."

# --- Cliche density (high-risk AI set phrases clustered, advisory) ---
FIXTURE10="$TMP_DIR/fixture-cliche-density.md"
printf '%s\n' \
  'Night settled over the city, and the neon lights flickered in the distance.' \
  'Lin took a deep breath and spoke in a calm, even tone.' \
  'Her heart raced as she stared at the screen.' \
  'A wave of relief washed over him.' \
  'At that moment, everything went quiet.' \
  'He couldn'"'"'t help but smile.' \
  'For some reason, she looked back.' \
  'Before he knew it, the day was over.' > "$FIXTURE10"
set +e
node "$SCRIPT" --json "$FIXTURE10" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const cd = r.findings.filter((f) => f.type === 'cliche-density-tic');
if (cd.length !== 1) throw new Error('high AI set-phrase density should report 1 cliche-density-tic: ' + JSON.stringify(r.findings));
if (cd[0].severity !== 'advisory') throw new Error('cliche-density-tic should be advisory');
if (!cd[0].excerpt.includes('took a deep breath') || !cd[0].excerpt.includes('heart raced')) {
  throw new Error('cliche-density-tic excerpt should include set-phrase samples: ' + JSON.stringify(cd[0]));
}
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE10" > /dev/null 2>&1
cliche_blk=$?
set -e
[ "$cliche_blk" -eq 0 ] || { echo "FAIL: cliche-density-tic --fail-on=blocking should exit 0, got $cliche_blk" >&2; exit 1; }

FIXTURE11="$TMP_DIR/fixture-cliche-density-normal.md"
printf '%s\n' \
  'She copied the phrase "a wave of relief" into her notebook and crossed it out with red ink.' \
  'Rain soaked the cardboard box by the window; Lin pulled out the top file and spread it beside the radiator.' \
  'Su Wan spoke in a low voice, and the empty office made every word land clearly.' > "$FIXTURE11"
set +e
node "$SCRIPT" --json "$FIXTURE11" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const cd = r.findings.filter((f) => f.type === 'cliche-density-tic');
if (cd.length !== 0) throw new Error('low-density/quoted set phrases should not fire cliche-density-tic: ' + JSON.stringify(cd));
NODE

echo "cliche-density-tic (set-phrase density) regression tests passed."

# --- Metaphor density (like / as if / as though sheet, advisory) ---
FIXTURE_METAPHOR="$TMP_DIR/fixture-metaphor-density.md"
printf '%s\n' \
  'The rain at the door had not stopped. The streetlight glowed like an eye sunk in dirty water, and the halo made people uneasy.' \
  'The guardroom glass looked like a film of oil, and any face pressed to it turned gray.' \
  'The crowd pressed at the foot of the steps like paper soaked through.' \
  'Zhou'"'"'s voice sounded like the stop announcement in an old elevator, stuck in his throat.' \
  'The red letters on the board went in like nails, one after another into the wall.' \
  'The child'"'"'s crying leaked through the gap between the buildings like wind, thin enough to raise goosebumps.' \
  'The badge lit up like a scratched old phone screen.' \
  'She stared at him as if he were a stranger.' > "$FIXTURE_METAPHOR"
set +e
node "$SCRIPT" --json "$FIXTURE_METAPHOR" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const md = r.findings.filter((f) => f.type === 'metaphor-density-tic');
if (md.length !== 1) throw new Error('high metaphor density should report 1 metaphor-density-tic: ' + JSON.stringify(r.findings));
if (md[0].severity !== 'advisory') throw new Error('metaphor-density-tic should be advisory');
if (!md[0].excerpt.includes('like an eye')) {
  throw new Error('metaphor-density-tic excerpt should include simile samples: ' + JSON.stringify(md[0]));
}
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE_METAPHOR" > /dev/null 2>&1
metaphor_blk=$?
set -e
[ "$metaphor_blk" -eq 0 ] || { echo "FAIL: metaphor-density-tic --fail-on=blocking should exit 0, got $metaphor_blk" >&2; exit 1; }

FIXTURE_METAPHOR_NORMAL="$TMP_DIR/fixture-metaphor-density-normal.md"
printf '%s\n' \
  'The group avatar had changed to white text on black, and Zhou stared at it for two seconds.' \
  'She wrote "like water" in her notebook and crossed it out with a red pen.' \
  'Rain dripped from the shed roof, like someone slowly pouring beans.' \
  'He pocketed the receipt and went to knock on door 3.' > "$FIXTURE_METAPHOR_NORMAL"
set +e
node "$SCRIPT" --json "$FIXTURE_METAPHOR_NORMAL" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const md = r.findings.filter((f) => f.type === 'metaphor-density-tic');
if (md.length !== 0) throw new Error('low-density/quoted similes should not fire metaphor-density-tic: ' + JSON.stringify(md));
NODE

echo "metaphor-density-tic (simile density) regression tests passed."

# --- Reasoning-chain density ("he knew / this meant / he had to decide", advisory) ---
FIXTURE12="$TMP_DIR/fixture-reasoning-chain.md"
cat > "$FIXTURE12" <<'TEXT'
Zhou stood at the gatehouse, watching the messages jump up the screen. He knew that the most important task was to steady the crowd and keep the panic from spreading. He understood that if the residents kept blocking the north gate, public order would fall apart. This meant every announcement had to be careful, because a wrong order could bring new deaths.

The real problem was that he had no complete rules, and he had to make a decision before the penalty came down. In this situation, any comfort could become a lie, and any silence could read as consent. He had to confirm who was still outside, and then which buildings could still let people in. Only then could he push the chaos back under control.

He knew what the task was: get every survivor home before midnight, keep the risk outside the red line, and stop wrong orders. By that logic, he should first reduce the people moving around, then set up order at each building door, and finally check every door plate.

He was sure that the system had handed him the responsibility. That is, he had to accept a result that should never have been his. He needed to stay calm, filter the information, and judge each person's risk level. He finally understood that tonight tested his ability to decide with incomplete information.
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE12" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const rc = r.findings.filter((f) => f.type === 'reasoning-chain-tic');
if (rc.length !== 1) throw new Error('high reasoning-chain density should report 1 reasoning-chain-tic: ' + JSON.stringify(r.findings));
if (rc[0].severity !== 'advisory') throw new Error('reasoning-chain-tic should be advisory');
if (!rc[0].excerpt.includes('He knew that') || !rc[0].excerpt.includes('This meant')) {
  throw new Error('reasoning-chain-tic excerpt should include chain samples: ' + JSON.stringify(rc[0]));
}
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE12" > /dev/null 2>&1
reason_blk=$?
set -e
[ "$reason_blk" -eq 0 ] || { echo "FAIL: reasoning-chain-tic --fail-on=blocking should exit 0, got $reason_blk" >&2; exit 1; }

# Action-based rewrite / quoted chain words: no fire.
FIXTURE13="$TMP_DIR/fixture-reasoning-chain-normal.md"
cat > "$FIXTURE13" <<'TEXT'
Zhou stood at the gatehouse while the messages kept jumping.

"Zhou, say something!"

"What is going on at the north gate?"

He pressed the broadcast key and let it go. More than a dozen people were still by the gate; the woman with the cat food crouched on the ground, her hands shaking, and the man with the dog had the leash wrapped around his wrist, staring at the row of keys outside the red line.

Zhou opened the duty log and scored the paper three times with his thumbnail. North gate, Building Three, kids' zone. He circled the names still outside, then wrote the visible building numbers beside them.

He wrote "this means responsibility" at the edge of the page, then crossed it out and wrote the three door plates of Building Three instead.

"Everyone, keep ten meters from the north gate," he said. "Building Three residents go back to the unit door first, no elevators. If someone in your family is still out, post the door plate in the group, don't spam."
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE13" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const rc = r.findings.filter((f) => f.type === 'reasoning-chain-tic');
if (rc.length !== 0) throw new Error('action-based rewrite / quoted chain words should not fire reasoning-chain-tic: ' + JSON.stringify(rc));
NODE

# Domain words (rules/risk/order/responsibility) without reasoning connectors: no fire.
FIXTURE14="$TMP_DIR/fixture-reasoning-chain-domain-words.md"
cat > "$FIXTURE14" <<'TEXT'
The rule board by the gate had blown crooked, and Zhou straightened it. The words "responsibility area" showed in the rain, and under them an old form with the risk notice torn at one corner.

The guard moved the order line forward half a meter; the rope scraped the tiles and left two muddy streaks. Zhou picked up the pen and added a line of responsibility to the register, then pressed the nail under the rule board back in.

The people of Building Three were still blocked at the gate. Someone pointed at the risk notice and cursed; someone held the order line and would not let go. Zhou did not explain, just handed the megaphone to the old guard and bent to pick the access card out of the water.

The rain came down harder, the responsibility column on the paper blurred, and the two rule words ran together. Beyond the order line, a child tilted his umbrella and stepped a shoe into the puddle.
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE14" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const rc = r.findings.filter((f) => f.type === 'reasoning-chain-tic');
if (rc.length !== 0) throw new Error('dense domain words without reasoning connectors should not fire reasoning-chain-tic: ' + JSON.stringify(rc));
NODE

# Negated cognition ("did not know / was not sure / did not need to") is not a chain.
FIXTURE15="$TMP_DIR/fixture-reasoning-chain-negated.md"
cat > "$FIXTURE15" <<'TEXT'
Zhou did not know what lay behind the rules, nor understand how the responsibility was divided. He was not sure where the risk came from, did not need to judge the outcome, and did not need to confirm who would pay.

The old form in the gatehouse blurred in the rain; the task column, the condition column, and the responsibility column ran together. The old guard asked whether he should broadcast; he shook his head and clipped the paper back into the folder.

He did not know why the people of Building Three had not left, nor understand why the order line had suddenly gone slack. The child's umbrella frame flipped up, a shoe stepped into the puddle, and the access card lay on the tiles.

Zhou was not sure whether these rules still counted, and did not need to analyze each person's risk. He put the megaphone back on the table and went to pull the north-gate awning out a little farther.
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE15" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const rc = r.findings.filter((f) => f.type === 'reasoning-chain-tic');
if (rc.length !== 0) throw new Error('negated cognition should not count as reasoning-chain core hits: ' + JSON.stringify(rc));
NODE

echo "reasoning-chain-tic (reasoning-chain density) regression tests passed."

# --- System-notice formality (hard rule words in [bracketed] lines, advisory) ---
FIXTURE16="$TMP_DIR/fixture-notice-formality.md"
cat > "$FIXTURE16" <<'TEXT'
[No one must leave this area at night.]

[All personnel must return to their registered quarters before midnight.]

[Administrators must maintain order in public areas. If public order fails, administrators take priority punishment.]

[Prohibited: sharing this notice with outsiders is forbidden.]

[This notice cannot be withdrawn, forwarded, or screenshotted.]

[Current area: Building One.]

[Current security level: 0.]

[Current public order: disrupted.]

[Night mission: return all personnel to their registered quarters before midnight.]

[Mission failure: administrators take priority punishment.]

[Notice: administrator announcements count as public orders. Wrong orders that cause deaths are counted as administrator responsibility.]
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE16" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const nf = r.findings.filter((f) => f.type === 'system-notice-formality-tic');
if (nf.length !== 1) throw new Error('a wall of hard-rule notices should report 1 system-notice-formality-tic: ' + JSON.stringify(r.findings));
if (nf[0].severity !== 'advisory') throw new Error('system-notice-formality-tic should be advisory');
if (!nf[0].excerpt.includes('must') || !nf[0].excerpt.includes('registered')) {
  throw new Error('system-notice-formality-tic excerpt should include hard rule words: ' + JSON.stringify(nf[0]));
}
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE16" > /dev/null 2>&1
notice_blk=$?
set -e
[ "$notice_blk" -eq 0 ] || { echo "FAIL: system-notice-formality-tic --fail-on=blocking should exit 0, got $notice_blk" >&2; exit 1; }

FIXTURE17="$TMP_DIR/fixture-notice-natural.md"
cat > "$FIXTURE17" <<'TEXT'
[No one can leave this area at night.]

[Everyone needs to be back in their registered rooms before midnight.]

[Administrators should keep public areas in order. If an area falls into chaos, administrators are punished first.]

[This notice cannot be taken back, passed on, or screenshotted.]

[The current area is Building One.]

[The security level right now is 0.]

[Public order in the area is currently messy.]

[The night task is to get everyone back to their rooms before midnight.]

[If the task fails, administrators are punished first.]

[Note: administrator announcements are treated as public instructions. Wrong orders that cause deaths are counted in the administrator's responsibility.]
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE17" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const nf = r.findings.filter((f) => f.type === 'system-notice-formality-tic');
if (nf.length !== 0) throw new Error('plain-language notices should not fire system-notice-formality-tic: ' + JSON.stringify(nf));
NODE

echo "system-notice-formality-tic (system-notice formality) regression tests passed."

# --- Overcompressed prose (many short narrative paragraphs, low function-word density) ---
FIXTURE18="$TMP_DIR/fixture-overcompressed-prose.md"
: > "$FIXTURE18"
for _ in $(seq 1 65); do
  cat >> "$FIXTURE18" <<'TEXT'
Zhou looked up, breath held.

TEXT
done
for _ in $(seq 1 49); do
  cat >> "$FIXTURE18" <<'TEXT'
Gray fog clung to the line, light shook into a smear, footsteps pressed back.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE18" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const oc = r.findings.filter((f) => f.type === 'overcompressed-prose-tic');
if (oc.length !== 1) throw new Error('long text with too many short paragraphs and low function words should report overcompressed-prose-tic: ' + JSON.stringify(r.findings));
if (oc[0].severity !== 'advisory') throw new Error('overcompressed-prose-tic should be advisory');
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE18" > /dev/null 2>&1
overcompressed_blk=$?
set -e
[ "$overcompressed_blk" -eq 0 ] || { echo "FAIL: overcompressed-prose-tic --fail-on=blocking should exit 0, got $overcompressed_blk" >&2; exit 1; }

FIXTURE19="$TMP_DIR/fixture-overcompressed-prose-natural.md"
: > "$FIXTURE19"
for _ in $(seq 1 40); do
  cat >> "$FIXTURE19" <<'TEXT'
Zhou looked up.

TEXT
done
for _ in $(seq 1 45); do
  cat >> "$FIXTURE19" <<'TEXT'
The fog still clung to the line outside the gate, the light shook into a cold smear, and the footsteps pressed back against the gatehouse.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE19" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const oc = r.findings.filter((f) => f.type === 'overcompressed-prose-tic');
if (oc.length !== 0) throw new Error('short-paragraph ratio under threshold should not fire overcompressed-prose-tic: ' + JSON.stringify(oc));
NODE

FIXTURE20="$TMP_DIR/fixture-overcompressed-prose-fast-natural.md"
: > "$FIXTURE20"
for _ in $(seq 1 60); do
  cat >> "$FIXTURE20" <<'TEXT'
He stopped for one second.

TEXT
done
for _ in $(seq 1 40); do
  cat >> "$FIXTURE20" <<'TEXT'
Rain was still falling at the door, the light was blurred by steam, and everyone stepped back a little.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE20" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const oc = r.findings.filter((f) => f.type === 'overcompressed-prose-tic');
if (oc.length !== 0) throw new Error('fast-paced but naturally connected short paragraphs should not fire overcompressed-prose-tic: ' + JSON.stringify(oc));
NODE

FIXTURE21="$TMP_DIR/fixture-overcompressed-prose-repaired-beats.md"
: > "$FIXTURE21"
for _ in $(seq 1 50); do
  cat >> "$FIXTURE21" <<'TEXT'
When Zhou looked up, the road beyond the north gate had vanished. Stranger still, the sound was gone too; the flood of question marks in the group chat paused for three seconds.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE21" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const oc = r.findings.filter((f) => f.type === 'overcompressed-prose-tic');
if (oc.length !== 0) throw new Error('the same scene after reading-through repair should not fire overcompressed-prose-tic: ' + JSON.stringify(oc));
NODE

echo "overcompressed-prose-tic (overcompressed short paragraphs) regression tests passed."

# --- Low connective density + missing mid-long sentences (conservative advisory) ---
FIXTURE22="$TMP_DIR/fixture-low-connective-density.md"
: > "$FIXTURE22"
for _ in $(seq 1 60); do
  cat >> "$FIXTURE22" <<'TEXT'
Zhou looked up. Red dots jumped. North lights died. Phones went dark. Footsteps stopped.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE22" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lc = r.findings.filter((f) => f.type === 'low-connective-density-tic');
if (lc.length !== 1) throw new Error('low connective density with no mid-long sentences should report 1 low-connective-density-tic: ' + JSON.stringify(r.findings));
if (lc[0].severity !== 'advisory') throw new Error('low-connective-density-tic should be advisory');
if (!lc[0].message.includes('don\'t pad mechanically')) throw new Error('low-connective-density-tic must warn against mechanical padding: ' + JSON.stringify(lc[0]));
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE22" > /dev/null 2>&1
low_connective_blk=$?
set -e
[ "$low_connective_blk" -eq 0 ] || { echo "FAIL: low-connective-density-tic --fail-on=blocking should exit 0, got $low_connective_blk" >&2; exit 1; }

# Quoted short speech/system text is naturally terse and must not count as telegraphic prose.
FIXTURE23="$TMP_DIR/fixture-low-connective-quoted-stream.md"
: > "$FIXTURE23"
for _ in $(seq 1 80); do
  cat >> "$FIXTURE23" <<'TEXT'
"Red dots jumped. North lights died. Phones went dark. Footsteps stopped."

TEXT
done
cat >> "$FIXTURE23" <<'TEXT'
Zhou scrolled the group messages up. In the gatehouse only the air conditioner hummed, and he did not speak at once.
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE23" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lc = r.findings.filter((f) => f.type === 'low-connective-density-tic');
if (lc.length !== 0) throw new Error('quoted short lines should not trigger low-connective-density-tic: ' + JSON.stringify(lc));
NODE

# All configured quote pairs must be stripped from the narration statistics; regex
# metacharacters inside quotes must not break the stripping.
FIXTURE24="$TMP_DIR/fixture-low-connective-all-quote-pairs.md"
: > "$FIXTURE24"
for _ in $(seq 1 35); do
  cat >> "$FIXTURE24" <<'TEXT'
“Red dots [jumped]*.” ‘North lights died+.’ "Phones went dark?" Footsteps stopped.

TEXT
done
cat >> "$FIXTURE24" <<'TEXT'
Zhou scrolled the group messages up. In the gatehouse only the air conditioner hummed, and he did not speak at once.
TEXT
set +e
node "$SCRIPT" --json "$FIXTURE24" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lc = r.findings.filter((f) => f.type === 'low-connective-density-tic');
if (lc.length !== 0) throw new Error('all quote pairs should be stripped; low-connective-density-tic must not fire: ' + JSON.stringify(lc));
NODE

# Low connectives but enough mid-long sentences: no fire (the false-positive guard).
FIXTURE25="$TMP_DIR/fixture-low-connective-long-sentences.md"
: > "$FIXTURE25"
for _ in $(seq 1 30); do
  cat >> "$FIXTURE25" <<'TEXT'
Zhou sent the screenshot back to the group; the north-gate light pressed against the fog in a cold smear, and the footsteps held still in front of the gatehouse.

TEXT
done
set +e
node "$SCRIPT" --json "$FIXTURE25" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const lc = r.findings.filter((f) => f.type === 'low-connective-density-tic');
if (lc.length !== 0) throw new Error('low connectives with ample mid-long sentences should not fire low-connective-density-tic: ' + JSON.stringify(lc));
NODE

echo "low-connective-density-tic (low connective density) regression tests passed."

# ============================================================
# Live-miss patterns (A-E): voice contrast / negation parade / kind-of /
# trailer ending / quote-emphasis abuse. Positives are the real English
# high-frequency sentences; negatives include dialogue exemption, either-or,
# normal quoting, and clean human-prose boundary sentences.
# ============================================================

# --- Live miss A: voice-contrast ("voice was quiet/soft/low... but/yet...", blocking) ---
FIXTURE_VOICE="$TMP_DIR/fixture-voice-contrast.md"
printf '%s\n' \
  'His voice was quiet, but the first sentence pinned the whole hall.' \
  '"His voice was low, but he was furious," someone muttered beside him.' \
  'Her voice was soft, and the front rows could hear her clearly.' > "$FIXTURE_VOICE"
set +e
node "$SCRIPT" --json "$FIXTURE_VOICE" > "$OUT"
node "$SCRIPT" --fail-on=blocking "$FIXTURE_VOICE" >/dev/null 2>&1
voice_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const vc = r.findings.filter((f) => f.type === 'voice-contrast');
if (vc.length !== 1) throw new Error('voice contrast should hit exactly 1 voice-contrast: ' + JSON.stringify(r.findings.map((f) => `${f.type}@${f.line}`)));
if (vc[0].line !== 1 || vc[0].severity !== 'blocking') throw new Error('voice-contrast should be line 1 blocking: ' + JSON.stringify(vc[0]));
// Quoted dialogue (line 2) and a flat description without the contrast flip (line 3)
// must not count as voice contrast.
if (vc[0].excerpt.includes('furious')) throw new Error('quoted dialogue should not hit voice-contrast: ' + JSON.stringify(vc[0]));
NODE
[ "$voice_blk" -eq 1 ] || { echo "FAIL: voice-contrast --fail-on=blocking should exit 1, got $voice_blk" >&2; exit 1; }

echo "voice-contrast (voice contrast flip) regression tests passed."

# --- Live miss B: negation-parade ("No X. No Y..." / "He didn't X. He just Y", blocking) ---
FIXTURE_PARADE="$TMP_DIR/fixture-negation-parade.md"
printf '%s\n' \
  'No hesitation. No doubt. No fear.' \
  'He didn'"'"'t show off. He just sang, every word flat and even.' \
  '"No food, no water — how do we spend the night?" someone shouted.' \
  'He did not turn back. The alley had no lights, so he walked by touch.' \
  'No mercy. No warning. No second chances.' > "$FIXTURE_PARADE"
set +e
node "$SCRIPT" --json "$FIXTURE_PARADE" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const np = r.findings.filter((f) => f.type === 'negation-parade');
if (np.length !== 3) throw new Error('negation parades should hit 3 negation-parade: ' + JSON.stringify(r.findings.map((f) => `${f.type}@${f.line}`)));
if (np[0].line !== 1 || np[1].line !== 2 || np[2].line !== 5) throw new Error('negation-parade should hit lines 1/2 and 5: ' + JSON.stringify(np.map((f) => f.line)));
if (!np.every((f) => f.severity === 'blocking')) throw new Error('negation-parade should be blocking');
// Quoted dialogue (line 3) and single independent negations (line 4) are not parades.
NODE

echo "negation-parade (negation parade) regression tests passed."

# --- Live miss C: kind-of is covered by the first fixture (advisory) ---

# --- Live miss D: trailer-ending (end-of-chapter previews, only the end window, blocking) ---
# Negatives: "no one knew" before the end window (line 1), dialogue inside the window,
# and a human announcer sentence ("officially kicked off").
FIXTURE_TRAILER="$TMP_DIR/fixture-trailer-ending.md"
printf '%s\n' 'He put the harmonica back in his pocket. No one knew how long he had practiced.' > "$FIXTURE_TRAILER"
for _ in $(seq 1 16); do
  printf '%s\n' 'The light in the yard was still on, and his mother carried the dried quilt into the house while he helped bring in the bamboo poles and put the lid back on the water jar.' >> "$FIXTURE_TRAILER"
done
printf '%s\n' \
  '"No one knows where the next show is," the old man muttered, tidying the music stand.' \
  'The bell rang again, and the competition officially kicked off.' \
  'No one knew that this was only the beginning.' \
  'Little did he know, their lives were about to change.' >> "$FIXTURE_TRAILER"
set +e
node "$SCRIPT" --json "$FIXTURE_TRAILER" > "$OUT"
node "$SCRIPT" --fail-on=blocking "$FIXTURE_TRAILER" >/dev/null 2>&1
trailer_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const te = r.findings.filter((f) => f.type === 'trailer-ending');
if (te.length !== 4) throw new Error('chapter-end previews should hit 4 trailer-ending: ' + JSON.stringify(r.findings.map((f) => `${f.type}@${f.line}:${f.excerpt}`)));
if (!te.every((f) => f.severity === 'blocking')) throw new Error('trailer-ending should be blocking');
if (te.some((f) => f.line === 1)) throw new Error('"no one knew" before the end window must not hit trailer-ending');
if (te.some((f) => f.excerpt.includes('No one knows where'))) throw new Error('dialogue "no one knows" must not hit trailer-ending');
if (te.some((f) => f.excerpt.includes('officially'))) throw new Error('the human announcer sentence must not hit trailer-ending');
const excerpts = te.map((f) => f.excerpt).join(' | ');
for (const marker of ['No one knew that', 'this was only the beginning', 'Little did he know', 'their lives were about to change']) {
  if (!excerpts.includes(marker)) throw new Error(`trailer-ending missing positive hit ${marker}: ${excerpts}`);
}
NODE
[ "$trailer_blk" -eq 1 ] || { echo "FAIL: trailer-ending --fail-on=blocking should exit 1, got $trailer_blk" >&2; exit 1; }

echo "trailer-ending (trailer ending previews) regression tests passed."

# --- trailer-summary: the outline's ending state written as a closing verdict (blocking) ---
FIXTURE_TRAILER_SUMMARY="$TMP_DIR/fixture-trailer-summary.md"
printf '%s\n' \
  'She spread the bill on the table, pressed a white crease with her fingertip, and the paper edge went soft with sweat.' \
  'He picked up the cup and set it down again; the bottom knocked once against the table.' \
  'It was a night that would change everything.' \
  'Nothing would ever be the same again.' > "$FIXTURE_TRAILER_SUMMARY"
set +e
node "$SCRIPT" --json "$FIXTURE_TRAILER_SUMMARY" > "$OUT"
node "$SCRIPT" --fail-on=blocking "$FIXTURE_TRAILER_SUMMARY" >/dev/null 2>&1
trailer_sum_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const ts = r.findings.filter((f) => f.type === 'trailer-summary');
if (ts.length !== 2) throw new Error('chapter-end state verdicts should each report: ' + JSON.stringify(ts.map((f) => f.excerpt)));
if (ts.some((f) => f.severity !== 'blocking')) throw new Error('trailer-summary should be blocking: ' + JSON.stringify(ts));
NODE
[ "$trailer_sum_blk" -eq 1 ] || { echo "FAIL: trailer-summary --fail-on=blocking should exit 1, got $trailer_sum_blk" >&2; exit 1; }

# Negatives, pinned one by one: time-jump ("and so a year passed"), transitive use
# ("ended the topic"), in-scene announcement ("announced the mixer was over"),
# conditional clause ("once all this is over"), bare cognition sentences ("at that
# moment I finally understood"), and plain action endings.
FIXTURE_TRAILER_SUMMARY_NORMAL="$TMP_DIR/fixture-trailer-summary-normal.md"
printf '%s\n' \
  'And so a year passed, and the ledger moved from the drawer into the safe.' \
  'And so the two of them blamed themselves for a while and finally ended the topic.' \
  'And so, at four in the afternoon, the commander announced the mixer was over.' \
  'Once all this is over, we can live a quiet, happy life.' \
  'He held the paper and did not know what any of this meant.' \
  'She stared at the screen, not understanding what any of this said.' \
  'At that moment I finally understood why my mother always cried at night.' \
  'I grabbed my coat and headed for the door, pulling it shut behind me.' > "$FIXTURE_TRAILER_SUMMARY_NORMAL"
set +e
node "$SCRIPT" --json "$FIXTURE_TRAILER_SUMMARY_NORMAL" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const ts = r.findings.filter((f) => f.type === 'trailer-summary');
if (ts.length !== 0) throw new Error('time jumps / bare cognition should not report trailer-summary: ' + JSON.stringify(ts));
NODE

echo "trailer-summary (chapter-end state summary) regression tests passed."

# --- Live miss E: quote-emphasis abuse (short words in narration wrapped in
# "scare quotes", advisory density; >= 3 narrative-layer hits) ---
FIXTURE_QUOTE_EMPH="$TMP_DIR/fixture-quote-emphasis.md"
printf '%s\n' \
  'He was hired to "oversee" things and came ready with a prepared speech.' \
  'That "masterpiece" performance was filmed, cut, and posted online.' \
  'No one moved; the whole hall sat pinned by that "flower".' \
  'She said "yes" and turned away.' \
  '"Mm."' \
  '"Ding." "Ding." "Ding."' > "$FIXTURE_QUOTE_EMPH"
set +e
node "$SCRIPT" --json "$FIXTURE_QUOTE_EMPH" > "$OUT"
node "$SCRIPT" --fail-on=blocking "$FIXTURE_QUOTE_EMPH" >/dev/null 2>&1
quote_emph_blk=$?
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const qe = r.findings.filter((f) => f.type === 'quote-emphasis-tic');
if (qe.length !== 1) throw new Error('>= 3 narrative-layer scare quotes should report 1 quote-emphasis-tic: ' + JSON.stringify(r.findings.map((f) => f.type)));
if (qe[0].severity !== 'advisory') throw new Error('quote-emphasis-tic should be advisory');
if (!qe[0].message.includes('3 short words')) throw new Error('speech-verb adjacency / standalone lines / sound spam should not count; exactly 3 expected: ' + JSON.stringify(qe[0]));
if (!qe[0].excerpt.includes('oversee')) throw new Error('quote-emphasis-tic excerpt should include the "oversee" positive: ' + JSON.stringify(qe[0]));
NODE
[ "$quote_emph_blk" -eq 0 ] || { echo "FAIL: quote-emphasis-tic --fail-on=blocking should exit 0, got $quote_emph_blk" >&2; exit 1; }

# Below the threshold (<3 hits) does not fire: a single emphasis is normal rhetoric.
FIXTURE_QUOTE_EMPH_NORMAL="$TMP_DIR/fixture-quote-emphasis-normal.md"
printf '%s\n' \
  'At twelve past midnight, the tourism website showed Su Yang'"'"'s photo; the poster in his hand read "I'"'"'m in Fancheng".' \
  'He was hired to "oversee" things and came ready with a prepared speech.' > "$FIXTURE_QUOTE_EMPH_NORMAL"
set +e
node "$SCRIPT" --json "$FIXTURE_QUOTE_EMPH_NORMAL" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const qe = r.findings.filter((f) => f.type === 'quote-emphasis-tic');
if (qe.length !== 0) throw new Error('fewer than 3 scare quotes should not fire quote-emphasis-tic: ' + JSON.stringify(qe));
NODE

echo "quote-emphasis-tic (scare-quote abuse) regression tests passed."

# --- Abstract summary repetition (fate / finally understood / from that moment on,
# advisory density; only the non-trailer phrases are used so the fixture stays
# advisory-only) ---
FIXTURE_ABSTRACT="$TMP_DIR/fixture-abstract-summary.md"
printf '%s\n' \
  'From that moment on, every arrangement was pushed into the open.' \
  'He finally understood what the old letter meant.' \
  'A new chapter had begun for the house by the river.' \
  'The stars had aligned for their escape.' > "$FIXTURE_ABSTRACT"
set +e
node "$SCRIPT" --json "$FIXTURE_ABSTRACT" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const ast = r.findings.filter((f) => f.type === 'abstract-summary-tic');
if (ast.length !== 1) throw new Error('high abstract-verdict density should report 1 abstract-summary-tic: ' + JSON.stringify(r.findings));
if (ast[0].severity !== 'advisory') throw new Error('abstract-summary-tic should be advisory');
if (!ast[0].excerpt.includes('From that moment on') || !ast[0].excerpt.includes('finally understood')) {
  throw new Error('abstract-summary-tic excerpt should include verdict samples: ' + JSON.stringify(ast[0]));
}
NODE

set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE_ABSTRACT" > /dev/null 2>&1
ast_blk=$?
set -e
[ "$ast_blk" -eq 0 ] || { echo "FAIL: abstract-summary-tic --fail-on=blocking should exit 0, got $ast_blk" >&2; exit 1; }

FIXTURE_ABSTRACT_NORMAL="$TMP_DIR/fixture-abstract-summary-normal.md"
printf '%s\n' \
  'She carried the old chessboard out of the cabinet; two pieces were missing, so she used buttons instead.' \
  'Father said, "From that moment on, you keep your own accounts." She nodded and turned the ledger to a blank page.' \
  'The rain outside had stopped, and the eaves were still dripping; she first spread the damp papers by the window.' > "$FIXTURE_ABSTRACT_NORMAL"
set +e
node "$SCRIPT" --json "$FIXTURE_ABSTRACT_NORMAL" > "$OUT"
set -e
node - "$OUT" <<'NODE'
const fs = require('fs');
const r = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const ast = r.findings.filter((f) => f.type === 'abstract-summary-tic');
if (ast.length !== 0) throw new Error('low-density/quoted abstract words should not fire abstract-summary-tic: ' + JSON.stringify(ast));
NODE

echo "abstract-summary-tic (abstract summary repetition) regression tests passed."

# --- Human-prose baseline: ordinary English commercial-fiction-like prose must
# not produce blocking findings. This is a regression floor, not an AIGC score;
# genre-specific corpora should be added before tightening thresholds. ---
FIXTURE_HUMAN_BASELINE="$TMP_DIR/fixture-human-baseline.md"
cat > "$FIXTURE_HUMAN_BASELINE" <<'EOF'
The state-of-the-art ward didn't fail—it shifted when Mara pressed her palm to the glass. A green line moved across the display, slow enough for her to follow. "You can still walk away," Jonah said. He kept one hand on the door, but he didn't open it.
Mara looked at the receipt tucked beneath the monitor. The date was yesterday's date, and the signature belonged to someone who had been dead for six months. She folded the paper once and put it in her pocket. If the ward had recognized her, the person who wrote the receipt had expected her to come.
EOF
set +e
node "$SCRIPT" --fail-on=blocking "$FIXTURE_HUMAN_BASELINE" >/dev/null 2>&1
human_status=$?
set -e
[ "$human_status" -eq 0 ] || { echo "FAIL: clean English baseline produced blocking findings" >&2; exit 1; }

echo "English human-prose baseline regression test passed."

echo "All AI pattern detector regression tests passed."
