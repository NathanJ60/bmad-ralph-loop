#!/bin/bash
#
# BMAD Ralph Loop - Installation Script
# =======================================
#
# This script installs claude-ralph-loop to your system.
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
SCRIPT_NAME="claude-ralph-loop.sh"
BINARY_NAME="claude-ralph-loop"

echo ""
echo -e "${CYAN}================================${NC}"
echo -e "${CYAN}   BMAD Ralph Loop Installer    ${NC}"
echo -e "${CYAN}================================${NC}"
echo ""

# Check dependencies
echo -e "${BLUE}[i]${NC} Checking dependencies..."

missing_deps=()

# Check Claude Code CLI
if command -v claude &> /dev/null; then
    echo -e "${GREEN}[+]${NC} Claude Code CLI found: $(claude --version 2>/dev/null || echo 'installed')"
else
    missing_deps+=("claude")
    echo -e "${RED}[x]${NC} Claude Code CLI not found"
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
            claude)
                echo "Install Claude Code CLI from: https://claude.ai"
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

    # Check if claude is still missing
    if [[ " ${missing_deps[*]} " =~ " claude " ]]; then
        echo ""
        echo -e "${RED}[x]${NC} Cannot continue without Claude Code CLI"
        echo "    Please install it first from: https://claude.ai"
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
echo -e "${BLUE}[i]${NC} Installing to: $INSTALL_DIR/$BINARY_NAME"

if [[ "$NEED_SUDO" == "true" ]]; then
    sudo cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$BINARY_NAME"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
else
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
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
if command -v $BINARY_NAME &> /dev/null; then
    echo -e "${GREEN}[+]${NC} Installation verified!"
    echo ""
    echo "Run 'claude-ralph-loop --help' to get started"
else
    echo -e "${YELLOW}[!]${NC} Installation complete, but command not found in PATH yet"
    echo ""
    echo "After updating your PATH, run: claude-ralph-loop --help"
fi

echo ""
echo -e "${CYAN}================================${NC}"
echo -e "${GREEN}  Installation Complete!       ${NC}"
echo -e "${CYAN}================================${NC}"
echo ""
