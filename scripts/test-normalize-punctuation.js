#!/usr/bin/env node
"use strict";

const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { spawnSync } = require("child_process");

const repoRoot = path.resolve(__dirname, "..");
const normalizer = path.join(
  repoRoot,
  "skills/story-deslop/scripts/normalize-punctuation.js"
);
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "normalize-punctuation-"));

function run(args) {
  return spawnSync(process.execPath, [normalizer, ...args], {
    cwd: repoRoot,
    encoding: "utf8",
  });
}

try {
  const prose = path.join(tmpDir, "prose.md");
  const original = [
    "---",
    "title: fixture",
    "---",
    "# Chapter 1",
    "He said ... the answer was like this -- really.",
    "10--20",
    "---",
    "```text",
    "fence content ... and -- must be kept",
    "```",
    "“Quotes ... keep style”",
    "",
  ].join("\r\n");
  fs.writeFileSync(prose, original, "utf8");

  const check = run(["--check", prose]);
  assert.strictEqual(check.status, 1, check.stderr);
  assert.match(check.stdout, /ellipsis/);
  assert.match(check.stdout, /double-hyphen/);
  assert.match(check.stdout, /markdown-divider/);
  assert.strictEqual(fs.readFileSync(prose, "utf8"), original, "--check must not write");

  const write = run([prose]);
  assert.strictEqual(write.status, 0, write.stderr);
  const normalized = fs.readFileSync(prose, "utf8");
  assert(normalized.includes("title: fixture\r\n---"), "frontmatter must remain intact");
  assert(normalized.includes("fence content ... and -- must be kept"), "fenced text must remain intact");
  assert(normalized.includes("10–20"), "numeric ranges must use the en dash");
  assert(normalized.includes("“Quotes … keep style”"), "default mode must keep quote style");
  assert(!normalized.split("\r\n").includes("---", 3), "body divider must be removed");
  assert(normalized.includes("\r\n"), "CRLF input must keep CRLF output");
  const normalizedProse = normalized
    .replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "")
    .replace(/```[\s\S]*?```/g, "");
  assert(!/(?:…{2,}|--)/m.test(normalizedProse));

  const second = run([prose]);
  assert.strictEqual(second.status, 0, second.stderr);
  assert.match(second.stdout, /Changed files: 0/);
  assert.strictEqual(fs.readFileSync(prose, "utf8"), normalized, "normalization must be idempotent");

  // Mixed line endings: one isolated CRLF must not flip the whole file to CRLF; a
  // clean pass must not touch a single byte, otherwise --check reports zero issues
  // while write mode rewrites the whole file — the two modes would disagree.
  const mixedEol = path.join(tmpDir, "mixed-eol.md");
  const mixedOriginal = "He stood where he was.\r\nThe wind was strong.\nThe rain stopped.\n";
  fs.writeFileSync(mixedEol, mixedOriginal, "utf8");
  const mixedCheck = run(["--check", mixedEol]);
  assert.strictEqual(mixedCheck.status, 0, mixedCheck.stdout + mixedCheck.stderr);
  const mixedWrite = run([mixedEol]);
  assert.strictEqual(mixedWrite.status, 0, mixedWrite.stderr);
  assert.match(mixedWrite.stdout, /Changed files: 0/);
  assert.strictEqual(
    fs.readFileSync(mixedEol, "utf8"),
    mixedOriginal,
    "mixed line endings must survive a clean pass byte-for-byte"
  );

  // Mixed line endings + a real punctuation issue: fix only the punctuation and
  // keep each line's own ending.
  const mixedDirty = path.join(tmpDir, "mixed-eol-dirty.md");
  fs.writeFileSync(mixedDirty, "He said ... really.\r\nThe wind was strong -- the rain stopped.\n", "utf8");
  assert.strictEqual(run([mixedDirty]).status, 0);
  assert.strictEqual(
    fs.readFileSync(mixedDirty, "utf8"),
    "He said … really.\r\nThe wind was strong — the rain stopped.\n",
    "per-line endings must be preserved while punctuation is normalized"
  );

  // The `--` inside an HTML comment is not pause punctuation: the
  // `<!-- deslop:skip -->` exemption marker must stay verbatim in the body —
  // rewriting it would dissolve the comment and the marker would leak as visible text.
  const marker = path.join(tmpDir, "marker.md");
  const markerOriginal = [
    "# Chapter 12 Rainy Night",
    "<!-- deslop:skip -->",
    "He clenched his fists and slowly got to his feet.",
    "<!--",
    "Multi-line comment with --- and ellipsis... stays as is",
    "-->",
    "Prose ... continues. <!-- inline note -->",
    "",
  ].join("\n");
  fs.writeFileSync(marker, markerOriginal, "utf8");
  const markerCheck = run(["--check", marker]);
  assert.strictEqual(markerCheck.status, 1, markerCheck.stderr);
  assert.doesNotMatch(markerCheck.stdout, /double-hyphen/, "HTML comments must not report double-hyphen");
  assert.doesNotMatch(markerCheck.stdout, /markdown-divider/, "a --- inside a comment is not a body divider");
  assert.strictEqual(run([marker]).status, 0);
  const markerNormalized = fs.readFileSync(marker, "utf8");
  assert(markerNormalized.includes("<!-- deslop:skip -->"), "the deslop:skip marker must stay verbatim");
  assert(markerNormalized.includes("Multi-line comment with --- and ellipsis... stays as is"), "multi-line comment content must stay verbatim");
  assert(markerNormalized.includes("<!-- inline note -->"), "inline comments must stay verbatim");
  assert(markerNormalized.includes("Prose … continues."), "prose outside comments must still be normalized");

  // An unclosed comment is not a license to exempt everything to EOF: it must be
  // reported by name, and the following prose must still be checked/normalized.
  // Otherwise one mistyped `<!--` would silently make `--check` exit 0 for a whole
  // file full of `...` / `---`.
  const unclosedComment = path.join(tmpDir, "unclosed-comment.md");
  fs.writeFileSync(
    unclosedComment,
    "# Chapter 13\n<!-- temp note\nProse ... continues.\n---\n",
    "utf8"
  );
  const unclosedCheck = run(["--check", unclosedComment]);
  assert.strictEqual(unclosedCheck.status, 1, unclosedCheck.stdout + unclosedCheck.stderr);
  assert.match(unclosedCheck.stdout, /html-comment-unclosed/);
  assert.match(unclosedCheck.stdout, /ellipsis|markdown-divider/);
  assert.strictEqual(run([unclosedComment]).status, 0);
  const unclosedNormalized = fs.readFileSync(unclosedComment, "utf8");
  assert(unclosedNormalized.includes("<!-- temp note"), "the unclosed comment opener must not be corrupted");
  assert(unclosedNormalized.includes("Prose … continues."), "prose after the unclosed comment must still be normalized");
  assert(!unclosedNormalized.includes("\n---\n"), "a body divider after the unclosed comment must still be removed");

  // Deleting empty pause tokens can glue neighboring dots/ellipses into new
  // "..."/"……" sequences; one pass must clean up fully, otherwise the finished text
  // keeps an ASCII ellipsis that a later rerun of the same step would re-edit.
  const merge = path.join(tmpDir, "merge.md");
  fs.writeFileSync(merge, "He said ….... really.\nAnd …... then.\n", "utf8");
  assert.strictEqual(run([merge]).status, 0);
  assert.strictEqual(fs.readFileSync(merge, "utf8"), "He said … really.\nAnd … then.\n");
  const mergeRecheck = run(["--check", merge]);
  assert.strictEqual(mergeRecheck.status, 0, "after one normalization pass --check must be clean: " + mergeRecheck.stdout);
  assert.match(run([merge]).stdout, /Changed files: 0/);

  // Double spaces and space-before-punctuation.
  const spacing = path.join(tmpDir, "spacing.md");
  fs.writeFileSync(spacing, "He said  no ,  but stayed .\n", "utf8");
  const spacingCheck = run(["--check", spacing]);
  assert.strictEqual(spacingCheck.status, 1, spacingCheck.stdout + spacingCheck.stderr);
  assert.match(spacingCheck.stdout, /spacing/);
  assert.strictEqual(run([spacing]).status, 0);
  assert.strictEqual(fs.readFileSync(spacing, "utf8"), "He said no, but stayed.\n");

  const fences = path.join(tmpDir, "fences.md");
  const fencedOriginal = [
    "~~~markdown",
    "tilde fence content ... must be kept",
    "```",
    "a different marker cannot close -- still kept",
    "~~",
    "a shorter tilde cannot close -- still kept",
    "~~~",
    "outside the tilde fence ... must be normalized",
    "````markdown",
    "```javascript",
    "four-backtick fence content ... must be kept",
    "```",
    "shorter backticks cannot close -- still kept",
    "````",
    "outside the backtick fence ... must be normalized",
    "",
  ].join("\n");
  fs.writeFileSync(fences, fencedOriginal, "utf8");

  const fencedWrite = run([fences]);
  assert.strictEqual(fencedWrite.status, 0, fencedWrite.stderr);
  const fencedNormalized = fs.readFileSync(fences, "utf8");
  assert(fencedNormalized.includes("tilde fence content ... must be kept"));
  assert(fencedNormalized.includes("a different marker cannot close -- still kept"));
  assert(fencedNormalized.includes("a shorter tilde cannot close -- still kept"));
  assert(fencedNormalized.includes("four-backtick fence content ... must be kept"));
  assert(fencedNormalized.includes("shorter backticks cannot close -- still kept"));
  assert(fencedNormalized.includes("outside the tilde fence … must be normalized"));
  assert(fencedNormalized.includes("outside the backtick fence … must be normalized"));

  const ascii = path.join(tmpDir, "ascii.md");
  fs.writeFileSync(ascii, '"Alpha" and “Beta”\n', "utf8");
  assert.strictEqual(run(["--quote-mode=ascii", ascii]).status, 0);
  assert.strictEqual(fs.readFileSync(ascii, "utf8"), '"Alpha" and "Beta"\n');

  const curly = path.join(tmpDir, "curly.md");
  fs.writeFileSync(curly, '"Alpha" and "Beta" — it\'s here.\n', "utf8");
  assert.strictEqual(run(["--quote-mode", "curly", curly]).status, 0);
  assert.strictEqual(fs.readFileSync(curly, "utf8"), "“Alpha” and “Beta” — it’s here.\n");

  const missing = run([path.join(tmpDir, "missing.md")]);
  assert.strictEqual(missing.status, 2);
  assert.match(missing.stderr, /unable to read/);

  console.log("OK: punctuation normalizer check/write, robust fences, CRLF, spacing, quote modes, and errors");
} finally {
  fs.rmSync(tmpDir, { recursive: true, force: true });
}
