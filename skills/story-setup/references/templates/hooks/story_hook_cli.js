#!/usr/bin/env node
"use strict"

// story_hook_cli.js — node bridge for Claude Code bash hooks
// Claude-side hooks are bash (settings.json registers bash scripts); the core
// logic lives here by requiring the shared core story_hook_core.js — the same one
// OpenCode/ZCode use, guaranteed byte-identical by check-shared-files. Surfaces
// centralized in the core (single implementation): prose net / word count
// (prose-net), path extraction (extract-target), git commit detection
// (is-git-commit), continuity (continuity).
// Surfaces still implemented per-CLI:
//   - outline block judgment: Claude uses guard-outline-before-prose.sh pure bash
//     (this CLI has no prose-block subcommand); codex prose_block_reason ↔ core
//     proseBlockReason parity is locked by scripts/test-prose-net-parity.sh Part E.
//   - staged markdown warnings: Claude uses validate-story-commit.sh bash grep;
//     codex staged_markdown_warnings ↔ core stagedMarkdownWarnings also locked by
//     Part E. Match semantics and copy follow the JS core.
// Each CLI keeps only a thin shell reading/writing its own hook I/O format. node
// writes UTF-8 stdout natively, dropping the old embedded-python cp936/LC_ALL dance.

const fs = require("node:fs")
const core = require("./story_hook_core.js")

function readStdin() {
  try {
    return fs.readFileSync(0, "utf8")
  } catch {
    return ""
  }
}

// Char-for-char matching the old extract_target_path dig: only dict
// file_path/path/filePath, recursing into tool_input/input/parameters/args;
// lists never descend.
function digTargetPath(value) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    for (const key of ["file_path", "path", "filePath"]) {
      const found = value[key]
      if (typeof found === "string" && found) return found
    }
    for (const key of ["tool_input", "input", "parameters", "args"]) {
      const found = digTargetPath(value[key])
      if (found) return found
    }
  }
  return ""
}

// Char-for-char matching the old validate-story-commit find_command: dict
// command/cmd/script (take any string, empty allowed), then recurse into
// tool_input/input/parameters/args.
function digCommand(value) {
  if (value && typeof value === "object" && !Array.isArray(value)) {
    for (const key of ["command", "cmd", "script"]) {
      if (typeof value[key] === "string") return value[key]
    }
    for (const key of ["tool_input", "input", "parameters", "args"]) {
      const found = digCommand(value[key])
      if (found) return found
    }
  }
  return ""
}

const [command, ...args] = process.argv.slice(2)

if (command === "extract-target") {
  // PostToolUse tool-input JSON → target file path. Missing input / parse failure /
  // no path all exit non-zero so the bash side passes silently (same as the old
  // python sys.exit(1)).
  const raw = process.env.HOOK_INPUT || readStdin()
  if (!raw) process.exit(1)
  let obj
  try {
    obj = JSON.parse(raw)
  } catch {
    process.exit(1)
  }
  const target = digTargetPath(obj)
  if (!target) process.exit(1)
  process.stdout.write(target)
} else if (command === "prose-net") {
  // Lightweight deterministic net (incl. toxic patterns) + word-count debt,
  // aligned with the old embedded-python second segment's out list (net items +
  // optional word-count line). Read failures exit silently (a backstop must not
  // bite the flow).
  const absolute = args[0]
  let text
  try {
    text = fs.readFileSync(absolute, "utf8")
  } catch {
    process.exit(0)
  }
  const out = core.proseNetFindings(text)
  const wordcount = core.wordcountFinding(absolute, text)
  if (wordcount) out.push(wordcount)
  if (out.length) process.stdout.write(out.join("\n"))
} else if (command === "prose-toxic") {
  // Toxic-pattern deterministic scan standalone (for the guard pre-gate / manual
  // rescan; prose-net already includes the same results).
  // Contract: empty stdout = clean; non-empty = finding lines (one per line, last
  // line is the clear-to-continue requirement + full-scan hint). Unreadable files
  // or any internal error exit 0 silently (consistent with this CLI's degradation
  // philosophy; a backstop must not bite the flow).
  const absolute = args[0]
  try {
    const text = fs.readFileSync(absolute, "utf8")
    const out = core.toxicPhraseFindings(text)
    if (out.length) process.stdout.write(out.join("\n"))
  } catch {
    process.exit(0)
  }
} else if (command === "is-git-commit") {
  // git commit detection. The command prefers STORY_COMMIT_COMMAND, otherwise digs
  // command/cmd/script out of HOOK_INPUT. Uses the shared core isGitCommitCommand
  // (js word-splitting semantics, consistent with OpenCode/ZCode; the documented
  // advisory-only differences from the old python shlex on "in-quote separators").
  // Is a git commit → exit 0, otherwise exit 1.
  let raw = process.env.STORY_COMMIT_COMMAND || ""
  if (!raw) {
    const hookInput = process.env.HOOK_INPUT || ""
    if (!hookInput) process.exit(1)
    let obj
    try {
      obj = JSON.parse(hookInput)
    } catch {
      obj = {}
    }
    raw = digCommand(obj)
  }
  if (!raw) process.exit(1)
  process.exit(core.isGitCommitCommand(raw) ? 0 : 1)
} else if (command === "continuity") {
  // Cross-batch continuity backstop: tracking staleness + duplicate chapter
  // titles. Uses the shared core continuityFindings (messages verbatim-aligned
  // with the old python; multi-book dedup ordering follows js semantics, only
  // affecting advisory order).
  const root = args[0]
  const out = core.continuityFindings(root)
  if (out.length) process.stdout.write(out.join("\n") + "\n")
} else {
  process.exit(2)
}
