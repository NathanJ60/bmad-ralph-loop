#!/bin/bash
#
# BMAD Ralph Loop - Installation Script
# =======================================
#
# This script installs Ralph Loop scripts to your system.
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_SCRIPT="ralph-loop-core.sh"
CLAUDE_SCRIPT="claude-ralph-loop.sh"
CODEX_SCRIPT="codex-ralph-loop.sh"
CLAUDE_BINARY="claude-ralph-loop"
CODEX_BINARY="codex-ralph-loop"

echo ""
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}   BMAD Ralph Loop Installer    ${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Check dependencies
echo -e "${BLUE}[i]${NC} Checking dependencies..."

missing_deps=()

# Check Claude Code CLI
has_claude=false
if command -v claude &> /dev/null; then
    has_claude=true
    echo -e "${GREEN}[+]${NC} Claude Code CLI found: $(claude --version 2>/dev/null || echo 'installed')"
else
    echo -e "${YELLOW}[!]${NC} Claude Code CLI not found"
fi

# Check OpenAI Codex CLI
has_codex=false
if command -v codex &> /dev/null; then
    has_codex=true
    echo -e "${GREEN}[+]${NC} OpenAI Codex CLI found"
else
    echo -e "${YELLOW}[!]${NC} OpenAI Codex CLI not found"
fi

# Require at least one provider
if [[ "$has_claude" == "false" && "$has_codex" == "false" ]]; then
    missing_deps+=("claude-or-codex")
fi

# Check yq
if command -v yq &> /dev/null; then
    echo -e "${GREEN}[+]${NC} yq found: $(yq --version 2>/dev/null | head -1)"
else
    missing_deps+=("yq")
    echo -e "${RED}[x]${NC} yq not found"
fi

# Check bash version
bash_version="${BASH_VERSINFO[0]}"
if [[ "$bash_version" -ge 4 ]]; then
    echo -e "${GREEN}[+]${NC} Bash version: $BASH_VERSION"
else
    echo -e "${YELLOW}[!]${NC} Bash version $BASH_VERSION (4+ recommended)"
fi

# Check git
if command -v git &> /dev/null; then
    echo -e "${GREEN}[+]${NC} Git found: $(git --version)"
else
    echo -e "${YELLOW}[!]${NC} Git not found (optional, for auto-commit)"
fi

echo ""

# Handle missing dependencies
if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo -e "${YELLOW}[!]${NC} Missing dependencies: ${missing_deps[*]}"
    echo ""

    for dep in "${missing_deps[@]}"; do
        case "$dep" in
            claude-or-codex)
                echo "Install a supported agent CLI:"
                echo "  - Claude Code CLI: https://claude.ai"
                echo "  - OpenAI Codex CLI: https://developers.openai.com/codex/cli"
                echo ""
                ;;
            yq)
                echo "Install yq:"
                if [[ "$(uname)" == "Darwin" ]]; then
                    echo "  brew install yq"
                else
                    echo "  sudo snap install yq"
                    echo "  # or: sudo apt install yq"
                fi
                echo ""

                # Offer to install yq
                if command -v brew &> /dev/null; then
                    read -p "Install yq with Homebrew now? [y/N]: " install_yq
                    if [[ "$install_yq" =~ ^[Yy] ]]; then
                        echo ""
                        echo -e "${BLUE}[i]${NC} Installing yq..."
                        brew install yq
                        echo -e "${GREEN}[+]${NC} yq installed successfully"
                    fi
                fi
                ;;
        esac
    done

    # Check if no provider is available
    if [[ " ${missing_deps[*]} " =~ " claude-or-codex " ]]; then
        echo ""
        echo -e "${RED}[x]${NC} Cannot continue without an agent CLI"
        echo "    Install Claude Code CLI or OpenAI Codex CLI first"
        exit 1
    fi
fi

# Choose installation location
echo -e "${BLUE}[i]${NC} Choose installation location:"
echo ""
echo "  1) /usr/local/bin (system-wide, requires sudo)"
echo "  2) ~/bin (user only)"
echo "  3) ~/.local/bin (user only, XDG standard)"
echo "  4) Custom path"
echo ""

read -p "Choose [1-4] (default: 2): " choice

case "$choice" in
    1)
        INSTALL_DIR="/usr/local/bin"
        NEED_SUDO=true
        ;;
    3)
        INSTALL_DIR="$HOME/.local/bin"
        NEED_SUDO=false
        ;;
    4)
        read -p "Enter custom path: " INSTALL_DIR
        NEED_SUDO=false
        ;;
    *)
        INSTALL_DIR="$HOME/bin"
        NEED_SUDO=false
        ;;
esac

# Create directory if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo -e "${BLUE}[i]${NC} Creating directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

# Install script
echo ""
echo -e "${BLUE}[i]${NC} Installing to: $INSTALL_DIR"

if [[ "$NEED_SUDO" == "true" ]]; then
    sudo cp "$SCRIPT_DIR/$CORE_SCRIPT" "$INSTALL_DIR/$CORE_SCRIPT"
    sudo cp "$SCRIPT_DIR/$CLAUDE_SCRIPT" "$INSTALL_DIR/$CLAUDE_BINARY"
    sudo cp "$SCRIPT_DIR/$CODEX_SCRIPT" "$INSTALL_DIR/$CODEX_BINARY"
    sudo chmod +x "$INSTALL_DIR/$CLAUDE_BINARY" "$INSTALL_DIR/$CODEX_BINARY"
else
    cp "$SCRIPT_DIR/$CORE_SCRIPT" "$INSTALL_DIR/$CORE_SCRIPT"
    cp "$SCRIPT_DIR/$CLAUDE_SCRIPT" "$INSTALL_DIR/$CLAUDE_BINARY"
    cp "$SCRIPT_DIR/$CODEX_SCRIPT" "$INSTALL_DIR/$CODEX_BINARY"
    chmod +x "$INSTALL_DIR/$CLAUDE_BINARY" "$INSTALL_DIR/$CODEX_BINARY"
fi

echo -e "${GREEN}[+]${NC} Installed successfully!"

# Check if install dir is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo -e "${YELLOW}[!]${NC} $INSTALL_DIR is not in your PATH"
    echo ""
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
    echo "Then run: source ~/.bashrc (or ~/.zshrc)"
fi

# Verify installation
echo ""
verified_any=false
if command -v "$CLAUDE_BINARY" &> /dev/null; then
    verified_any=true
    echo -e "${GREEN}[+]${NC} $CLAUDE_BINARY installed!"
fi
if command -v "$CODEX_BINARY" &> /dev/null; then
    verified_any=true
    echo -e "${GREEN}[+]${NC} $CODEX_BINARY installed!"
fi

echo ""
if [[ "$verified_any" == "true" ]]; then
    echo "Run 'claude-ralph-loop --help' or 'codex-ralph-loop --help' to get started"
else
    echo -e "${YELLOW}[!]${NC} Installation complete, but commands not found in PATH yet"
    echo ""
    echo "After updating your PATH, run: claude-ralph-loop --help"
fi

echo ""
echo -e "${CYAN}================================${NC}"
echo -e "${GREEN}  Installation Complete!       ${NC}"
echo -e "${CYAN}================================${NC}"
echo ""
