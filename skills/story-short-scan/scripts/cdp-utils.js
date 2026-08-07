/**
 * CDP utility functions — shared dependency for scraping scripts across platforms
 *
 * Usage:
 *   const { ab, sleep, evalJSON, evalJSONBase64, scrollLoad, getArg, safeStr, localDateStamp } = require("./cdp-utils");
 *
 * Prerequisites:
 *   node {SKILL_DIR}/browser-cdp/scripts/setup-cdp-chrome.js 9222
 */

const { execFileSync } = require("child_process");
const fs = require("fs");
const path = require("path");

/**
 * On Windows `agent-browser` is an npm shim (agent-browser.cmd/.ps1) that
 * forwards to the real target — the native agent-browser-win32-*.exe or a
 * bundled Node CLI. Node refuses to execFile the `.cmd` without a shell
 * (CVE-2024-27980), and routing the argv array through a shell mangles it: the
 * `.cmd`'s `%*` is re-tokenized by cmd.exe (splitting on spaces, breaking on
 * & | ^), and calling the shim by bare name from powershell.exe collapses the
 * whole array into a single space-joined argument. The exact locus differs by
 * runtime, so instead of hardening any one shell path we bypass shells entirely:
 * read the `.cmd` shim, recover the real program plus its fixed leading args,
 * and execFile that target directly with the argv array — verbatim, no shell.
 */
function resolveWindowsAgentBrowser(argv) {
  const dirs = String(process.env.PATH || "").split(path.delimiter);
  let cmdPath = null;
  for (const dir of dirs) {
    if (!dir) continue;
    const candidate = path.join(dir, "agent-browser.cmd");
    if (fs.existsSync(candidate)) {
      cmdPath = candidate;
      break;
    }
  }
  if (!cmdPath) return { file: "agent-browser", args: argv };
  const dir = path.dirname(cmdPath);
  const forwardLine =
    fs
      .readFileSync(cmdPath, "utf8")
      .split(/\r?\n/)
      .find((line) => line.includes("%*")) || "";
  const tokens = [...forwardLine.matchAll(/"([^"]*)"/g)]
    .map((m) => m[1])
    .map((t) =>
      t
        .replace(/%~dp0/gi, () => dir + path.sep)
        .replace(/%dp0%/gi, () => dir + path.sep)
    );
  const jsIndex = tokens.findIndex((t) => /\.[cm]?js$/i.test(t));
  if (jsIndex >= 0) {
    return { file: process.execPath, args: [...tokens.slice(jsIndex), ...argv] };
  }
  if (tokens.length > 0) {
    return { file: tokens[0], args: [...tokens.slice(1), ...argv] };
  }
  return { file: "agent-browser", args: argv };
}

/**
 * Build a shell-free invocation. POSIX runs the native `agent-browser` binary
 * directly; Windows resolves the npm `.cmd` shim to that native target so the
 * argument array is passed verbatim, never routed through cmd.exe/PowerShell.
 */
function buildAgentBrowserInvocation(port, args, platform = process.platform) {
  const argv = ["--cdp", String(port), ...args.map(String)];
  if (platform !== "win32") {
    return { file: "agent-browser", args: argv };
  }
  return resolveWindowsAgentBrowser(argv);
}

// ---------------------------------------------------------------------------
// agent-browser utility functions
// ---------------------------------------------------------------------------

/**
 * Invoke the agent-browser CLI
 * @param {number} port - CDP port
 * @param  {...string} args - agent-browser arguments
 * @returns {string} stdout (trimmed)
 */
function ab(port, ...args) {
  const invocation = buildAgentBrowserInvocation(port, args);
  try {
    return execFileSync(
      invocation.file,
      invocation.args,
      {
        encoding: "utf-8",
        timeout: 20000,
        stdio: ["pipe", "pipe", "pipe"],
        windowsHide: true,
      }
    ).trim();
  } catch (error) {
    const stderr = error && error.stderr ? String(error.stderr).trim() : "";
    const stdout = error && error.stdout ? String(error.stdout).trim() : "";
    const detail = stderr || stdout || (error && error.message) || "unknown error";
    throw new Error(`agent-browser failed: ${detail}`, { cause: error });
  }
}

/** Wait ms milliseconds (cross-platform, independent of the system sleep command) */
function sleep(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function parseJSONResult(raw) {
  if (!raw || raw === "ERR") {
    throw new Error("agent-browser returned no JSON result");
  }
  try {
    let parsed = JSON.parse(raw);
    if (typeof parsed === "string") {
      try { parsed = JSON.parse(parsed); } catch {}
    }
    return parsed;
  } catch (error) {
    throw new Error(`agent-browser returned invalid JSON: ${String(raw).slice(0, 160)}`, {
      cause: error,
    });
  }
}

/**
 * Execute JS inside the browser and parse the JSON return value.
 * Always routes through base64 (-b): scraping JS often contains quotes, backslashes, etc. that
 * cannot be passed verbatim as command-line arguments on Windows (.cmd's %* and PowerShell both
 * re-parse them). base64 keeps the argument to [A-Za-z0-9+/=] only, sharing the same safe channel
 * as evalJSONBase64 already used by the scraping scripts.
 */
function evalJSON(port, js) {
  return evalJSONBase64(port, js);
}

/**
 * Execute complex JS via agent-browser's base64 argument, avoiding command-line escaping
 * and argument boundary issues.
 */
function evalJSONBase64(port, js) {
  const encoded = Buffer.from(String(js), "utf8").toString("base64");
  return parseJSONResult(ab(port, "eval", "-b", encoded));
}

/**
 * Safely insert a value into a browser eval string.
 * Uses JSON.stringify so the value cannot break the eval string with special characters
 * (quotes, backslashes, etc.).
 * @param {*} val - The value to insert
 * @returns {string} JSON string representation (with quotes)
 */
function safeStr(val) {
  return JSON.stringify(String(val));
}

/**
 * Scroll the page to load more content
 * @param {number} port - CDP port
 * @param {number} times - Number of scrolls
 * @param {number} [interval=1000] - Interval between scrolls (ms)
 */
function scrollLoad(port, times, interval = 1000) {
  for (let i = 0; i < times; i++) {
    ab(port, "eval", "window.scrollBy(0, window.innerHeight)");
    sleep(interval);
  }
}

/** Parse --xxx style arguments */
function getArg(args, name) {
  const i = args.indexOf(name);
  if (i >= 0) return i + 1 < args.length ? args[i + 1] : null;
  const prefix = `${name}=`;
  const inline = args.find((arg) => String(arg).startsWith(prefix));
  return inline === undefined ? null : String(inline).slice(prefix.length);
}

/**
 * Date stamp for output filenames (YYYYMMDD), always the **local calendar day**.
 * Do not use new Date().toISOString().slice(0,10): that is the UTC date, 8 hours behind UTC+8.
 * Filenames are the sole dedup key for scraping scripts (one report per ranking per day); a scrape
 * between Beijing time 00:00-08:00 would fall back to "yesterday"'s filename, silently overwriting
 * the same-named report collected the night before, and the data would be labeled as the previous day.
 * @param {Date} [date] - Defaults to the current time
 * @returns {string} YYYYMMDD
 */
function localDateStamp(date) {
  const d = date instanceof Date ? date : new Date();
  const y = String(d.getFullYear()).padStart(4, "0");
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}${m}${day}`;
}

/**
 * Run a scraper entrypoint and turn empty/partial output into machine-readable
 * CLI status. Legacy entrypoints may return an integer; multi-target scrapers
 * return {planned,written,failed,partial,partialReasons}.
 */
function runCli(main, label) {
  Promise.resolve()
    .then(main)
    .then((result) => {
      const outcome = Number.isInteger(result)
        ? { planned: result, written: result, failed: 0, partial: false, partialReasons: [] }
        : result;
      if (!outcome || !Number.isInteger(outcome.written) || outcome.written < 1) {
        throw new Error("no output was written");
      }
      const failed = Number.isInteger(outcome.failed) ? outcome.failed : 0;
      const planned = Number.isInteger(outcome.planned)
        ? outcome.planned
        : outcome.written + failed;
      const reasons = Array.isArray(outcome.partialReasons)
        ? outcome.partialReasons.filter(Boolean).map(String)
        : [];
      if (outcome.partial || failed > 0) {
        const details = [`wrote ${outcome.written}/${planned}`];
        if (failed > 0) details.push(`failed ${failed}`);
        details.push(...reasons);
        console.error(`${label} partial: ${details.join("; ")}`);
        process.exitCode = 2;
      }
    })
    .catch((error) => {
      const message = error && error.message ? error.message : String(error);
      console.error(`${label} failed: ${message}`);
      process.exitCode = 1;
    });
}

module.exports = {
  ab,
  sleep,
  evalJSON,
  evalJSONBase64,
  buildAgentBrowserInvocation,
  safeStr,
  scrollLoad,
  getArg,
  localDateStamp,
  runCli,
};
