#!/bin/bash

################################################################################
# zsh-sync - Chunk Restore & Recovery
#
# Author: Gopesh Chaudhary <hello@gopesh.dev>
# GitHub: https://github.com/briskgopesh/zsh-sync
# License: MIT
#
# Description:
#   Restore ZSH history from backup chunks. Supports restoring from:
#   - Current device chunks
#   - Specific device (multi-device setup)
#   - Previous backup (rollback)
#   - Specific git commit
#   - All devices merged (SYNCALL)
#
# Usage:
#   ./chunk-restore.sh                      # Restore from current device
#   ./chunk-restore.sh --device UUID        # Restore from specific device
#   ./chunk-restore.sh --commit HASH        # Restore from git commit
#   ./chunk-restore.sh --backup TIMESTAMP   # Restore from backup folder
#   ./chunk-restore.sh --list               # List available backups
#
# Safety:
#   - Always backs up current ~/.zsh_history before restore
#   - Creates .restore file with timestamp
#   - Requires explicit confirmation before overwriting
#
################################################################################

set -o pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.json"
CHUNKS_DIR="$SCRIPT_DIR/chunks"
LOG_DIR="$SCRIPT_DIR/logs"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

format_bytes() {
    local bytes=$1
    if [[ $bytes -lt 1024 ]]; then
        echo "${bytes}B"
    elif [[ $bytes -lt $((1024 * 1024)) ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "$((bytes / 1024 / 1024))MB"
    fi
}

count_commands() {
    local file="$1"
    grep -c "^:" "$file" 2>/dev/null || echo 0
}

calculate_hash() {
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

get_laptop_id() {
    system_profiler SPHardwareDataType 2>/dev/null | grep "UUID" | awk '{print $3}' | tr -d '\n'
}

get_hostname() {
    hostname -s 2>/dev/null || echo "unknown"
}

backup_current_history() {
    if [[ ! -f ~/.zsh_history ]]; then
        return 0
    fi
    
    print_info "Backing up current ~/.zsh_history"
    local backup_file="$HOME/.zsh_history.restore.$(date +%Y%m%d_%H%M%S)"
    cp ~/.zsh_history "$backup_file"
    print_success "Backup created: $backup_file"
    echo "$backup_file"
}

list_available_backups() {
    print_section "Available Backup Sources"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config not found"
        return 1
    fi
    
    echo ""
    print_info "Devices in config:"
    jq -r 'to_entries[] | "  \(.key): \(.value.hostname) - \(.value.chunks.command_count) commands"' "$CONFIG_FILE"
    
    echo ""
    print_info "Previous backups:"
    find "$CHUNKS_DIR" -maxdepth 1 -type d -name "chunks.backup.*" -o -name "*.backup.*" | sort -r | head -5 | while read dir; do
        local name=$(basename "$dir")
        local size=$(du -sh "$dir" 2>/dev/null | awk '{print $1}')
        echo "  $name ($size)"
    done
    
    echo ""
    print_info "Recent git commits:"
    git log --oneline -10 2>/dev/null | while read commit msg; do
        echo "  $commit - $msg"
    done
    
    echo ""
}

restore_from_device() {
    local device_id="$1"
    
    if ! jq -e ".\"$device_id\"" "$CONFIG_FILE" > /dev/null 2>&1; then
        print_error "Device not found: $device_id"
        return 1
    fi
    
    local hostname=$(jq -r ".\"$device_id\".hostname // \"unknown\"" "$CONFIG_FILE")
    local command_count=$(jq -r ".\"$device_id\".chunks.command_count" "$CONFIG_FILE")
    local timestamp=$(jq -r ".\"$device_id\".chunks.timestamp" "$CONFIG_FILE")
    local chunk_count=$(jq -r ".\"$device_id\".chunks.count" "$CONFIG_FILE")
    
    print_info "Restoring from device: $hostname"
    echo "  UUID: $device_id"
    echo "  Timestamp: $timestamp"
    echo "  Commands: $command_count"
    echo "  Chunks: $chunk_count"
    
    local device_chunks_dir="$CHUNKS_DIR/$device_id"
    
    if [[ ! -d "$device_chunks_dir" ]] || [[ ! -f "$device_chunks_dir/chunk_aa" ]]; then
        print_error "No chunks found for device"
        return 1
    fi
    
    read -p "Continue with restore? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled"
        return 1
    fi
    
    print_section "Restoring history"
    
    # Backup current
    local backup_file=$(backup_current_history)
    
    # Restore from chunks
    print_info "Merging chunks..."
    cat "$device_chunks_dir"/chunk_* > ~/.zsh_history
    
    local new_count=$(count_commands ~/.zsh_history)
    print_success "Restored: $new_count commands"
    
    # Reload shell
    print_info "Reloading shell..."
    exec zsh
}

restore_from_commit() {
    local commit_hash="$1"
    
    print_info "Checking out commit: $commit_hash"
    
    git show "$commit_hash:config.json" > /dev/null 2>&1 || {
        print_error "Commit not found"
        return 1
    }
    
    read -p "Continue with restore from commit $commit_hash? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled"
        return 1
    fi
    
    print_section "Restoring from commit"
    
    # Backup current
    backup_current_history
    
    # Get device ID from current config
    local device_id=$(get_laptop_id)
    
    # Checkout chunks from git
    print_info "Checking out chunks from git..."
    git checkout "$commit_hash" -- "chunks/$device_id/" 2>/dev/null
    
    if [[ -d "$CHUNKS_DIR/$device_id" ]] && [[ -f "$CHUNKS_DIR/$device_id/chunk_aa" ]]; then
        print_info "Merging chunks..."
        cat "$CHUNKS_DIR/$device_id"/chunk_* > ~/.zsh_history
        
        local new_count=$(count_commands ~/.zsh_history)
        print_success "Restored: $new_count commands"
        
        exec zsh
    else
        print_error "Failed to restore chunks"
        return 1
    fi
}

restore_from_backup() {
    local backup_timestamp="$1"
    
    local backup_dir="$CHUNKS_DIR/$backup_timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "Backup not found: $backup_timestamp"
        return 1
    fi
    
    print_info "Restoring from backup: $backup_timestamp"
    
    read -p "Continue with restore? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo "Cancelled"
        return 1
    fi
    
    print_section "Restoring history"
    
    # Backup current
    backup_current_history
    
    # Restore from backup
    print_info "Merging chunks..."
    if [[ -f "$backup_dir/chunk_aa" ]]; then
        cat "$backup_dir"/chunk_* > ~/.zsh_history
    else
        print_error "No chunks found in backup"
        return 1
    fi
    
    local new_count=$(count_commands ~/.zsh_history)
    print_success "Restored: $new_count commands"
    
    exec zsh
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)           Restore from current device"
    echo "  --device UUID       Restore from specific device"
    echo "  --commit HASH       Restore from git commit"
    echo "  --backup TIMESTAMP  Restore from backup folder"
    echo "  --list              List available backups"
    echo "  --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  ./chunk-restore.sh"
    echo "  ./chunk-restore.sh --list"
    echo "  ./chunk-restore.sh --device C1A873F7-..."
    echo "  ./chunk-restore.sh --commit abc1234"
    echo "  ./chunk-restore.sh --backup 20260704_120000"
    echo ""
    echo "Safety:"
    echo "  - Always backs up current history before restore"
    echo "  - Requires explicit confirmation"
    echo "  - Backup saved as: ~/.zsh_history.restore.TIMESTAMP"
    echo ""
}

main() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║         ↶ CHUNK RESTORE - History Recovery & Rollback                   ║
║              Restore from backups, devices, or commits                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Parse arguments
    local restore_mode="current"
    local restore_target=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                restore_mode="device"
                restore_target="$2"
                shift 2
                ;;
            --commit)
                restore_mode="commit"
                restore_target="$2"
                shift 2
                ;;
            --backup)
                restore_mode="backup"
                restore_target="$2"
                shift 2
                ;;
            --list)
                list_available_backups
                exit 0
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Perform restore based on mode
    case $restore_mode in
        current)
            local device_id=$(get_laptop_id)
            if [[ -z "$device_id" ]]; then
                print_error "Could not determine device UUID"
                exit 1
            fi
            restore_from_device "$device_id"
            ;;
        device)
            restore_from_device "$restore_target"
            ;;
        commit)
            restore_from_commit "$restore_target"
            ;;
        backup)
            restore_from_backup "$restore_target"
            ;;
        *)
            print_error "Invalid restore mode"
            exit 1
            ;;
    esac
    
    exit $?
}

main "$@"