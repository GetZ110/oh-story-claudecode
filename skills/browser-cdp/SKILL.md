---
name: browser-cdp
description: "Use this skill when you need to control a Chrome browser via CDP (Chrome DevTools Protocol) to reuse existing login sessions. Covers: launching Chrome in debug mode, opening URLs, waiting for page load, evaluating JavaScript, taking snapshots, and extracting auth tokens. Trigger phrases: browser automation, CDP, agent-browser, Chrome CDP, reuse login session, extract token from browser."
metadata: {"openclaw":{"requires":{"bins":["agent-browser"]},"source":"https://github.com/GetZ110/oh-story-claudecode"}}
---
# Browser CDP Operations

Control Chrome over the CDP protocol, reuse existing login sessions, and run browser automation.

## Interaction language

- Unless the user explicitly requests another reply language, communicate with the user in Simplified Chinese (简体中文), including questions, progress updates, confirmations, errors, and summaries.
- This applies to conversational output only. Keep browser commands, URLs, extracted source text, code, and other user-requested artifacts in their required language.

## Prerequisites

- macOS / Linux / Windows (experimental), Google Chrome installed
- Node.js 20+
- `agent-browser` installed: `npm install -g agent-browser`

> **First launch kills the user's regular Chrome.** You must get the user's consent before launching (see "Launch flow" below); otherwise the user may lose unsaved tabs/drafts.

---

## Launch flow (mandatory steps in skill mode)

**Step 1: probe the current state (no side effects)**

```bash
node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --detect-only
```

Output looks like:

```
CDP_STATUS=ready                        # ready; can reuse directly
CDP_URL=http://127.0.0.1:9222/json/version
BROWSER=Chrome/148.0.7778.168
```

or:

```
CDP_STATUS=needs-setup
CHROME_RUNNING=yes                      # user has Chrome running; launching will kill it
CHROME_PID_COUNT=3
```

**Step 2: branch on the probe result**

- `CDP_STATUS=ready` -> use `agent-browser --cdp 9222 ...` directly; **do not run setup**.
- `CDP_STATUS=needs-setup` and `CHROME_RUNNING=no` -> safe launch:
  ```bash
  node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --yes
  ```
- `CDP_STATUS=needs-setup` and `CHROME_RUNNING=yes` -> **confirm with the user first via the AskUserQuestion tool**: tell them N Chrome processes will be killed and unsaved work may be lost; launch with `--yes` only after consent; if the user declines, abandon this automation round.

**Why not just `--yes`:** in a non-TTY context (skill mode / Bash tool), if the script detects Chrome running without `--yes`, it exits with code 3 reporting `NEEDS_CONSENT: ...` and aborts — it will **not** silently kill processes. This is an intentional backstop — but the skill flow should still ask the user first, not blindly pass `--yes` when it sees exit code 3.

---

## Launch script options

| Option | Description |
|--------|-------------|
| `--detect-only` | probe only; change nothing (skill use) |
| `--yes` | consent already given; skip the interactive prompt |
| `--reset` | wipe `~/chrome-debug-profile` before launch (use when login has expired) |
| `--profile <name>` | use a non-Default Chrome profile (e.g., `"Profile 1"`) |
| `--dry-run` | print the steps that would run; don't run them |

Exit codes: `0` success / `1` general error / `2` user declined (TTY) / `3` consent needed but `--yes` missing.

---

## Common operations

### Open a page and wait for load

```bash
agent-browser --cdp 9222 open "<URL>"
agent-browser --cdp 9222 wait 3000
```

### Extract page text

```bash
agent-browser --cdp 9222 eval 'document.body.innerText.substring(0, 8000)'
```

### Extract an auth token

```bash
agent-browser --cdp 9222 eval 'localStorage.getItem("token") || document.cookie'
```

### Complex JS (quotes / `$` / backticks)

Shell escaping is error-prone; use one of these two:

```bash
# 1) base64 wrapper
agent-browser --cdp 9222 eval -b "$(echo -n "document.querySelectorAll('a').length" | base64)"

# 2) heredoc + --stdin
cat <<'EOF' | agent-browser --cdp 9222 eval --stdin
const links = document.querySelectorAll('a');
links.length;
EOF
```

### Page interaction (snapshot for element refs)

```bash
agent-browser --cdp 9222 snapshot -i        # interactive elements only
agent-browser --cdp 9222 click "<CSS or @e1>"
agent-browser --cdp 9222 type "<sel>" "<text>"
```

---

## Stop / clean up

- Close the debug Chrome window, or rerun the setup script with `--reset --yes`; cleanup is limited to the process IDs discovered for this setup run.
- Login expired: `node {SKILL_DIR}/scripts/setup-cdp-chrome.js 9222 --reset --yes` (note: `--yes` also requires asking the user first).

---

## Windows / restricted-environment pitfalls (field-tested 2026-08)

These are real failures hit during market scans in a sandboxed Windows environment. Read this section before scripting collection on Windows; each pit has a verified workaround.

### P1. agent-browser cannot write its socket directory

Error: `✗ Socket directory 'C:\Users\<user>\.agent-browser' is not writable: 拒绝访问 (os error 5)`.

Cause: agent-browser keeps its control socket under `~/.agent-browser`; a sandbox or ACL that denies writes to the home dir kills every command.

Fix: point the socket dir at a writable location with the env var **`AGENT_BROWSER_SOCKET_DIR`** (verified; the binary reads this exact name — `USERPROFILE`/`HOME` overrides do NOT work on Windows):

```powershell
$env:AGENT_BROWSER_SOCKET_DIR = "D:\work\.agent-browser"   # any writable dir
```

### P2. Capturing agent-browser output hangs on Windows (pipe EOF)

Symptoms: `$x = agent-browser ...`, `agent-browser ... | Out-File`, and `Start-Process -Wait -RedirectStandardOutput` all HANG even though the command itself completes in ~1 s. Direct console output works; `| Select-Object -First N` works only because it closes the pipe early.

Cause: agent-browser (or a descendant) keeps the stdout handle open past process exit, so PowerShell waits for pipe EOF forever. Do not retry different capture shapes — use the verified poll pattern:

```powershell
$p = Start-Process -FilePath $abExe -ArgumentList @("--cdp","9222","eval","-b",$b64) `
  -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -PassThru
while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 400 }
# read $outFile after exit; Stop-Process -Id $p.Id -Force on timeout
```

A ready-made, parameterized implementation lives in **`scripts/ab-run.ps1`** (function `Invoke-AB`): dot-source it, then `$result = Invoke-AB -Port 9222 -B64 $b64` returns the eval output as text. In restricted sandboxes, node-based helpers that capture child stdout via pipes (`child_process` with default `stdio: 'pipe'`) fail with EPERM — the PowerShell poll pattern is the fallback there.

### P3. Chrome itself refuses to launch (sandbox/ACL, not a config bug)

Symptoms: setup script reports "Failed to bring up the Chrome CDP environment within 30 seconds" while Chrome processes die instantly; foreground launch shows `FATAL:mojo\public\cpp\platform\platform_channel.cc Check failed (拒绝访问)` and/or crashpad `OpenProcess: 拒绝访问 (0x5)`.

Cause: Chrome's Mojo IPC uses named pipes and crashpad needs `OpenProcess` — restricted environments (sandboxes, job objects, tight ACLs) deny both, so Chrome self-terminates at startup. The profile-copy EPERM warnings in the same run are the same root cause.

Handling:
- This is an environment boundary, not a profile problem: `--reset` will not help.
- If the environment supports an escalation mechanism (e.g. a one-shot "full access" retry of the setup command), use it — the setup script then succeeds unchanged.
- Otherwise fall back to non-browser collection (plain HTTP where allowed, API endpoints, or built-in knowledge) and record the fallback in the report.

### P4. `eval` return values are JSON-encoded strings

`agent-browser eval` returns the result as a JSON string literal (escaped), e.g. `"{\"count\":0}"`. Parse twice (or use `cdp-utils.js` `evalJSON`, which already double-parses):

```powershell
$j = ($result | ConvertFrom-Json | ConvertFrom-Json)
```

### P5. Big eval payloads feel like hangs

Fetching 20-50 API records in one eval is fine (the fetch itself is fast); the apparent hang is usually P2. Still, compact the payload before returning it (map to short keys, truncate descriptions, slice tag arrays) and prefer `limit=20-50` with pagination over `limit=100+`.

---

## OpenCode environment notes

opencode has no background command-line tool; long CDP operations (waiting for page load, bulk scraping) block the whole session and the CLI stops responding.

### Timeout wrapper

On Windows, wrap CDP commands in a PowerShell Job with a timeout:

```powershell
$job = Start-Job { agent-browser --cdp 9222 eval "window.location.replace('https://www.royalroad.com/rankings/')" }
Wait-Job $job -Timeout 30 | Out-Null
if ($job.State -eq 'Running') { Stop-Job $job; Write-Output "CDP operation timed out (30s); retry or interrupt manually" }
else { Receive-Job $job }
Remove-Job $job -Force
```

On macOS / Linux use the `timeout` command:

```bash
timeout 30 agent-browser --cdp 9222 eval "window.location.replace('https://www.royalroad.com/rankings/')" || echo "CDP operation timed out (30s); retry or interrupt manually"
```

### Known limitations

Even with the timeout wrapper, these scenarios can still fail:

| Scenario | Risk | Mitigation |
|----------|------|------------|
| Page load timeout | eval waits forever | 30s timeout; retry after timeout |
| Bulk data scraping | cumulative waits across pagination | per-page independent timeouts; resume from the breakpoint after failure |
| Chrome process stuck | CDP connection drops but the process lingers | rerun the setup script with `--reset --yes`, then reconnect |
| Network fluctuation | requests hang with no timeout | retry once automatically after timeout |

If an operation keeps hanging in opencode, press `ESC` to interrupt manually.

---

## FAQ

| Problem | Solution |
|---------|----------|
| `NEEDS_CONSENT` + exit code 3 | ask the user via AskUserQuestion whether killing Chrome is OK; on consent re-run with `--yes` |
| CDP port not listening | re-check with `--detect-only`; port busy -> use another port |
| Page redirected to login | `snapshot -i` to find the login button and operate it |
| `eval` returns `null` | check the localStorage key name; quote-heavy JS uses `eval -b` or `--stdin` |
| Login expired | `setup-cdp-chrome.js 9222 --reset --yes` to re-copy |
| Multiple Chrome profiles | specify with `--profile "Profile 1"` |
| Chrome won't start (30s timeout) | try `--reset`; check port conflicts; check whether `~/chrome-debug-profile/` is corrupted |
