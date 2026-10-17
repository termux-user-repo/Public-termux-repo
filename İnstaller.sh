#!/bin/bash

################################################################################
# Termux Mods Installer
# Installs and manages modifications for Termux
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODS_DIR="$SCRIPT_DIR/mods"
INSTALL_LOG="$SCRIPT_DIR/.install.log"

################################################################################
# Functions
################################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$INSTALL_LOG"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$INSTALL_LOG"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$INSTALL_LOG"
}

check_termux() {
    if [ ! -d "$HOME/.termux" ]; then
        log_error "Not running in Termux environment!"
        log_error "This installer only works in Termux."
        exit 1
    fi
    log_info "Termux environment detected ✓"
}

check_permissions() {
    if [ "$EUID" -eq 0 ]; then
        log_warn "Running as root - this is not recommended"
    fi
    log_info "Checking write permissions..."
    if [ ! -w "$HOME" ]; then
        log_error "No write permissions to home directory"
        exit 1
    fi
    log_info "Write permissions OK ✓"
}

list_mods() {
    echo -e "\n${BLUE}Available Mods:${NC}"
    if [ ! -d "$MODS_DIR" ]; then
        log_error "Mods directory not found: $MODS_DIR"
        return 1
    fi
    
    local count=0
    for mod_dir in "$MODS_DIR"/*; do
        if [ -d "$mod_dir" ] && [ -f "$mod_dir/install.sh" ]; then
            local mod_name=$(basename "$mod_dir")
            echo "  • $mod_name"
            ((count++))
        fi
    done
    
    if [ $count -eq 0 ]; then
        log_warn "No mods found in $MODS_DIR"
        return 1
    fi
    echo ""
}

install_all_mods() {
    log_info "Starting installation of all mods..."
    
    if [ ! -d "$MODS_DIR" ]; then
        log_error "Mods directory not found: $MODS_DIR"
        exit 1
    fi
    
    local installed=0
    local failed=0
    
    for mod_dir in "$MODS_DIR"/*; do
        if [ -d "$mod_dir" ]; then
            local mod_name=$(basename "$mod_dir")
            local install_script="$mod_dir/install.sh"
            
            if [ -f "$install_script" ]; then
                log_info "Installing: $mod_name..."
                
                if bash "$install_script"; then
                    log_success "$mod_name installed successfully"
                    ((installed++))
                else
                    log_error "$mod_name installation failed"
                    ((failed++))
                fi
            else
                log_warn "No install.sh found in $mod_dir, skipping..."
            fi
        fi
    done
    
    echo ""
    log_info "Installation Summary:"
    log_success "Installed: $installed mod(s)"
    if [ $failed -gt 0 ]; then
        log_error "Failed: $failed mod(s)"
        return 1
    fi
}

install_specific_mod() {
    local mod_name="$1"
    local mod_dir="$MODS_DIR/$mod_name"
    local install_script="$mod_dir/install.sh"
    
    if [ ! -d "$mod_dir" ]; then
        log_error "Mod not found: $mod_name"
        return 1
    fi
    
    if [ ! -f "$install_script" ]; then
        log_error "No install script found for: $mod_name"
        return 1
    fi
    
    log_info "Installing mod: $mod_name..."
    bash "$install_script"
}

uninstall_all_mods() {
    log_info "Starting uninstallation of all mods..."
    
    local uninstalled=0
    local failed=0
    
    for mod_dir in "$MODS_DIR"/*; do
        if [ -d "$mod_dir" ]; then
            local mod_name=$(basename "$mod_dir")
            local install_script="$mod_dir/install.sh"
            
            if [ -f "$install_script" ]; then
                log_info "Uninstalling: $mod_name..."
                
                if bash "$install_script" --uninstall; then
                    log_success "$mod_name uninstalled"
                    ((uninstalled++))
                else
                    log_error "$mod_name uninstallation failed"
                    ((failed++))
                fi
            fi
        fi
    done
    
    echo ""
    log_info "Uninstallation Summary:"
    log_success "Uninstalled: $uninstalled mod(s)"
    if [ $failed -gt 0 ]; then
        log_error "Failed: $failed mod(s)"
    fi
}

uninstall_specific_mod() {
    local mod_name="$1"
    local mod_dir="$MODS_DIR/$mod_name"
    local install_script="$mod_dir/install.sh"
    
    if [ ! -d "$mod_dir" ]; then
        log_error "Mod not found: $mod_name"
        return 1
    fi
    
    if [ ! -f "$install_script" ]; then
        log_error "No install script found for: $mod_name"
        return 1
    fi
    
    log_info "Uninstalling mod: $mod_name..."
    bash "$install_script" --uninstall
}

show_usage() {
    cat << EOF
${BLUE}Termux Mods Installer${NC}

Usage: bash installer.sh [COMMAND] [MOD_NAME]

Commands:
    install              Install all mods (default)
    install <mod_name>   Install a specific mod
    uninstall            Uninstall all mods
    uninstall <mod_name> Uninstall a specific mod
    list                 List available mods
    help                 Show this help message

Examples:
    bash installer.sh                    # Install all mods
    bash installer.sh install Csharp     # Install Csharp mod
    bash installer.sh uninstall Python   # Uninstall Python mod
    bash installer.sh list               # List all mods

EOF
}

################################################################################
# Main Script
################################################################################

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║     Termux Mods Installer v1.0.0       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Initialize log file
    > "$INSTALL_LOG"
    
    # Pre-flight checks
    check_termux
    check_permissions
    
    # Parse commands
    local command="${1:-install}"
    local mod_name="${2:-}"
    
    case "$command" in
        install)
            if [ -n "$mod_name" ]; then
                install_specific_mod "$mod_name"
            else
                list_mods
                install_all_mods
            fi
            ;;
        uninstall)
            if [ -n "$mod_name" ]; then
                uninstall_specific_mod "$mod_name"
            else
                list_mods
                uninstall_all_mods
            fi
            ;;
        list)
            list_mods
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
    
    log_info "Install log saved to: $INSTALL_LOG"
}

# Run main function
main "$@"
