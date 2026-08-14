# ab-run.ps1 — Invoke-AB: run agent-browser eval from PowerShell on Windows.
#
# WHY THIS EXISTS (field-tested 2026-08, see browser-cdp/SKILL.md P2):
#   On Windows, capturing agent-browser output through a PowerShell variable,
#   a pipeline, or Start-Process -Wait all HANG (pipe EOF never arrives),
#   and in restricted sandboxes node helpers that capture child stdout via
#   pipes fail with EPERM. The verified pattern is: Start-Process with file
#   redirection, poll HasExited (never -Wait), then read the output file.
#
# USAGE:
#   . ./ab-run.ps1                      # dot-source (defines Invoke-AB)
#   $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($js))
#   $result = Invoke-AB -B64 $b64       # eval output as text (agent-browser prints a JSON string literal; parse twice)
#   $j = $result | ConvertFrom-Json | ConvertFrom-Json
#
# PARAMS:
#   -B64          base64-encoded JS (the -b channel; avoids cmd/pwsh re-escaping)
#   -Port         CDP port (default 9222)
#   -OutDir       temp dir for stdout/stderr files (default: $env:TEMP/ab-run)
#   -TimeoutSec   per-call budget (default 90); kills the child on expiry
#
# NOTE: also export $env:AGENT_BROWSER_SOCKET_DIR to a writable dir before use
# (see SKILL.md P1) when the home dir is not writable.

$script:AB_RUN_EXE = ""

function Resolve-AgentBrowserExe {
  # Prefer the native binary (bypasses the .cmd shim; same behavior either way).
  $cmd = Get-Command agent-browser -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($cmd -and $cmd.Source) {
    $dir = Split-Path $cmd.Source -Parent
    $native = Join-Path $dir "node_modules\agent-browser\bin\agent-browser-win32-x64.exe"
    if (Test-Path $native) { return $native }
    return $cmd.Source   # fall back to the shim (works too)
  }
  throw "agent-browser not found on PATH"
}

function Invoke-AB {
  param(
    [Parameter(Mandatory = $true)][string]$B64,
    [int]$Port = 9222,
    [string]$OutDir = "",
    [int]$TimeoutSec = 90
  )
  if (-not $script:AB_RUN_EXE) { $script:AB_RUN_EXE = Resolve-AgentBrowserExe }
  if (-not $OutDir) { $OutDir = Join-Path $env:TEMP "ab-run" }
  if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
  $out = Join-Path $OutDir ("ab_out_" + [guid]::NewGuid().ToString("N") + ".txt")
  $err = Join-Path $OutDir ("ab_err_" + [guid]::NewGuid().ToString("N") + ".txt")
  $p = Start-Process -FilePath $script:AB_RUN_EXE -ArgumentList @("--cdp", [string]$Port, "eval", "-b", $B64) `
    -RedirectStandardOutput $out -RedirectStandardError $err -NoNewWindow -PassThru
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 400 }
  if (-not $p.HasExited) {
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    throw "agent-browser timed out after ${TimeoutSec}s (port $Port)"
  }
  $so = if (Test-Path $out) { Get-Content $out -Raw } else { "" }
  $se = if (Test-Path $err) { Get-Content $err -Raw } else { "" }
  Remove-Item $out, $err -Force -ErrorAction SilentlyContinue
  if ($se -and -not $so) { throw "agent-browser stderr: $se" }
  return $so
}

# Export-ModuleMember only makes sense when imported as a module; dot-sourcing is the
# documented usage, so swallow the "can only be called from inside a module" error.
try { Export-ModuleMember -Function Invoke-AB -ErrorAction Stop } catch {}
