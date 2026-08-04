import type { Plugin } from "@opencode-ai/plugin"
import * as fs from "node:fs"
import * as path from "node:path"
import { execSync } from "node:child_process"
import {
  discoverActiveBook,
  resolveTarget,
  extractProseTargets,
  extractPatchTargets,
  proseBlockReason,
  proseAfterWrite,
} from "./lib/story_hook_core.js"

// The prose-write guard logic (de-AI lightweight deterministic net, outline/chapter
// outline guard, word count / landing / title dedup, prose target extraction) shares
// the same story_hook_core.js with the ZCode hook, deployed with this plugin to
// .opencode/plugins/lib/story_hook_core.js (in lib/ rather than flat: OpenCode scans
// .opencode/plugins/*.js one level deep for plugins, and a flat copy would be mistaken
// for a second plugin and fail loading; lib/ is out of the scan range). Only the
// OpenCode-host-specific parts stay here: project-root resolution, the event model
// (experimental.session.compacting / tool.execute.*), and the output envelope that
// appends findings to write-tool results. The bash hook is the shared core's oracle;
// parity is guarded by test-prose-net-parity.sh.

function projectRoot(): string {
  try {
    return execSync("git rev-parse --show-toplevel", {
      cwd: process.cwd(),
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim()
  } catch {
    return process.cwd()
  }
}

function targetBase(root: string, args?: Record<string, unknown>): string {
  const raw = args?.workdir || args?.cwd
  if (typeof raw !== "string" || !raw.trim()) return root
  let candidate = path.resolve(root, raw)
  let canonicalRoot = path.resolve(root)
  try {
    if (!fs.statSync(candidate).isDirectory()) return root
    candidate = fs.realpathSync(candidate)
    canonicalRoot = fs.realpathSync(root)
  } catch {
    return root
  }
  const relative = path.relative(canonicalRoot, candidate)
  return relative && (relative === ".." || relative.startsWith(`..${path.sep}`))
    ? root
    : candidate
}

function tryGit(root: string, args: string): string {
  try {
    return execSync(`git ${args}`, {
      cwd: root,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    }).trim()
  } catch {
    return ""
  }
}

// The OpenCode Plugin API offers a chat.message hook (see the @opencode-ai/plugin
// type definitions) that could inject session-start checks and gap detection. This
// version deploys only experimental.session.compacting and tool.execute.* in
// partial form; later versions can extend.

function preCompactOutput(): string {
  const root = projectRoot()
  const lines = ["=== Pre-Compact Summary ==="]
  const bookDir = discoverActiveBook(root)
  if (bookDir) {
    const ctxPath = path.join(bookDir, "tracking", "context.md")
    if (fs.existsSync(ctxPath)) {
      const lineCount = fs.readFileSync(ctxPath, "utf-8").split("\n").length
      const relPath = path.relative(root, ctxPath)
      lines.push(`Writing context: ${relPath} (${lineCount} lines)`)
    } else {
      lines.push("Active state: not found")
    }
  } else {
    lines.push("Active state: not found")
  }

  const changed = tryGit(root, "diff --name-only")
  const staged = tryGit(root, "diff --name-only --cached")
  const changedCount = changed ? changed.split("\n").filter(Boolean).length : 0
  const stagedCount = staged ? staged.split("\n").filter(Boolean).length : 0
  lines.push(`Git: ${changedCount} unstaged, ${stagedCount} staged`)

  lines.push("=== Pre-Compact Complete ===")
  return lines.join("\n")
}

export default (async () => {
  return {
    "experimental.session.compacting": async (
      _input: unknown,
      output: { context: string[]; prompt?: string }
    ) => {
      const preMsg = preCompactOutput()
      if (preMsg) {
        output.context = [...output.context, preMsg]
      }
      // No post-compact injection: OpenCode has no post-compact hook
    },

    "tool.execute.before": async (
      input: { tool: string; args?: Record<string, unknown> },
      output: { args?: Record<string, unknown> }
    ) => {
      const targets: string[] = []

      if (input.tool === "write" || input.tool === "edit") {
        const filePath = (output.args?.filePath as string) || ""
        if (filePath) targets.push(filePath)
      } else if (input.tool === "apply_patch") {
        // apply_patch is OpenCode's edit-class tool (upstream permission is in the
        // same group as write/edit), and gpt-5-family models only expose it, hiding
        // write/edit — skipping this branch would disable the guard entirely.
        // Target extraction (*** Add/Update File: and the *** Move to: destination)
        // reuses the shared core, the same judgment as the ZCode/Codex adapters;
        // Move must resolve to the destination, otherwise a move-style patch could
        // carry an outline-less draft into prose/.
        const patchText = (output.args?.patchText as string) || ""
        for (const t of extractPatchTargets(patchText)) targets.push(t)
      } else if (input.tool === "bash") {
        const cmd = (output.args?.command as string) || ""
        for (const t of extractProseTargets(cmd)) targets.push(t)
      } else {
        return
      }

      // Non-write tools (read/grep/glob/list/…) already returned above: projectRoot()
      // is a synchronous execSync, and this plugin lives in the OpenCode service
      // process — fork git only when there is a target to check.
      if (targets.length === 0) return

      const root = projectRoot()
      const base = targetBase(root, output.args || input.args)
      for (const target of [...new Set(targets)]) {
        const reason = proseBlockReason(root, resolveTarget(root, target, base))
        if (reason) {
          throw new Error(`${reason} (This operation cannot be bypassed through Bash/command line.)`)
        }
      }
    },

    // Prose landing backstop: after writing prose, run the lightweight deterministic
    // net (truncation/refusal/engineering words/repeat + landing/word count/title
    // dedup) and append findings to the write tool's returned output for the model
    // to read. Non-prose files and clean results never touch the output (silent
    // pass). OpenCode has no PostToolUse; tool.execute.after is the only post-write
    // hook that can speak back to the model.
    "tool.execute.after": async (
      input: { tool: string; args?: Record<string, unknown> },
      output: { output?: string }
    ) => {
      const targets: string[] = []
      if (input.tool === "write" || input.tool === "edit") {
        const filePath = (input.args?.filePath as string) || ""
        if (filePath) targets.push(filePath)
      } else if (input.tool === "apply_patch") {
        // Same target extraction as before (including the *** Move to: destination —
        // a chapter moved into prose/ must scan the destination, the source no
        // longer exists): gpt-5-family models only have apply_patch, so skipping
        // this would leave no landing backstop at all.
        const patchText = (input.args?.patchText as string) || ""
        for (const t of extractPatchTargets(patchText)) targets.push(t)
      } else {
        return
      }
      if (targets.length === 0) return
      const root = projectRoot()
      const base = targetBase(root, input.args)
      try {
        const notes: string[] = []
        for (const target of [...new Set(targets)]) {
          const note = proseAfterWrite(root, resolveTarget(root, target, base))
          if (note) notes.push(note)
        }
        if (notes.length && typeof output.output === "string") {
          output.output += `\n\n${notes.join("\n\n")}`
        }
      } catch {
        // A backstop must not bite the flow: parse failures always pass
      }
    },
  }
}) satisfies Plugin
