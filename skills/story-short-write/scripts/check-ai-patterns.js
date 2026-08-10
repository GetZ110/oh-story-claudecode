#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const USAGE = `Usage: node check-ai-patterns.js [--check] [--json] [--fail-on=blocking|all] <file...>

Detect high-risk AI-flavor prose patterns that need human rewrite:
  - em-dash clusters (2+ em dashes on one narrative line)
  - long paragraphs (over a single screen)
  - quiet/soft voice + contrast flip ("His voice was quiet, but...")
  - negation parades ("No X. No Y. No Z.")
  - kind-of constructions ("the kind of smile that never reached her eyes")
  - trailer endings (end-of-chapter previews: "little did he know", "what happened next would...")
  - chapter-end state summaries ("It was a night that would change everything")
  - quote-emphasis abuse ("scare quotes" around short words in narration)
  - period stutter (runs of ultra-short narrative sentences)
  - hedged micro-beat repetition (smiled slightly / nodded gently density)
  - surveillance-camera action lists (stacked generic action verbs in one paragraph)
  - abstract-summary repetition (fate/destiny/finally understood density)
  - cliche density (took a deep breath / heart raced / a wave of / couldn't help but)
  - metaphor density (like / as if / as though clusters)
  - reasoning-chain density (he knew / this meant / had to decide)
  - system-notice formality ([bracketed] rule lines full of must/shall/prohibited)
  - overcompressed prose (many short narrative paragraphs, low function-word density)
  - low connective density (outline/telegraphic distribution)

Each finding carries severity: blocking by default for generation/deslop cleanup
(em-dash-cluster / voice-contrast / negation-parade / trailer-ending /
trailer-summary) or advisory (period-stutter / long-paragraph / micro-action-tic /
action-list-tic / kind-of / abstract-summary-tic / cliche-density-tic /
metaphor-density-tic / reasoning-chain-tic / system-notice-formality-tic /
overcompressed-prose-tic / low-connective-density-tic / quote-emphasis-tic — hints
only; justified prose can stay).
--fail-on=blocking exits 1 only when a blocking finding appears; default
--fail-on=all exits 1 on any finding.

The script reports findings only. It never rewrites text, because the safe fix is
contextual: usually delete the setup phrase, write the positive term directly,
or show it via action/detail. Density thresholds below are the v1 calibration —
re-derive them from a clean English prose corpus before tightening.

This is a local style/readability gate, not an AIGC detector score; functional human
text can be marked for review instead of hard-edited for a detector.`;

const STOP_CHARS = new Set(['.', '!', '?', '\n']);

// Period stutter: a run of STUTTER_MIN_RUN narrative sentences of <= STUTTER_MAX_SENTENCE
// words with no breathing room. Dialogue is skipped (staccato dialogue is normal genre form).
const STUTTER_MIN_RUN = 6;
const STUTTER_MAX_SENTENCE = 4; // words
// Long paragraph: single paragraph over LONG_PARAGRAPH_WORDS words is a mobile-reading
// red flag; normal genre paragraphs are far below this.
const LONG_PARAGRAPH_WORDS = 120;

// Hedged micro-beats: "smiled slightly / nodded gently / sighed softly" is the English
// cousin of the Chinese 轻量补语 tic — a repeated identical reaction template. Density rule.
const MICRO_TIC_PATTERN = /\b(smiled|nodded|glanced|sighed|shrugged|frowned|blinked|raised|lowered|shook|paused|stepped|leaned|turned|looked|stared|whispered|murmured|tensed|arched|pursed|clenched)\w*\s+(slightly|gently|softly|quietly|briefly|slowly|carefully|lightly|barely|almost)\b/gi;
const MICRO_TIC_MIN_HITS = 5;
const MICRO_TIC_PER_KILO = 5;

// Surveillance-camera action list: one paragraph stacking generic action verbs
// (reached/grabbed/picked/turned/walked...) joined by commas, reads like a camera log.
// Advisory only; fight/chase choreography may keep functional verbs.
const ACTION_LIST_VERB_PATTERN = /\b(reached|grabbed|picked|took|held|gripped|pulled|pushed|opened|closed|set|placed|tossed|dropped|turned|spun|walked|stepped|moved|sat|stood|leaned|looked|stared|glanced|nodded|raised|lowered|lifted|put|slipped|tucked|adjusted|straightened)\w*\b/gi;
const ACTION_LIST_MIN_HITS = 7;
const ACTION_LIST_MIN_SEPARATORS = 6;

// Abstract summary repetition: templated paragraphs inflate the character's present
// moment into authorial verdicts ("the wheels of fate", "he finally understood",
// "from that moment on"). A single phrase may serve a genre; density only.
const ABSTRACT_SUMMARY_PATTERNS = [
  /\b(?:the )?(?:wheel|wheels|hand|hands) of fate\b/gi,
  /\bfate had other plans\b/gi,
  /\b(?:fate|destiny)\s+(?:was\s+)?(?:sealed|written|decided)\b/gi,
  /\b(?:he|she|they|everyone) finally understood\b/gi,
  /\bfrom that (?:moment|day|night|point) on\b/gi,
  /\ba new chapter (?:began|had begun|was (?:about to )?beginning)\b/gi,
  /\bthe stars (?:had )?aligned\b/gi,
  /\b(?:nothing|everything) (?:would|had) (?:ever )?be the same\b/gi,
];
const ABSTRACT_SUMMARY_MIN_HITS = 3;
const ABSTRACT_SUMMARY_PER_KILO = 3;

// Cliche density: a single "took a deep breath" may be fine; clustered AI-flavor
// set phrases are the template signature. Only patterns explicitly marked high-risk
// in banned-words.md are collected here, so ordinary function words stay out.
const CLICHE_PATTERNS = [
  /\btook? a deep breath\b/gi,
  /\b(?:his|her|their) heart (?:raced|sank|lurched|hammered|pounded|skipped a beat)\b/gi,
  /\b(?:a|the) wave of [a-z]+ (?:washed|swept|crashed|rolled) (?:over|through)\b/gi,
  /\b(?:in|at) that (?:moment|instant)\b/gi,
  /\bas if on cue\b/gi,
  /\bcouldn'?t help but\b/gi,
  /\ba mix of\b/gi,
  /\bfor some reason\b/gi,
  /\bdeep down\b/gi,
  /\bin the depths of\b/gi,
  /\bthere was something about\b/gi,
  /\bbefore (?:he|she|they|i) knew it\b/gi,
  /\blittle by little\b|\bone by one\b/gi,
  /\bthe weight of the (?:moment|silence|words|truth)\b/gi,
  /\bsomehow\b/gi,
  /\beyes widened\b|\beyes narrowed\b|\beyes met\b/gi,
];
const CLICHE_DENSITY_MIN_HITS = 6;
const CLICHE_DENSITY_PER_KILO = 8;

// Metaphor density: single concrete similes serve the image; a sheet of
// like/as if/as though markers is AI-style ornament stacking. Advisory only.
const METAPHOR_MARKER_PATTERN = /\b(?:like|as if|as though|as if to say)\b/gi;
const METAPHOR_DENSITY_MIN_HITS = 8;
const METAPHOR_DENSITY_PER_KILO = 6;

// Reasoning-chain density: "he knew that / this meant / he had to decide" narrating
// the reasoning instead of showing evidence. A single judgment verb is fine; density
// of the chain reads like a report.
const REASONING_CHAIN_PATTERNS = [
  { key: 'mental', core: true, pattern: /\b(?:he|she|they|i) (?:knew|understood|realized|recognized|was sure|was certain|could tell) (?:that|it|this|what|who|how|why)\b/gi },
  { key: 'connector', core: true, pattern: /\b(?:this|which|that) (?:meant|implied|suggested)\b|\bin other words\b|\bthe real (?:problem|question|issue) (?:was|is)\b|\bthe problem (?:was|is)\b/gi },
  { key: 'modal', core: true, pattern: /\b(?:had|has|would have) to (?:make (?:a decision|sure)|decide|understand|face|accept|keep|hold|control|maintain|avoid|prevent|deal with|handle|confirm|check)\b/gi },
  { key: 'abstract', core: false, pattern: /\b(?:risk|consequence|logic|situation|outcome|responsibility|order|rules?|information)\b/gi },
];
const REASONING_CHAIN_MIN_HITS = 8;
const REASONING_CHAIN_CORE_MIN_HITS = 3;
const REASONING_CHAIN_MIN_BUCKETS = 2;
const REASONING_CHAIN_PER_KILO = 15;

// System-notice formality: only full-line [bracketed] rule/panel text is scanned —
// a single serious rule, plain narration, or dialogue never triggers. This is not a
// genre wordlist; it flags rule lines that read like an API doc.
const NOTICE_FORMAL_PATTERNS = [
  /\b(?:must|shall|shall not|may not|prohibited|forbidden|required|mandatory|violation|penalty|sanction|immediately)\b/gi,
  /\b(?:quest|mission|objective|status|level|rank|exp|points|coins|inventory|notification|system|administrator)\b/gi,
  /\b(?:maintain|public|order|priority|reward|punishment|authority|execute|command|instruction)\b/gi,
  /\b(?:considered|counted as|credited|applied|registered|withdrawn|forwarded|captured)\b/gi,
];
const NOTICE_FORMAL_CORE_PATTERN = /\b(?:must|shall|prohibited|forbidden|required|mandatory|violation|penalty)\b/gi;
const NOTICE_FORMAL_MIN_LINES = 4;
const NOTICE_FORMAL_MIN_HITS = 10;
const NOTICE_FORMAL_CORE_MIN_HITS = 4;
const NOTICE_FORMAL_PER_KILO = 40;

// Overcompressed prose: over-processed samples show many very short narrative
// paragraphs and too few connective function words (the/and/was/had/but...).
// Advisory; never force-feed words — read and repair the broken joints instead.
const OVERCOMPRESSED_PROSE_FUNCTION_PATTERN = /\b(?:the|a|an|and|but|or|so|was|were|had|has|have|with|from|to|of|in|on|at|it|he|she|they|them|his|her|their|for|not|no|as|by|that|this|then|when|while|because|after|before|just|still|also|very|there|here|said|would|could|should|did|does|do|is|are|be|been)\b/gi;
const OVERCOMPRESSED_PROSE_MIN_WORDS = 1000;
const OVERCOMPRESSED_PROSE_MIN_PARAS = 35;
const OVERCOMPRESSED_PROSE_SHORT_MAX_WORDS = 12;
const OVERCOMPRESSED_PROSE_SHORT_RATIO = 0.55;
const OVERCOMPRESSED_PROSE_FUNCTION_PER_KILO = 280; // fire when below

// Low connective density: narrative function words AND plain connectors both low,
// and few mid-long sentences — the outline/telegraphic distribution. Advisory.
const LOW_CONNECTIVE_FUNCTION_TERMS = ['the', 'and', 'was', 'had', 'but', 'so', 'then', 'with', 'from', 'after', 'because', 'however', 'though', 'yet', 'also', 'still', 'just', 'when', 'while', 'before', 'that', 'this', 'which', 'where'];
const LOW_CONNECTIVE_PLAIN_TERMS = ['the', 'was', 'had', 'said', 'like', 'just', 'still', 'then', 'after', 'before', 'thing', 'stuff', 'way', 'time', 'something', 'everything', 'nothing'];
const LOW_CONNECTIVE_MIN_WORDS = 600;
const LOW_CONNECTIVE_FUNCTION_PER_KILO = 240; // fire when below
const LOW_CONNECTIVE_PLAIN_PER_KILO = 90; // fire when below
const LOW_CONNECTIVE_LONG_SENTENCE_WORDS = 25;
const LOW_CONNECTIVE_LONG_SENTENCE_RATIO = 0.10;

// ---- Live-miss patterns (captured from real writing sessions; 2026-08 calibration) ----
// The calibration baseline for v1 is a public-domain clean-prose sample set; every
// blocking rule should hit ≈0 on human prose. Re-verify when a real English corpus
// is available.

// Voice contrast (live miss A): "His voice was quiet, but the first sentence pinned
// the whole room." Blocking per occurrence in narration; fix = delete the volume
// setup and write the concrete effect the voice lands on the room.
const VOICE_CONTRAST_PATTERN = /\b(?:his|her|their|the (?:man'?s|woman'?s|boy'?s|girl'?s)) voice\s+(?:was|were|sounded|stayed|remained|dropped)\s+(?:quiet|soft|low|calm|even|level|steady|gentle|barely (?:audible|a whisper))[^.!?\n]{0,30}?\b(?:but|yet|still|though)\b|\b(?:quiet|soft|low|calm|even|steady|gentle) voice[^.!?\n]{0,24}\b(?:but|yet|still)\b/gi;

// Negation parade (live miss B): "No hesitation. No doubt. No fear." — 2+ consecutive
// "no X," items, or "He didn't panic. He just smiled." (negated setup + just/only pivot).
const NEGATION_PARADE_PATTERNS = [
  /\bno\s+[a-z][a-z0-9' -]{1,24}\s*(?:,|\.)\s*\bno\s+[a-z][a-z0-9' -]{1,24}\s*(?:,|\.)?\s*\bno\s+[a-z][a-z0-9' -]{1,24}\b/gi,
  /\b(?:no\s+[a-z][a-z0-9' -]{1,24}(?:,|\.)\s*){2}\bno\s+[a-z][a-z0-9' -]{1,24}\b/gi,
  /\bdidn'?t\s+[a-z][a-z0-9' -]{1,24}\s*(?:,|\.)\s*\b(?:he|she|they|it)\s+just\b/gi,
];

// Kind-of construction (live miss C): "the kind of smile that never reached her eyes" —
// a structurally distinctive AI habit. Blocking per occurrence.
const KIND_OF_PATTERN = /\bthe kind of (?:a|an|the )?[a-z][a-z0-9' -]{1,30}\s+(?:that|who|which|to)\b/gi;

// Trailer ending (live miss D): end-of-chapter previews that narrate the future for the
// reader ("little did he know", "what happened next would..."). Only the end window is
// scanned (narrative words, stripped of dialogue); mid-text occurrences of these phrases
// in ordinary narration are not flagged. Blocking.
const TRAILER_ENDING_PATTERNS = [
  /\blittle did (?:he|she|they|we|i|anyone|everyone) know\b/gi,
  /\bunbeknownst to (?:him|her|them|us|everyone)\b/gi,
  /\bno (?:one|body) knew (?:that|what|how|why|where|who)\b/gi,
  /\bnone of them knew\b/gi,
  /\bwhat (?:happened|came) next would\b/gi,
  /\bthis (?:was|is|would be) only the beginning\b/gi,
  /\bthe (?:night|day|battle|war|real (?:battle|war|test|challenge)) (?:was|is|had) (?:just|only) (?:beginning|starting)\b/gi,
  /\b(?:their|his|her|the) (?:lives|life|world|story) (?:was|were|is|are) about to change\b/gi,
  /\bfate had other plans\b/gi,
];
const TRAILER_ENDING_WINDOW_WORDS = 250;

// Chapter-end state summary: the outline's "ending state" written verbatim as a closing
// verdict ("It was a night that would change everything", "nothing would ever be the
// same"). Shares the end window with trailer-ending; it seals the past where
// trailer-ending previews the future. Blocking.
const TRAILER_SUMMARY_PATTERNS = [
  /\bit was (?:a|the) (?:night|day|morning|moment) that would (?:change|alter|end) everything\b/gi,
  /\b(?:nothing|everything) would (?:ever )?be the same (?:again)?\b/gi,
  /\beverything was about to change\b/gi,
  /\bthe world would never be the same\b/gi,
  /\b(?:his|her|their|the) (?:life|world|story) (?:would|was) (?:be )?(?:forever|permanently) changed\b/gi,
  /\bthe wheels? of fate\b/gi,
];

// Quote-emphasis abuse (live miss E, advisory density): short words in narration
// wrapped in "scare quotes" (he was hired to "oversee" things). Full document counts
// narrative-layer quoted fragments of <= QUOTE_EMPHASIS_MAX_VISIBLE words.
const QUOTE_EMPHASIS_MIN_HITS = 3;
const QUOTE_EMPHASIS_MAX_VISIBLE = 4; // words
const QUOTE_EMPHASIS_SPEECH_VERB_PATTERN = /\b(?:said|asked|replied|answered|called|shouted|whispered|murmured|yelled|screamed|read|wrote|sang|muttered|demanded|declared|announced|snapped|hissed|grunted)\b/i;

// Paired-quote sources (dialogue/system text), shared by stripQuoted/maskQuoted/
// quotedRanges. A stray opening quote is common; spans never cross lines, so an
// unclosed quote cannot silently exempt the rest of the document.
const QUOTE_PAIRS = [['“', '”'], ['‘', '’'], ['"', '"']];
const QUOTE_SOURCES = QUOTE_PAIRS.map(([open, close]) => `${escapeRegExp(open)}[^${escapeRegExpCharClass(close)}\\n]*${escapeRegExp(close)}`);

const options = {
  json: false,
  files: [],
  failOn: 'all',
};

for (let i = 2; i < process.argv.length; i += 1) {
  const arg = process.argv[i];
  if (arg === '--check') {
    // Accepted for symmetry with normalize-punctuation.js; detection is always check-only.
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
  for (const finding of allFindings) {
    console.log(`${finding.file}:${finding.line}:${finding.column}: [${finding.severity}] ${finding.type}: ${finding.message} (${finding.excerpt})`);
  }
}

if (failed) process.exit(2);
// --fail-on=blocking exits 1 only on blocking findings (advisory reports only);
// default all keeps "any finding is 1".
const hasBlocking = allFindings.some((f) => f.severity === 'blocking');
if (options.failOn === 'blocking' ? hasBlocking : allFindings.length > 0) process.exit(1);

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function escapeRegExpCharClass(text) {
  return text.replace(/[\\\]^-]/g, '\\$&');
}

function die(message) {
  console.error(message);
  console.error(USAGE.trimEnd());
  process.exit(2);
}

function scanDocument(input) {
  const lines = input.split(/\r?\n/);
  const findings = [];
  let fence = null;
  let inFrontMatter = hasYamlFrontMatter(lines);
  const proseLines = [];

  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const trimmed = line.trim();

    if (inFrontMatter) {
      if (index > 0 && trimmed === '---') inFrontMatter = false;
      continue;
    }

    const fenceMarker = parseFenceMarker(trimmed);
    if (fence) {
      if (fenceMarker && fenceMarker.char === fence.char && fenceMarker.length >= fence.length) {
        fence = null;
      }
      continue;
    }

    if (fenceMarker) {
      fence = fenceMarker;
      continue;
    }

    proseLines.push({ text: line, lineNo: index + 1 });
  }

  findings.push(...scanProsePatterns(proseLines));
  findings.sort((a, b) => a.line - b.line || a.column - b.column);
  return findings;
}

// Line-level detection: em-dash clusters, long paragraphs.
function scanProsePatterns(proseLines) {
  const findings = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;

    const noComments = stripHtmlComments(trimmed);
    const dashPattern = /—|--+/g;
    let dash;
    let dashes = 0;
    let firstDash = -1;
    while ((dash = dashPattern.exec(noComments)) !== null) {
      dashes += 1;
      if (firstDash === -1) firstDash = dash.index;
    }
    if (dashes >= 2) {
      findings.push({
        line: lineNo,
        column: firstDash + 1,
        type: 'em-dash-cluster',
        severity: 'blocking',
        message: `Em-dash cluster (${dashes} on one line): AI prose overuses the em-dash; keep at most one per line — split the sentence or use a comma/period where the dash only hedges.`,
        excerpt: compact(noComments.slice(Math.max(0, firstDash - 20), firstDash + 24)),
      });
    }

    if (visibleLength(trimmed) > LONG_PARAGRAPH_WORDS) {
      findings.push({
        line: lineNo,
        column: 1,
        type: 'long-paragraph',
        severity: 'advisory',
        message: `Paragraph too long (${visibleLength(trimmed)} words): break at a new shot/action/thread or POV shift instead of one unbroken block.`,
        excerpt: compact(trimmed.slice(0, 80)),
      });
    }
  }

  findings.push(...findVoiceContrast(proseLines));
  findings.push(...findNegationParade(proseLines));
  findings.push(...findKindOf(proseLines));
  findings.push(...findTrailerEnding(proseLines));
  findings.push(...findQuoteEmphasisTic(proseLines));
  findings.push(...findPeriodStutter(proseLines));
  findings.push(...findMicroActionTic(proseLines));
  findings.push(...findActionListTic(proseLines));
  findings.push(...findAbstractSummaryTic(proseLines));
  findings.push(...findClicheDensityTic(proseLines));
  findings.push(...findMetaphorDensityTic(proseLines));
  findings.push(...findReasoningChainTic(proseLines));
  findings.push(...findNoticeFormalityTic(proseLines));
  findings.push(...findOvercompressedProseTic(proseLines));
  findings.push(...findLowConnectiveDensityTic(proseLines));
  return findings;
}

// Voice contrast: narration only, blocking per occurrence; positions/excerpts from
// the original text (maskQuoted keeps offsets with equal-length placeholders).
function findVoiceContrast(proseLines) {
  const findings = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const masked = maskQuoted(text);
    VOICE_CONTRAST_PATTERN.lastIndex = 0;
    let match;
    while ((match = VOICE_CONTRAST_PATTERN.exec(masked)) !== null) {
      findings.push({
        line: lineNo,
        column: match.index + 1,
        type: 'voice-contrast',
        severity: 'blocking',
        message: 'Voice-contrast flip: "voice was quiet/soft/low... but/yet..." is an AI high-frequency contrast template; delete the volume setup and write the concrete effect the voice lands on the room (who stopped, which row went silent).',
        excerpt: compact(text.slice(match.index, match.index + match[0].length)),
      });
    }
  }

  return findings;
}

// Negation parade: two variants ("No X. No Y." runs / negated setup + "just" pivot)
// may overlap on the same span; dedupe by interval.
function findNegationParade(proseLines) {
  const findings = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const masked = maskQuoted(text);

    const spans = [];
    for (const pattern of NEGATION_PARADE_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(masked)) !== null) {
        spans.push([match.index, match.index + match[0].length]);
      }
    }
    spans.sort((a, b) => a[0] - b[0]);

    let lastEnd = -1;
    for (const [start, end] of spans) {
      if (start < lastEnd) {
        lastEnd = Math.max(lastEnd, end);
        continue;
      }
      lastEnd = end;
      findings.push({
        line: lineNo,
        column: start + 1,
        type: 'negation-parade',
        severity: 'blocking',
        message: 'Negation parade: "No X. No Y..." / "He didn\'t X. He just Y" is an AI high-frequency list template; delete the denial list and write what is actually there — keep at most one most-informative negation.',
        excerpt: compact(text.slice(start, end)),
      });
    }
  }

  return findings;
}

// Kind-of construction: "the kind of X that Y" is an AI habit, but the same
// construction appears in clean human prose ("the kind of tired that comes from
// driving all night"), so it is advisory — a density hint, not a forced rewrite.
function findKindOf(proseLines) {
  const findings = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const masked = maskQuoted(text);
    KIND_OF_PATTERN.lastIndex = 0;
    let match;
    while ((match = KIND_OF_PATTERN.exec(masked)) !== null) {
      findings.push({
        line: lineNo,
        column: match.index + 1,
        type: 'kind-of',
        severity: 'advisory',
        message: '"The kind of X that Y" is an AI habit construction (advisory: it also appears in good human prose); when it shows up often, replace it with a concrete detail or action the reader can picture.',
        excerpt: compact(text.slice(match.index, match.index + match[0].length)),
      });
    }
  }

  return findings;
}

// Trailer ending / summary: only the end window is scanned. Walk backward from the
// end, collecting narrative lines until the stripped-visible word count reaches the
// window (boundary line counted in full).
function findTrailerEnding(proseLines) {
  const windowLines = [];
  let accumulated = 0;

  for (let i = proseLines.length - 1; i >= 0 && accumulated < TRAILER_ENDING_WINDOW_WORDS; i -= 1) {
    const { text } = proseLines[i];
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    windowLines.unshift(proseLines[i]);
    accumulated += visibleLength(stripQuoted(trimmed));
  }

  const findings = [];
  for (const { text, lineNo } of windowLines) {
    const masked = maskQuoted(text);
    for (const pattern of TRAILER_ENDING_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(masked)) !== null) {
        findings.push({
          line: lineNo,
          column: match.index + 1,
          type: 'trailer-ending',
          severity: 'blocking',
          message: 'Trailer ending: "little did he know / what happened next would / only the beginning" previews the next chapter for the reader — an AI chapter-end tell. End on a concrete action, image, or line; let the event itself hang, don\'t narrate the future.',
          excerpt: compact(text.slice(match.index, match.index + match[0].length)),
        });
      }
    }
    for (const pattern of TRAILER_SUMMARY_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(masked)) !== null) {
        findings.push({
          line: lineNo,
          column: match.index + 1,
          type: 'trailer-summary',
          severity: 'blocking',
          message: 'Chapter-end state summary: "It was a night that would change everything / nothing would ever be the same" writes the outline\'s ending state as a verdict. The ending state is a planning statement — land the chapter on one last concrete action, image, or line instead of sealing it for the reader.',
          excerpt: compact(text.slice(match.index, match.index + match[0].length)),
        });
      }
    }
  }

  return findings;
}

// Quote-emphasis abuse: count narrative-layer "scare-quoted" fragments of <= 4 words;
// report one finding per document (a distribution fingerprint, not per-spot).
function findQuoteEmphasisTic(proseLines) {
  let hits = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    // Lines with no narration outside quotes (pure dialogue/emote spam) are skipped:
    // emphasis abuse is a narration-layer fingerprint.
    if (visibleLength(stripQuoted(trimmed)) === 0) continue;
    const ranges = quotedRanges(text);

    for (const [start, end] of ranges) {
      // Nested quotes: emphasis inside dialogue belongs to the character, not narration.
      if (ranges.some(([s2, e2]) => s2 <= start && end <= e2 && (s2 !== start || e2 !== end))) continue;
      const inner = text.slice(start + 1, end - 1);
      const visible = visibleLength(inner);
      if (visible < 1 || visible > QUOTE_EMPHASIS_MAX_VISIBLE) continue;
      if (/[.!?…;,:]/.test(inner)) continue; // contains sentence punctuation = dialogue, not emphasis
      const before = text.slice(Math.max(0, start - 8), start);
      const after = text.slice(end, end + 5);
      if (QUOTE_EMPHASIS_SPEECH_VERB_PATTERN.test(before) || QUOTE_EMPHASIS_SPEECH_VERB_PATTERN.test(after)) continue; // speech verb adjacency = very short line
      hits += 1;
      if (firstLine === null) firstLine = lineNo;
      if (samples.length < 6 && !samples.includes(inner)) samples.push(inner);
    }
  }

  if (hits < QUOTE_EMPHASIS_MIN_HITS) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'quote-emphasis-tic',
    severity: 'advisory',
    message: `Quote-emphasis abuse: ${hits} short words in narration wrapped in "scare quotes"; keep only the one or two that truly need ironic/reported emphasis, drop the rest or write a concrete action the reader can read for themselves.`,
    excerpt: compact(samples.join(' ')),
  }];
}

// Hedged micro-beats: count "V + slightly/gently/softly..." in narration. Density rule.
function findMicroActionTic(proseLines) {
  let hits = 0;
  let narrativeWords = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed);
    narrativeWords += visibleLength(narrative);
    MICRO_TIC_PATTERN.lastIndex = 0;
    let match;
    while ((match = MICRO_TIC_PATTERN.exec(narrative)) !== null) {
      hits += 1;
      if (firstLine === null) firstLine = lineNo;
      if (samples.length < 6 && !samples.includes(match[0])) samples.push(match[0]);
    }
  }

  if (narrativeWords === 0 || hits < MICRO_TIC_MIN_HITS) return [];
  const perKilo = (hits / narrativeWords) * 1000;
  if (perKilo < MICRO_TIC_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'micro-action-tic',
    severity: 'advisory',
    message: `Hedged micro-beats: "smiled slightly / nodded gently / sighed softly" reactions ${hits} times (${perKilo.toFixed(1)}/1000 words); the same hedged reaction template repeating is a mechanical fingerprint — merge beats, vary with concrete detail, don't bolt a hedge onto every action.`,
    excerpt: compact(samples.join(' ')),
  }];
}

function findActionListTic(proseLines) {
  const findings = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed).trim();
    if (!narrative) continue;

    ACTION_LIST_VERB_PATTERN.lastIndex = 0;
    const verbs = [];
    let match;
    while ((match = ACTION_LIST_VERB_PATTERN.exec(narrative)) !== null) {
      verbs.push(match[0]);
    }

    if (verbs.length < ACTION_LIST_MIN_HITS) continue;
    const separators = (narrative.match(/[,;]/g) || []).length;
    if (separators < ACTION_LIST_MIN_SEPARATORS) continue;

    findings.push({
      line: lineNo,
      column: 1,
      type: 'action-list-tic',
      severity: 'advisory',
      message: `Surveillance-camera action list: ${verbs.length} generic action verbs and ${separators} separators in one paragraph; merge the trivial steps, keep only actions with emotional or plot function, and buffer with hesitation, misjudgment, or environment feedback when needed.`,
      excerpt: compact(verbs.slice(0, 8).join(' ')),
    });
  }

  return findings;
}

// Cliche density: count high-risk AI set phrases in narration. Not a word-swapper;
// only fires when density forms a template voice.
function findClicheDensityTic(proseLines) {
  let hits = 0;
  let narrativeWords = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed);
    narrativeWords += visibleLength(narrative);

    for (const pattern of CLICHE_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(narrative)) !== null) {
        hits += 1;
        if (firstLine === null) firstLine = lineNo;
        if (samples.length < 8 && !samples.includes(match[0])) samples.push(match[0]);
      }
    }
  }

  if (narrativeWords === 0 || hits < CLICHE_DENSITY_MIN_HITS) return [];
  const perKilo = (hits / narrativeWords) * 1000;
  if (perKilo < CLICHE_DENSITY_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'cliche-density-tic',
    severity: 'advisory',
    message: `Cliche density too high: ${hits} high-risk AI set phrases (${perKilo.toFixed(1)}/1000 words); don't synonym-swap — write the action, object, line, and concrete consequence the character can see right now.`,
    excerpt: compact(samples.join(' ')),
  }];
}

// Metaphor density: count like/as if/as though markers in narration.
// A single metaphor is fine; a sheet of them is ornament stacking.
function findMetaphorDensityTic(proseLines) {
  let hits = 0;
  let narrativeWords = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed);
    narrativeWords += visibleLength(narrative);

    METAPHOR_MARKER_PATTERN.lastIndex = 0;
    let match;
    while ((match = METAPHOR_MARKER_PATTERN.exec(narrative)) !== null) {
      hits += 1;
      if (firstLine === null) firstLine = lineNo;
      const sample = sentenceAround(narrative, match.index);
      if (samples.length < 6 && sample && !samples.includes(sample)) samples.push(sample);
    }
  }

  if (narrativeWords === 0 || hits < METAPHOR_DENSITY_MIN_HITS) return [];
  const perKilo = (hits / narrativeWords) * 1000;
  if (perKilo < METAPHOR_DENSITY_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'metaphor-density-tic',
    severity: 'advisory',
    message: `Metaphor density too high: like/as if/as though markers ${hits} times (${perKilo.toFixed(1)}/1000 words); keep the few similes that do narrative work, return the rest to concrete action, objects, sounds, or consequences — don't swap in new metaphors.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

// Reasoning-chain density: count "he knew / this meant / he had to decide" chains.
// One report per document; the fix is not to add filler but to land judgments on
// visible action, objects, dialogue, and scene feedback.
function findReasoningChainTic(proseLines) {
  let hits = 0;
  let coreHits = 0;
  let narrativeWords = 0;
  let firstLine = null;
  const samples = [];
  const buckets = new Set();

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed);
    narrativeWords += visibleLength(narrative);

    for (const { pattern, key, core } of REASONING_CHAIN_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(narrative)) !== null) {
        hits += 1;
        if (core) coreHits += 1;
        buckets.add(key);
        if (firstLine === null) firstLine = lineNo;
        const sample = compact(match[0]);
        if (samples.length < 8 && !samples.includes(sample)) samples.push(sample);
      }
    }
  }

  if (narrativeWords === 0 || hits < REASONING_CHAIN_MIN_HITS) return [];
  if (coreHits < REASONING_CHAIN_CORE_MIN_HITS || buckets.size < REASONING_CHAIN_MIN_BUCKETS) return [];
  const perKilo = (hits / narrativeWords) * 1000;
  if (perKilo < REASONING_CHAIN_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'reasoning-chain-tic',
    severity: 'advisory',
    message: `Reasoning-chain density too high: he knew / this meant / he had to decide judgments ${hits} times (${perKilo.toFixed(1)}/1000 words); reads like a logic report — land the judgments on what the character can see, touch, hear, and say right now.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

// System/rule lines that read like an API doc or government notice. The fix is not
// to delete the rules but to keep the carrier and plain-language the hard words,
// or show the concrete consequence the character understands on the spot.
function findNoticeFormalityTic(proseLines) {
  let hits = 0;
  let noticeWords = 0;
  let noticeLines = 0;
  let coreHits = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!/^\[[^\]]+\]$/.test(trimmed)) continue;
    noticeLines += 1;
    noticeWords += visibleLength(trimmed);

    NOTICE_FORMAL_CORE_PATTERN.lastIndex = 0;
    while (NOTICE_FORMAL_CORE_PATTERN.exec(trimmed) !== null) coreHits += 1;

    for (const pattern of NOTICE_FORMAL_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(trimmed)) !== null) {
        hits += 1;
        if (firstLine === null) firstLine = lineNo;
        const sample = compact(match[0]);
        if (samples.length < 8 && !samples.includes(sample)) samples.push(sample);
      }
    }
  }

  if (noticeLines < NOTICE_FORMAL_MIN_LINES || noticeWords === 0 || hits < NOTICE_FORMAL_MIN_HITS || coreHits < NOTICE_FORMAL_CORE_MIN_HITS) return [];
  const perKilo = (hits / noticeWords) * 1000;
  if (perKilo < NOTICE_FORMAL_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'system-notice-formality-tic',
    severity: 'advisory',
    message: `System-notice formality too dense: ${hits} hard rule words in [bracketed] lines (${perKilo.toFixed(1)}/1000 words); keep the screen/notice/rule carrier the character sees, plain-language some hard words inside the carrier, and show the concrete consequence the character understands — don't explain as narrator.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

// Whole-document "too tidy" signal: many short narrative paragraphs and too few
// function words, reads like a processed outline/beat sheet.
function findOvercompressedProseTic(proseLines) {
  let narrativeWords = 0;
  let narrativeParas = 0;
  let shortParas = 0;
  let functionWords = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed) || /^\[[^\]]+\]$/.test(trimmed)) continue;
    const narrative = stripQuoted(trimmed).trim();
    const len = visibleLength(narrative);
    if (len === 0) continue;

    if (firstLine === null) firstLine = lineNo;
    narrativeParas += 1;
    narrativeWords += len;
    if (len <= OVERCOMPRESSED_PROSE_SHORT_MAX_WORDS) {
      shortParas += 1;
      if (samples.length < 6) samples.push(narrative);
    }

    OVERCOMPRESSED_PROSE_FUNCTION_PATTERN.lastIndex = 0;
    while (OVERCOMPRESSED_PROSE_FUNCTION_PATTERN.exec(narrative) !== null) functionWords += 1;
  }

  if (narrativeWords < OVERCOMPRESSED_PROSE_MIN_WORDS || narrativeParas < OVERCOMPRESSED_PROSE_MIN_PARAS) return [];
  const shortRatio = shortParas / narrativeParas;
  if (shortRatio < OVERCOMPRESSED_PROSE_SHORT_RATIO) return [];
  const functionPerKilo = (functionWords / narrativeWords) * 1000;
  if (functionPerKilo >= OVERCOMPRESSED_PROSE_FUNCTION_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'overcompressed-prose-tic',
    severity: 'advisory',
    message: `Overcompressed prose: ${narrativeParas} narrative paragraphs, ${shortParas} of them <= ${OVERCOMPRESSED_PROSE_SHORT_MAX_WORDS} words (${(shortRatio * 100).toFixed(0)}%), function words ${functionPerKilo.toFixed(1)}/1000 words (low); read it through first — if it genuinely reads like an outline, repair the broken joints and necessary function words; intentional staccato moments may stay, don't pad mechanically.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

// Low connective density: function words AND plain connectors both low, and few
// mid-long sentences — the outline/telegraphic distribution.
function findLowConnectiveDensityTic(proseLines) {
  let bodyWords = 0;
  let functionHits = 0;
  let plainHits = 0;
  let firstLine = null;
  const sentences = [];
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;

    // Narration only. Dialogue/chat/system text can be naturally terse; mixing it in
    // would mistake a genre feature for telegraphic prose.
    const narrative = stripQuoted(trimmed).trim();
    const narrativeLen = visibleLength(narrative);
    if (narrativeLen === 0) continue;

    if (firstLine === null) firstLine = lineNo;
    bodyWords += narrativeLen;
    functionHits += countTerms(narrative, LOW_CONNECTIVE_FUNCTION_TERMS);
    plainHits += countTerms(narrative, LOW_CONNECTIVE_PLAIN_TERMS);

    for (const sentence of splitSentences(narrative)) {
      const len = visibleLength(sentence);
      if (len === 0) continue;
      sentences.push(len);
      if (len <= 4 && samples.length < 6) samples.push(sentence);
    }
  }

  if (bodyWords < LOW_CONNECTIVE_MIN_WORDS || sentences.length === 0) return [];
  const functionPerKilo = (functionHits / bodyWords) * 1000;
  if (functionPerKilo >= LOW_CONNECTIVE_FUNCTION_PER_KILO) return [];
  const plainPerKilo = (plainHits / bodyWords) * 1000;
  if (plainPerKilo >= LOW_CONNECTIVE_PLAIN_PER_KILO) return [];
  const longSentenceRatio = sentences.filter((len) => len >= LOW_CONNECTIVE_LONG_SENTENCE_WORDS).length / sentences.length;
  if (longSentenceRatio >= LOW_CONNECTIVE_LONG_SENTENCE_RATIO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'low-connective-density-tic',
    severity: 'advisory',
    message: `Low connective density: function words ${functionPerKilo.toFixed(1)}/1000 words, plain connectors ${plainPerKilo.toFixed(1)}/1000 words, and only ${(longSentenceRatio * 100).toFixed(0)}% sentences >= ${LOW_CONNECTIVE_LONG_SENTENCE_WORDS} words — looks like an outline/telegraph. Read it through and restore necessary connectives and mid-length sentence groups; don't pad mechanically.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

// Abstract summary repetition: count high-abstraction closing templates in narration.
// One report per document — return to what the character can see, touch, say, and
// the physical consequences; don't let fate-words summarize for the reader.
function findAbstractSummaryTic(proseLines) {
  let hits = 0;
  let narrativeWords = 0;
  let firstLine = null;
  const samples = [];

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed || isDivider(trimmed) || isStructural(trimmed)) continue;
    const narrative = stripQuoted(trimmed);
    narrativeWords += visibleLength(narrative);

    for (const pattern of ABSTRACT_SUMMARY_PATTERNS) {
      pattern.lastIndex = 0;
      let match;
      while ((match = pattern.exec(narrative)) !== null) {
        hits += 1;
        if (firstLine === null) firstLine = lineNo;
        const sample = compact(match[0]);
        if (samples.length < 6 && !samples.includes(sample)) samples.push(sample);
      }
    }
  }

  if (narrativeWords === 0 || hits < ABSTRACT_SUMMARY_MIN_HITS) return [];
  const perKilo = (hits / narrativeWords) * 1000;
  if (perKilo < ABSTRACT_SUMMARY_PER_KILO) return [];

  return [{
    line: firstLine,
    column: 1,
    type: 'abstract-summary-tic',
    severity: 'advisory',
    message: `Abstract summary repetition: fate/wheels of fate/he finally understood/from that moment on authorial verdicts ${hits} times (${perKilo.toFixed(1)}/1000 words); return to what the character can see, touch, say, and the physical consequences — don't seal it for the reader.`,
    excerpt: compact(samples.join(' | ')),
  }];
}

function findPeriodStutter(proseLines) {
  const findings = [];
  let runLen = 0;
  let runStartLine = null;
  let runSample = [];

  const flush = () => {
    if (runLen >= STUTTER_MIN_RUN) {
      findings.push({
        line: runStartLine,
        column: 1,
        type: 'period-stutter',
        severity: 'advisory',
        message: `Period stutter: ${runLen} consecutive short narrative sentences with no breathing room; merge the fragments into mid-length sentences and restore image and connective tissue (see the sentence-length/density rules in this skill).`,
        excerpt: compact(runSample.join(' ')),
      });
    }
    runLen = 0;
    runStartLine = null;
    runSample = [];
  };

  for (const { text, lineNo } of proseLines) {
    const trimmed = text.trim();
    if (!trimmed) continue; // blank line = one-sentence-one-paragraph layout, not a break in narration
    if (isDivider(trimmed) || isStructural(trimmed)) {
      flush(); // divider/markdown structure line: reset stutter count
      continue;
    }
    const narrative = stripQuoted(trimmed);
    if (visibleLength(narrative) === 0) {
      flush(); // pure dialogue/chat: staccato is normal genre form, reset
      continue;
    }
    // Narration fragments only; mixed lines (narration + quoted object/short line)
    // still contribute their outside-quote fragments to the stutter count.
    for (const sentence of splitSentences(narrative)) {
      if (visibleLength(sentence) <= STUTTER_MAX_SENTENCE) {
        if (runLen === 0) runStartLine = lineNo;
        runLen += 1;
        if (runSample.length < 6) runSample.push(sentence);
      } else {
        flush();
      }
    }
  }
  flush();
  return findings;
}

function isDivider(trimmed) {
  return /^-{3,}$/.test(trimmed) || /^[*_]{3,}$/.test(trimmed);
}

// Markdown structure lines (headings/lists/quotes/tables) and chapter titles are not
// narrative prose; long-paragraph/stutter/em-dash checks skip them.
function isStructural(trimmed) {
  return /^(#{1,6}\s|>\s?|[-*+]\s|\d+[.)]\s|\|)/.test(trimmed)
    || /^chapter\s+\d+/i.test(trimmed);
}

// HTML comments (the `<!-- deslop:skip -->` exemption marker) are meta lines, not
// prose; `--` inside them must not count as an em dash.
function stripHtmlComments(text) {
  let out = text;
  let previous;
  do {
    previous = out;
    out = out.replace(/<!--[\s\S]*?-->|<!--[\s\S]*$/g, '');
  } while (out !== previous);
  return out;
}

// Strip paired-quote spans (dialogue/system text), leaving narration only.
function stripQuoted(text) {
  let out = text;
  for (const src of QUOTE_SOURCES) out = out.replace(new RegExp(src, 'g'), '');
  return out;
}

// Replace paired-quote spans (including the quotes) with equal-length '?' placeholders:
// exempts dialogue from per-spot rules while preserving original offsets for
// positioning and excerpting. The placeholder is a sentence boundary, so rules using
// [^.!?\n] treat quoted spans as a break — exactly what dialogue exemption means.
function maskQuoted(text) {
  let out = text;
  for (const src of QUOTE_SOURCES) {
    out = out.replace(new RegExp(src, 'g'), (m) => '?'.repeat(m.length));
  }
  return out;
}

// Return quoted spans (including the quotes) as [start, end) ranges.
function quotedRanges(text) {
  const ranges = [];
  for (const src of QUOTE_SOURCES) {
    const re = new RegExp(src, 'g');
    let match;
    while ((match = re.exec(text)) !== null) ranges.push([match.index, match.index + match[0].length]);
  }
  return ranges;
}

function splitSentences(trimmed) {
  return trimmed
    .split(/[.!?]+/)
    .map((s) => s.trim())
    .filter(Boolean);
}

function sentenceAround(text, index) {
  let start = index;
  while (start > 0 && !STOP_CHARS.has(text[start - 1])) start -= 1;
  let end = index;
  while (end < text.length && !STOP_CHARS.has(text[end])) end += 1;
  return compact(text.slice(start, end).trim());
}

// Word count (the English density denominator): letters/digits with internal
// apostrophes and hyphens count as one word.
function visibleLength(text) {
  const m = text.match(/[A-Za-z0-9]+(?:['’][A-Za-z0-9]+|-[A-Za-z0-9]+)*/g);
  return m ? m.length : 0;
}

function countTerms(text, terms) {
  let count = 0;
  for (const term of terms) {
    let index = text.toLowerCase().indexOf(term);
    while (index !== -1) {
      count += 1;
      index = text.toLowerCase().indexOf(term, index + term.length);
    }
  }
  return count;
}

function parseFenceMarker(trimmedLine) {
  const match = /^(?:`{3,}|~{3,})/.exec(trimmedLine);
  if (!match) return null;
  return { char: match[0][0], length: match[0].length };
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
