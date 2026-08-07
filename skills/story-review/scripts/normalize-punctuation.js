#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const USAGE = `Usage: node normalize-punctuation.js [--check] [--quote-mode keep|curly|ascii] <file...>

Normalize prose punctuation deterministically:
  - collapse "...", "....", "…" runs to a single ellipsis character (…)
  - convert double hyphens (--) to an em dash (—); never inside HTML comments
  - collapse double spaces; drop space before sentence punctuation ( , . ! ? ; : )
  - remove markdown divider lines (---) from prose
  - keep quote style by default; convert quotes only when explicitly requested
    (curly: straight quotes to typographic quotes; ascii: typographic to straight)
`;

const options = {
  check: false,
  quoteMode: 'keep',
  files: [],
};

for (let i = 2; i < process.argv.length; i += 1) {
  const arg = process.argv[i];
  if (arg === '--check') {
    options.check = true;
  } else if (arg === '--quote-mode') {
    const value = process.argv[i + 1];
    if (!value) die('--quote-mode requires keep, curly, or ascii');
    options.quoteMode = value;
    i += 1;
  } else if (arg.startsWith('--quote-mode=')) {
    options.quoteMode = arg.slice('--quote-mode='.length);
  } else if (arg === '-h' || arg === '--help') {
    process.stdout.write(USAGE);
    process.exit(0);
  } else if (arg.startsWith('-')) {
    die(`Unknown option: ${arg}`);
  } else {
    options.files.push(arg);
  }
}

if (!['keep', 'curly', 'ascii'].includes(options.quoteMode)) {
  die(`Invalid --quote-mode: ${options.quoteMode}`);
}
if (options.files.length === 0) {
  die('No files provided');
}

let totalFindings = 0;
let changedFiles = 0;
let failed = false;

for (const file of options.files) {
  const fullPath = path.resolve(file);
  let input;
  try {
    input = fs.readFileSync(fullPath, 'utf8');
  } catch (error) {
    failed = true;
    console.error(`${file}: unable to read (${error.message})`);
    continue;
  }

  const result = normalizeDocument(input, options.quoteMode);
  totalFindings += result.findings.length;

  if (options.check) {
    for (const finding of result.findings) {
      console.log(`${file}:${finding.line}:${finding.column}: ${finding.type}: ${finding.message}`);
    }
    continue;
  }

  if (result.output !== input) {
    fs.writeFileSync(fullPath, result.output, 'utf8');
    changedFiles += 1;
    console.log(`${file}: normalized (${result.findings.length} issue${result.findings.length === 1 ? '' : 's'})`);
  }
}

if (failed) {
  process.exit(2);
}
if (options.check && totalFindings > 0) {
  process.exit(1);
}
if (!options.check) {
  console.log(`Done. Changed files: ${changedFiles}`);
}

function die(message) {
  console.error(message);
  console.error(USAGE.trimEnd());
  process.exit(2);
}

function normalizeDocument(input, quoteMode) {
  const { lines, endings } = splitLinesKeepingEndings(input);

  const findings = [];
  const outputLines = [];
  let fence = null;
  let inFrontMatter = hasYamlFrontMatter(lines);
  let quoteOpen = false;
  let commentOpen = false;
  let commentStart = null;
  const commentCloseAhead = new Array(lines.length + 1).fill(false);
  for (let index = lines.length - 1; index >= 0; index -= 1) {
    commentCloseAhead[index] = lines[index].includes('-->') || commentCloseAhead[index + 1];
  }

  for (let index = 0; index < lines.length; index += 1) {
    const lineNo = index + 1;
    const ending = endings[index];
    let line = lines[index];
    const trimmed = line.trim();

    // An unclosed `<!--` must not mask the rest of the document as a comment. If there
    // is no `-->` before EOF, report it at the start position and resume prose scanning
    // from the current line; the line containing the opener stays protected.
    if (commentOpen && !commentCloseAhead[index]) {
      findings.push({
        line: commentStart?.line || lineNo,
        column: commentStart?.column || 1,
        type: 'html-comment-unclosed',
        message: 'HTML comment is not closed; the rest of the content is still checked as prose.',
      });
      commentOpen = false;
      commentStart = null;
    }

    if (inFrontMatter) {
      outputLines.push(line + ending);
      if (index > 0 && trimmed === '---') inFrontMatter = false;
      continue;
    }

    if (fence) {
      outputLines.push(line + ending);
      if (isClosingFence(line, fence)) fence = null;
      continue;
    }

    const openingFence = parseOpeningFence(line);
    if (openingFence) {
      fence = openingFence;
      outputLines.push(line + ending);
      continue;
    }

    // A `---` inside a multi-line HTML comment is comment content, not a prose divider.
    if (trimmed === '---' && !commentOpen) {
      findings.push({
        line: lineNo,
        column: line.indexOf('-') + 1,
        type: 'markdown-divider',
        message: 'Do not use markdown divider lines in prose; remove this line.',
      });
      continue;
    }

    const commentOpenBefore = commentOpen;
    const punctuationResult = normalizePausePunctuation(line, lineNo, commentOpen);
    findings.push(...punctuationResult.findings);
    line = punctuationResult.line;
    commentOpen = punctuationResult.commentOpen;
    if (!commentOpenBefore && commentOpen) {
      commentStart = { line: lineNo, column: Math.max(1, line.lastIndexOf('<!--') + 1) };
    } else if (!commentOpen) {
      commentStart = null;
    }

    const quoteResult = normalizeQuotes(line, quoteMode, quoteOpen, lineNo);
    findings.push(...quoteResult.findings);
    line = quoteResult.line;
    quoteOpen = quoteResult.quoteOpen;

    outputLines.push(line + ending);
  }

  if (commentOpen) {
    findings.push({
      line: commentStart?.line || lines.length,
      column: commentStart?.column || 1,
      type: 'html-comment-unclosed',
      message: 'HTML comment is not closed; the rest of the content is still checked as prose.',
    });
  }

  return {
    output: outputLines.join(''),
    findings,
  };
}

// Remember each line's original ending. Normalizing the whole file to one ending
// because a single stray CRLF appears would flip every line — an unrequested full-file
// diff; --check reports nothing about endings, and this punctuation-only step must not
// touch them.
function splitLinesKeepingEndings(input) {
  const lines = [];
  const endings = [];
  let cursor = 0;

  while (cursor < input.length) {
    const newlineIndex = input.indexOf('\n', cursor);
    if (newlineIndex === -1) {
      lines.push(input.slice(cursor));
      endings.push('');
      break;
    }
    const crlf = newlineIndex > cursor && input[newlineIndex - 1] === '\r';
    lines.push(input.slice(cursor, crlf ? newlineIndex - 1 : newlineIndex));
    endings.push(crlf ? '\r\n' : '\n');
    cursor = newlineIndex + 1;
  }

  return { lines, endings };
}

function parseOpeningFence(line) {
  const match = line.match(/^ {0,3}(`{3,}|~{3,})(.*)$/);
  if (!match) return null;

  const marker = match[1];
  const rest = match[2];
  if (marker[0] === '`' && rest.includes('`')) return null;

  return { marker: marker[0], minimumLength: marker.length };
}

function isClosingFence(line, fence) {
  const marker = fence.marker === '`' ? '`' : '~';
  const match = line.match(new RegExp(`^ {0,3}(${marker}{3,})[\\t ]*$`));
  return Boolean(match && match[1].length >= fence.minimumLength);
}

// Deleting empty pause tokens can glue neighboring dots/hyphens into new "..."/"--"
// sequences (e.g. ".. -- ." -> "--"), so one pass never cleans up fully and a second
// run would re-edit settled prose. Iterate to a fixed point: each pass replaces at
// least one token with a non-pause character, so it strictly converges.
function normalizePausePunctuation(line, lineNo, commentOpen) {
  let current = line;
  let findings = null;
  let commentOpenAfter = commentOpen;

  for (;;) {
    const comments = htmlCommentSpans(current, commentOpen);
    commentOpenAfter = comments.open;
    const pass = normalizePausePunctuationPass(current, lineNo, comments.spans);
    if (findings === null) findings = pass.findings;
    if (pass.line === current) break;
    current = pass.line;
  }

  return { line: current, findings, commentOpen: commentOpenAfter };
}

function normalizePausePunctuationPass(line, lineNo, commentSpans) {
  const findings = [];
  const original = line;
  const pattern = /\.{3,}|(?:…){2,}|--+/g;
  let output = '';
  let lastIndex = 0;
  let match;

  while ((match = pattern.exec(original)) !== null) {
    const token = match[0];
    // HTML comments are prose meta (such as the `<!-- deslop:skip -->` exemption
    // marker): the `--` inside `<!--`/`-->` is not pause punctuation. Rewriting it
    // would dissolve the comment and the marker would become visible prose.
    if (insideSpans(match.index, match.index + token.length, commentSpans)) continue;
    output += original.slice(lastIndex, match.index);
    const replacement = choosePauseReplacement(original, match.index, token.length);
    output += replacement;
    findings.push({
      line: lineNo,
      column: match.index + 1,
      type: getPauseType(token),
      message: replacement ? `Replaced with ${replacement}.` : 'Removed duplicate punctuation.',
    });
    lastIndex = match.index + token.length;
  }

  output += original.slice(lastIndex);

  // Collapse double spaces and drop space before sentence punctuation. HTML comment
  // spans were already protected by the token pass; whitespace edits inside comments
  // are harmless here because the marker words stay intact.
  const collapsed = output.replace(/ {2,}/g, ' ').replace(/ +([,.;:!?])/g, '$1');
  if (collapsed !== output) {
    findings.push({
      line: lineNo,
      column: 1,
      type: 'spacing',
      message: 'Collapsed double spaces / removed space before punctuation.',
    });
    output = collapsed;
  }
  return { line: output, findings };
}

// In-line HTML comment spans (including `<!--`/`-->` themselves); comments may span
// lines, and an unclosed state is handed to the next line.
function htmlCommentSpans(line, openBefore) {
  const spans = [];
  let open = openBefore;
  let cursor = 0;

  while (cursor < line.length) {
    if (open) {
      const close = line.indexOf('-->', cursor);
      if (close === -1) {
        spans.push([cursor, line.length]);
        return { spans, open: true };
      }
      spans.push([cursor, close + 3]);
      cursor = close + 3;
      open = false;
      continue;
    }

    const start = line.indexOf('<!--', cursor);
    if (start === -1) break;
    cursor = start;
    open = true;
  }

  return { spans, open };
}

function insideSpans(start, end, spans) {
  return spans.some(([spanStart, spanEnd]) => start < spanEnd && end > spanStart);
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

function getPauseType(token) {
  if (token.startsWith('-')) return 'double-hyphen';
  return 'ellipsis';
}

// English house style: ellipsis is a single … character; -- becomes an em dash (—).
// Both rewrites are deterministic and safe for prose (an em dash is standard English
// punctuation; the style gate handles overuse, this normalizer only repairs the form).
function choosePauseReplacement(text, start, length) {
  const before = previousNonSpace(text, start - 1);
  const after = nextNonSpace(text, start + length);

  if (getPauseType(text.slice(start, start + length)) === 'double-hyphen') {
    // "--" between two digits is a range in some house styles ("pages 3--4");
    // normal prose has no such use, but don't corrupt one.
    if (/\d/.test(before) && /\d/.test(after)) return '–';
    return '—';
  }
  return '…';
}

function previousNonSpace(text, index) {
  for (let i = index; i >= 0; i -= 1) {
    if (!/\s/.test(text[i])) return text[i];
  }
  return '';
}

function nextNonSpace(text, index) {
  for (let i = index; i < text.length; i += 1) {
    if (!/\s/.test(text[i])) return text[i];
  }
  return '';
}

function normalizeQuotes(line, quoteMode, quoteOpen, lineNo) {
  if (quoteMode === 'keep') {
    return { line, findings: [], quoteOpen };
  }

  const findings = [];
  let output = '';

  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (quoteMode === 'ascii' && /[“”‘’]/.test(ch)) {
      output += '"';
      findings.push({ line: lineNo, column: i + 1, type: 'quote-style', message: 'Converted to straight quotes per explicit quote-mode.' });
      continue;
    }
    if (quoteMode === 'curly' && (ch === '"' || ch === "'")) {
      // Straight single quotes in prose are overwhelmingly apostrophes
      // (contractions/possessives) — their typographic form is the right single
      // quote, and they never flip the double-quote pairing state.
      if (ch === "'") {
        output += '’';
        findings.push({ line: lineNo, column: i + 1, type: 'quote-style', message: 'Converted to typographic apostrophe per explicit quote-mode.' });
        continue;
      }
      // Alternate open/close within a line; track state across lines so an unclosed
      // opening quote on one line still pairs with the next line's closing quote.
      output += quoteOpen ? '”' : '“';
      quoteOpen = !quoteOpen;
      findings.push({ line: lineNo, column: i + 1, type: 'quote-style', message: 'Converted to typographic quotes per explicit quote-mode.' });
      continue;
    }
    output += ch;
  }

  return { line: output, findings, quoteOpen };
}
