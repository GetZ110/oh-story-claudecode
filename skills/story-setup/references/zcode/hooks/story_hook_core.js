"use strict"

const fs = require("node:fs")
const path = require("node:path")
const { spawnSync } = require("node:child_process")

function existingDir(value) {
  if (typeof value !== "string" || !value.trim()) return null
  try {
    const resolved = fs.realpathSync(path.resolve(value))
    return fs.statSync(resolved).isDirectory() ? resolved : null
  } catch {
    return null
  }
}

function safeRelative(root, target) {
  try {
    const rel = path.relative(path.resolve(root), path.resolve(target))
    return rel && !rel.startsWith("..") ? rel.split(path.sep).join("/") : String(target)
  } catch {
    return String(target)
  }
}

function resolveTarget(root, target, base = root) {
  const normalized = String(target || "").replace(/\\/g, "/")
  return path.isAbsolute(normalized) ? path.resolve(normalized) : path.resolve(base || root, normalized)
}

function firstLine(file) {
  try {
    return fs.readFileSync(file, "utf8").split(/\r?\n/, 1)[0].trim()
  } catch {
    return ""
  }
}

function findFirst(base, maxDepth, predicate) {
  if (maxDepth < 0) return null
  let entries = []
  try {
    entries = fs.readdirSync(base, { withFileTypes: true })
  } catch {
    return null
  }
  for (const entry of entries) {
    if (entry.name.startsWith(".") || entry.name === "node_modules") continue
    const full = path.join(base, entry.name)
    if (predicate(full, entry)) return full
  }
  if (maxDepth === 0) return null
  for (const entry of entries) {
    if (!entry.isDirectory() || entry.name.startsWith(".") || entry.name === "node_modules") continue
    const found = findFirst(path.join(base, entry.name), maxDepth - 1, predicate)
    if (found) return found
  }
  return null
}

function discoverActiveBook(root) {
  const declared = firstLine(path.join(root, ".active-book"))
  if (declared) {
    const candidate = resolveTarget(root, declared)
    const rel = path.relative(root, candidate)
    if (!rel.startsWith("..") && existingDir(candidate)) return candidate
  }
  const tracking = findFirst(root, 4, (_full, entry) => entry.isDirectory() && entry.name === "tracking")
  if (tracking) return path.dirname(tracking)
  const body = findFirst(root, 4, (_full, entry) => entry.isDirectory() && entry.name === "prose")
  if (body) return path.dirname(body)
  const bodyFile = findFirst(root, 4, (_full, entry) => entry.isFile() && entry.name === "prose.md")
  return bodyFile ? path.dirname(bodyFile) : null
}

function discoverAllBooks(root) {
  const books = new Map()
  function walk(base, depth) {
    if (depth < 0) return
    let entries = []
    try { entries = fs.readdirSync(base, { withFileTypes: true }) } catch { return }
    for (const entry of entries) {
      if (entry.name.startsWith(".") || entry.name === "node_modules") continue
      const full = path.join(base, entry.name)
      if (entry.isDirectory() && (entry.name === "tracking" || entry.name === "prose")) {
        books.set(path.dirname(full), path.dirname(full))
      } else if (entry.isFile() && entry.name === "prose.md") {
        books.set(path.dirname(full), path.dirname(full))
      }
    }
    for (const entry of entries) {
      if (!entry.isDirectory() || entry.name.startsWith(".") || entry.name === "node_modules") continue
      walk(path.join(base, entry.name), depth - 1)
    }
  }
  walk(root, 8)
  return [...books.values()]
}

function continuityFindings(root) {
  const messages = []
  for (const book of discoverAllBooks(root)) {
    const bodyDir = path.join(book, "prose")
    let chapters = []
    try {
      chapters = fs.readdirSync(bodyDir)
        .filter((file) => /^chapter.*\.md$/i.test(file))
        .map((file) => path.join(bodyDir, file))
    } catch {}

    const context = path.join(book, "tracking", "context.md")
    if (chapters.length && fs.existsSync(context)) {
      try {
        const newest = Math.max(...chapters.map((file) => fs.statSync(file).mtimeMs))
        const contextTime = fs.statSync(context).mtimeMs
        if (newest > contextTime + 1000) {
          const latest = chapters.reduce((left, right) => fs.statSync(left).mtimeMs > fs.statSync(right).mtimeMs ? left : right)
          messages.push(`[continuity] ${safeRelative(root, book)}: prose is ahead of tracking — latest is "${path.basename(latest)}" but tracking/context.md is older; continuation will lose continuity. Update tracking/context.md and tracking/foreshadowing.md before continuing.`)
        }
      } catch {}
    }

    const titles = new Map()
    for (const chapter of chapters) {
      const match = path.basename(chapter, ".md").match(/^chapter[_ ]?0*\d+[_\- ]+(.+)$/i)
      if (!match) continue
      const title = match[1].trim()
      if (title) titles.set(title, [...(titles.get(title) || []), path.basename(chapter)])
    }
    for (const [title, files] of titles.entries()) {
      if (files.length > 1) {
        messages.push(`[continuity] ${safeRelative(root, book)}: ${files.length} chapters share the title "${title}" (${files.join(", ").slice(0, 60)}); consider renaming.`)
      }
    }
  }
  return messages
}

function extractProseTargets(command) {
  const targets = []
  // Target tokens come in three shapes (quoted spans win): double-quoted / single-quoted /
  // bare word. The bare class only excludes ASCII whitespace (space/Tab/CR/LF, the shell's
  // real word splitters): \s in both js and python includes U+3000, and a full-width space
  // does not split shell words. Backslash-escaped spaces are still not supported —
  // resolveTarget normalizes \ to path separators (Windows paths).
  const bare = `[^ \\t\\r\\n"'<>|;&()]`
  const token = `"([^"]*prose[^"]*)"|'([^']*prose[^']*)'|["']?(${bare}*prose${bare}*)["']?`
  for (const source of [`>>?\\s*(?:${token})`, `(?:^|[\\s;&|(){}<>])(?:tee(?:\\s+-a)?|touch)\\s+(?:${token})`]) {
    const regex = new RegExp(source, "gm")
    let match
    while ((match = regex.exec(command)) !== null) {
      const target = match[1] || match[2] || match[3]
      if (target) targets.push(target)
    }
  }
  for (const raw of shellSegments(command)) {
    const segment = beforeShellRedirection(raw)
    const words = shellWords(segment)
    if (words.length >= 2 && (words[0] === "cp" || words[0] === "mv")) {
      const positional = words.slice(1).filter((word) => !word.startsWith("-"))
      const destination = positional[positional.length - 1]
      if (destination && destination.includes("prose")) targets.push(destination)
    }
  }
  return targets
}

// apply_patch target extraction. Only Add/Update would miss `*** Move to:` — a sub-directive
// of the Update File section (apply_patch's rename/move form) whose written path is the
// *destination*; the source no longer exists after the move. `*** Move to:` thus *replaces*
// the same section's source target. Delete File never enters the table (deletion is not a
// write; proseBlockReason already passes for existing prose and there is nothing to scan
// after deletion) — but a Delete section can still carry Move to (move then delete source),
// so Delete only clears the source slot pending replacement.
function extractPatchTargets(patchText) {
  const targets = []
  let sourceIndex = -1
  for (const line of String(patchText).split(/\r?\n/)) {
    const file = line.match(/^\*\*\* (Add|Update|Delete) File: (.+)$/)
    if (file) {
      if (file[1] === "Delete") {
        sourceIndex = -1
        continue
      }
      targets.push(file[2].trim())
      sourceIndex = targets.length - 1
      continue
    }
    const move = line.match(/^\*\*\* Move to: (.+)$/)
    if (move) {
      const destination = move[1].trim()
      if (!destination) continue
      if (sourceIndex >= 0) targets[sourceIndex] = destination
      else targets.push(destination)
      sourceIndex = -1
    }
  }
  return targets
}

function proseBlockReason(root, absolute) {
  const base = path.basename(absolute)
  const parent = path.basename(path.dirname(absolute))
  if (base === "prose.md") {
    if (fs.existsSync(absolute)) return null
    const book = path.dirname(absolute)
    if (fs.existsSync(path.join(root, "teardown-lib", path.basename(book)))) return null
    if (!fs.existsSync(path.join(book, "setting.md"))) return null
    if (!fs.existsSync(path.join(book, "section-outline.md"))) {
      return `⛔ Prose blocked: ${safeRelative(root, absolute)} is missing section-outline.md in the same directory. Finish "section-outline.md" per story-short-write before writing prose.`
    }
    return null
  }
  if (parent !== "prose" || !/^chapter.*\.md$/i.test(base) || fs.existsSync(absolute)) return null
  const match = base.match(/^chapter[_ ]?0*(\d+)/i)
  if (!match) return null
  const chapter = match[1]
  const book = path.dirname(path.dirname(absolute))
  // Canonical guard case: an agent may create {book}/prose/chapter_N.md before any
  // scaffolding exists. "Looks like a book" is not a pass condition; relative-path
  // misresolution belongs to the host adapter resolving against cwd, not a fail-open
  // in the core guard.
  if (fs.existsSync(path.join(root, "teardown-lib", path.basename(book)))) return null
  const outlineDir = path.join(book, "outline")
  let found = false
  try {
    found = fs.readdirSync(outlineDir).some((file) => {
      const candidate = file.match(/^outline_chapter_0*(\d+).*\.md$/i)
      return candidate && candidate[1] === chapter
    })
  } catch {}
  if (!found) {
    return `⛔ Prose blocked: chapter ${chapter} has no chapter outline (${safeRelative(root, outlineDir)}/outline_chapter_${chapter}.md). Build the chapter outline per story-long-write before writing prose.`
  }
  // Debt gate (stateless): before first-writing chapter N, if the previous chapter has
  // uncleared toxic patterns and no "deslop:skip" exemption, clear them first. The check
  // is computed from the previous chapter file itself; a missing/unreadable previous
  // chapter passes (miss over false-hit).
  const prevNum = Number(chapter) - 1
  if (prevNum >= 1) {
    let prevFile = null
    try {
      for (const file of fs.readdirSync(path.dirname(absolute))) {
        const pm = file.match(/^chapter[_ ]?0*(\d+).*\.md$/i)
        if (pm && Number(pm[1]) === prevNum) {
          prevFile = path.join(path.dirname(absolute), file)
          break
        }
      }
    } catch {}
    if (prevFile) {
      let prevText = null
      try { prevText = fs.readFileSync(prevFile, "utf8") } catch {}
      if (prevText !== null && !/deslop\s*:\s*skip/i.test(prevText.split(/\r?\n/).slice(0, 6).join("\n"))) {
        const hits = toxicPhraseFindings(prevText).filter((line) => /^Line \d+/.test(line))
        if (hits.length) {
          const shown = hits.slice(0, 6)
          const more = hits.length - shown.length
          let reason = `⛔ Prose blocked: the previous chapter (${path.basename(prevFile)}) still has ${hits.length} uncleared toxic patterns; clear them before writing chapter ${chapter}. To exempt explicitly, add <!-- deslop:skip --> under the previous chapter's title line and retry.\n${shown.join("\n")}`
          if (more > 0) reason += `\n(${more} more; full scan: node <skill>/scripts/check-ai-patterns.js --check <previous chapter file>)`
          return reason
        }
      }
    }
  }
  return null
}

// Terminal punctuation set aligned with check-degeneration.js findTruncation: a finished
// chapter ends on terminal/closing punctuation. ASCII " is the legal closing quote from
// normalize-punctuation.js --quote-mode ascii, so it is not "suspected truncation".
const TERMINAL = new Set(Array.from(".!?…”’”])}~—\""))
const QUOTE_OPENERS = new Set(["“", "‘", '"', "'"])
const SOFT_PATTERNS = [
  // Model-typed suffixes (language model / AI assistant / chatbot) must be consumed
  // optionally, otherwise the lookahead sees the next word and misses the classic
  // degenerate opening entirely.
  [/\b(?:as an?|being an?)\s+(?:AI|language model|artificial intelligence|chatbot|assistant)(?=\b|[.,;:!?"')\]]|I(?:'m| am)|can'?t|cannot|won'?t|will not|would|shall|must|$)/i, "AI self-reference"],
  [/^(Sure|Certainly|Here'?s|As an AI|I (?:cannot|can't|am unable|apologize))/, "AI chatbot voice"],
  [/\b(?:I|we)(?:'m|'re| am| are)? (?:sorry|apologize|unable|not able|can'?t|cannot) (?:to )?(?:continue|write|generate|finish|complete|help|assist|provide|produce)\b/i, "generation refusal"],
]
const HARD_PATTERNS = [
  [/\b(?:TODO|TBD|placeholder|to be continued)\b|\[INSERT[^\]]{0,20}\]/i, "placeholder"],
  [/\b(?:chapter outline|volume outline|master outline|story unit|plot point|target words?|word count target|hook note|payoff note|foreshadowing note)\b/i, "engineering-word leakage"],
  [/�/, "mojibake (replacement char)"],
]

function skippableLine(line) {
  return !line || line.startsWith("#") || line === "---" || /^[-—=*·•\s]+$/.test(line)
}

// ── Toxic patterns (deterministic AI sentence fingerprints, hot path of the
// after-write net) ───────────────────────────────────────────────
// Same spec as the same-name rules in check-ai-patterns.js: only deterministic,
// low-false-positive patterns; density/advisory checks belong to the deep scan, not
// this per-write net. All regexes scan linearly with bounded quantifiers — no
// catastrophic backtracking. Dialogue/chat/system text doesn't count: paired-quote
// spans are replaced with equal-length '?' placeholders (the placeholder naturally
// truncates the rules' character classes so no rule can stitch a false hit across
// quotes), and lines that still contain quote chars after masking (cross-line
// dialogue / unclosed quotes) are skipped whole. The Python mirror (codex
// story_codex_hook.py) is parity-locked by scripts/check-hook-regex-sync.sh and
// scripts/test-prose-net-parity.sh; the messages here are canonical.
const TOXIC_QUOTE_SPANS = [/“[^”]*”/g, /‘[^’]*’/g, /"[^"]*"/g, /'[^']*'/g]
const TOXIC_QUOTE_CHARS = new Set(Array.from("“”‘’\"'"))
// Clause-start boundary (a preceding char in this set admits the "wasn't X. It was Y"
// second clause opener); also used as the affirmation boundary.
const TOXIC_CLAUSE_BOUNDARY = new Set(Array.from(" ,.!?;:…—~ \t"))
const TOXIC_TRAILER_WINDOW_WORDS = 250
const TOXIC_SENTENCE_PATTERNS = [
  [/\b(?:his|her|their|the (?:man'?s|woman'?s|boy'?s|girl'?s)) voice\s+(?:was|were|sounded|stayed|remained|dropped)\s+(?:quiet|soft|low|calm|even|level|steady|gentle|barely (?:audible|a whisper))[^.!?\n]{0,30}?\b(?:but|yet|still|though)\b/gi, "voice-contrast", "Cut the 'voice was quiet/soft... but/yet...' contrast setup; write the concrete effect the voice lands on the room."],
  [/(?:\bno\s+[a-z][a-z0-9' -]{1,24}(?:,|\.)\s*){2}\bno\s+[a-z][a-z0-9' -]{1,24}\b/gi, "negation-parade", "Cut the 'No X. No Y...' denial list to one or none; write what is actually present."],
  [/\b(it|that|this) wasn'?t (?:just|merely|simply)\s+[^.!?\n,]{1,20}[,.]\s*\b(?:it|that|this) (?:was|is)\b/gi, "not-was-comparison", "Cut the negated setup; write the positive term directly, or show it through action/detail."],
]
// An in-scene announcement is not a narrator preview; the English net has no
// such lookbehind because the English preview phrases below are not in-scene
// announcements.
const TOXIC_TRAILER_PATTERN = /\blittle did (?:he|she|they|we|i|anyone|everyone) know\b|\bunbeknownst to (?:him|her|them|us|everyone)\b|\bno (?:one|body) knew (?:that|what|how|why|where|who)\b|\bnone of them knew\b|\bwhat (?:happened|came) next would\b|\bthis (?:was|is|would be) only the beginning\b|\bthe (?:night|day|battle|war|real (?:battle|war|test|challenge)) (?:was|is|had) (?:just|only) (?:beginning|starting)\b|\b(?:their|his|her|the) (?:lives|life|world|story) (?:was|were|is|are) about to change\b|\bfate had other plans\b/gi
// Chapter-end state summary: shares the end window with trailer-ending; it seals the
// past where trailer-ending previews the future. All branches are the banned forms by
// name. "In that moment, he finally understood" is NOT collected — in human narration
// that is a normal cognitive beat (and the density advisory covers the cluster).
const TOXIC_TRAILER_SUMMARY_PATTERN = /\bit was (?:a|the) (?:night|day|morning|moment) that would (?:change|alter|end) everything\b|\b(?:nothing|everything) would (?:ever )?be the same (?:again)?\b|\beverything was about to change\b|\bthe world would never be the same\b|\b(?:his|her|their|the) (?:life|world|story) (?:would|was) (?:be )?(?:forever|permanently) changed\b|\bthe wheels? of fate\b/gi

// The placeholder is "?" rather than ".": it must truncate the rules' [^.!?\n]
// negative classes (? is equivalent to a period in every rule's class) without
// landing on any rule's acceptance position. A period placeholder would forge a
// terminator for the end-window rules. Length is preserved, so the window cut
// doesn't drift.
function maskQuotedSpans(line) {
  let out = line
  for (const spans of TOXIC_QUOTE_SPANS) out = out.replace(spans, (m) => "?".repeat(m.length))
  return out
}

// "Wasn't it obvious?" — a question opener is not the "wasn't just X... was Y"
// contrast (the regex already requires a following "it/that/this was", but a
// question form "Wasn't it just X?" would otherwise slip past the comma clause).
function toxicNotWasExcluded(line, matched, start) {
  const before = line.slice(Math.max(0, start - 12), start)
  if (/wasn'?t it$/i.test(before)) return true
  return false
}

// Each line reports only the first matching sentence rule (rescan-to-clean
// philosophy: fix one spot, rescan for the next).
function matchToxicSentence(line) {
  for (const [regex, label, fix] of TOXIC_SENTENCE_PATTERNS) {
    regex.lastIndex = 0
    let match
    while ((match = regex.exec(line)) !== null) {
      if (label === "not-was-comparison" && toxicNotWasExcluded(line, match[0], match.index)) continue
      return [label, fix, match[0]]
    }
  }
  return null
}

function wordCount(text) {
  const m = text.match(/[A-Za-z0-9]+(?:['’][A-Za-z]+)?/g)
  return m ? m.length : 0
}

function toxicPhraseFindings(text) {
  const findings = []
  const content = []
  text.split("\n").forEach((raw, index) => {
    const line = raw.trim()
    if (skippableLine(line)) return
    const masked = maskQuotedSpans(line)
    for (const ch of masked) {
      if (TOXIC_QUOTE_CHARS.has(ch)) return
    }
    content.push([index + 1, masked])
  })
  for (const [lineNo, masked] of content) {
    const hit = matchToxicSentence(masked)
    if (hit) findings.push(`Line ${lineNo} toxic pattern [${hit[0]}]: "${hit[2].slice(0, 20)}" — ${hit[1]}`)
  }
  // trailer-ending / trailer-summary scan only the end window (word count after
  // quote masking, boundary line counted in full).
  let acc = 0
  let cut = content.length
  while (cut > 0 && acc < TOXIC_TRAILER_WINDOW_WORDS) {
    cut -= 1
    acc += wordCount(content[cut][1])
  }
  for (let i = cut; i < content.length; i++) {
    const [lineNo, masked] = content[i]
    const match = masked.match(TOXIC_TRAILER_PATTERN)
    if (match) findings.push(`Line ${lineNo} toxic pattern [trailer-ending]: "${match[0].slice(0, 20)}" — cut the chapter-end preview; end on an action or image that is happening now.`)
    const summary = masked.match(TOXIC_TRAILER_SUMMARY_PATTERN)
    if (summary) findings.push(`Line ${lineNo} toxic pattern [trailer-summary]: "${summary[0].slice(0, 20)}" — cut the chapter-end state verdict; the ending state is outline planning language — land the chapter on a concrete action, image, or line.`)
  }
  if (findings.length) findings.push("Toxic patterns are deterministic AI fingerprints: clear this chapter before continuing. Full scan: node <skill>/scripts/check-ai-patterns.js --check <prose file>")
  return findings
}

function proseNetFindings(text) {
  const findings = []
  const content = []
  text.split("\n").forEach((raw, index) => {
    const line = raw.trim()
    if (skippableLine(line)) return
    const lineNo = index + 1
    content.push([lineNo, line])
    let hit = false
    if (!QUOTE_OPENERS.has(line[0])) {
      for (const [regex, label] of SOFT_PATTERNS) {
        const match = line.match(regex)
        if (match) {
          findings.push(`Line ${lineNo} meta leakage (${label}): "${match[0].slice(0, 20)}"`)
          hit = true
          break
        }
      }
    }
    if (hit) return
    for (const [regex, label] of HARD_PATTERNS) {
      const match = line.match(regex)
      if (match) {
        findings.push(`Line ${lineNo} ${label}: "${match[0].slice(0, 20)}"`)
        break
      }
    }
  })
  for (let i = 1; i < content.length; i++) {
    const previous = content[i - 1][1]
    const [lineNo, current] = content[i]
    if (previous === current && current.length >= 8) findings.push(`Line ${lineNo} verbatim repeat: line identical to the previous line "${current.slice(0, 20)}"`)
  }
  if (content.length) {
    const [lineNo, last] = content[content.length - 1]
    if (!TERMINAL.has(Array.from(last).pop())) findings.push(`Line ${lineNo} suspected truncation: ending "...${last.slice(-12)}" does not end with terminal punctuation`)
  }
  // The "deslop:skip" exemption shares the debt-gate criterion (first 6 lines of the
  // file): when the marker is present, skip the toxic-pattern push-back only — the
  // rest of the net (meta/placeholder/repeat/truncation) still runs.
  if (!/deslop\s*:\s*skip/i.test(text.split(/\r?\n/).slice(0, 6).join("\n"))) {
    findings.push(...toxicPhraseFindings(text))
  }
  return findings
}

function isProsePath(absolute) {
  const base = path.basename(absolute)
  const parent = path.basename(path.dirname(absolute))
  if (base === "prose.md") return fs.existsSync(path.join(path.dirname(absolute), "setting.md"))
  if (parent !== "prose" || !/^chapter.*\.md$/i.test(base)) return false
  const book = path.dirname(path.dirname(absolute))
  // outline/tracking/setting must be directories; setting.md a file — matches the bash
  // oracle check-prose-after-write.sh (`[ -d outline ] || … || [ -f setting.md ]`).
  return ["outline", "tracking", "setting"].some((name) => existingDir(path.join(book, name))) || fs.existsSync(path.join(book, "setting.md"))
}

function wordcountFinding(absolute, text) {
  if (path.basename(path.dirname(absolute)) !== "prose") return null
  const match = path.basename(absolute).match(/^chapter[_ ]?0*(\d+)/i)
  if (!match) return null
  const chapter = match[1]
  const outlineDir = path.join(path.dirname(path.dirname(absolute)), "outline")
  let target = null
  try {
    for (const file of fs.readdirSync(outlineDir)) {
      const fileMatch = file.match(/^outline_chapter_0*(\d+).*\.md$/i)
      if (!fileMatch || fileMatch[1] !== chapter) continue
      const content = fs.readFileSync(path.join(outlineDir, file), "utf8")
      const targetMatch = content.match(/[Tt]arget words?:?\s*(\d{3,6})/)
      if (targetMatch) target = Number(targetMatch[1])
      break
    }
  } catch {}
  if (!target) return null
  const actual = wordCount(text)
  return actual < target * 0.9
    ? `Word count: chapter ${chapter} is ${actual} words < 90% of the target ${target} (${Math.floor(target * 0.9)}). Locate the thin dense/light spots against the outline budget and rewrite once to quota — don't squeeze in piecemeal fixes.`
    : null
}

function duplicateTitleFindings(absolute) {
  const bodyDir = path.dirname(absolute)
  if (path.basename(bodyDir) !== "prose") return []
  const titles = new Map()
  try {
    for (const file of fs.readdirSync(bodyDir)) {
      const match = file.replace(/\.md$/, "").match(/^chapter[_ ]?0*\d+[_\- ]+(.+)$/i)
      if (!match) continue
      const title = match[1].trim()
      if (title) titles.set(title, [...(titles.get(title) || []), file])
    }
  } catch {}
  const findings = []
  for (const [title, files] of titles.entries()) {
    if (files.length > 1) findings.push(`${files.length} chapters share the title "${title}" (${files.join(", ").slice(0, 60)}); consider renaming.`)
  }
  return findings
}

function proseAfterWrite(root, absolute) {
  if (!fs.existsSync(absolute) || !isProsePath(absolute)) return ""
  const findings = []
  try {
    const bytes = fs.statSync(absolute).size
    if (bytes < 200) findings.push(`[LANDED] prose is only ${bytes} bytes — possibly unfinished or failed to write (quota/timeout?), verify and finish it.`)
    const text = fs.readFileSync(absolute, "utf8")
    findings.push(...proseNetFindings(text))
    const wordcount = wordcountFinding(absolute, text)
    if (wordcount) findings.push(wordcount)
  } catch {
    return ""
  }
  findings.push(...duplicateTitleFindings(absolute))
  if (!findings.length) return ""
  return `=== Prose backstop check (${safeRelative(root, absolute)}) ===\nLightweight deterministic net auto-rescan (model-independent; catches final cleanup the main session might miss). Handle by type, then rescan to clean:\n${findings.join("\n")}`
}

// Linear hand-rolled word splitter; no ambiguous-alternation regex (the old
// /"(?:\\.|[^"])*"|'[^']*'|[^\s]+/ let both \\. and [^"] eat backslashes, and the
// caller splitting on [;&|\n] could leave an unclosed quote where every backslash
// doubled the search space — a 130-char command burned 27s CPU). Char-by-char scan:
// quoted spans copied verbatim (paired quotes stripped, unclosed runs to segment
// end), ASCII whitespace (space/Tab/CR/LF) splits — U+3000 is not a shell word
// splitter, so it does not split. No \ unescaping: resolveTarget treats \ as a path
// separator (Windows paths).
function shellWords(segment) {
  const words = []
  let current = ""
  let started = false
  let quote = ""
  for (const ch of String(segment)) {
    if (quote) {
      if (ch === quote) quote = ""
      else current += ch
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      started = true
      continue
    }
    if (ch === " " || ch === "\t" || ch === "\r" || ch === "\n") {
      if (started) words.push(current)
      current = ""
      started = false
      continue
    }
    started = true
    current += ch
  }
  if (started) words.push(current)
  return words
}

function shellSegments(command) {
  const segments = []
  let current = ""
  let quote = ""
  for (const ch of String(command)) {
    if (quote) {
      current += ch
      if (ch === quote) quote = ""
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      current += ch
      continue
    }
    if (ch === ";" || ch === "&" || ch === "|" || ch === "\n") {
      if (current) segments.push(current)
      current = ""
      continue
    }
    current += ch
  }
  if (current) segments.push(current)
  return segments
}

function beforeShellRedirection(segment) {
  let current = ""
  let quote = ""
  for (const ch of String(segment)) {
    if (quote) {
      current += ch
      if (ch === quote) quote = ""
      continue
    }
    if (ch === '"' || ch === "'") {
      quote = ch
      current += ch
      continue
    }
    if (ch === "<" || ch === ">") {
      return current.replace(/\d+$/, "")
    }
    current += ch
  }
  return current
}

function isGitCommitCommand(command) {
  const valueOptions = new Set(["-C", "-c", "--git-dir", "--work-tree", "--namespace", "--exec-path", "--super-prefix", "--config-env"])
  // Flatten subshell/brace grouping to spaces so `(git commit)` / `{ git commit; }` still
  // expose the git verb; split on separators; skip leading shell wrappers and control
  // words (then/do/else/elif) so a commit inside if/for/while is detected. Mirrors the
  // Claude bash oracle validate-story-commit.sh and the codex is_git_commit_command.
  for (const rawSegment of String(command).replace(/\r/g, "").replace(/[(){}]/g, " ").split(/[;&|\n]+/)) {
    const words = shellWords(rawSegment)
    let i = 0
    while (i < words.length && (/^[A-Za-z_][A-Za-z0-9_]*=/.test(words[i]) || ["command", "noglob", "then", "do", "else", "elif"].includes(words[i]))) i++
    if (words[i] === "env") {
      i++
      while (i < words.length && (/^[A-Za-z_][A-Za-z0-9_]*=/.test(words[i]) || ["-i", "--ignore-environment"].includes(words[i]))) i++
    }
    if (words[i] !== "git") continue
    i++
    while (i < words.length) {
      const token = words[i]
      if (token === "commit") return true
      if (valueOptions.has(token)) { i += 2; continue }
      if ([...valueOptions].some((option) => option.startsWith("--") && token.startsWith(`${option}=`))) { i++; continue }
      if (token.startsWith("-")) { i++; continue }
      break
    }
  }
  return false
}

// Project-level setting files directly under setting/: artifact-protocols.md defines
// relationships.md (body is "# Character Relationship Map"), genre-positioning.md,
// style.md, and genre-prose-card.md — these have no name field by design.
const SETTING_NON_CHARACTER_FILES = new Set(["relationships.md", "genre-positioning.md", "genre-prose-card.md", "style.md", "world-rules.md", "worldview.md", "cheat.md", "background.md"])

// Only character sheets are checked: scanning the whole setting/ tree would flood
// every commit touching setting/ with false warnings and bury real "hardcoded
// character attributes in prose" warnings. Matches the case branches in
// validate-story-commit.sh / opencode pre-commit.sh (bash↔js↔py four-end parity,
// don't unilaterally revert to one-shot):
// ① files inside a setting/characters|people subdirectory → character sheet;
// ② anything else under a setting/<subdir>/ → whole directory skipped
//    (worldview/factions/reports/principles/relationships etc.);
// ③ flat files directly under setting/ → character sheets except the known
//    project-level files (protagonist.md/side-character.md/villain.md etc.).
function isCharacterSheetPath(relative) {
  const segments = relative.split("/")
  const last = segments.length - 1
  // Branch ①: some "setting" segment is followed by characters/people with a file under it
  for (let i = 0; i + 1 < last; i++) {
    if (segments[i] === "setting" && (segments[i + 1] === "characters" || segments[i + 1] === "people")) return true
  }
  // Branch ②: some "setting" segment has >=2 segments after it, i.e. a non-character subdir
  for (let i = 0; i + 1 < last; i++) {
    if (segments[i] === "setting") return false
  }
  // Branch ③: flat files directly under setting/ (branch ② already excluded deeper paths,
  // so the setting segment can only be the second-to-last)
  return last >= 1 && segments[last - 1] === "setting" && !SETTING_NON_CHARACTER_FILES.has(segments[last])
}

function stagedMarkdownWarnings(root) {
  let output
  try {
    output = spawnSync("git", ["-C", root, "-c", "core.quotepath=false", "diff", "--cached", "--relative", "--name-only", "--diff-filter=ACM", "-z", "--", "."], {
      encoding: "buffer",
      stdio: ["ignore", "pipe", "ignore"],
    })
    if (output.status !== 0 || !output.stdout) return ""
  } catch {
    return ""
  }
  const warnings = []
  for (const relative of output.stdout.toString("utf8").split("\0").filter(Boolean)) {
    if (!relative.endsWith(".md")) continue
    const full = path.join(root, relative)
    let text = ""
    try { text = fs.readFileSync(full, "utf8") } catch { continue }
    if (relative === "prose.md" || relative.includes("/prose.md") || relative.startsWith("prose/") || relative.includes("/prose/")) {
      const hits = []
      text.split(/\r?\n/).forEach((line, index) => {
        if (/\b(height|weight|age)\b[\s]*(:)[\s]*[0-9]+/i.test(line)) hits.push(`${index + 1}:${line}`)
      })
      if (hits.length) warnings.push(`⚠ ${relative}: prose hardcodes character attributes; reference the setting file instead:\n${hits.join("\n")}`)
    }
    if (isCharacterSheetPath(relative) && !/^[\s]*(name)[\s]*(:)/im.test(text)) {
      warnings.push(`⚠ ${relative}: setting file is missing the required name field.`)
    }
  }
  return warnings.length ? `=== Story Commit Warnings (advisory only) ===\n${warnings.join("\n")}\n=== End Warnings ===` : ""
}

module.exports = {
  existingDir,
  safeRelative,
  resolveTarget,
  firstLine,
  findFirst,
  discoverActiveBook,
  discoverAllBooks,
  continuityFindings,
  extractProseTargets,
  extractPatchTargets,
  proseBlockReason,
  isProsePath,
  wordcountFinding,
  duplicateTitleFindings,
  proseAfterWrite,
  shellWords,
  isGitCommitCommand,
  stagedMarkdownWarnings,
  TERMINAL,
  QUOTE_OPENERS,
  SOFT_PATTERNS,
  HARD_PATTERNS,
  skippableLine,
  proseNetFindings,
  maskQuotedSpans,
  toxicPhraseFindings,
}
