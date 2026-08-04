#!/usr/bin/env node
"use strict";

// test-scan-runtime.js — regression tests for the shared CDP scraper utility
// (skills/story-long-scan/scripts/cdp-utils.js and its byte-identical copy in
// story-short-scan). The old Chinese rank scrapers (qidian/fanqie/jjwxc/qimao/
// ciweimao) were deleted in the English edition; cdp-utils.js remains the shared
// dependency for the browser-automation scan flow. Its pure functions
// (buildAgentBrowserInvocation / getArg / localDateStamp / safeStr / runCli) are
// tested here; the browser-invoking functions (ab/evalJSON/scrollLoad) are
// deliberately not run — they need a real agent-browser + CDP Chrome.

const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const longUtilsPath = path.join(
  repoRoot,
  "skills/story-long-scan/scripts/cdp-utils.js"
);
const shortUtilsPath = path.join(
  repoRoot,
  "skills/story-short-scan/scripts/cdp-utils.js"
);

const utils = require(longUtilsPath);

// The two copies must stay behaviorally identical (story-short-scan reuses the
// shared utility; the copies may carry cosmetic comment differences, but every
// exported function must agree on the same inputs).
const shortUtils = require(shortUtilsPath);
assert.deepStrictEqual(
  Object.keys(shortUtils).sort(),
  Object.keys(utils).sort(),
  "cdp-utils.js export surface drifted between story-long-scan and story-short-scan"
);
assert.deepStrictEqual(
  shortUtils.buildAgentBrowserInvocation(9222, ["eval", "-b", "aGk="], "linux"),
  utils.buildAgentBrowserInvocation(9222, ["eval", "-b", "aGk="], "linux")
);
assert.strictEqual(
  shortUtils.getArg(["--port", "9222"], "--port"),
  utils.getArg(["--port", "9222"], "--port")
);
assert.strictEqual(
  shortUtils.localDateStamp(new Date(2026, 7, 4)),
  utils.localDateStamp(new Date(2026, 7, 4))
);
for (const name of [
  "ab",
  "sleep",
  "evalJSON",
  "evalJSONBase64",
  "buildAgentBrowserInvocation",
  "safeStr",
  "scrollLoad",
  "getArg",
  "localDateStamp",
  "runCli",
]) {
  assert.strictEqual(typeof utils[name], "function", `missing cdp-utils export: ${name}`);
}

// --- buildAgentBrowserInvocation -------------------------------------------------
// POSIX runs the native binary directly with a verbatim argv array.
const posix = utils.buildAgentBrowserInvocation(9222, ["eval", "-b", "aGk="], "linux");
assert.deepStrictEqual(posix, {
  file: "agent-browser",
  args: ["--cdp", "9222", "eval", "-b", "aGk="],
});

// Windows resolves the npm .cmd shim to its real target so the argv array is
// passed verbatim (never re-tokenized by cmd.exe / PowerShell, CVE-2024-27980
// class). No .cmd on PATH -> bare-name fallback.
const noShim = utils.buildAgentBrowserInvocation(9222, ["x"], "win32");
assert.strictEqual(noShim.file, "agent-browser");
assert.deepStrictEqual(noShim.args, ["--cdp", "9222", "x"]);

// With a .cmd shim on PATH whose forwarding line names a Node wrapper, the
// invocation resolves to process.execPath + the wrapper path + argv verbatim.
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "scan-runtime-"));
try {
  const wrapper = path.join(tmpDir, "fake-agent-browser.js");
  fs.writeFileSync(wrapper, "console.log('fake');", "utf8");
  fs.writeFileSync(
    path.join(tmpDir, "agent-browser.cmd"),
    `@echo off\r\n"${process.execPath}" "%~dp0fake-agent-browser.js" %*\r\n`,
    "utf8"
  );
  const savedPath = process.env.PATH;
  process.env.PATH = tmpDir;
  try {
    const win = utils.buildAgentBrowserInvocation(8080, ["eval", "1+1"], "win32");
    assert.strictEqual(win.file, process.execPath);
    assert.deepStrictEqual(win.args, [
      path.join(tmpDir, "fake-agent-browser.js"),
      "--cdp",
      "8080",
      "eval",
      "1+1",
    ]);
  } finally {
    process.env.PATH = savedPath;
  }
} finally {
  fs.rmSync(tmpDir, { recursive: true, force: true });
}

// --- getArg ----------------------------------------------------------------------
assert.strictEqual(utils.getArg(["--port", "9222"], "--port"), "9222");
assert.strictEqual(utils.getArg(["--port=9222"], "--port"), "9222");
assert.strictEqual(utils.getArg(["--outdir", "a b"], "--outdir"), "a b");
assert.strictEqual(utils.getArg(["--port"], "--port"), null); // value-less flag at end
assert.strictEqual(utils.getArg(["x", "y"], "--port"), null); // absent
assert.strictEqual(utils.getArg([], "--port"), null);

// --- safeStr ---------------------------------------------------------------------
assert.strictEqual(utils.safeStr("it's \"fine\""), JSON.stringify("it's \"fine\""));
assert.strictEqual(utils.safeStr(42), JSON.stringify("42")); // coerced to string

// --- localDateStamp ---------------------------------------------------------------
// Always the LOCAL calendar day, never the UTC date (a scrape between local
// midnight and UTC midnight must not fall back to "yesterday"'s filename).
const summerLocal = new Date(2026, 7, 4, 23, 30); // Aug 4 23:30 local
assert.strictEqual(utils.localDateStamp(summerLocal), "20260804");
const earlyLocal = new Date(2026, 7, 4, 0, 30); // Aug 4 00:30 local (UTC is still Aug 3)
assert.strictEqual(utils.localDateStamp(earlyLocal), "20260804");
assert.strictEqual(utils.localDateStamp(new Date(2026, 0, 9)), "20260109"); // zero-padding

// --- runCli ------------------------------------------------------------------------
// Turns legacy integer / object return values into a machine-readable CLI
// status: success keeps exitCode 0, partial output exits 2 with details,
// failures and empty output exit 1 with the reason on stderr.
function captureRunCli(main, label) {
  const stderrChunks = [];
  const original = console.error;
  console.error = (msg) => stderrChunks.push(String(msg));
  const originalExitCode = process.exitCode;
  process.exitCode = 0;
  try {
    utils.runCli(main, label);
    return new Promise((resolve) => {
      // runCli settles on the microtask queue; one tick is enough for its .then
      // chain plus the console.error calls.
      setTimeout(() => {
        const exitCode = process.exitCode;
        console.error = original;
        process.exitCode = originalExitCode;
        resolve({ exitCode, stderr: stderrChunks.join("\n") });
      }, 5);
    });
  } catch (error) {
    console.error = original;
    process.exitCode = originalExitCode;
    throw error;
  }
}

(async () => {
  // integer success (legacy entrypoint shape)
  let r = await captureRunCli(async () => 3, "t-int");
  assert.strictEqual(r.exitCode, 0, r.stderr);

  // object success
  r = await captureRunCli(
    async () => ({ planned: 5, written: 5, failed: 0, partial: false, partialReasons: [] }),
    "t-ok"
  );
  assert.strictEqual(r.exitCode, 0, r.stderr);

  // partial output -> exit 2 with a "wrote X/Y; failed N; reasons" summary
  r = await captureRunCli(
    async () => ({ planned: 5, written: 3, failed: 2, partial: true, partialReasons: ["timeout"] }),
    "t-partial"
  );
  assert.strictEqual(r.exitCode, 2, r.stderr);
  assert(r.stderr.includes("partial: wrote 3/5; failed 2; timeout"), r.stderr);

  // empty output -> exit 1
  r = await captureRunCli(async () => ({ planned: 0, written: 0, failed: 0, partial: false, partialReasons: [] }), "t-empty");
  assert.strictEqual(r.exitCode, 1, r.stderr);
  assert(r.stderr.includes("no output was written"), r.stderr);

  // thrown error -> exit 1 with the message
  r = await captureRunCli(async () => { throw new Error("boom"); }, "t-err");
  assert.strictEqual(r.exitCode, 1, r.stderr);
  assert(r.stderr.includes("t-err failed: boom"), r.stderr);

  console.log("OK: cdp-utils shared runtime (module parity, invocation builder, args, date stamp, CLI status)");
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
