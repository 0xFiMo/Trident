#!/usr/bin/env bash
set -euo pipefail

# Trident Design Review — Multi-Platform Installer
# https://github.com/0xFiMo/trident

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/trident"
AGENTS_SRC="$SCRIPT_DIR/agents"
COMMANDS_SRC="$SCRIPT_DIR/commands/tri"
SCRIPTS_SRC="$SCRIPT_DIR/scripts"
VERSION=$(grep -m1 '## \[' "$SCRIPT_DIR/CHANGELOG.md" 2>/dev/null | sed 's/.*\[\(.*\)\].*/\1/')

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
echo -e "  Trident Design Review — Installer (${GREEN}v${VERSION:-unknown}${NC})"
echo "  One agent skill. Three adversarial minds."
echo ""

# ─── Platform Selection ──────────────────────────────────────────

install_claude=false
install_opencode=false
install_project=false
cli_model=""
cli_g_model=""
cli_d_model=""
cli_a_model=""

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        case "$arg" in
            --claude)   install_claude=true ;;
            --opencode) install_opencode=true ;;
            --project)  install_project=true ;;
            --all)      install_claude=true; install_opencode=true ;;
            --model=*)  cli_model="${arg#--model=}" ;;
            --generator-model=*)     cli_g_model="${arg#--generator-model=}" ;;
            --discriminator-model=*) cli_d_model="${arg#--discriminator-model=}" ;;
            --arbiter-model=*)       cli_a_model="${arg#--arbiter-model=}" ;;
            --help|-h)
                echo "Usage: ./install.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --claude                     Install for Claude Code (user-level)"
                echo "  --opencode                   Install for OpenCode (user-level)"
                echo "  --project                    Install into current project (.claude/)"
                echo "  --all                        Install for all supported platforms"
                echo "  --model=MODEL                Set same model for all Trident agents"
                echo "  --generator-model=MODEL      Set Generator model"
                echo "  --discriminator-model=MODEL   Set Discriminator model"
                echo "  --arbiter-model=MODEL        Set Arbiter model"
                echo "  --help                       Show this help"
                echo ""
                echo "Examples:"
                echo "  ./install.sh --opencode --model=minimax/MiniMax-M2.7"
                echo "  ./install.sh --all --generator-model=minimax/MiniMax-M2.7 --discriminator-model=anthropic/claude-opus-4-6 --arbiter-model=anthropic/claude-opus-4-6"
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
    # Copy subdirectories (templates, prompts, reference)
    for subdir in templates prompts reference; do
        if [ -d "$SKILL_SRC/$subdir" ]; then
            mkdir -p "$dest/$subdir"
            cp "$SKILL_SRC/$subdir"/*.md "$dest/$subdir/"
        fi
    done
    ok "Skill → $dest/ (with templates, prompts, reference)"
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

    # Model configuration for Claude Code agents
    if [[ -n "$cli_model" || -n "$cli_g_model" ]]; then
        gm="${cli_g_model:-$cli_model}"
        dm="${cli_d_model:-$cli_model}"
        am="${cli_a_model:-$cli_model}"
        claude_agents="$HOME/.claude/agents"
        set_claude_model() {
            local f="$1" m="$2"
            if [[ -f "$f" ]] && ! grep -q '^model:' "$f"; then
                sed -i "/^mode: subagent/a model: $m" "$f"
            elif [[ -f "$f" ]]; then
                sed -i "s|^model:.*|model: $m|" "$f"
            fi
        }
        [[ -n "$gm" ]] && set_claude_model "$claude_agents/trident-generator.md" "$gm"
        [[ -n "$dm" ]] && set_claude_model "$claude_agents/trident-discriminator.md" "$dm"
        [[ -n "$am" ]] && set_claude_model "$claude_agents/trident-arbiter.md" "$am"
        ok "Generator → $gm"
        ok "Discriminator → $dm"
        ok "Arbiter → $am"
    fi

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
    copy_agents "$HOME/.config/opencode/agents"

    oc_cmd_dir="$HOME/.config/opencode/command"
    mkdir -p "$oc_cmd_dir"
    if [[ -f "$SCRIPT_DIR/commands/tri.md" ]]; then
        cp "$SCRIPT_DIR/commands/tri.md" "$oc_cmd_dir/tri.md"
        ok "Command → $oc_cmd_dir/tri.md"
    else
        warn "OpenCode command file (commands/tri.md) not found. Skipping."
    fi

    # If oh-my-opencode detected, inject model into agent .md files
    omo_config="$HOME/.config/opencode/oh-my-opencode.json"
    oc_config="$HOME/.config/opencode/opencode.json"
    set_agent_model() {
        local agent_file="$1" model="$2"
        if [[ -f "$agent_file" ]] && ! grep -q '^model:' "$agent_file"; then
            sed -i "/^mode: subagent/a model: $model" "$agent_file"
        elif [[ -f "$agent_file" ]]; then
            sed -i "s|^model:.*|model: $model|" "$agent_file"
        fi
    }

    agents_dir="$HOME/.config/opencode/agents"

    if [[ -f "$omo_config" ]]; then
        info "oh-my-opencode detected."

        # If CLI flags provided, skip interactive
        if [[ -n "$cli_model" || -n "$cli_g_model" ]]; then
            gm="${cli_g_model:-$cli_model}"
            dm="${cli_d_model:-$cli_model}"
            am="${cli_a_model:-$cli_model}"
            [[ -n "$gm" ]] && set_agent_model "$agents_dir/trident-generator.md" "$gm"
            [[ -n "$dm" ]] && set_agent_model "$agents_dir/trident-discriminator.md" "$dm"
            [[ -n "$am" ]] && set_agent_model "$agents_dir/trident-arbiter.md" "$am"
            ok "Generator → $gm"
            ok "Discriminator → $dm"
            ok "Arbiter → $am"
        else

        main_model=""
        if [[ -f "$oc_config" ]]; then
            main_model=$(grep '"model"' "$oc_config" 2>/dev/null | head -1 | sed 's/.*"model"[[:space:]]*:[[:space:]]*"//;s/".*//')
        fi

        available_models=""
        if command -v opencode &>/dev/null; then
            available_models=$(opencode models 2>/dev/null)
        fi

        model_list=()
        if [[ -n "$main_model" ]]; then
            model_list+=("$main_model")
        fi
        while IFS= read -r m; do
            if [[ -n "$m" && "$m" != "$main_model" ]]; then
                model_list+=("$m")
            fi
        done <<< "$available_models"

        echo ""
        echo "  Trident uses three AI roles:"
        echo -e "    ${GREEN}Generator${NC}      — designs and implements code"
        echo -e "    ${RED}Discriminator${NC}   — scores and reviews (the critic)"
        echo -e "    ${YELLOW}Arbiter${NC}        — independent final check (prevents collusion)"
        echo ""
        echo "  Model configuration:"
        echo "    1) Same model for all three roles"
        echo "    2) Different model per role (e.g. cheap for Generator, strong for reviewers)"
        echo "    0) Skip"
        echo ""
        echo -n "  Choose (press Enter for 1): "
        read -r config_mode

        pick_model() {
            local role="$1"
            local page=0 page_size=20 total=${#model_list[@]}
            while true; do
                local start=$((page * page_size))
                local end=$((start + page_size))
                [[ $end -gt $total ]] && end=$total

                echo "" >&2
                echo "  Select model for $role (${total} available):" >&2
                for ((j=start; j<end; j++)); do
                    local label="${model_list[$j]}"
                    [[ "$label" == "$main_model" ]] && label="$label (current)"
                    echo "    $((j+1))) $label" >&2
                done
                [[ $end -lt $total ]] && echo "    N) Next page" >&2
                [[ $page -gt 0 ]] && echo "    P) Previous page" >&2
                echo "    C) Enter custom model" >&2
                echo -n "  Choose (press Enter for 1): " >&2
                read -r pick
                case "$pick" in
                    [Nn]) page=$((page + 1)); continue ;;
                    [Pp]) [[ $page -gt 0 ]] && page=$((page - 1)); continue ;;
                    ""|1) echo "${model_list[0]:-$main_model}"; return ;;
                    [Cc]) echo -n "  Model: " >&2; read -r cm; echo "$cm"; return ;;
                    [0-9]*)
                        local pi=$((pick - 1))
                        if [[ $pi -lt $total ]]; then echo "${model_list[$pi]}"; return
                        else echo -n "  Model: " >&2; read -r cm; echo "$cm"; return; fi ;;
                    *) echo "$pick"; return ;;
                esac
            done
        }

        case "$config_mode" in
            ""|1)
                trident_model=$(pick_model "all Trident agents")
                if [[ -n "$trident_model" ]]; then
                    set_agent_model "$agents_dir/trident-generator.md" "$trident_model"
                    set_agent_model "$agents_dir/trident-discriminator.md" "$trident_model"
                    set_agent_model "$agents_dir/trident-arbiter.md" "$trident_model"
                    ok "All Trident agents → $trident_model"
                fi
                ;;
            2)
                g_model=$(pick_model "Generator")
                d_model=$(pick_model "Discriminator")
                a_model=$(pick_model "Arbiter")
                [[ -n "$g_model" ]] && set_agent_model "$agents_dir/trident-generator.md" "$g_model"
                [[ -n "$d_model" ]] && set_agent_model "$agents_dir/trident-discriminator.md" "$d_model"
                [[ -n "$a_model" ]] && set_agent_model "$agents_dir/trident-arbiter.md" "$a_model"
                ok "Generator → $g_model"
                ok "Discriminator → $d_model"
                ok "Arbiter → $a_model"
                ;;
            0)
                info "Skipped. Trident agents will use platform default (sisyphus-junior model)."
                ;;
        esac
        fi
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

    if $install_claude; then
        info "Skipping project-level commands — already installed globally."
    else
        copy_commands ".claude/commands/tri"
    fi

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
echo -e "  Done! Trident ${GREEN}v${VERSION:-unknown}${NC} installed."
echo "  Run again anytime to update to the latest version."
echo ""
echo "  Usage:"
echo "    /tri new <description>     Start a design review"
echo "    /tri apply <task-slug>     Implement with Three Strikes"
echo "    /tri status                Show active and completed tasks"
echo "    /tri archive <task-slug>   Archive completed review"
echo ""
echo "  Docs: https://github.com/0xFiMo/trident"
echo ""
