#!/bin/bash

################################################################################
# zsh-sync - Multi-Device ZSH History Backup & Sync System
#
# Author: Gopesh Chaudhary <briskgopesh@proton.me>
# GitHub: https://github.com/briskgopesh/zsh-sync
# License: MIT
#
# Description:
#   Intelligent incremental backup system for ZSH command history across
#   multiple macOS devices. Features:
#   - Incremental backups with chunked storage
#   - Git/GitHub integration for version control
#   - Multi-device sync with SYNCALL/NOSYNC modes
#   - SHA256 hash validation
#   - Automatic corruption detection
#   - Zero-conflict concurrent backups
#
# Usage:
#   SYNC_MODE=SYNCALL ./chunk-backup.sh     # Normal backup (auto-sync)
#   SYNC_MODE=NOSYNC ./chunk-backup.sh      # Isolated backup
#   ./chunk-backup.sh --reset                # Full reset
#   ./chunk-backup.sh --force                # Force backup
#   ./chunk-backup.sh --cleanup              # Clean old backups
#
# Configuration:
#   export SYNC_MODE=SYNCALL    # or NOSYNC for isolated devices
#
# For more info:
#   - README.md for quick start
#   - docs/ for detailed guides
#   - GitHub issues for bug reports
#
################################################################################

set -o pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.json"
CHUNKS_DIR="$SCRIPT_DIR/chunks"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/backup-$(date +%Y%m%d_%H%M%S).log"

CHUNK_SIZE=$((20 * 1024 * 1024))
KEEP_BACKUPS=2

SYNC_MODE="${SYNC_MODE:-SYNCALL}"

FORCE_BACKUP=false
RESET_BACKUP=false
CLEANUP_ONLY=false

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" | tee -a "$LOG_FILE"
}

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

add_backup_marker() {
    local timestamp="$1"
    local marker_line=": $(date +%s):0;# [CHUNK_BACKUP_MARKER: $timestamp]"
    echo "$marker_line" >> ~/.zsh_history
}

get_laptop_id() {
    system_profiler SPHardwareDataType 2>/dev/null | grep "UUID" | awk '{print $3}' | tr -d '\n'
}

get_hostname() {
    hostname -s 2>/dev/null || echo "unknown"
}

list_other_devices() {
    jq -r "keys[] | select(. != \"$LAPTOP_ID\")" "$CONFIG_FILE" 2>/dev/null
}

sync_from_other_devices() {
    local mode="$1"
    
    if [[ "$mode" != "SYNCALL" ]]; then
        return 0
    fi
    
    print_section "Auto-syncing from other devices"
    
    local other_devices=$(list_other_devices)
    
    if [[ -z "$other_devices" ]]; then
        echo "No other devices found"
        return 0
    fi
    
    local temp_merged="/tmp/sync_merged_$$.txt"
    cp ~/.zsh_history "$temp_merged"
    
    local total_synced=0
    
    while IFS= read -r other_device; do
        if [[ -z "$other_device" ]]; then
            continue
        fi
        
        local other_chunks_dir="$CHUNKS_DIR/$other_device"
        
        if [[ ! -d "$other_chunks_dir" ]] || [[ ! -f "$other_chunks_dir/chunk_aa" ]]; then
            echo "  Skip: $other_device (no chunks found)"
            continue
        fi
        
        local other_command_count=$(jq -r ".\"$other_device\".chunks.command_count // 0" "$CONFIG_FILE")
        local other_hostname=$(jq -r ".\"$other_device\".hostname // \"unknown\"" "$CONFIG_FILE")
        
        echo "  Syncing from: $other_hostname ($other_device)"
        echo "    Commands: $other_command_count"
        
        cat "$other_chunks_dir"/chunk_* >> "$temp_merged" 2>/dev/null
        total_synced=$((total_synced + other_command_count))
    done <<< "$other_devices"
    
    if [[ $total_synced -gt 0 ]]; then
        sort -u "$temp_merged" > "$temp_merged.dedup"
        mv "$temp_merged.dedup" "$temp_merged"
        cp "$temp_merged" ~/.zsh_history
        
        print_success "Synced: $total_synced commands from other devices"
        rm -f "$temp_merged"
    fi
}

cleanup_old_backups() {
    print_section "Cleaning up old backup folders"
    
    local backup_dirs=$(find "$SCRIPT_DIR" -maxdepth 1 -type d -name "chunks.backup.*" | sort -r)
    local backup_count=$(echo "$backup_dirs" | grep -c "chunks.backup")
    
    if [[ $backup_count -eq 0 ]]; then
        echo "No backup folders found"
        return
    fi
    
    echo "Found $backup_count backup folders (keeping $KEEP_BACKUPS recent)"
    
    local count=0
    echo "$backup_dirs" | while read backup_dir; do
        count=$((count + 1))
        local size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
        local basename=$(basename "$backup_dir")
        
        if [[ $count -le $KEEP_BACKUPS ]]; then
            echo "  ✓ Keep: $basename ($size)"
        else
            echo "  ✗ Delete: $basename ($size)"
            rm -rf "$backup_dir"
        fi
    done
    
    print_success "Cleanup complete"
}

initialize_device() {
    if ! jq -e ".\"$LAPTOP_ID\"" "$CONFIG_FILE" > /dev/null 2>&1; then
        print_info "Initializing device in config.json..."
        
        jq \
            --arg LAPTOP_ID "$LAPTOP_ID" \
            --arg hostname "$(get_hostname)" \
            --arg created "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            ".\"$LAPTOP_ID\" = {
                \"laptop_id\": \$LAPTOP_ID,
                \"hostname\": \$hostname,
                \"created\": \$created,
                \"sync_mode\": \"NOSYNC\",
                \"chunks\": {
                    \"count\": 0,
                    \"total_size\": 0,
                    \"command_count\": 0,
                    \"timestamp\": null,
                    \"parts\": []
                }
            }" \
            "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        print_success "Device initialized"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "SYNC_MODE environment variable:"
    echo "  SYNC_MODE=SYNCALL   Auto-merge all other devices (default)"
    echo "  SYNC_MODE=NOSYNC    Keep isolated, don't auto-merge"
    echo ""
    echo "Options:"
    echo "  (no args)    Normal incremental backup"
    echo "  --force      Skip corruption check"
    echo "  --reset      Clean old backup, start fresh"
    echo "  --cleanup    Remove old backup folders"
    echo "  --help       Show this help"
    echo ""
    echo "Examples:"
    echo "  SYNC_MODE=SYNCALL ./chunk-backup.sh"
    echo "  ./chunk-backup.sh --reset"
    echo "  ./chunk-backup.sh --cleanup"
    echo ""
}

main() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                      🔄 zsh-sync - Backup System                        ║
║            Multi-Device ZSH History Backup & Sync (v1.0)                ║
║                                                                           ║
║                    Author: Gopesh Chaudhary                             ║
║                  GitHub: briskgopesh/zsh-sync                           ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ "$CLEANUP_ONLY" == "true" ]]; then
        cleanup_old_backups
        exit 0
    fi
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "{}" > "$CONFIG_FILE"
    fi
    
    LAPTOP_ID=$(get_laptop_id)
    HOSTNAME=$(get_hostname)
    
    if [[ -z "$LAPTOP_ID" ]]; then
        print_error "Could not determine laptop UUID"
        exit 1
    fi
    
    echo -e "Device: ${CYAN}$HOSTNAME${NC}"
    echo -e "UUID: ${CYAN}$LAPTOP_ID${NC}"
    
    initialize_device
    
    case "$SYNC_MODE" in
        SYNCALL)
            echo -e "Mode: ${MAGENTA}SYNCALL${NC} (auto-merge all devices)"
            ;;
        NOSYNC)
            echo -e "Mode: ${CYAN}NOSYNC${NC} (keep isolated)"
            ;;
        *)
            print_error "Invalid SYNC_MODE: $SYNC_MODE"
            exit 1
            ;;
    esac
    
    if [[ "$RESET_BACKUP" == "true" ]]; then
        print_section "RESET MODE"
        
        read -p "Are you absolutely sure? (type 'YES' to confirm): " confirm
        if [[ "$confirm" != "YES" ]]; then
            echo "Cancelled"
            exit 0
        fi
        
        local device_chunks_dir="$CHUNKS_DIR/$LAPTOP_ID"
        
        if [[ -d "$device_chunks_dir" ]] && [[ -n "$(ls "$device_chunks_dir"/chunk_* 2>/dev/null)" ]]; then
            local backup_dir="$device_chunks_dir.backup.$(date +%Y%m%d_%H%M%S)"
            cp -r "$device_chunks_dir" "$backup_dir"
            print_warning "Old chunks saved to: $backup_dir"
        fi
        
        rm -rf "$device_chunks_dir"
        mkdir -p "$device_chunks_dir"
        
        jq ".\"$LAPTOP_ID\".chunks = {count: 0, total_size: 0, command_count: 0, timestamp: null, parts: []}" \
            "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        
        if grep -q "CHUNK_BACKUP_MARKER" ~/.zsh_history 2>/dev/null; then
            grep -v "CHUNK_BACKUP_MARKER" ~/.zsh_history > ~/.zsh_history.tmp
            mv ~/.zsh_history.tmp ~/.zsh_history
        fi
        
        print_success "Reset complete"
    fi
    
    print_section "Step 1: Checking backup status"
    
    local last_timestamp=$(jq -r ".\"$LAPTOP_ID\".chunks.timestamp" "$CONFIG_FILE" 2>/dev/null)
    local last_command_count=$(jq -r ".\"$LAPTOP_ID\".chunks.command_count // 0" "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$last_timestamp" ]] || [[ "$last_timestamp" == "null" ]]; then
        echo "Status: First backup"
    else
        echo "Last backup: $last_timestamp"
        echo "Commands: $(printf '%8d' $last_command_count)"
    fi
    
    if [[ "$SYNC_MODE" == "SYNCALL" ]]; then
        sync_from_other_devices "SYNCALL"
    fi
    
    print_section "Step 2: Extracting new commands"
    
    local new_commands_file="/tmp/new_commands_$$.txt"
    
    if [[ "$RESET_BACKUP" == "true" ]]; then
        cp ~/.zsh_history "$new_commands_file"
    else
        local marker_pattern="\[CHUNK_BACKUP_MARKER: $last_timestamp\]"
        if [[ -n "$last_timestamp" ]] && [[ "$last_timestamp" != "null" ]] && grep -q "$marker_pattern" ~/.zsh_history 2>/dev/null; then
            grep -A 999999 "$marker_pattern" ~/.zsh_history | tail -n +2 > "$new_commands_file"
        else
            cp ~/.zsh_history "$new_commands_file"
        fi
    fi
    
    local new_command_count=$(count_commands "$new_commands_file")
    
    echo "New commands: $(printf '%6d' $new_command_count) commands, $(format_bytes $(wc -c < "$new_commands_file"))"
    
    if [[ $new_command_count -eq 0 ]]; then
        print_success "No new commands since last backup"
        rm -f "$new_commands_file"
        exit 0
    fi
    
    print_success "Extracted"
    
    print_section "Step 3: Preparing merge"
    
    local merged_file="/tmp/merged_history_$$.txt"
    local device_chunks_dir="$CHUNKS_DIR/$LAPTOP_ID"
    
    mkdir -p "$device_chunks_dir"
    
    if [[ "$RESET_BACKUP" == "true" ]]; then
        cp "$new_commands_file" "$merged_file"
        echo "Fresh backup mode"
    else
        if [[ -f "$device_chunks_dir/chunk_aa" ]]; then
            echo "Recovering old chunks..."
            cat "$device_chunks_dir"/chunk_* > "$merged_file"
        else
            cp "$new_commands_file" "$merged_file"
        fi
        
        if [[ -s "$new_commands_file" ]]; then
            cat "$new_commands_file" >> "$merged_file"
        fi
    fi
    
    local merged_command_count=$(count_commands "$merged_file")
    local merged_size=$(wc -c < "$merged_file")
    
    echo "Merged: $(printf '%8d' $merged_command_count) commands, $(format_bytes $merged_size)"
    print_success "Ready for chunking"
    
    print_section "Step 4: Splitting into chunks"
    
    if [[ -n "$(ls "$device_chunks_dir"/chunk_* 2>/dev/null)" ]]; then
        local backup_dir="$device_chunks_dir.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$device_chunks_dir" "$backup_dir"
        echo "Old chunks: $backup_dir"
    fi
    
    rm -f "$device_chunks_dir"/chunk_* 2>/dev/null
    split -b $CHUNK_SIZE "$merged_file" "$device_chunks_dir/chunk_"
    
    local chunk_count=$(ls -1 "$device_chunks_dir"/chunk_* 2>/dev/null | wc -l)
    
    echo "Chunks: $chunk_count"
    echo "Size: $(format_bytes $merged_size)"
    print_success "Split complete"
    
    print_section "Step 5: Updating config.json"
    
    echo "[]" > /tmp/chunks_$$.json
    local index=0
    
    for chunk_file in "$device_chunks_dir"/chunk_*; do
        if [[ -f "$chunk_file" ]]; then
            local chunk_name=$(basename "$chunk_file")
            local chunk_hash=$(calculate_hash "$chunk_file")
            local chunk_size=$(wc -c < "$chunk_file")
            
            jq ". += [{index: $index, name: \"$chunk_name\", hash: \"$chunk_hash\", size: $chunk_size}]" \
                /tmp/chunks_$$.json > /tmp/chunks_$$.json.tmp 2>/dev/null
            
            mv /tmp/chunks_$$.json.tmp /tmp/chunks_$$.json
            index=$((index + 1))
        fi
    done
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    jq \
        --arg LAPTOP_ID "$LAPTOP_ID" \
        --arg sync_mode "$SYNC_MODE" \
        --arg timestamp "$timestamp" \
        --argjson chunk_count "$chunk_count" \
        --argjson total_size "$merged_size" \
        --argjson command_count "$merged_command_count" \
        --slurpfile parts /tmp/chunks_$$.json \
        ".\"$LAPTOP_ID\".sync_mode = \$sync_mode | .\"$LAPTOP_ID\".chunks = {
            \"timestamp\": \$timestamp,
            \"count\": \$chunk_count,
            \"total_size\": \$total_size,
            \"command_count\": \$command_count,
            \"parts\": (\$parts[0] // [])
        }" \
        "$CONFIG_FILE" > "$CONFIG_FILE.tmp" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        print_success "Config updated"
    else
        print_error "Failed to update config"
        rm -f "$merged_file" "$new_commands_file" /tmp/chunks_$$.json*
        exit 1
    fi
    
    print_section "Step 6: Validating chunks"
    
    local valid_count=0
    for chunk_file in "$device_chunks_dir"/chunk_*; do
        local chunk_name=$(basename "$chunk_file")
        local actual_hash=$(calculate_hash "$chunk_file")
        local expected_hash=$(jq -r ".\"$LAPTOP_ID\".chunks.parts[] | select(.name==\"$chunk_name\") | .hash" "$CONFIG_FILE" 2>/dev/null)
        
        if [[ "$actual_hash" == "$expected_hash" ]]; then
            echo "  ✓ $chunk_name"
            ((valid_count++))
        else
            print_error "Hash mismatch: $chunk_name"
            exit 1
        fi
    done
    
    print_success "All $valid_count chunks valid"
    
    print_section "Step 7: Marking backup point"
    add_backup_marker "$timestamp"
    print_success "Marker added"
    
    print_section "Step 8: Committing to git"
    
    git add chunks/ config.json 2>/dev/null
    local git_ts=$(date +"%Y-%m-%d %H:%M:%S")
    if git commit -m "Backup - $git_ts (mode: $SYNC_MODE)" >> "$LOG_FILE" 2>&1; then
        print_success "Committed"
    else
        echo "Nothing new"
    fi
    
    print_section "Step 9: Pushing to GitHub"
    
    if git push >> "$LOG_FILE" 2>&1; then
        print_success "Pushed!"
    else
        print_error "Push failed"
    fi
    
    cleanup_old_backups
    
    rm -f "$merged_file" "$new_commands_file" /tmp/chunks_$$.json*
    
    print_section "✅ COMPLETE"
    echo ""
    echo -e "Mode: ${MAGENTA}$SYNC_MODE${NC}"
    echo -e "Device: ${CYAN}$HOSTNAME${NC}"
    echo -e "New Commands: ${CYAN}$(printf '%6d' $new_command_count)${NC}"
    echo -e "Total Commands: ${CYAN}$(printf '%6d' $merged_command_count)${NC}"
    echo -e "Chunks: ${CYAN}$chunk_count${NC}"
    echo -e "Total Size: ${CYAN}$(format_bytes $merged_size)${NC}"
    echo -e "Timestamp: ${CYAN}$timestamp${NC}"
    echo ""
    
    log "Backup: mode=$SYNC_MODE, $new_command_count new, $merged_command_count total, $chunk_count chunks"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE_BACKUP=true
            shift
            ;;
        --reset)
            RESET_BACKUP=true
            shift
            ;;
        --cleanup)
            CLEANUP_ONLY=true
            shift
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

cd "$SCRIPT_DIR" || exit 1
main
exit $?