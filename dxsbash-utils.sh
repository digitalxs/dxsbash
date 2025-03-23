#!/bin/bash
# dxsbash-utils.sh - Shared utilities for dxsbash scripts

# Color codes
RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local log_file="$HOME/.dxsbash/logs/dxsbash.log"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$log_file")"
    
    # Format the log message
    local formatted_log="[$timestamp] [$level] $message"
    
    # Output to console with colors if appropriate
    case "$level" in
        "INFO")  echo -e "${GREEN}$formatted_log${RC}" ;;
        "WARN")  echo -e "${YELLOW}$formatted_log${RC}" ;;
        "ERROR") echo -e "${RED}$formatted_log${RC}" ;;
        *)       echo "$formatted_log" ;;
    esac
    
    # Append to log file
    echo "$formatted_log" >> "$log_file"
}

# Log rotation function
rotate_logs() {
    local log_dir="$HOME/.dxsbash/logs"
    local main_log="$log_dir/dxsbash.log"
    local max_size=1048576  # 1MB
    
    # Check if log exists and is larger than max size
    if [ -f "$main_log" ] && [ $(stat -c %s "$main_log") -gt $max_size ]; then
        local timestamp=$(date "+%Y%m%d_%H%M%S")
        mv "$main_log" "$log_dir/dxsbash_$timestamp.log"
        # Keep only the 5 most recent log files
        ls -t "$log_dir"/dxsbash_*.log | tail -n +6 | xargs rm -f 2>/dev/null
    fi
}
