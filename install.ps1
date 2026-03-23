# Trident Design Review — Windows Installer (PowerShell)
# https://github.com/0xFiMo/trident

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillSrc = Join-Path $ScriptDir "skills\trident"
$AgentsSrc = Join-Path $ScriptDir "agents"
$CommandsSrc = Join-Path $ScriptDir "commands\tri"
$ScriptsSrc = Join-Path $ScriptDir "scripts"

$Version = "unknown"
$ChangelogPath = Join-Path $ScriptDir "CHANGELOG.md"
if (Test-Path $ChangelogPath) {
    $firstMatch = Select-String -Path $ChangelogPath -Pattern '## \[(.+?)\]' | Select-Object -First 1
    if ($firstMatch) { $Version = $firstMatch.Matches.Groups[1].Value }
}

function Info($msg)  { Write-Host "  [info]  $msg" -ForegroundColor Blue }
function Ok($msg)    { Write-Host "  [ok]    $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "  [warn]  $msg" -ForegroundColor Yellow }
function Err($msg)   { Write-Host "  [error] $msg" -ForegroundColor Red }

Write-Host ""
Write-Host "  Trident Design Review — Installer (" -NoNewline
Write-Host "v$Version" -ForegroundColor Green -NoNewline
Write-Host ")"
Write-Host "  One agent skill. Three adversarial minds."
Write-Host ""

function Copy-Skill($dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item (Join-Path $SkillSrc "SKILL.md") -Destination $dest -Force
    foreach ($subdir in @("templates", "prompts", "reference")) {
        $srcSub = Join-Path $SkillSrc $subdir
        if (Test-Path $srcSub) {
            $destSub = Join-Path $dest $subdir
            New-Item -ItemType Directory -Path $destSub -Force | Out-Null
            Copy-Item (Join-Path $srcSub "*.md") -Destination $destSub -Force
        }
    }
    Ok "Skill → $dest/"
}

function Copy-Agents($dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    foreach ($agent in @("trident-generator.md", "trident-discriminator.md", "trident-arbiter.md")) {
        Copy-Item (Join-Path $AgentsSrc $agent) -Destination $dest -Force
    }
    Ok "Agents → $dest/"
}

function Copy-Commands($dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    Copy-Item (Join-Path $CommandsSrc "*.md") -Destination $dest -Force
    Ok "Commands → $dest/"
}

function Copy-Scripts($dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $shFile = Join-Path $ScriptsSrc "heartbeat.sh"
    $ps1File = Join-Path $ScriptsSrc "heartbeat.ps1"
    if (Test-Path $shFile) { Copy-Item $shFile -Destination $dest -Force }
    if (Test-Path $ps1File) { Copy-Item $ps1File -Destination $dest -Force }
    Ok "Scripts → $dest/"
}

if (-not (Test-Path (Join-Path $SkillSrc "SKILL.md"))) {
    Err "SKILL.md not found. Are you running this from the trident repository root?"
    exit 1
}

$installClaude = $false
$installOpencode = $false
$installProject = $false
$cliModel = ""
$cliGModel = ""
$cliDModel = ""
$cliAModel = ""

if ($args.Count -gt 0) {
    foreach ($arg in $args) {
        if ($arg -match '^--model=(.+)$') { $cliModel = $Matches[1]; continue }
        if ($arg -match '^--generator-model=(.+)$') { $cliGModel = $Matches[1]; continue }
        if ($arg -match '^--discriminator-model=(.+)$') { $cliDModel = $Matches[1]; continue }
        if ($arg -match '^--arbiter-model=(.+)$') { $cliAModel = $Matches[1]; continue }
        switch ($arg) {
            "--claude"   { $installClaude = $true }
            "--opencode" { $installOpencode = $true }
            "--project"  { $installProject = $true }
            "--all"      { $installClaude = $true; $installOpencode = $true }
            "--help"     {
                Write-Host "Usage: .\install.ps1 [OPTIONS]"
                Write-Host ""
                Write-Host "Options:"
                Write-Host "  --claude                     Install for Claude Code (user-level)"
                Write-Host "  --opencode                   Install for OpenCode (user-level)"
                Write-Host "  --project                    Install into current project (.claude\)"
                Write-Host "  --all                        Install for all supported platforms"
                Write-Host "  --model=MODEL                Set same model for all Trident agents"
                Write-Host "  --generator-model=MODEL      Set Generator model"
                Write-Host "  --discriminator-model=MODEL   Set Discriminator model"
                Write-Host "  --arbiter-model=MODEL        Set Arbiter model"
                Write-Host "  --help                       Show this help"
                exit 0
            }
            default { Err "Unknown option: $arg"; exit 1 }
        }
    }
} else {
    Write-Host "Which platforms do you want to install for?"
    Write-Host ""
    $r = Read-Host "  Claude Code (user-level ~\.claude\)? [Y/n]"
    if ($r -ne "n" -and $r -ne "N") { $installClaude = $true }
    $r = Read-Host "  OpenCode (user-level ~\.config\opencode\)? [Y/n]"
    if ($r -ne "n" -and $r -ne "N") { $installOpencode = $true }
    $r = Read-Host "  Current project (.claude\ in working dir)? [y/N]"
    if ($r -eq "y" -or $r -eq "Y") { $installProject = $true }
    Write-Host ""
}

if (-not $installClaude -and -not $installOpencode -and -not $installProject) {
    Warn "No platforms selected. Nothing to do."
    exit 0
}

# Claude Code
if ($installClaude) {
    $claudeSkill = Join-Path $env:USERPROFILE ".claude\skills\trident"
    if (Test-Path (Join-Path $claudeSkill "SKILL.md")) { Info "Updating Claude Code..." }
    else { Info "Installing for Claude Code..." }

    Copy-Skill $claudeSkill
    Copy-Scripts (Join-Path $claudeSkill "scripts")
    Copy-Agents (Join-Path $env:USERPROFILE ".claude\agents")
    Copy-Commands (Join-Path $env:USERPROFILE ".claude\commands\tri")

    if ($cliModel -or $cliGModel) {
        $gm = if ($cliGModel) { $cliGModel } else { $cliModel }
        $dm = if ($cliDModel) { $cliDModel } else { $cliModel }
        $am = if ($cliAModel) { $cliAModel } else { $cliModel }
        $claudeAgents = Join-Path $env:USERPROFILE ".claude\agents"
        function Set-ClaudeModel($filePath, $model) {
            $content = Get-Content $filePath -Raw
            if ($content -match "(?m)^model:") {
                $content = $content -replace "(?m)^model:.*", "model: $model"
            } else {
                $content = $content -replace "(?m)^mode: subagent", "mode: subagent`nmodel: $model"
            }
            Set-Content $filePath $content -NoNewline
        }
        if ($gm) { Set-ClaudeModel (Join-Path $claudeAgents "trident-generator.md") $gm }
        if ($dm) { Set-ClaudeModel (Join-Path $claudeAgents "trident-discriminator.md") $dm }
        if ($am) { Set-ClaudeModel (Join-Path $claudeAgents "trident-arbiter.md") $am }
        Ok "Generator → $gm"
        Ok "Discriminator → $dm"
        Ok "Arbiter → $am"
    }

    Ok "Claude Code ready."
    Write-Host ""
}

# OpenCode
if ($installOpencode) {
    $ocSkill = Join-Path $env:USERPROFILE ".config\opencode\skills\trident"
    if (Test-Path (Join-Path $ocSkill "SKILL.md")) { Info "Updating OpenCode..." }
    else { Info "Installing for OpenCode..." }

    Copy-Skill $ocSkill
    Copy-Scripts (Join-Path $ocSkill "scripts")
    Copy-Agents (Join-Path $env:USERPROFILE ".config\opencode\agents")

    $ocCmdDir = Join-Path $env:USERPROFILE ".config\opencode\command"
    New-Item -ItemType Directory -Path $ocCmdDir -Force | Out-Null
    $triCmd = Join-Path $ScriptDir "commands\tri.md"
    if (Test-Path $triCmd) {
        Copy-Item $triCmd -Destination (Join-Path $ocCmdDir "tri.md") -Force
        Ok "Command → $ocCmdDir\tri.md"
    }

    # oh-my-opencode model configuration
    $omoConfig = Join-Path $env:USERPROFILE ".config\opencode\oh-my-opencode.json"
    $ocConfig = Join-Path $env:USERPROFILE ".config\opencode\opencode.json"
    if (Test-Path $omoConfig) {
        Info "oh-my-opencode detected."

        if ($cliModel -or $cliGModel) {
            $gm = if ($cliGModel) { $cliGModel } else { $cliModel }
            $dm = if ($cliDModel) { $cliDModel } else { $cliModel }
            $am = if ($cliAModel) { $cliAModel } else { $cliModel }
            $agentsDir = Join-Path $env:USERPROFILE ".config\opencode\agents"
            if ($gm) { Set-AgentModel (Join-Path $agentsDir "trident-generator.md") $gm }
            if ($dm) { Set-AgentModel (Join-Path $agentsDir "trident-discriminator.md") $dm }
            if ($am) { Set-AgentModel (Join-Path $agentsDir "trident-arbiter.md") $am }
            Ok "Generator → $gm"
            Ok "Discriminator → $dm"
            Ok "Arbiter → $am"
        } else {

        $mainModel = ""
        if (Test-Path $ocConfig) {
            $cfg = Get-Content $ocConfig -Raw | ConvertFrom-Json
            $mainModel = $cfg.model
        }

        $modelList = @()
        if ($mainModel) { $modelList += $mainModel }

        try {
            $models = & opencode models 2>$null
            foreach ($m in $models) {
                if ($m -and $m -ne $mainModel) { $modelList += $m }
            }
        } catch {}

        function Pick-Model($role) {
            $page = 0; $pageSize = 20; $total = $modelList.Count
            while ($true) {
                $start = $page * $pageSize
                $end = [Math]::Min($start + $pageSize, $total)
                Write-Host ""
                Write-Host "  Select model for ${role} (${total} available):"
                for ($j = $start; $j -lt $end; $j++) {
                    $label = $modelList[$j]
                    if ($j -eq 0 -and $mainModel) { $label += " (current)" }
                    Write-Host "    $($j+1)) $label"
                }
                if ($end -lt $total) { Write-Host "    N) Next page" }
                if ($page -gt 0) { Write-Host "    P) Previous page" }
                Write-Host "    C) Enter custom model"
                $pick = Read-Host "  Choose (press Enter for 1)"
                switch -Regex ($pick) {
                    "^[Nn]$" { $page++; continue }
                    "^[Pp]$" { if ($page -gt 0) { $page-- }; continue }
                    "^$"     { return $modelList[0] }
                    "^1$"    { return $modelList[0] }
                    "^[Cc]$" { return (Read-Host "  Model") }
                    "^\d+$"  {
                        $pi = [int]$pick - 1
                        if ($pi -lt $total) { return $modelList[$pi] }
                        else { return (Read-Host "  Model") }
                    }
                    default  { return $pick }
                }
            }
        }

        function Set-AgentModel($filePath, $model) {
            $content = Get-Content $filePath -Raw
            if ($content -match "(?m)^model:") {
                $content = $content -replace "(?m)^model:.*", "model: $model"
            } else {
                $content = $content -replace "(?m)^mode: subagent", "mode: subagent`nmodel: $model"
            }
            Set-Content $filePath $content -NoNewline
        }

        Write-Host ""
        Write-Host "  Trident uses three AI roles:"
        Write-Host "    Generator" -ForegroundColor Green -NoNewline; Write-Host "      — designs and implements code"
        Write-Host "    Discriminator" -ForegroundColor Red -NoNewline; Write-Host "   — scores and reviews (the critic)"
        Write-Host "    Arbiter" -ForegroundColor Yellow -NoNewline; Write-Host "        — independent final check (prevents collusion)"
        Write-Host ""
        Write-Host "  Model configuration:"
        Write-Host "    1) Same model for all three roles"
        Write-Host "    2) Different model per role (e.g. cheap for Generator, strong for reviewers)"
        Write-Host "    0) Skip"
        Write-Host ""
        $configMode = Read-Host "  Choose (press Enter for 1)"

        $agentsDir = Join-Path $env:USERPROFILE ".config\opencode\agents"
        switch ($configMode) {
            { $_ -eq "" -or $_ -eq "1" } {
                $m = Pick-Model "all Trident agents"
                if ($m) {
                    Set-AgentModel (Join-Path $agentsDir "trident-generator.md") $m
                    Set-AgentModel (Join-Path $agentsDir "trident-discriminator.md") $m
                    Set-AgentModel (Join-Path $agentsDir "trident-arbiter.md") $m
                    Ok "All Trident agents → $m"
                }
            }
            "2" {
                $gm = Pick-Model "Generator"
                $dm = Pick-Model "Discriminator"
                $am = Pick-Model "Arbiter"
                if ($gm) { Set-AgentModel (Join-Path $agentsDir "trident-generator.md") $gm }
                if ($dm) { Set-AgentModel (Join-Path $agentsDir "trident-discriminator.md") $dm }
                if ($am) { Set-AgentModel (Join-Path $agentsDir "trident-arbiter.md") $am }
                Ok "Generator → $gm"
                Ok "Discriminator → $dm"
                Ok "Arbiter → $am"
            }
            "0" {
                Info "Skipped. Trident agents will use platform default."
            }
        }
        }
    }

    Ok "OpenCode ready."
    Write-Host ""
}

# Project-Level
if ($installProject) {
    $projSkill = Join-Path (Get-Location) ".claude\skills\trident"
    if (Test-Path (Join-Path $projSkill "SKILL.md")) { Info "Updating current project..." }
    else { Info "Installing into current project..." }

    Copy-Skill $projSkill
    Copy-Scripts (Join-Path $projSkill "scripts")
    Copy-Agents (Join-Path (Get-Location) ".claude\agents")

    if ($installClaude) {
        Info "Skipping project-level commands — already installed globally."
    } else {
        Copy-Commands (Join-Path (Get-Location) ".claude\commands\tri")
    }

    if (Test-Path (Join-Path (Get-Location) ".opencode")) {
        Copy-Skill (Join-Path (Get-Location) ".opencode\skills\trident")
        Copy-Scripts (Join-Path (Get-Location) ".opencode\skills\trident\scripts")
    }

    Ok "Project-level ready."
    Write-Host "  Files added to .claude\ — commit them to share with your team."
    Write-Host ""
}

Write-Host ""
Write-Host "  Done! Trident " -NoNewline
Write-Host "v$Version" -ForegroundColor Green -NoNewline
Write-Host " installed."
Write-Host "  Run again anytime to update to the latest version."
Write-Host ""
Write-Host "  Usage:"
Write-Host "    /tri new <description>     Start a design review"
Write-Host "    /tri apply <task-slug>     Implement with Three Strikes"
Write-Host "    /tri status                Show active and completed tasks"
Write-Host "    /tri archive <task-slug>   Archive completed review"
Write-Host ""
Write-Host "  Docs: https://github.com/0xFiMo/trident"
Write-Host ""
