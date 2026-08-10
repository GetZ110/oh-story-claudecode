#!/usr/bin/env node
// setup-cdp-chrome.js
// Prepare a Chrome environment with CDP (Chrome DevTools Protocol) debugging enabled (cross-platform).
// Through this script, agent-browser can reuse the user's Chrome login state.
//
// Usage:
//   node setup-cdp-chrome.js [port] [options]
//
// Options:
//   --detect-only            Only probe the current state (structured output), make no changes
//   --yes                    Confirm killing existing Chrome, skip interactive prompts
//   --reset                  Clear ~/chrome-debug-profile then re-copy
//   --profile <name>         Use the specified Chrome profile (default: Default)
//   --dry-run                Print the operations that would be executed without actually running them
//
// Note: When the CDP port is already listening, the default behavior is to reuse the existing Chrome
//       and exit 0; but with --reset or an explicit --profile it does NOT reuse — those two flags mean
//       "rebuild the debug profile" (a stale login state takes this path). The script first closes the
//       existing Chrome (needs --yes when not a TTY, otherwise exit 3 with NEEDS_CONSENT). The rebuild
//       path has two hard gates: after the processes are closed the port must truly stop responding
//       (otherwise the script exits 1 before touching the profile — it will never delete the profile
//       of a still-running Chrome); after launch it must prove that "the endpoint answering on the
//       port is the instance launched this time" — an identity can be obtained and differs from the
//       pre-rebuild one, the spawned process is still alive, all LISTEN holders of the port are inside
//       this process tree, and one holder in the tree actually carries this run's
//       --remote-debugging-port. If any of these cannot be proven (including being un-queryable),
//       success is refused, so someone else's session is never handed over as a new browser.
//
// Exit codes:
//   0  Success / detect-only completed
//   1  Generic error (missing environment, timeout, etc.)
//   2  User declined (answered N in TTY mode)
//   3  Consent needed but currently not a TTY and --yes not passed
//
// detect-only structured output (stdout, one KEY=value per line):
//   CDP_STATUS=ready|needs-setup
//   CDP_URL=...                    (only when ready)
//   BROWSER=...                    (only when ready)
//   CHROME_RUNNING=yes|no
//   CHROME_PID_COUNT=N             (only when CHROME_RUNNING=yes)

"use strict";

const { execSync, spawn } = require("child_process");
const fs = require("fs");
const http = require("http");
const net = require("net");
const os = require("os");
const path = require("path");
const readline = require("readline");

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const flags = { dryRun: false, yes: false, detectOnly: false, reset: false };
  let profile = "Default";
  // Whether --profile was explicitly passed: the default "Default" cannot distinguish
  // "not passed" from "passed Default", and the two cases differ semantically in the
  // "CDP already ready" branch (reuse vs. rebuild with the specified profile)
  let profileExplicit = false;
  let port = null;

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case "--dry-run": flags.dryRun = true; break;
      case "--yes": case "-y": flags.yes = true; break;
      case "--detect-only": flags.detectOnly = true; break;
      case "--reset": flags.reset = true; break;
      case "--profile":
        profile = argv[++i];
        if (!profile) {
          console.error("❌ --profile requires an argument (e.g. --profile \"Profile 1\")");
          process.exit(1);
        }
        profileExplicit = true;
        break;
      default:
        if (/^\d+$/.test(a)) {
          port = parseInt(a, 10);
        } else if (a.startsWith("--")) {
          console.error(`⚠️  Unknown argument: ${a}`);
        } else {
          console.error(`⚠️  Ignoring argument: ${a}`);
        }
    }
  }

  if (port === null) port = 9222;
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    console.error(`❌ Invalid port: ${port}. Must be an integer between 1-65535.`);
    process.exit(1);
  }

  return { flags, profile, profileExplicit, port };
}

const ARGS = parseArgs(process.argv.slice(2));
const CDP_PORT = ARGS.port;
const PLATFORM = os.platform();

// ---------------------------------------------------------------------------
// Platform configuration map
// ---------------------------------------------------------------------------

const PLATFORM_CONFIG = {
  darwin: {
    chromePaths: [
      "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    ],
    profileDir: path.join(
      os.homedir(),
      "Library",
      "Application Support",
      "Google",
      "Chrome"
    ),
    findChrome() {
      for (const p of this.chromePaths) if (fs.existsSync(p)) return p;
      return null;
    },
    listChromePids() {
      try {
        const out = execSync("pgrep -x 'Google Chrome'", { encoding: "utf-8" }).trim();
        return out.split("\n").map(Number).filter((n) => n > 0);
      } catch { return []; }
    },
    killChrome(pids) {
      for (const pid of pids) {
        if (Number.isInteger(pid) && pid > 0) {
          try { execSync(`kill -9 ${pid}`, { stdio: "ignore" }); } catch {}
        }
      }
    },
  },
  win32: {
    chromePaths: [
      path.join(process.env["PROGRAMFILES(X86)"] || "", "Google", "Chrome", "Application", "chrome.exe"),
      path.join(process.env.PROGRAMFILES || "", "Google", "Chrome", "Application", "chrome.exe"),
      path.join(process.env.LOCALAPPDATA || "", "Google", "Chrome", "Application", "chrome.exe"),
    ],
    profileDir: path.join(
      process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local"),
      "Google", "Chrome", "User Data"
    ),
    findChrome() {
      for (const p of this.chromePaths) if (p && fs.existsSync(p)) return p;
      return null;
    },
    listChromePids() {
      try {
        const out = execSync('tasklist /FI "IMAGENAME eq chrome.exe" /NH /FO CSV', { encoding: "utf-8" }).trim();
        return out.split("\n").map((line) => {
          const m = line.match(/"chrome.exe","(\d+)"/i);
          return m ? parseInt(m[1], 10) : 0;
        }).filter((n) => n > 0);
      } catch { return []; }
    },
    killChrome(pids) {
      for (const pid of pids) {
        if (Number.isInteger(pid) && pid > 0) {
          try { execSync(`taskkill /F /PID ${pid}`, { stdio: "ignore" }); } catch {}
        }
      }
    },
  },
  linux: {
    chromePaths: [
      "/usr/bin/google-chrome-stable",
      "/usr/bin/google-chrome",
      "/opt/google/chrome/google-chrome",
    ],
    profileDir: path.join(os.homedir(), ".config", "google-chrome"),
    findChrome() {
      for (const p of this.chromePaths) if (fs.existsSync(p)) return p;
      return null;
    },
    listChromePids() {
      // Cover common Chrome process naming conventions
      const patterns = ["google-chrome-stable", "google-chrome", "chrome"];
      const pids = new Set();
      for (const pat of patterns) {
        try {
          const out = execSync(`pgrep -x ${pat}`, { encoding: "utf-8" }).trim();
          out.split("\n").map(Number).filter((n) => n > 0).forEach((n) => pids.add(n));
        } catch {}
      }
      return [...pids];
    },
    killChrome(pids) {
      for (const pid of pids) {
        if (Number.isInteger(pid) && pid > 0) {
          try { execSync(`kill -9 ${pid}`, { stdio: "ignore" }); } catch {}
        }
      }
    },
  },
};

// ---------------------------------------------------------------------------
// Utility functions
// ---------------------------------------------------------------------------

function log(msg) { console.log(msg); }
function warn(msg) { console.warn("⚠️  " + msg); }
function ok(msg) { console.log("✅ " + msg); }
function err(msg) { console.error("❌ " + msg); }

function getConfig() {
  const config = PLATFORM_CONFIG[PLATFORM];
  if (!config) {
    err(`Unsupported platform: ${PLATFORM}. Supported: darwin/win32/linux.`);
    process.exit(1);
  }
  return config;
}

/** Synchronously wait ms milliseconds (independent of setTimeout / system sleep) */
function sleepSync(ms) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

/**
 * HTTP GET to check the CDP endpoint. Rejects 4xx/5xx; auto-drains the response body.
 * agent:false is required — Node 19+'s http.globalAgent defaults to keepAlive, so sockets used by
 * probes would stay in the connection pool; meanwhile this script blocks the event loop with
 * sleepSync (waiting for process exit / startup), during which the server closes the connection
 * after 5s of idle and the client never gets to handle the FIN. Reusing that dead socket on the
 * next probe yields ECONNRESET, so "port still alive" is misjudged as "nothing responding". That
 * false negative would slip straight past the port gate below, so one fresh connection per try.
 */
function httpGet(url) {
  return new Promise((resolve, reject) => {
    const req = http.get(url, { timeout: 3000, agent: false }, (res) => {
      let body = "";
      res.on("data", (chunk) => (body += chunk));
      res.on("end", () => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}`));
        } else {
          resolve(body);
        }
      });
    });
    req.on("error", reject);
    req.on("timeout", () => {
      req.destroy();
      reject(new Error("timeout"));
    });
  });
}

async function probeCDP(port) {
  try {
    const version = await httpGet(`http://127.0.0.1:${port}/json/version`);
    return version;
  } catch {
    return null;
  }
}

/** Raw TCP probe: HTTP 500/malformed JSON still means the port is occupied; it must not unlock destructive profile operations. */
function probeTcp(port, timeoutMs = 1000) {
  return new Promise((resolve) => {
    const socket = net.createConnection({ host: "127.0.0.1", port });
    let settled = false;
    const done = (listening) => {
      if (settled) return;
      settled = true;
      socket.destroy();
      resolve(listening);
    };
    socket.setTimeout(timeoutMs);
    socket.once("connect", () => done(true));
    socket.once("error", () => done(false));
    socket.once("timeout", () => done(false));
  });
}

/**
 * Extract an identifier from the /json/version response that can distinguish "instances".
 * Chrome rotates a new browser GUID on every launch (the tail of webSocketDebuggerUrl), which is
 * perfect for this. Returns null if unavailable — callers must treat null as "cannot compare",
 * never as "same" or "different".
 */
function cdpIdentity(version) {
  if (!version) return null;
  try {
    const obj = JSON.parse(version);
    if (obj.webSocketDebuggerUrl) return String(obj.webSocketDebuggerUrl);
  } catch {}
  return null;
}

/**
 * Wait until the TCP port is truly no longer listening; true = the port is free,
 * false = something is still listening after the timeout.
 * Cannot use probeCDP: HTTP 500/malformed responses only mean "not healthy CDP",
 * not "port is free".
 */
async function waitForPortFree(port, maxMs = 8000, stepMs = 500, needQuiet = 2) {
  const start = Date.now();
  let quiet = 0;
  for (;;) {
    if (await probeTcp(port)) {
      quiet = 0;
    } else if (++quiet >= needQuiet) {
      return true;
    }
    if (Date.now() - start >= maxMs) return false;
    sleepSync(stepMs);
  }
}

/** Best-effort lookup of the process holding the port, for diagnostics only (returns null if not found; does not affect the decision) */
function describePortHolder(port) {
  const cmd =
    PLATFORM === "win32"
      ? `netstat -ano -p tcp | findstr LISTENING | findstr :${port}`
      : `lsof -nP -iTCP:${port} -sTCP:LISTEN`;
  try {
    const out = execSync(cmd, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
    const line = out
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l && !/^COMMAND\s/.test(l))[0];
    return line ? line.slice(0, 200) : null;
  } catch {
    return null;
  }
}

/** Run a read-only query command and capture stdout; returns null for missing command / non-zero exit / timeout */
function queryStdout(cmd) {
  try {
    const out = execSync(cmd, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 5000,
      maxBuffer: 8 * 1024 * 1024,
    });
    return typeof out === "string" ? out : String(out);
  } catch {
    return null;
  }
}

/**
 * List the pids of processes LISTENing on the given port.
 * Only called after a CDP response has been detected — at that moment something must be listening,
 * so an empty result can only mean missing/hidden tooling; always return null meaning
 * "cannot tell", never treat it as "nobody is using it" and let it pass.
 */
function listPortListenerPids(port) {
  const queries =
    PLATFORM === "win32"
      ? [
          {
            kind: "pid",
            cmd: `powershell -NoProfile -NonInteractive -Command "Get-NetTCPConnection -State Listen -LocalPort ${port} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess"`,
          },
          {
            kind: "pid",
            cmd: `pwsh -NoProfile -NonInteractive -Command "Get-NetTCPConnection -State Listen -LocalPort ${port} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess"`,
          },
          { kind: "netstat", cmd: "netstat -ano -p tcp" },
        ]
      : [
          { kind: "pid", cmd: `lsof -nP -iTCP:${port} -sTCP:LISTEN -t` },
          // lsof is often not pre-installed on Linux; fall back to ss / fuser
          { kind: "ss", cmd: `ss -H -ltnp "sport = :${port}"` },
          { kind: "pid", cmd: `fuser -n tcp ${port}` },
        ];
  for (const { kind, cmd } of queries) {
    const out = queryStdout(cmd);
    if (out === null) continue;
    const pids = new Set();
    if (kind === "netstat") {
      // Do not parse localized state text. A listening line's stable shape is TCP + local
      // destination port + foreign port 0 + Owning PID in the last column; established
      // connections have a non-zero foreign port.
      for (const line of out.split("\n")) {
        const fields = line.trim().split(/\s+/);
        if (fields.length < 5 || fields[0].toUpperCase() !== "TCP") continue;
        const localPort = Number((fields[1].match(/:(\d+)$/) || [])[1]);
        const foreignPort = Number((fields[2].match(/:(\d+)$/) || [])[1]);
        const pid = Number(fields[fields.length - 1]);
        if (localPort === port && foreignPort === 0 && Number.isInteger(pid) && pid > 0) {
          pids.add(pid);
        }
      }
    } else if (kind === "ss") {
      for (const m of out.matchAll(/pid=(\d+)/g)) pids.add(Number(m[1]));
    } else {
      // PowerShell OwningProcess / lsof -t / fuser: a bunch of pure-numeric pids
      for (const tok of out.split(/\s+/)) {
        const n = Number(tok);
        if (Number.isInteger(n) && n > 0) pids.add(n);
      }
    }
    const list = [...pids].filter((n) => n > 0);
    if (list.length > 0) return list;
  }
  return null;
}

/** Machine-wide pid -> ppid table; returns null if unavailable (cannot tell, not "no parent") */
function listProcessParents() {
  const cmds =
    PLATFORM === "win32"
      ? [
          // wmic has been removed on newer Windows; fall back to PowerShell CIM (try both 5.1 / 7)
          "wmic process get ProcessId,ParentProcessId /format:csv",
          'powershell -NoProfile -NonInteractive -Command "Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId | ConvertTo-Csv -NoTypeInformation"',
          'pwsh -NoProfile -NonInteractive -Command "Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId | ConvertTo-Csv -NoTypeInformation"',
        ]
      : ["ps -A -o pid=,ppid="]; // recognized by both macOS (BSD) and Linux (procps)
  for (const cmd of cmds) {
    const out = queryStdout(cmd);
    if (out === null) continue;
    const map = new Map();
    if (PLATFORM === "win32") {
      // The two sources order columns differently (wmic alphabetically, PowerShell by Select order); locate columns by header
      const lines = out.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
      const head = lines.findIndex(
        (l) => /processid/i.test(l) && /parentprocessid/i.test(l)
      );
      if (head < 0) continue;
      const cols = lines[head]
        .split(",")
        .map((c) => c.replace(/"/g, "").trim().toLowerCase());
      const pidCol = cols.indexOf("processid");
      const ppidCol = cols.indexOf("parentprocessid");
      if (pidCol < 0 || ppidCol < 0) continue;
      for (const line of lines.slice(head + 1)) {
        const cells = line.split(",").map((c) => c.replace(/"/g, "").trim());
        const pid = Number(cells[pidCol]);
        const ppid = Number(cells[ppidCol]);
        if (pid > 0 && Number.isInteger(ppid)) map.set(pid, ppid);
      }
    } else {
      for (const line of out.split("\n")) {
        const m = line.trim().match(/^(\d+)\s+(\d+)$/);
        if (m) map.set(Number(m[1]), Number(m[2]));
      }
    }
    if (map.size > 0) return map;
  }
  return null;
}

/** Get the full command line of a pid; returns null if unavailable */
function processCommandLine(pid) {
  const cmds =
    PLATFORM === "win32"
      ? [
          `wmic process where "ProcessId=${pid}" get CommandLine /value`,
          `powershell -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}').CommandLine"`,
          `pwsh -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_Process -Filter 'ProcessId=${pid}').CommandLine"`,
        ]
      : [`ps -ww -o command= -p ${pid}`]; // -ww: do not truncate to terminal width; Chrome's command line is very long
  for (const cmd of cmds) {
    const out = queryStdout(cmd);
    if (out === null) continue;
    const text =
      PLATFORM === "win32" ? out.replace(/^\s*CommandLine=/im, "") : out;
    const trimmed = text.trim();
    if (trimmed) return trimmed;
  }
  return null;
}

/** Whether pid is inside rootPid's process tree (including rootPid itself); walk up via ppid */
function isInProcessTree(pid, rootPid, parents) {
  let cur = pid;
  for (let hops = 0; hops < 64; hops++) {
    if (cur === rootPid) return true;
    if (!Number.isInteger(cur) || cur <= 1) return false;
    const next = parents.get(cur);
    if (next === undefined || next === cur) return false;
    cur = next;
  }
  return false;
}

function commandLineHasArgument(commandLine, argument) {
  const escaped = argument.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`(?:^|[\\s"'])${escaped}(?=$|[\\s"'])`).test(commandLine);
}

/**
 * Prove that the endpoint answering on the port truly belongs to the process spawned this run.
 * Both must hold:
 *   ① All LISTEN holders on the port are inside rootPid's process tree — Chrome spawns a separate
 *      browser process, and on macOS the launched binary may re-exec, so the comparison is against
 *      the whole tree, not the direct pid; conversely, child processes that inherited the listening
 *      fd are also listed by lsof, so the requirement is "all in the tree", not "one in it".
 *   ② One holder in the tree indeed carries this run's --remote-debugging-port=<port> — proving
 *      the responder is the instance we configured, not some other process in the tree that
 *      happened to take the port.
 * If any step cannot be determined, return unverifiable: rather fail hard than treat
 * "cannot prove" as "proven".
 */
function verifyPortOwnedByLaunch(port, rootPid) {
  const fail = (code, lines) => ({ ok: false, code, lines: [`${code}: ${lines[0]}`, ...lines.slice(1)] });
  const unverifiable = (why) =>
    fail("CDP_OWNER_UNVERIFIABLE", [
      `Cannot confirm the ownership of the LISTEN holder on port ${port} (${why}).`,
      "Refusing to report success: if we cannot prove this endpoint belongs to this launch, it must not be handed to subsequent collection.",
      PLATFORM === "win32"
        ? "This machine needs netstat plus wmic or PowerShell to resolve process ownership."
        : "This machine needs lsof (or ss / fuser) plus ps to resolve process ownership.",
      `How to proceed: install the tools above and rerun, or manually confirm that the process on ${port} is indeed the just-launched Chrome.`,
    ]);

  if (!rootPid) return unverifiable("spawn did not yield a pid");
  const listeners = listPortListenerPids(port);
  if (!listeners) return unverifiable("cannot find a process listening on that port");

  // When the holder is exactly the spawned pid, no process table is needed — the most common
  // shape (Chrome's browser process is the one we launched) thus depends on nothing beyond wmic/ps
  let outside = listeners.filter((pid) => pid !== rootPid);
  if (outside.length > 0) {
    const parents = listProcessParents();
    if (!parents) return unverifiable("cannot read the process table (pid/ppid)");
    outside = outside.filter((pid) => !isInProcessTree(pid, rootPid, parents));
  }
  if (outside.length > 0) {
    const holder = describePortHolder(port);
    return fail("CDP_PORT_NOT_OURS", [
      `The LISTEN holder of port ${port} (pid ${outside.join(", ")}) is not inside this launch's process tree (root pid ${rootPid}).`,
      "Refusing to report success: the port is held by another process; any further use would read someone else's session on every collection.",
      ...(holder ? [`Holder: ${holder}`] : []),
      `How to proceed: terminate the process holding ${port} and rerun, or switch to another port.`,
    ]);
  }

  const marker = `--remote-debugging-port=${port}`;
  let sawCommandLine = false;
  for (const pid of listeners) {
    const cmdline = processCommandLine(pid);
    if (cmdline === null) continue;
    sawCommandLine = true;
    if (commandLineHasArgument(cmdline, marker)) return { ok: true, pids: listeners, pid };
  }
  if (!sawCommandLine) return unverifiable("cannot read the holder's command line");
  return fail("CDP_OWNER_NOT_LAUNCHED_INSTANCE", [
    `The LISTEN holder of port ${port} (pid ${listeners.join(", ")}) is inside this launch's process tree, but none of them carries ${marker}.`,
    "Refusing to report success: the responder is not the Chrome launched this run — just another process in the same tree that took this port.",
    `How to proceed: confirm ${port} is not occupied by another process, or rerun with a different port.`,
  ]);
}

/** Whether the spawned Chrome is still alive (exitCode/signalCode are authoritative; fall back to kill(pid, 0)) */
function isChildAlive(child) {
  if (!child || !child.pid) return false;
  if (child.exitCode !== null || child.signalCode !== null) return false;
  try {
    process.kill(child.pid, 0);
    return true;
  } catch {
    return false;
  }
}

function isPidAlive(pid) {
  if (!Number.isInteger(pid) || pid <= 0) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

/** Only terminate the process tree raised by this spawn; never call the global killChrome to collateral-kill the user's other windows. */
function terminateLaunchTree(rootPid) {
  if (!Number.isInteger(rootPid) || rootPid <= 0) return;
  if (PLATFORM === "win32") {
    try {
      execSync(`taskkill /F /T /PID ${rootPid}`, { stdio: "ignore" });
    } catch {}
    return;
  }

  const parents = listProcessParents();
  const tree = [];
  if (parents) {
    for (const pid of parents.keys()) {
      if (pid !== process.pid && isInProcessTree(pid, rootPid, parents)) tree.push(pid);
    }
  }
  if (!tree.includes(rootPid)) tree.push(rootPid);

  // Stop descendants first and the launcher last, so a detached listener is not reparented and
  // loses its ownership when the parent dies first.
  const depth = (pid) => {
    let current = pid;
    for (let hops = 0; hops < 64; hops++) {
      if (current === rootPid) return hops;
      const next = parents?.get(current);
      if (!next || next === current) return -1;
      current = next;
    }
    return -1;
  };
  tree.sort((left, right) => depth(right) - depth(left));
  for (const pid of tree) {
    try { process.kill(pid, "SIGTERM"); } catch {}
  }
  sleepSync(200);
  for (const pid of tree) {
    if (!isPidAlive(pid)) continue;
    try { process.kill(pid, "SIGKILL"); } catch {}
  }
}

/** Copy a file (swallow ENOENT; print one warning for other errors so the user can investigate) */
function copyFileSafe(src, dest) {
  try {
    fs.copyFileSync(src, dest);
    return true;
  } catch (e) {
    if (e.code !== "ENOENT") {
      warn(`Copy failed: ${src} -> ${dest} (${e.code || e.message})`);
    }
    return false;
  }
}

/** Recursively copy a directory */
function copyDirRecursive(src, dest) {
  fs.cpSync(src, dest, { recursive: true, force: true });
}

/** Recursively delete a directory */
function rmDirSafe(dir) {
  fs.rmSync(dir, { recursive: true, force: true });
}

/**
 * Refresh login-state related files (used on the "incremental" path where debugProfile already exists).
 * Also tries both Default/Cookies and Default/Network/Cookies as Chrome may currently use either,
 * covering -journal / -wal / -shm sidecar files of all kinds, plus Google account login data.
 */
function refreshAuthFiles(srcDefault, destDefault) {
  const targets = [
    "Cookies", "Cookies-journal",
    "Login Data", "Login Data-journal",
    "Login Data For Account", "Login Data For Account-journal",
    "Web Data", "Web Data-journal",
    path.join("Network", "Cookies"),
    path.join("Network", "Cookies-journal"),
  ];
  let copied = 0;
  for (const rel of targets) {
    const src = path.join(srcDefault, rel);
    if (!fs.existsSync(src)) continue;
    const dest = path.join(destDefault, rel);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    if (copyFileSafe(src, dest)) copied++;
  }
  return copied;
}

/** Clear Chrome singleton locks to avoid a failed launch after a previous crash */
function clearSingletonLocks(profileDir) {
  const names = ["SingletonLock", "SingletonCookie", "SingletonSocket"];
  for (const n of names) {
    try { fs.unlinkSync(path.join(profileDir, n)); } catch {}
  }
}

/** Wait until the Chrome PID list is empty */
function waitForChromeExit(config, maxMs = 8000, stepMs = 500) {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    if (config.listChromePids().length === 0) return true;
    sleepSync(stepMs);
  }
  return false;
}

/** Interactive TTY prompt */
function promptYesNo(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(question, (answer) => {
      rl.close();
      resolve(/^y(es)?$/i.test((answer || "").trim()));
    });
  });
}

// ---------------------------------------------------------------------------
// detect-only mode
// ---------------------------------------------------------------------------

async function runDetectOnly(config) {
  const version = await probeCDP(CDP_PORT);
  if (version) {
    log("CDP_STATUS=ready");
    log(`CDP_URL=http://127.0.0.1:${CDP_PORT}/json/version`);
    // Try to extract the browser version from JSON (fault-tolerant)
    try {
      const obj = JSON.parse(version);
      if (obj.Browser) log(`BROWSER=${obj.Browser}`);
    } catch {}
    process.exit(0);
  }
  log("CDP_STATUS=needs-setup");
  const pids = config.listChromePids();
  if (pids.length > 0) {
    log("CHROME_RUNNING=yes");
    log(`CHROME_PID_COUNT=${pids.length}`);
  } else {
    log("CHROME_RUNNING=no");
  }
  process.exit(0);
}

// ---------------------------------------------------------------------------
// Consent flow: return true to continue, false when the user declined
// ---------------------------------------------------------------------------

async function ensureConsentToKill(pids) {
  if (pids.length === 0) return true;
  if (ARGS.flags.yes) return true;

  // Not a TTY: refuse to silently kill processes; give the caller (Claude / parent scripts)
  // a clear signal
  if (!process.stdin.isTTY) {
    err(`NEEDS_CONSENT: ${pids.length} running Chrome process(es) will be killed.`);
    err(`Pass --yes to confirm (after asking the user), or stop Chrome manually first.`);
    process.exit(3);
  }

  // TTY: interactive prompt
  warn(`Detected ${pids.length} running Chrome process(es).`);
  warn("Continuing will kill them; unsaved work in your regular Chrome may be lost.");
  return promptYesNo("Continue? [y/N] ");
}

// ---------------------------------------------------------------------------
// Main flow
// ---------------------------------------------------------------------------

async function main() {
  const config = getConfig();
  const debugProfile = path.join(os.homedir(), "chrome-debug-profile");

  // 1) Locate the Chrome executable (detect-only also needs profileDir)
  const chromePath = config.findChrome();

  // detect-only: no state is modified
  if (ARGS.flags.detectOnly) {
    if (!chromePath) {
      log("CDP_STATUS=needs-setup");
      log("CHROME_INSTALLED=no");
      process.exit(0);
    }
    return runDetectOnly(config);
  }

  log("=== CDP Chrome environment setup ===");
  log(`Platform: ${PLATFORM} | CDP port: ${CDP_PORT} | profile: ${ARGS.profile}`);

  if (!chromePath) {
    err("Google Chrome not found. Please make sure it is installed.");
    err(`Search paths: ${JSON.stringify(config.chromePaths, null, 2)}`);
    process.exit(1);
  }
  log(`Chrome path: ${chromePath}`);

  // 2) dry-run: print the plan before any side effects (including "reuse existing CDP") so
  //    the user can see the steps that would actually run
  const defaultProfile = path.join(config.profileDir, ARGS.profile);
  const hasProfile = fs.existsSync(defaultProfile);

  if (ARGS.flags.dryRun) {
    const cdpAlive = !!(await probeCDP(CDP_PORT));
    const tcpOccupied = await probeTcp(CDP_PORT);
    // --reset / explicit --profile skip reuse (see step 3 below); dry-run must say so truthfully
    const willReuse = cdpAlive && !ARGS.flags.reset && !ARGS.profileExplicit;
    const cdpNote = !tcpOccupied
      ? "not listening"
      : !cdpAlive
        ? "has a TCP listener but is not healthy CDP (the real run will hard-fail before touching the profile)"
      : willReuse
        ? "ready (the real run will reuse it directly)"
        : "ready (but --reset/--profile was passed; the real run will rebuild, not reuse)";
    log(`Chrome profile: ${defaultProfile} (${hasProfile ? "exists" : "does not exist"})`);
    log(`CDP port ${CDP_PORT}: ${cdpNote}`);
    const runningPids = config.listChromePids();
    log(`Detected ${runningPids.length} Chrome process(es)`);
    log("\n--- dry-run mode: only prints operations, executes nothing ---");
    if (willReuse) {
      log("0. CDP is ready; the real run will reuse it and exit 0 (the steps below are for reference only)");
    } else if (cdpAlive) {
      log("0. CDP is ready, but --reset/--profile was passed: the real run will NOT reuse; it will rebuild per the steps below");
    }
    // Step numbers are dynamically numbered in real execution order: kill processes first,
    // then confirm the port is free, and only then touch the profile directory
    let stepNo = 0;
    const step = (msg) => log(`${++stepNo}. ${msg}`);
    if (runningPids.length > 0) {
      step(`${ARGS.flags.yes ? "(consented) " : "after asking for consent, "}kill ${runningPids.length} Chrome process(es)`);
    } else {
      step("No Chrome processes; nothing to kill");
    }
    step(`Confirm via TCP that port ${CDP_PORT} is free (any lingering listener aborts: no profile deletion, no launch)`);
    if (ARGS.flags.reset) step(`delete ${debugProfile}`);
    if (hasProfile) {
      step(`copy profile: ${defaultProfile} -> ${debugProfile}/Default`);
    } else {
      step("⚠️ no user profile; will launch with an empty profile");
    }
    step("clear SingletonLock / SingletonCookie / SingletonSocket");
    step("launch Chrome (with --remote-allow-origins=*, --no-first-run, etc.)");
    step(
      `verify http://127.0.0.1:${CDP_PORT}/json/version comes from this launch's instance` +
        " (identity obtainable and changed + process alive + the port's LISTEN holder is inside this process tree)"
    );
    ok("dry-run completed.");
    process.exit(0);
  }

  // 3) If CDP is ready → reuse and exit directly.
  //    But --reset / explicit --profile semantically mean "rebuild the debug profile": the docs
  //    tell users to run --reset when the login state expires, and at that moment CDP is exactly
  //    alive (the expiry was discovered from this very session). If we reused as usual, both flags
  //    would be silently dropped while still reporting "success" with exit 0. So these two cases
  //    do not reuse; they continue into the rebuild below.
  const existing = await probeCDP(CDP_PORT);
  const portWasListening = await probeTcp(CDP_PORT);
  if (existing) {
    if (!ARGS.flags.reset && !ARGS.profileExplicit) {
      ok("CDP is ready; reusing the existing Chrome.");
      log(existing.split("\n").slice(0, 5).join("\n"));
      process.exit(0);
    }
    const requested = ARGS.flags.reset ? "--reset" : `--profile ${ARGS.profile}`;
    warn(`CDP port ${CDP_PORT} is already listening, but ${requested} was passed: no reuse; the existing Chrome will be closed and the debug profile rebuilt.`);
  }
  // Identity of the pre-rebuild instance: step 10 uses it to prove "the responder is the newly
  // launched instance", not merely "something answered"
  const staleIdentity = cdpIdentity(existing);

  if (!hasProfile) {
    err(`Chrome profile not found: ${defaultProfile}`);
    err("Please make sure Google Chrome is installed and has been used at least once, or specify another profile with --profile <name>.");
    process.exit(1);
  }

  // 4) Consent flow: if Chrome processes must be killed, ask for consent first
  const runningPids = config.listChromePids();
  const consented = await ensureConsentToKill(runningPids);
  if (!consented) {
    err("User declined; aborted.");
    process.exit(2);
  }

  // 5) Kill the existing Chrome processes and wait for them to exit
  if (runningPids.length > 0) {
    log(`Stopping ${runningPids.length} Chrome process(es)...`);
    config.killChrome(runningPids);
    if (!waitForChromeExit(config, 6000)) {
      warn("Chrome processes still remain after the first kill; trying again...");
      config.killChrome(runningPids);
      waitForChromeExit(config, 4000);
    }
    const remain = config.listChromePids();
    if (remain.length > 0) {
      err(`${remain.length} Chrome process(es) have not exited; aborted.`);
      err("No debug profile was deleted or modified, and no new Chrome was launched — state is unchanged.");
      process.exit(1);
    } else {
      ok("Chrome has exited.");
    }
  }

  // 5.5) Hard gate: the port must be truly free before the profile directory may be touched
  //      or a new instance launched. The order is deliberate — the gate comes before deleting
  //      the profile. Continuing while the old instance is alive hits the worst outcome:
  //      the profile of a still-running Chrome gets deleted first (destructive on its own),
  //      the new process cannot start because the port is taken, and step 10's probeCDP happens
  //      to be answered by the stale endpoint, so exit 0 reports "rebuild succeeded" — the caller
  //      believes it has a new browser while every collection afterwards reads the old/other
  //      session. Here the only option is a hard failure.
  //      Runs regardless of whether /json/version is healthy: HTTP 500 may also be holding the port.
  // Only give a grace period after processes were killed; when no Chrome was identified, the holder
  // won't exit on its own — confirm quickly and fail.
  const graceMs = runningPids.length > 0 ? 8000 : 1000;
  if (!(await waitForPortFree(CDP_PORT, graceMs))) {
    const remain = config.listChromePids();
    err(
      existing
        ? `The old instance on CDP port ${CDP_PORT} is still responding; aborted.`
        : `CDP port ${CDP_PORT} is still occupied and not released; aborted.`
    );
    if (remain.length > 0) {
      err(`Reason: ${remain.length} Chrome process(es) could not exit (kill ineffective — possibly insufficient privileges or a stuck process).`);
    } else if (runningPids.length === 0) {
      err("Reason: the port is held by an unrecognized process — no Chrome process was found, so the script cannot close it.");
    } else {
      err("Reason: Chrome processes have exited, but another process is still holding the port.");
    }
    const holder = describePortHolder(CDP_PORT);
    if (holder) err(`Holder: ${holder}`);
    err("No debug profile was deleted or modified, and no new Chrome was launched — state is unchanged.");
    err(`How to proceed: manually terminate the process holding ${CDP_PORT} and rerun, or switch to another port (node setup-cdp-chrome.js <other-port> ...).`);
    process.exit(1);
  }
  if (portWasListening) {
    ok(`CDP port ${CDP_PORT} has been released.`);
  }

  // 6) --reset: wipe the debug profile
  if (ARGS.flags.reset) {
    log(`Deleting debug profile: ${debugProfile}`);
    rmDirSafe(debugProfile);
  }

  // 7) Copy / refresh the profile (Chrome is closed by now, so SQLite is consistent)
  const debugDefault = path.join(debugProfile, "Default");
  if (!fs.existsSync(debugDefault)) {
    log("Copying Chrome profile to the debug directory...");
    fs.mkdirSync(debugProfile, { recursive: true });
    try { fs.chmodSync(debugProfile, 0o700); } catch {}
    copyDirRecursive(defaultProfile, debugDefault);
    ok(`Profile copied to: ${debugProfile}`);
  } else {
    log("debug profile already exists; refreshing login-state related files...");
    try { fs.chmodSync(debugProfile, 0o700); } catch {}
    const n = refreshAuthFiles(defaultProfile, debugDefault);
    ok(`Refreshed ${n} login-state file(s)`);
  }

  // 8) Clear singleton locks
  clearSingletonLocks(debugProfile);

  // 9) Launch Chrome in CDP mode
  log(`Launching Chrome in CDP mode (port ${CDP_PORT})...`);
  const chromeArgs = [
    `--remote-debugging-port=${CDP_PORT}`,
    `--user-data-dir=${debugProfile}`,
    "--remote-allow-origins=*",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-features=ChromeWhatsNewUI",
  ];
  const child = spawn(chromePath, chromeArgs, { detached: true, stdio: "ignore" });
  const childPid = child.pid;
  let spawnError = null;
  child.on("error", (e) => { spawnError = e; });
  child.unref();

  /** Post-launch verification failed: only clean up the processes we just started (the one on the port is not ours — other people's Chrome must not be collateral-killed) */
  function abortAfterLaunch(reasons) {
    for (const line of reasons) err(line);
    err("Cleaning up the just-launched Chrome processes...");
    terminateLaunchTree(childPid);
    process.exit(1);
  }

  // 10) Wait for launch and verify. A mere response is not success — it could be an old instance
  //     that was not shut down, or another process that happened to take the port. All four must pass:
  //     ① The new endpoint's browser GUID is obtainable (unobtainable = cannot compare; by contract
  //        it counts as neither same nor different);
  //     ② This GUID differs from the pre-rebuild one (combined with step 5.5 confirming the old
  //        endpoint disappeared);
  //     ③ The just-spawned process is still alive (if it died, the responder on the port cannot be
  //        this launch's instance);
  //     ④ The port's LISTEN holders are indeed inside this spawned process tree and carry this run's
  //        --remote-debugging-port. The first three are only circumstantial — "old endpoint gone +
  //        identity changed + launcher alive" does not imply "the port belongs to it"; only ④ truly
  //        binds the port to the process.
  log("Waiting for Chrome to launch...");
  let identityMisses = 0;
  for (let i = 1; i <= 15; i++) {
    sleepSync(2000);
    if (spawnError) {
      abortAfterLaunch([`Failed to launch Chrome: ${spawnError.message}`]);
    }
    const version = await probeCDP(CDP_PORT);
    if (version) {
      const identity = cdpIdentity(version);
      if (identity === null) {
        // A freshly started endpoint may theoretically answer HTTP first; grant two rounds of
        // grace; hard-fail if the identity is still unobtainable after that.
        if (++identityMisses < 3) {
          log(`   Port responds but the instance identity cannot be obtained; retrying ${identityMisses}/3...`);
          continue;
        }
        abortAfterLaunch([
          `CDP_IDENTITY_UNVERIFIABLE: port ${CDP_PORT} answers HTTP, but the instance identity (webSocketDebuggerUrl) cannot be obtained from /json/version.`,
          "Refusing to report success: without an identity there is no way to prove this is a newly launched instance — by contract it is neither same nor different, only unproven.",
          `How to proceed: confirm that a Chrome CDP endpoint (not some other HTTP service) is running on ${CDP_PORT}, or rerun with a different port.`,
        ]);
      }
      if (staleIdentity && identity === staleIdentity) {
        abortAfterLaunch([
          `Port ${CDP_PORT} is still answered by the pre-rebuild instance (${identity}), not the newly launched Chrome.`,
          "Refusing to report success: any further use would read the old session on every collection.",
        ]);
      }
      if (!isChildAlive(child)) {
        const holder = describePortHolder(CDP_PORT);
        abortAfterLaunch([
          `Port ${CDP_PORT} answers CDP, but the just-launched Chrome (pid ${childPid}) has already exited.`,
          "Refusing to report success: this endpoint does not belong to this launch's instance.",
          ...(holder ? [`Holder: ${holder}`] : []),
          `How to proceed: confirm ${CDP_PORT} is not occupied by another process, or rerun with a different port.`,
        ]);
      }
      const owner = verifyPortOwnedByLaunch(CDP_PORT, childPid);
      if (!owner.ok) abortAfterLaunch(owner.lines);
      ok(`Chrome launched successfully in CDP mode (port ${CDP_PORT})`);
      log(version.split("\n").slice(0, 5).join("\n"));
      process.exit(0);
    }
    log(`   Attempt ${i}/15...`);
  }

  // 11) Failure cleanup: kill the orphan Chrome launched above
  err("Failed to bring up the Chrome CDP environment within 30 seconds.");
  err("Cleaning up the just-launched Chrome processes...");
  terminateLaunchTree(childPid);
  err("Possible causes:");
  err("  - Chrome does not support --remote-debugging-port");
  err(`  - port ${CDP_PORT} is already occupied by another process`);
  err("  - the debug profile directory is corrupted (try --reset)");
  process.exit(1);
}

main().catch((e) => {
  err(`Startup failed: ${e.message}`);
  process.exit(1);
});
