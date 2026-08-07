#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const srcDir = path.join(repoRoot, "skills/story-setup/references/opencode");
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "story-opencode-plugin-"));
const originalCwd = process.cwd();

// plugin.ts imports "./lib/story_hook_core.js" (the prose-guard core shared with the
// ZCode hook, deployed to .opencode/plugins/lib/). In the repo source the core sits
// flat; only the deployment layout has the lib/ subdirectory — replicate that layout
// in tmp so the import resolves.
const deployDir = path.join(tmp, "plugins");
fs.mkdirSync(path.join(deployDir, "lib"), { recursive: true });
fs.copyFileSync(path.join(srcDir, "plugin.ts"), path.join(deployDir, "plugin.ts"));
fs.copyFileSync(
  path.join(srcDir, "story_hook_core.js"),
  path.join(deployDir, "lib", "story_hook_core.js")
);
const pluginPath = path.join(deployDir, "plugin.ts");

async function expectBlocked(action, label) {
  await assert.rejects(action, /Prose blocked/, label);
}

try {
  execFileSync("git", ["init", "-q", tmp]);
  process.chdir(tmp);
  const imported = await import(`${pathToFileURL(pluginPath).href}?test=${Date.now()}`);
  const hooks = await imported.default({});
  assert.equal(typeof hooks["tool.execute.before"], "function");
  assert.equal(typeof hooks["tool.execute.after"], "function");
  assert.equal(typeof hooks["experimental.session.compacting"], "function");

  fs.mkdirSync("book/prose", { recursive: true });
  fs.mkdirSync("book/outline", { recursive: true });
  fs.mkdirSync("book/tracking", { recursive: true });
  fs.writeFileSync("book/tracking/context.md", "# Context\nCurrent position\n", "utf8");
  fs.writeFileSync(".active-book", "book\n", "utf8");

  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "write" },
        { args: { filePath: "book/prose/chapter_001_opening.md" } }
      ),
    "new long prose without an outline"
  );

  fs.writeFileSync("book/outline/outline_chapter_001.md", "# Outline\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "write" },
    { args: { filePath: "book/prose/chapter_001_opening.md" } }
  );

  fs.mkdirSync("bare/prose", { recursive: true });
  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "write" },
        { args: { filePath: "bare/prose/chapter_001_first.md" } }
      ),
    "bare long project without scaffolding must fail closed"
  );

  fs.mkdirSync("cwd-book/prose", { recursive: true });
  fs.mkdirSync("cwd-book/outline", { recursive: true });
  await assert.rejects(
    () =>
      hooks["tool.execute.before"](
        { tool: "bash" },
        {
          args: {
            command: "cat draft.md > prose/chapter_008_relative.md",
            workdir: path.join(tmp, "cwd-book"),
          },
        }
      ),
    /cwd-book\/outline/,
    "relative Bash target must resolve from the tool workdir"
  );
  fs.writeFileSync("cwd-book/outline/outline_chapter_008.md", "# Outline\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "bash" },
    {
      args: {
        command: "cat draft.md > prose/chapter_008_relative.md",
        workdir: path.join(tmp, "cwd-book"),
      },
    }
  );

  fs.writeFileSync("book/prose/chapter_002_continuation.md", "Existing prose.\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "edit" },
    { args: { filePath: "book/prose/chapter_002_continuation.md" } }
  );

  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "bash" },
        { args: { command: "cat draft.md > book/prose/chapter_003_bypass.md" } }
      ),
    "bash redirect must not bypass the outline guard"
  );
  await hooks["tool.execute.before"](
    { tool: "bash" },
    { args: { command: "grep 'book/prose/chapter_003_bypass.md' notes.md" } }
  );

  // apply_patch is OpenCode's edit-class tool, and gpt-5-family models only expose
  // it, hiding write/edit: the guard and the landing backstop must both recognize
  // it, otherwise those models get no outline guard and no prose backstop at all.
  const addPatch = (target) =>
    `*** Begin Patch\n*** Add File: ${target}\n+First prose line.\n*** End Patch\n`;
  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "apply_patch" },
        { args: { patchText: addPatch("book/prose/chapter_004_patch.md") } }
      ),
    "apply_patch must not bypass the outline guard"
  );
  fs.writeFileSync("book/outline/outline_chapter_004.md", "# Outline\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "apply_patch" },
    { args: { patchText: addPatch("book/prose/chapter_004_patch.md") } }
  );

  // *** Move to: is the move/rename form of apply_patch (a sub-instruction of the
  // Update/Delete File segments); the on-disk target is the destination. If only
  // Add/Update File were recognized, "Update draft.md + Move to book/prose/chapter_N.md"
  // would extract just draft.md: the outline gate would pass empty and the after-write
  // net would scan a source that no longer exists — an outline-less draft moved into a
  // new chapter with no guard at all.
  const movePatch = (source, destination, verb = "Update") =>
    `*** Begin Patch\n*** ${verb} File: ${source}\n*** Move to: ${destination}\n+First prose line.\n*** End Patch\n`;
  fs.writeFileSync("draft.md", "A draft line.\n", "utf8");
  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "apply_patch" },
        { args: { patchText: movePatch("draft.md", "book/prose/chapter_009_moved.md") } }
      ),
    "apply_patch *** Move to: must not bypass the outline guard"
  );
  // The judgment must land on the destination chapter (chapter 9), not on the
  // source draft.md (the source is not prose and should never be judged).
  await assert.rejects(
    () =>
      hooks["tool.execute.before"](
        { tool: "apply_patch" },
        { args: { patchText: movePatch("draft.md", "book/prose/chapter_009_moved.md") } }
      ),
    /chapter 9 has no chapter outline/,
    "Move must be judged on the destination chapter number"
  );
  // Delete File + Move to (deleting the source after the move) is also a move: the
  // destination must enter the table as well.
  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "apply_patch" },
        { args: { patchText: movePatch("draft.md", "book/prose/chapter_010_moved.md", "Delete") } }
      ),
    "*** Delete File: + *** Move to: must gate the destination too"
  );
  // Add the outline and it passes: the gate is one that a chapter outline can
  // clear, not a blanket block on Move.
  fs.writeFileSync("book/outline/outline_chapter_009.md", "# Outline\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "apply_patch" },
    { args: { patchText: movePatch("draft.md", "book/prose/chapter_009_moved.md") } }
  );
  // Reverse direction: moving prose OUT of prose/ (destination is not prose) must
  // not be blocked — the source is no longer a write target.
  await hooks["tool.execute.before"](
    { tool: "apply_patch" },
    { args: { patchText: movePatch("book/prose/chapter_002_continuation.md", "draft_out.md") } }
  );
  // Pure Delete never enters the table (a documented trade-off of the shared core):
  // deleting a chapter number that does not exist and has no outline must not be
  // misreported as a prose write.
  await hooks["tool.execute.before"](
    { tool: "apply_patch" },
    {
      args: {
        patchText: "*** Begin Patch\n*** Delete File: book/prose/chapter_011_deleted.md\n*** End Patch\n",
      },
    }
  );

  fs.mkdirSync("short", { recursive: true });
  fs.writeFileSync("short/setting.md", "# Setting\n", "utf8");
  await expectBlocked(
    () =>
      hooks["tool.execute.before"](
        { tool: "write" },
        { args: { filePath: "short/prose.md" } }
      ),
    "new short prose without section outline"
  );
  fs.writeFileSync("short/section-outline.md", "# Section outline\n", "utf8");
  await hooks["tool.execute.before"](
    { tool: "write" },
    { args: { filePath: "short/prose.md" } }
  );

  fs.writeFileSync(
    "book/prose/chapter_001_opening.md",
    `${"The streetlamps blinked on one by one.".repeat(30)}\nTODO finish this scene`,
    "utf8"
  );
  const afterOutput = { output: "write complete" };
  await hooks["tool.execute.after"](
    { tool: "write", args: { filePath: "book/prose/chapter_001_opening.md" } },
    afterOutput
  );
  assert.match(afterOutput.output, /Prose backstop check/);
  assert.match(afterOutput.output, /placeholder/);

  const nonProseOutput = { output: "unchanged" };
  fs.writeFileSync("notes.md", "TODO\n", "utf8");
  await hooks["tool.execute.after"](
    { tool: "write", args: { filePath: "notes.md" } },
    nonProseOutput
  );
  assert.equal(nonProseOutput.output, "unchanged");

  fs.writeFileSync(
    "book/prose/chapter_004_patch.md",
    `${"The streetlamps blinked on one by one.".repeat(30)}\nTODO finish this scene`,
    "utf8"
  );
  const patchAfterOutput = { output: "patch applied" };
  await hooks["tool.execute.after"](
    { tool: "apply_patch", args: { patchText: addPatch("book/prose/chapter_004_patch.md") } },
    patchAfterOutput
  );
  assert.match(patchAfterOutput.output, /Prose backstop check/);
  assert.match(patchAfterOutput.output, /placeholder/);

  const nonProsePatchOutput = { output: "unchanged" };
  await hooks["tool.execute.after"](
    { tool: "apply_patch", args: { patchText: addPatch("notes.md") } },
    nonProsePatchOutput
  );
  assert.equal(nonProsePatchOutput.output, "unchanged");

  // After-write backstop for a move-style patch: it must scan the **destination**
  // chapter. If only Add/Update File were recognized here, this would extract
  // draft.md and the net would pass empty — a chapter moved into prose/ carrying a
  // TODO would get no response at all.
  fs.writeFileSync(
    "book/prose/chapter_009_moved.md",
    `${"The streetlamps blinked on one by one.".repeat(30)}\nTODO finish this scene`,
    "utf8"
  );
  const moveAfterOutput = { output: "patch applied" };
  await hooks["tool.execute.after"](
    {
      tool: "apply_patch",
      args: { patchText: movePatch("draft.md", "book/prose/chapter_009_moved.md") },
    },
    moveAfterOutput
  );
  assert.match(moveAfterOutput.output, /Prose backstop check \(book\/prose\/chapter_009_moved\.md\)/);
  assert.match(moveAfterOutput.output, /placeholder/);

  // Reverse direction: a patch moving prose out of prose/ must not scan the source
  // (it no longer exists; the destination is not prose) — the output returns as is.
  const moveOutAfterOutput = { output: "unchanged" };
  await hooks["tool.execute.after"](
    {
      tool: "apply_patch",
      args: { patchText: movePatch("book/prose/chapter_009_moved.md", "draft_out.md") },
    },
    moveOutAfterOutput
  );
  assert.equal(moveOutAfterOutput.output, "unchanged");

  // Non-write tools must return before dispatch, so read/grep/... never fork a
  // git rev-parse (the plugin lives in the OpenCode service process and this
  // synchronous execSync would block the event loop). Swap a bookkeeping git shim
  // into PATH: after read-class tools the log must stay empty; after a write tool
  // it must have an entry — the latter prevents this assertion from being vacuous.
  if (process.platform !== "win32") {
    const shimDir = path.join(tmp, "bin");
    const gitLog = path.join(tmp, "git-calls.log");
    fs.mkdirSync(shimDir, { recursive: true });
    fs.writeFileSync(
      path.join(shimDir, "git"),
      `#!/bin/sh\nprintf '%s\\n' "$*" >> ${JSON.stringify(gitLog)}\nprintf '%s\\n' ${JSON.stringify(tmp)}\n`,
      { mode: 0o755 }
    );
    const realPath = process.env.PATH;
    process.env.PATH = shimDir;
    try {
      for (const tool of ["read", "grep", "glob", "list", "todowrite", "webfetch"]) {
        await hooks["tool.execute.before"]({ tool, args: {} }, { args: {} });
      }
      assert.equal(
        fs.existsSync(gitLog),
        false,
        "non-write tools must not fork git rev-parse"
      );
      await hooks["tool.execute.before"](
        { tool: "write" },
        { args: { filePath: "book/prose/chapter_002_continuation.md" } }
      );
      assert.match(
        fs.readFileSync(gitLog, "utf8"),
        /rev-parse/,
        "git shim must actually intercept projectRoot()"
      );
    } finally {
      process.env.PATH = realPath;
    }
  }

  const compact = { context: [] };
  await hooks["experimental.session.compacting"]({}, compact);
  assert(compact.context.some((entry) => entry.includes(`Writing context: book${path.sep}tracking${path.sep}context.md`)));

  console.log("OK: OpenCode plugin guards outlines and reports after-write findings behaviorally");
} finally {
  process.chdir(originalCwd);
  fs.rmSync(tmp, { recursive: true, force: true });
}
