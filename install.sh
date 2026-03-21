#!/usr/bin/env bash
set -euo pipefail

# Trident Design Review — Multi-Platform Installer
# https://github.com/0xFiMo/trident

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/trident"
AGENTS_SRC="$SCRIPT_DIR/agents"
COMMANDS_SRC="$SCRIPT_DIR/commands/tri"
SCRIPTS_SRC="$SCRIPT_DIR/scripts"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

echo ""
echo "  Trident Design Review — Installer"
echo "  Adversarial design review for AI coding agents."
echo ""

# ─── Platform Selection ──────────────────────────────────────────

install_claude=false
install_opencode=false
install_project=false

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        case "$arg" in
            --claude)   install_claude=true ;;
            --opencode) install_opencode=true ;;
            --project)  install_project=true ;;
            --all)      install_claude=true; install_opencode=true ;;
            --help|-h)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --claude     Install for Claude Code (user-level)"
                echo "  --opencode   Install for OpenCode (user-level)"
                echo "  --project    Install into current project (.claude/)"
                echo "  --all        Install for all supported platforms"
                echo "  --help       Show this help"
                echo ""
                echo "If no options given, interactive mode is used."
                exit 0
                ;;
            *)
                err "Unknown option: $arg"
                exit 1
                ;;
        esac
    done
else
    # Interactive mode
    echo "Which platforms do you want to install for?"
    echo ""

    read -p "  Claude Code (user-level ~/.claude/)? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && install_claude=true

    read -p "  OpenCode (user-level ~/.config/opencode/)? [Y/n] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Nn]$ ]] && install_opencode=true

    read -p "  Current project (.claude/ in working dir)? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_project=true

    echo ""
fi

if ! $install_claude && ! $install_opencode && ! $install_project; then
    warn "No platforms selected. Nothing to do."
    exit 0
fi

# ─── Verify Source Files ─────────────────────────────────────────

if [[ ! -f "$SKILL_SRC/SKILL.md" ]]; then
    err "SKILL.md not found at $SKILL_SRC/SKILL.md"
    err "Are you running this from the trident repository root?"
    exit 1
fi

# ─── Install Functions ───────────────────────────────────────────

copy_skill() {
    local dest="$1"
    mkdir -p "$dest"
    cp "$SKILL_SRC/SKILL.md" "$dest/SKILL.md"
    ok "Skill → $dest/"
}

copy_agents() {
    local dest="$1"
    mkdir -p "$dest"
    cp "$AGENTS_SRC/trident-generator.md" "$dest/"
    cp "$AGENTS_SRC/trident-discriminator.md" "$dest/"
    cp "$AGENTS_SRC/trident-arbiter.md" "$dest/"
    ok "Agents → $dest/"
}

copy_commands() {
    local dest="$1"
    mkdir -p "$dest"
    cp "$COMMANDS_SRC"/*.md "$dest/"
    ok "Commands → $dest/"
}

copy_scripts() {
    local dest="$1"
    mkdir -p "$dest"
    cp "$SCRIPTS_SRC"/heartbeat.sh "$dest/"
    chmod +x "$dest/heartbeat.sh"
    if [ -f "$SCRIPTS_SRC/heartbeat.ps1" ]; then
        cp "$SCRIPTS_SRC"/heartbeat.ps1 "$dest/"
    fi
    ok "Scripts → $dest/"
}

check_existing() {
    local path="$1"
    if [[ -f "$path" ]]; then
        return 0
    fi
    return 1
}

# ─── Claude Code (User-Level) ───────────────────────────────────

if $install_claude; then
    if check_existing "$HOME/.claude/skills/trident/SKILL.md"; then
        info "Updating Claude Code (user-level)..."
    else
        info "Installing for Claude Code (user-level)..."
    fi

    copy_skill "$HOME/.claude/skills/trident"
    copy_scripts "$HOME/.claude/skills/trident/scripts"
    copy_agents "$HOME/.claude/agents"
    copy_commands "$HOME/.claude/commands/tri"

    ok "Claude Code ready."
    echo ""
fi

# ─── OpenCode (User-Level) ──────────────────────────────────────

if $install_opencode; then
    if check_existing "$HOME/.config/opencode/skills/trident/SKILL.md"; then
        info "Updating OpenCode (user-level)..."
    else
        info "Installing for OpenCode (user-level)..."
    fi

    copy_skill "$HOME/.config/opencode/skills/trident"
    copy_scripts "$HOME/.config/opencode/skills/trident/scripts"

    oc_cmd_dir="$HOME/.config/opencode/command"
    mkdir -p "$oc_cmd_dir"
    if [[ -f "$SCRIPT_DIR/commands/tri.md" ]]; then
        cp "$SCRIPT_DIR/commands/tri.md" "$oc_cmd_dir/tri.md"
        ok "Command → $oc_cmd_dir/tri.md"
    else
        warn "OpenCode command file (commands/tri.md) not found. Skipping."
    fi

    ok "OpenCode ready."
    echo ""
fi

# ─── Project-Level ──────────────────────────────────────────────

if $install_project; then
    if check_existing ".claude/skills/trident/SKILL.md"; then
        info "Updating current project..."
    else
        info "Installing into current project..."
    fi

    copy_skill ".claude/skills/trident"
    copy_scripts ".claude/skills/trident/scripts"
    copy_agents ".claude/agents"
    copy_commands ".claude/commands/tri"

    # Also install OpenCode skill + scripts into project if .opencode/ exists
    if [[ -d ".opencode" ]]; then
        copy_skill ".opencode/skills/trident"
        copy_scripts ".opencode/skills/trident/scripts"
    fi

    ok "Project-level ready."
    echo "  Files added to .claude/ — commit them to share with your team."
    echo ""
fi

# ─── Summary ────────────────────────────────────────────────────

echo ""
echo "  Done! Run again anytime to update to the latest version."
echo ""
echo "  Usage:"
echo "    /tri new <description>     Start a design review"
echo "    /tri apply <task-slug>     Implement with Three Strikes"
echo "    /tri status                Show active and completed tasks"
echo "    /tri archive <task-slug>   Archive completed review"
echo ""
echo "  Docs: https://github.com/0xFiMo/trident"
echo ""
