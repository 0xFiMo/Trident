# Trident Installation Guide

This guide is designed for both humans and AI agents. Follow the steps for your platform.

## Prerequisites

- `git` installed
- One of: Claude Code, OpenCode, or any agent tool supporting SKILL.md

## Step 1: Clone

```bash
git clone https://github.com/0xFiMo/trident.git /tmp/trident
```

## Step 2: Install for Your Platform

### Option A: Interactive Installer (recommended)

```bash
cd /tmp/trident && ./install.sh
```

The installer auto-detects your platform and asks which to set up.

### Option B: Claude Code (manual)

```bash
# Skill + templates + prompts + reference
mkdir -p ~/.claude/skills/trident/{templates,prompts,reference}
cp /tmp/trident/skills/trident/SKILL.md ~/.claude/skills/trident/
cp /tmp/trident/skills/trident/templates/*.md ~/.claude/skills/trident/templates/
cp /tmp/trident/skills/trident/prompts/*.md ~/.claude/skills/trident/prompts/
cp /tmp/trident/skills/trident/reference/*.md ~/.claude/skills/trident/reference/

# Heartbeat script
mkdir -p ~/.claude/skills/trident/scripts
cp /tmp/trident/scripts/heartbeat.sh ~/.claude/skills/trident/scripts/
chmod +x ~/.claude/skills/trident/scripts/heartbeat.sh

# Agents (Generator + Discriminator + Arbiter roles)
mkdir -p ~/.claude/agents
cp /tmp/trident/agents/trident-generator.md ~/.claude/agents/
cp /tmp/trident/agents/trident-discriminator.md ~/.claude/agents/
cp /tmp/trident/agents/trident-arbiter.md ~/.claude/agents/

# Commands (/tri new, /tri apply, /tri status, /tri archive)
mkdir -p ~/.claude/commands/tri
cp /tmp/trident/commands/tri/new.md ~/.claude/commands/tri/
cp /tmp/trident/commands/tri/apply.md ~/.claude/commands/tri/
cp /tmp/trident/commands/tri/status.md ~/.claude/commands/tri/
cp /tmp/trident/commands/tri/archive.md ~/.claude/commands/tri/
```

### Option C: OpenCode (manual)

```bash
# Skill + templates + prompts + reference
mkdir -p ~/.config/opencode/skills/trident/{templates,prompts,reference}
cp /tmp/trident/skills/trident/SKILL.md ~/.config/opencode/skills/trident/
cp /tmp/trident/skills/trident/templates/*.md ~/.config/opencode/skills/trident/templates/
cp /tmp/trident/skills/trident/prompts/*.md ~/.config/opencode/skills/trident/prompts/
cp /tmp/trident/skills/trident/reference/*.md ~/.config/opencode/skills/trident/reference/

# Heartbeat script
mkdir -p ~/.config/opencode/skills/trident/scripts
cp /tmp/trident/scripts/heartbeat.sh ~/.config/opencode/skills/trident/scripts/
chmod +x ~/.config/opencode/skills/trident/scripts/heartbeat.sh

# Agents (Generator + Discriminator + Arbiter)
mkdir -p ~/.config/opencode/agents
cp /tmp/trident/agents/trident-generator.md ~/.config/opencode/agents/
cp /tmp/trident/agents/trident-discriminator.md ~/.config/opencode/agents/
cp /tmp/trident/agents/trident-arbiter.md ~/.config/opencode/agents/

# Command
mkdir -p ~/.config/opencode/command
cp /tmp/trident/commands/tri.md ~/.config/opencode/command/tri.md
```

### Option D: Project-Level (shared with team)

From your project root:

```bash
# Claude Code
mkdir -p .claude/skills/trident/scripts .claude/agents .claude/commands/tri
cp /tmp/trident/agents/*.md .claude/agents/
cp /tmp/trident/skills/trident/SKILL.md .claude/skills/trident/
cp /tmp/trident/scripts/heartbeat.sh .claude/skills/trident/scripts/
chmod +x .claude/skills/trident/scripts/heartbeat.sh
cp /tmp/trident/agents/*.md .claude/agents/
cp /tmp/trident/commands/tri/*.md .claude/commands/tri/

# OpenCode (if .opencode/ exists)
if [ -d ".opencode" ]; then
  mkdir -p .opencode/skills/trident/scripts
  cp /tmp/trident/skills/trident/SKILL.md .opencode/skills/trident/
  cp /tmp/trident/scripts/heartbeat.sh .opencode/skills/trident/scripts/
  chmod +x .opencode/skills/trident/scripts/heartbeat.sh
fi
```

### Windows Note

All platforms include both `heartbeat.sh` (bash) and `heartbeat.ps1` (PowerShell).
On Windows without WSL, the agent will use `heartbeat.ps1` automatically.
No additional setup needed — both scripts are copied during installation.

## Step 3: Verify

Start a new agent session and type:

```
/tri status
```

If the command is recognized, installation is complete.

## Updating

Run the installer again — it detects existing installations and updates in place:

```bash
cd /tmp/trident && git pull && ./install.sh
```

## Usage

```
/tri new "fix memory leak on disconnect"     ← Design it
/tri apply                                    ← Build it
/tri archive                                  ← Ship it
```

Full documentation: https://github.com/0xFiMo/trident
