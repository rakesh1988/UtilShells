#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_DIR="$HOME/machine-backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Creating backup in:${NC} $BACKUP_DIR"
echo "=================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup file if it exists
backup_file() {
    local file="$1"
    local dest="$BACKUP_DIR/$(basename "$file")"
    if [ -f "$file" ]; then
        cp "$file" "$dest" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Backed up: $(basename "$file")"
    fi
}

# Function to backup directory if it exists
backup_dir() {
    local dir="$1"
    local dest="$BACKUP_DIR/$(basename "$dir")"
    if [ -d "$dir" ]; then
        cp -r "$dir" "$dest" 2>/dev/null
        echo -e "  ${GREEN}✓${NC} Backed up: $(basename "$dir")/"
    fi
}

# 1. Dotfiles
echo -e "\n${CYAN}Backing up dotfiles:${NC}"
backup_file "$HOME/.zshrc"
backup_file "$HOME/.bashrc"
backup_file "$HOME/.bash_profile"
backup_file "$HOME/.profile"
backup_file "$HOME/.gitconfig"
backup_file "$HOME/.gitignore_global"
backup_file "$HOME/.npmrc"
backup_file "$HOME/.yarnrc"
backup_file "$HOME/.gemrc"
backup_file "$HOME/.p10k.zsh"

# 2. SSH Keys
echo -e "\n${CYAN}Backing up SSH keys:${NC}"
if [ -d "$HOME/.ssh" ]; then
    mkdir -p "$BACKUP_DIR/ssh"
    cp -r "$HOME/.ssh/"* "$BACKUP_DIR/ssh/" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Backed up SSH keys"
else
    echo -e "  ${YELLOW}⚠${NC} No SSH directory found"
fi

# 3. GPG Keys
echo -e "\n${CYAN}Backing up GPG keys:${NC}"
if [ -d "$HOME/.gnupg" ]; then
    mkdir -p "$BACKUP_DIR/gnupg"
    cp -r "$HOME/.gnupg/"* "$BACKUP_DIR/gnupg/" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Backed up GPG keys"
else
    echo -e "  ${YELLOW}⚠${NC} No GPG directory found"
fi

# 4. VS Code
echo -e "\n${CYAN}Backing up VS Code:${NC}"
VSCODE_PATH="$HOME/Library/Application Support/Code/User"
if [ -d "$VSCODE_PATH" ]; then
    mkdir -p "$BACKUP_DIR/vscode"
    cp "$VSCODE_PATH/"*.json "$BACKUP_DIR/vscode/" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Backed up VS Code settings"
else
    echo -e "  ${YELLOW}⚠${NC} VS Code not found"
fi

# 5. Custom scripts
echo -e "\n${CYAN}Backing up custom scripts:${NC}"
backup_dir "$HOME/bin"
backup_dir "$HOME/scripts"

# 6. Export package lists
echo -e "\n${CYAN}Exporting package lists:${NC}"

# Homebrew
if command_exists brew; then
    brew list --formula > "$BACKUP_DIR/brew-formulas.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Homebrew formulas: $(wc -l < "$BACKUP_DIR/brew-formulas.txt" 2>/dev/null || echo '0') packages"
    
    brew list --cask > "$BACKUP_DIR/brew-casks.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Homebrew casks: $(wc -l < "$BACKUP_DIR/brew-casks.txt" 2>/dev/null || echo '0') packages"
    
    brew tap > "$BACKUP_DIR/brew-taps.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Homebrew taps: $(wc -l < "$BACKUP_DIR/brew-taps.txt" 2>/dev/null || echo '0') taps"
else
    echo -e "  ${YELLOW}⚠${NC} Homebrew not installed"
fi

# Node.js global packages
if command_exists npm; then
    npm list -g --depth=0 --parseable 2>/dev/null | sed 's/.*\/node_modules\///' | sort -u > "$BACKUP_DIR/npm-global.txt"
    echo -e "  ${GREEN}✓${NC} NPM global packages: $(wc -l < "$BACKUP_DIR/npm-global.txt" 2>/dev/null || echo '0') packages"
else
    echo -e "  ${YELLOW}⚠${NC} NPM not installed"
fi

# Python packages
if command_exists pip3; then
    pip3 list --format=freeze > "$BACKUP_DIR/python3-packages.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Python3 packages: $(wc -l < "$BACKUP_DIR/python3-packages.txt" 2>/dev/null || echo '0') packages"
elif command_exists pip; then
    pip list --format=freeze > "$BACKUP_DIR/python-packages.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Python packages: $(wc -l < "$BACKUP_DIR/python-packages.txt" 2>/dev/null || echo '0') packages"
else
    echo -e "  ${YELLOW}⚠${NC} Pip not installed"
fi

# VS Code extensions
if command_exists code; then
    code --list-extensions > "$BACKUP_DIR/vscode-extensions.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} VS Code extensions: $(wc -l < "$BACKUP_DIR/vscode-extensions.txt" 2>/dev/null || echo '0') extensions"
else
    echo -e "  ${YELLOW}⚠${NC} VS Code command not available"
fi

# Mac App Store apps
if command_exists mas; then
    mas list > "$BACKUP_DIR/mac-app-store.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Mac App Store apps: $(wc -l < "$BACKUP_DIR/mac-app-store.txt" 2>/dev/null || echo '0') apps"
else
    echo -e "  ${YELLOW}⚠${NC} mas (Mac App Store CLI) not installed"
fi

# Ruby gems
if command_exists gem; then
    gem list --local > "$BACKUP_DIR/ruby-gems.txt" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Ruby gems: $(wc -l < "$BACKUP_DIR/ruby-gems.txt" 2>/dev/null || echo '0') gems"
else
    echo -e "  ${YELLOW}⚠${NC} Ruby gems not installed"
fi
