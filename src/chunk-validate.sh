#!/bin/bash

################################################################################
# zsh-sync - Chunk Validation & Integrity Check
#
# Author: Gopesh Chaudhary <hello@gopesh.dev>
# GitHub: https://github.com/briskgopesh/zsh-sync
# License: MIT
#
# Description:
#   Validates integrity of all backup chunks using SHA256 hashes.
#   Checks file sizes, hash mismatches, and missing chunks.
#   Supports multi-device backups with device-specific chunk directories.
#
# Usage:
#   ./chunk-validate.sh                 # Validate current device
#   ./chunk-validate.sh --all           # Validate all devices
#   ./chunk-validate.sh --device UUID   # Validate specific device
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

calculate_hash() {
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
}

get_laptop_id() {
    system_profiler SPHardwareDataType 2>/dev/null | grep "UUID" | awk '{print $3}' | tr -d '\n'
}

get_hostname() {
    hostname -s 2>/dev/null || echo "unknown"
}

validate_device() {
    local device_id="$1"
    
    if ! jq -e ".\"$device_id\"" "$CONFIG_FILE" > /dev/null 2>&1; then
        print_error "Device not found: $device_id"
        return 1
    fi
    
    local hostname=$(jq -r ".\"$device_id\".hostname // \"unknown\"" "$CONFIG_FILE")
    local chunk_count=$(jq -r ".\"$device_id\".chunks.count" "$CONFIG_FILE")
    local total_size=$(jq -r ".\"$device_id\".chunks.total_size" "$CONFIG_FILE")
    local command_count=$(jq -r ".\"$device_id\".chunks.command_count" "$CONFIG_FILE")
    local timestamp=$(jq -r ".\"$device_id\".chunks.timestamp" "$CONFIG_FILE")
    
    echo ""
    echo -e "Device: ${CYAN}$hostname${NC}"
    echo -e "UUID: ${CYAN}$device_id${NC}"
    echo -e "Timestamp: ${CYAN}$timestamp${NC}"
    echo -e "Chunks: ${CYAN}$chunk_count${NC}"
    echo -e "Size: ${CYAN}$(format_bytes $total_size)${NC}"
    echo -e "Commands: ${CYAN}$command_count${NC}"
    
    if [[ $chunk_count -eq 0 ]]; then
        print_warning "No chunks in config"
        return 0
    fi
    
    print_section "Validating chunks for $hostname"
    
    local device_chunks_dir="$CHUNKS_DIR/$device_id"
    
    if [[ ! -d "$device_chunks_dir" ]]; then
        print_error "Chunk directory not found: $device_chunks_dir"
        return 1
    fi
    
    local valid_count=0
    local failed_count=0
    local total_checked=0
    
    for ((i=0; i<chunk_count; i++)); do
        local chunk_info=$(jq -r ".\"$device_id\".chunks.parts[$i]" "$CONFIG_FILE")
        local chunk_name=$(echo "$chunk_info" | jq -r '.name')
        local expected_hash=$(echo "$chunk_info" | jq -r '.hash')
        local expected_size=$(echo "$chunk_info" | jq -r '.size')
        
        local chunk_file="$device_chunks_dir/$chunk_name"
        
        ((total_checked++))
        
        # Check if file exists
        if [[ ! -f "$chunk_file" ]]; then
            print_error "Missing: $chunk_name"
            ((failed_count++))
            continue
        fi
        
        # Check file size
        local actual_size=$(wc -c < "$chunk_file")
        if [[ $actual_size -ne $expected_size ]]; then
            print_error "$chunk_name: size mismatch (actual: $(format_bytes $actual_size), expected: $(format_bytes $expected_size))"
            ((failed_count++))
            continue
        fi
        
        # Check hash
        local actual_hash=$(calculate_hash "$chunk_file")
        if [[ "$actual_hash" != "$expected_hash" ]]; then
            print_error "$chunk_name: hash mismatch"
            print_error "  Expected: $expected_hash"
            print_error "  Actual:   $actual_hash"
            ((failed_count++))
            continue
        fi
        
        # All checks passed
        echo "  ✓ $chunk_name: $(format_bytes $actual_size)"
        ((valid_count++))
    done
    
    echo ""
    if [[ $failed_count -eq 0 ]]; then
        print_success "All $valid_count chunks valid!"
        return 0
    else
        print_error "Validation failed: $failed_count/$total_checked chunks"
        return 1
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (no args)      Validate current device"
    echo "  --all          Validate all devices"
    echo "  --device UUID  Validate specific device"
    echo "  --help         Show this help"
    echo ""
    echo "Examples:"
    echo "  ./chunk-validate.sh"
    echo "  ./chunk-validate.sh --all"
    echo "  ./chunk-validate.sh --device C1A873F7-..."
    echo ""
}

main() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║            ✓ CHUNK VALIDATE - Integrity Check & Verification            ║
║                   SHA256 Hash Validation & Size Check                    ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Config not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Parse arguments
    local validate_all=false
    local target_device=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                validate_all=true
                shift
                ;;
            --device)
                target_device="$2"
                shift 2
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
    
    # Determine which devices to validate
    local devices_to_check=()
    
    if [[ -n "$target_device" ]]; then
        # Validate specific device
        devices_to_check=("$target_device")
    elif [[ "$validate_all" == true ]]; then
        # Validate all devices
        mapfile -t devices_to_check < <(jq -r 'keys[]' "$CONFIG_FILE")
    else
        # Validate current device only
        local current_device=$(get_laptop_id)
        if [[ -z "$current_device" ]]; then
            print_error "Could not determine device UUID"
            exit 1
        fi
        devices_to_check=("$current_device")
    fi
    
    if [[ ${#devices_to_check[@]} -eq 0 ]]; then
        print_error "No devices found to validate"
        exit 1
    fi
    
    # Validate each device
    print_section "Starting validation of ${#devices_to_check[@]} device(s)"
    
    local total_valid=0
    local total_failed=0
    
    for device in "${devices_to_check[@]}"; do
        if validate_device "$device"; then
            ((total_valid++))
        else
            ((total_failed++))
        fi
    done
    
    echo ""
    print_section "✅ VALIDATION COMPLETE"
    echo ""
    echo -e "Devices Validated: ${CYAN}${#devices_to_check[@]}${NC}"
    echo -e "Successful: ${GREEN}$total_valid${NC}"
    
    if [[ $total_failed -gt 0 ]]; then
        echo -e "Failed: ${RED}$total_failed${NC}"
        echo ""
        print_error "Some validations failed. Check errors above."
        exit 1
    else
        echo -e "Failed: ${GREEN}0${NC}"
        echo ""
        print_success "All chunks verified successfully!"
        exit 0
    fi
}

main "$@"