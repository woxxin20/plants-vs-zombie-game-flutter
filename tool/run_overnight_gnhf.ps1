[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logRoot = "$repo-gnhf-logs"
$gnhf = (Get-Command gnhf -ErrorAction Stop).Source
$maxCycles = 6
$startupTimeout = [TimeSpan]::FromMinutes(8)
$pollSeconds = 15
New-Item -ItemType Directory -Force -Path $logRoot | Out-Null

function Quote-Single([string]$value) {
  return "'" + $value.Replace("'", "''") + "'"
}

function Get-Head {
  return (git -C $repo rev-parse --short HEAD).Trim()
}

function Save-DirtyWork([string]$role, [string]$reason) {
  $dirty = git -C $repo status --porcelain
  if (-not $dirty) { return }
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $inspection = Join-Path $logRoot "$stamp-$role-dirty-inspection.log"
  @(
    "reason=$reason"
    'status:'
    $dirty
    'diff-check:'
    (git -C $repo diff --check 2>&1)
    'diff-stat:'
    (git -C $repo diff --stat 2>&1)
  ) | Set-Content -LiteralPath $inspection
  git -C $repo add -A
  git -C $repo commit -m "WIP(gnhf): preserve $role work after $reason"
}

function Invoke-Role(
  [string]$role,
  [string]$agent,
  [int]$iterations,
  [string]$stopWhen,
  [string]$contractPath,
  [int]$cycle
) {
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $prefix = Join-Path $logRoot "$stamp-c$cycle-$role"
  $stdout = "$prefix.stdout.log"
  $stderr = "$prefix.stderr.log"
  $activity = "$prefix.activity.json"
  $start = Get-Date
  $startHead = Get-Head
  $prompt = "Read and obey the complete role contract at $contractPath. Work in $repo."
  $args = @(
    '--agent', $agent,
    '--current-branch',
    '--prevent-sleep', 'on',
    '--max-iterations', "$iterations",
    '--max-rate-limit-wait', '20h',
    '--stop-when', $stopWhen,
    $prompt
  )
  $quotedArgs = ($args | ForEach-Object { Quote-Single $_ }) -join ' '
  $command = "& $(Quote-Single $gnhf) $quotedArgs"
  $process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command
  ) -WorkingDirectory $repo -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -WindowStyle Hidden
  Write-Host "ROLE_START cycle=$cycle role=$role agent=$agent pid=$($process.Id) startCommit=$startHead"
  $lastBytes = 0L
  $lastLine = ''
  $latestProgress = $start
  $resetWait = $false
  $stalled = $false

  while (-not $process.HasExited) {
    Start-Sleep -Seconds $pollSeconds
    $bytes = 0L
    if (Test-Path $stdout) { $bytes += (Get-Item $stdout).Length }
    if (Test-Path $stderr) { $bytes += (Get-Item $stderr).Length }
    if ($bytes -gt $lastBytes -or (Get-Head) -ne $startHead) {
      $latestProgress = Get-Date
      $lastBytes = $bytes
      $progressLine = @()
      if (Test-Path $stdout) { $progressLine += Get-Content $stdout -Tail 1 }
      if (Test-Path $stderr) { $progressLine += Get-Content $stderr -Tail 1 }
      $progressLine = ($progressLine -join ' ').Trim()
      if ($progressLine -and $progressLine -ne $lastLine) {
        Write-Host "ROLE_PROGRESS role=$role outputBytes=$bytes message=$progressLine"
        $lastLine = $progressLine
      }
    }
    $tail = @()
    if (Test-Path $stdout) { $tail += Get-Content $stdout -Tail 80 }
    if (Test-Path $stderr) { $tail += Get-Content $stderr -Tail 80 }
    $resetWait = ($tail -join "`n") -match '(?i)(rate.?limit|usage.?limit|reset).*(wait|resume|hour|minute|[0-9]{1,2}:[0-9]{2})'
    if (-not $resetWait -and $lastBytes -eq 0 -and (Get-Date) - $start -gt $startupTimeout -and (Get-Head) -eq $startHead) {
      $stalled = $true
      taskkill /PID $process.Id /T /F | Out-Null
      break
    }
  }
  $process.WaitForExit()
  $end = Get-Date
  $exitCode = if ($stalled) { 124 } else { $process.ExitCode }
  $record = [ordered]@{
    role = $role
    cycle = $cycle
    pid = $process.Id
    startedAt = $start.ToString('o')
    latestProgressAt = $latestProgress.ToString('o')
    endedAt = $end.ToString('o')
    outputBytes = $lastBytes
    startCommit = $startHead
    endCommit = Get-Head
    exitStatus = $exitCode
    providerResetWaitRecognized = $resetWait
    stalled = $stalled
    stdout = $stdout
    stderr = $stderr
  }
  $record | ConvertTo-Json | Set-Content -LiteralPath $activity
  Write-Host "ROLE_END cycle=$cycle role=$role exit=$exitCode endCommit=$($record.endCommit) resetWait=$resetWait stalled=$stalled"
  if ($stalled -or $exitCode -ne 0) {
    $reason = if ($stalled) { 'silent stall' } else { "exit $exitCode" }
    Save-DirtyWork $role $reason
  }
  return $record
}

Set-Location $repo
for ($cycle = 1; $cycle -le $maxCycles; $cycle++) {
  $assignment = Join-Path $repo '.ai\inbox\gnhf-assignment.md'
  $plan = Invoke-Role 'claude-planner' 'claude' 3 'PLAN_READY after a complete bounded assignment exists' (Join-Path $repo '.ai\overnight\claude-planner.md') $cycle
  if ($plan.exitStatus -ne 0 -and -not (Test-Path $assignment)) { continue }

  $implementation = Invoke-Role 'cursor-implementer' 'cursor' 8 'IMPLEMENTATION_READY or IMPLEMENTATION_BLOCKED after evidence is written' (Join-Path $repo '.ai\overnight\cursor-implementer.md') $cycle
  if ($implementation.exitStatus -ne 0) { continue }

  $review = Invoke-Role 'codex-reviewer' 'codex' 4 'REVIEW_PASS or REVIEW_FAIL after independent verification is recorded' (Join-Path $repo '.ai\overnight\codex-reviewer.md') $cycle
  if ($review.exitStatus -ne 0) { continue }

  $watchdog = Invoke-Role 'claude-watchdog' 'claude' 3 'WATCHDOG_DONE after a valid strict JSON verdict exists' (Join-Path $repo '.ai\overnight\claude-watchdog.md') $cycle
  $verdictPath = Join-Path $repo '.ai\inbox\watchdog-verdict.json'
  if ($watchdog.exitStatus -ne 0 -or -not (Test-Path $verdictPath)) { continue }
  try {
    $verdict = Get-Content -Raw $verdictPath | ConvertFrom-Json
    if ($verdict.done -eq $true -and [string]::IsNullOrEmpty($verdict.nextTask)) {
      Write-Host "OVERNIGHT_DONE: $($verdict.evidence)"
      exit 0
    }
  } catch {
    Write-Warning "Invalid watchdog verdict: $($_.Exception.Message)"
  }
}

Save-DirtyWork 'supervisor' 'cycle limit reached'
Write-Error "Overnight objective incomplete after $maxCycles cycles. See $logRoot and .ai/inbox/watchdog-verdict.json."
