# heartbeat.ps1 — Poll for Trident background agent completion (Windows)
#
# Watches for .trident/<task-slug>/.done signal file created by the
# Discriminator or Arbiter when they finish their evaluation.
#
# Usage:
#   .\heartbeat.ps1 <task-slug> [timeout_seconds] [interval_seconds]
#
# Exit codes:
#   0  Signal file detected
#   1  Timeout

param(
    [Parameter(Mandatory=$true)][string]$TaskSlug,
    [int]$Timeout = 300,
    [int]$Interval = 3
)

$signal = ".trident\$TaskSlug\.done"
$elapsed = 0

while ($elapsed -lt $Timeout) {
    if (Test-Path $signal) {
        Get-Content $signal
        exit 0
    }
    Start-Sleep -Seconds $Interval
    $elapsed += $Interval
}

Write-Output "TIMEOUT: no signal after ${Timeout}s"
exit 1
