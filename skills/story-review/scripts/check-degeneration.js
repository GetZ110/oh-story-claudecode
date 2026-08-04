#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const USAGE = `Usage: node check-degeneration.js [--check] [--json] [--fail-on=blocking|all] <file...>

Detect model-degeneration fingerprints that a degrading model cannot self-report:
  - verbatim repetition (looping): a long sentence repeated, or back-to-back identical lines
  - mid-sentence truncation: file ends without terminal/closing punctuation
  - placeholder / refusal / meta leakage: "as an AI", "I cannot continue",
    "[INSERT ...]", "to be continued", mojibake
  - engineering-word leakage: "chapter outline", "plot point", "this chapter",
    "the reader", "foreshadowing" leaking into prose

Each finding carries severity: blocking (repetition / truncation / placeholder /
refusal / tier1 pure pipeline terms — never legal in prose, hit means rewrite) or
advisory (tier2 chapter/ambiguous words and dialogue-line pipeline words — report
only, human/LLM decides).
--fail-on=blocking exits 1 only when a blocking finding appears; default
--fail-on=all exits 1 on any finding.

Report-only. The script never rewrites — the safe response is to regenerate the
affected unit (chapter / summary) with the finding fed back as a constraint, cap
retries, then surface the evidence to the user. Conservative by design: fiction
deliberately uses anaphora, refrain, and repeated dialogue for rhythm, so short and
dialogue repetition is exempt.`;

// Repetition: a long sentence (visible words >= REPEAT_MIN_WORDS) appearing >=
// REPEAT_MIN_COUNT times is a loop; adjacent identical full lines (visible words >=
// ADJACENT_MIN_WORDS) are an immediate cycle. Short lines / dialogue spam are exempt.
const REPEAT_MIN_WORDS = 8;
const REPEAT_MIN_COUNT = 3;
const ADJACENT_MIN_WORDS = 6;

// hard = flags on any line (never legal in prose); soft = only flags on
// non-dialogue narrative lines (a character saying "I can't do this" is normal
// dialogue, not a model refusal).
const PLACEHOLDER_PATTERNS = [
  // "As an AI" must sit at a self-reference position (followed by punctuation,
  // "I", a modal, or end of line) so compound nouns like "AI-generated art" don't
  // false-positive; dialogue lines are exempt (an in-story AI character's line
  // "As an AI, I will protect you" is legal dialogue).
  { re: /\b(?:as an?|being an?)\s+(?:AI|language model|artificial intelligence|chatbot|assistant)(?=\b|[.,;:!?"')\]]|I(?:'m| am)|can'?t|cannot|won'?t|will not|would|shall|must|$)|\b(?:as an?|being an?)\s+(?:AI|language model)\s+(?:assistant|chatbot|model)?\b/i, label: 'meta leakage (AI self-reference)', hard: false },
  { re: /�/, label: 'mojibake (replacement char �)', hard: true },
  { re: /\b(?:I|we)(?:'m|'re| am| are)? (?:sorry|apologize|unable|not able|can'?t|cannot) (?:to )?(?:continue|write|generate|finish|complete|help|assist|provide|produce)\b/i, label: 'meta leakage (generation refusal)', hard: false },
  { re: /\[(?:INSERT|PLACEHOLDER|TBD|TODO|CONTINUE|MORE TO COME|REMOVE THIS)[^\]]{0,20}\]/, label: 'placeholder (bracketed)', hard: true },
  { re: /\((?:insert|add|write|describe|elaborate|expand|to be continued|placeholder|scene)[^)]{0,30}\)/, label: 'placeholder (parenthetical)', hard: true },
  { re: /\b(?:to be continued|TBC|未完待续)\b/i, label: 'placeholder', hard: true },
  { re: /\bthe (?:story|narrative) (?:will|would|shall) (?:continue|end here|be continued)\b/i, label: 'meta leakage (writer note)', hard: false },
];

// Engineering-word leakage (deterministic version of the prose meta check): a weak
// model leaks writing-pipeline terms into prose and breaks immersion. tier1 = pure
// pipeline terms, almost never legal in prose; tier2 = chapter-structure/ambiguous
// words, legal when a character in-story reads/discusses "Chapter X" text or uses
// in-story system/UI language (report-only, human/LLM decides).
const META_TIER1_RE = /\b(?:chapter outline|volume outline|master outline|story unit|plot point|plot points|target words?|word count target|hook note|payoff note|foreshadowing note|deslop skip|细纲|情节点|卷纲|字数目标|章首钩子|章尾钩子)\b/i;
const META_TIER2_RE = /\b(?:this chapter|next chapter|previous chapter|last chapter|chapter \d+|the chapter|the reader|the author|foreshadow(?:ing)?|cliffhanger|as mentioned|to recap|the plot|the outline)\b/i;

const options = { json: false, files: [], failOn: 'all' };

for (let i = 2; i < process.argv.length; i += 1) {
  const arg = process.argv[i];
  if (arg === '--check') {
    // Accepted for symmetry with the other detectors; detection is always check-only.
  } else if (arg === '--json') {
    options.json = true;
  } else if (arg.startsWith('--fail-on=')) {
    const v = arg.slice('--fail-on='.length);
    if (v !== 'blocking' && v !== 'all') die(`--fail-on must be 'blocking' or 'all'`);
    options.failOn = v;
  } else if (arg === '-h' || arg === '--help') {
    process.stdout.write(`${USAGE}\n`);
    process.exit(0);
  } else if (arg.startsWith('-')) {
    die(`Unknown option: ${arg}`);
  } else {
    options.files.push(arg);
  }
}

if (options.files.length === 0) {
  die('No files provided');
}

let failed = false;
const allFindings = [];

for (const file of options.files) {
  const fullPath = path.resolve(file);
  let input;
  try {
    input = fs.readFileSync(fullPath, 'utf8');
  } catch (error) {
    failed = true;
    if (!options.json) console.error(`${file}: unable to read (${error.message})`);
    continue;
  }
  const findings = scanDocument(input).map((finding) => ({ file, ...finding }));
  allFindings.push(...findings);
}

if (options.json) {
  process.stdout.write(`${JSON.stringify({ findings: allFindings }, null, 2)}\n`);
} else {
  for (const f of allFindings) {
    console.log(`${f.file}:${f.line}:${f.column}: [${f.severity}] ${f.type}: ${f.message} (${f.excerpt})`);
  }
}

if (failed) process.exit(2);
// --fail-on=blocking exits 1 only on blocking findings (advisory reports only);
// default all keeps "any finding is 1".
const hasBlocking = allFindings.some((f) => f.severity === 'blocking');
if (options.failOn === 'blocking' ? hasBlocking : allFindings.length > 0) process.exit(1);

function die(message) {
  console.error(message);
  console.error(USAGE.trimEnd());
  process.exit(2);
}

function scanDocument(input) {
  const lines = input.split(/\r?\n/);
  const content = []; // { text, trimmed, lineNo } for body lines outside front-matter/fences
  let fence = null;
  let inFrontMatter = hasYamlFrontMatter(lines);

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();
    if (inFrontMatter) {
      if (index > 0 && trimmed === '---') inFrontMatter = false;
      continue;
    }
    const fenceMarker = /^(?:`{3,}|~{3,})/.exec(trimmed);
    if (fence) {
      if (fenceMarker && trimmed[0] === fence) fence = null;
      continue;
    }
    if (fenceMarker) {
      fence = trimmed[0];
      continue;
    }
    content.push({ text: line, trimmed, lineNo: index + 1 });
  }

  const findings = [];
  findings.push(...findRepetition(content));
  findings.push(...findTruncation(content));
  findings.push(...findPlaceholders(content));
  findings.push(...findMetaLeak(content));
  findings.sort((a, b) => a.line - b.line || a.column - b.column);
  return findings;
}

function isContent(trimmed) {
  return trimmed && !trimmed.startsWith('#') && !/^-{3,}$/.test(trimmed);
}

function isDialogueLike(trimmed) {
  return /[“”"'‘’]/.test(trimmed);
}

// Strip paired-quote spans (dialogue/system words), leaving narration only.
// Repetition judgment: repeated dialogue is a genre device (exempt), but narration
// outside quotes on a mixed line still counts toward degeneration.
function stripQuoted(text) {
  return text
    .replace(/“[^”]*”/g, '')
    .replace(/‘[^’]*’/g, '')
    .replace(/"[^"]*"/g, '')
    .replace(/'[^']*'/g, '');
}

function visibleLength(text) {
  const m = text.match(/[A-Za-z0-9]+(?:['’][A-Za-z]+)?/g);
  return m ? m.length : 0;
}

function findRepetition(content) {
  const findings = [];
  const body = content.filter((c) => isContent(c.trimmed));

  // (1) back-to-back identical lines (immediate loop). Pure dialogue/refrain lines
  // (very short outside-quote narration) are exempt; a mixed "narration + quoted
  // object" line still counts when its narration is long enough.
  for (let i = 1; i < body.length; i += 1) {
    if (
      body[i].trimmed === body[i - 1].trimmed &&
      visibleLength(stripQuoted(body[i].trimmed)) >= ADJACENT_MIN_WORDS
    ) {
      findings.push({
        line: body[i].lineNo,
        column: 1,
        type: 'verbatim-repeat',
        severity: 'blocking',
        message: 'Verbatim repeat (back-to-back identical lines): suspected model loop — rewrite this passage, delete the duplicate.',
        excerpt: compact(body[i].trimmed),
      });
    }
  }

  // (2) any long sentence repeated >= REPEAT_MIN_COUNT times across the file.
  // Only quoted dialogue is exempt (genre device); narrative sentences still count,
  // including on mixed "narration + quoted object" lines.
  const counts = new Map();
  for (const { trimmed } of body) {
    for (const sentence of stripQuoted(trimmed).split(/[.!?]+/)) {
      const s = sentence.trim();
      if (visibleLength(s) < REPEAT_MIN_WORDS) continue;
      const entry = counts.get(s) || { count: 0, firstLine: null };
      entry.count += 1;
      counts.set(s, entry);
    }
  }
  const flagged = new Set();
  for (const [s, entry] of counts) {
    if (entry.count >= REPEAT_MIN_COUNT) flagged.add(s);
  }
  if (flagged.size) {
    for (const { trimmed, lineNo } of body) {
      for (const sentence of stripQuoted(trimmed).split(/[.!?]+/)) {
        const s = sentence.trim();
        if (flagged.has(s)) {
          findings.push({
            line: lineNo,
            column: 1,
            type: 'verbatim-repeat',
            severity: 'blocking',
            message: `Long sentence repeated (${counts.get(s).count} times): suspected model loop — rewrite, keep one.`,
            excerpt: compact(s),
          });
          flagged.delete(s); // report each repeated sentence once, at its first occurrence
        }
      }
    }
  }

  return findings;
}

function findTruncation(content) {
  const body = content.filter((c) => isContent(c.trimmed));
  if (body.length === 0) return [];
  const last = body[body.length - 1];
  // a finished chapter ends on terminal/closing punctuation; otherwise it was cut off.
  if (/[.!?…”"'’）)】]$/.test(last.trimmed)) return [];
  return [{
    line: last.lineNo,
    column: last.trimmed.length,
    type: 'truncated',
    severity: 'blocking',
    message: 'Suspected truncation: prose does not end with terminal/closing punctuation — the model may have been cut off mid-sentence; finish or rewrite the ending.',
    excerpt: compact(last.trimmed.slice(-40)),
  }];
}

function findPlaceholders(content) {
  const findings = [];
  for (const { trimmed, lineNo } of content) {
    if (!isContent(trimmed)) continue;
    const dialogue = isDialogueLike(trimmed);
    for (const { re, label, hard } of PLACEHOLDER_PATTERNS) {
      if (!hard && dialogue) continue; // soft refusal language may be a legal line in dialogue
      const m = re.exec(trimmed);
      if (m) {
        findings.push({
          line: lineNo,
          column: (m.index || 0) + 1,
          type: 'placeholder-leak',
          severity: 'blocking',
          message: `${label}: prose contains meta/refusal/placeholder text — rewrite this passage to land cleanly.`,
          excerpt: compact(trimmed.slice(Math.max(0, (m.index || 0) - 20), (m.index || 0) + 40)),
        });
        break; // one finding per line is enough
      }
    }
  }
  return findings;
}

function findMetaLeak(content) {
  const findings = [];
  let firstContentSeen = false;
  for (const { trimmed, lineNo } of content) {
    if (!isContent(trimmed)) continue;
    if (!firstContentSeen) {
      firstContentSeen = true;
      // The title line ("Chapter N: Title", with or without a ## prefix) is not
      // prose; skip it.
      if (/^chapter\s+\d+/i.test(trimmed)) continue;
    }
    const dialogue = isDialogueLike(trimmed);
    let m = META_TIER1_RE.exec(trimmed);
    if (m) {
      // tier1 pure pipeline terms are almost never legal in prose -> blocking; but in
      // writer/editor fiction where a character genuinely discusses craft in-story,
      // a dialogue line may be legal — downgrade to advisory (still reported).
      findings.push({
        line: lineNo,
        column: m.index + 1,
        type: 'meta-leak',
        severity: dialogue ? 'advisory' : 'blocking',
        message: `Engineering-word leakage: "${m[0]}" is a writing-pipeline term that must not appear in prose; rewrite in in-scene terms.${dialogue ? ' Exception: a character who is an author/editor genuinely discussing craft in-story may say this in dialogue.' : ''}`,
        excerpt: compact(trimmed.slice(Math.max(0, m.index - 20), m.index + 30)),
      });
      continue; // tier1 hit is enough; don't stack tier2
    }
    m = META_TIER2_RE.exec(trimmed);
    if (m) {
      findings.push({
        line: lineNo,
        column: m.index + 1,
        type: 'meta-leak',
        severity: 'advisory',
        message: `Meta leakage: "${m[0]}" looks like a chapter-structure/engineering word in prose; rewrite as an event anchor or relative time the character can perceive. Exception: a character in-story reading/discussing "Chapter X" text, a real author/reader identity, or in-story system/UI language.`,
        excerpt: compact(trimmed.slice(Math.max(0, m.index - 20), m.index + 30)),
      });
    }
  }
  return findings;
}

function hasYamlFrontMatter(lines) {
  if (!lines[0] || lines[0].trim() !== '---') return false;
  let sawYamlField = false;
  for (let i = 1; i < Math.min(lines.length, 40); i += 1) {
    const trimmed = lines[i].trim();
    if (trimmed === '---') return sawYamlField;
    if (/^[A-Za-z0-9_-]+:\s*/.test(trimmed)) sawYamlField = true;
  }
  return false;
}

function compact(text) {
  const normalized = text.replace(/\s+/g, ' ').trim();
  return normalized.length > 80 ? `${normalized.slice(0, 77)}...` : normalized;
}
