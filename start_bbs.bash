#!/usr/bin/env bash
# copyright 2025 by moshix
# This is a BBS for 3270 terminals
# all rights reserved by moshix

# Detect if we're running on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "linux"* ]]; then
    # Linux machine - enable logging to /var/log/tsu.log
    LOG_FILE="/var/log/tsu.log"
    
    # Check if sudo is available and working
    if ! command -v sudo &> /dev/null; then
        echo "Error: sudo is not available. Cannot enable logging."
        echo "Falling back to non-logging mode."
        echo
        # Fall back to non-logging mode
        while true; do
            time ./tsu
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "tsu exited successfully. Not restarting."
                break
            elif [ $EXIT_CODE -eq 42 ]; then
                echo "REIPL requested. Restarting immediately..."
                continue
            else
                echo "tsu exited with error $EXIT_CODE. Restarting in 2 seconds..."
                sleep 2
            fi
        done
        exit 0
    fi
    
    # Test if we can write to the log file
    if ! sudo touch "$LOG_FILE" 2>/dev/null; then
        echo "Error: Cannot create or write to log file $LOG_FILE"
        echo "Check permissions or run with appropriate sudo access."
        echo "Falling back to non-logging mode."
        echo
        # Fall back to non-logging mode
        while true; do
            time ./tsu
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "tsu exited successfully. Not restarting."
                break
            elif [ $EXIT_CODE -eq 42 ]; then
                echo "REIPL requested. Restarting immediately..."
                continue
            else
                echo "tsu exited with error $EXIT_CODE. Restarting in 2 seconds..."
                sleep 2
            fi
        done
        exit 0
    fi
    
    # Inform user about logging (console only, not in log file)
    echo "=== TSU BBS Startup Script ==="
    echo "Linux system detected - logging enabled"
    echo "Log file: $LOG_FILE"
    echo "All application output will be logged there"
    echo "========================================"
    echo
    
    # Start logging to file
    if ! echo "$(date '+%Y-%m-%d %H:%M:%S') - TSU BBS starting on Linux - logging to $LOG_FILE" | sudo tee -a "$LOG_FILE" >/dev/null; then
        echo "Warning: Failed to write to log file. Continuing without logging."
        echo
        # Fall back to non-logging mode
        while true; do
            time ./tsu
            EXIT_CODE=$?
            
            if [ $EXIT_CODE -eq 0 ]; then
                echo "tsu exited successfully. Not restarting."
                break
            elif [ $EXIT_CODE -eq 42 ]; then
                echo "REIPL requested. Restarting immediately..."
                continue
            else
                echo "tsu exited with error $EXIT_CODE. Restarting in 2 seconds..."
                sleep 2
            fi
        done
        exit 0
    fi
    
    # Function to log messages with error handling
    log_message() {
        if ! echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" >/dev/null; then
            echo "Warning: Failed to write to log file: $1"
        fi
    }
    
    log_message "Starting TSU BBS application"
    
    while true; do
        log_message "Launching TSU application"
        time ./tsu 2>&1 | sudo tee -a "$LOG_FILE"
        EXIT_CODE=${PIPESTATUS[0]}  # Get exit code of ./tsu, not tee
        
        if [ $EXIT_CODE -eq 0 ]; then
            log_message "TSU exited successfully. Not restarting."
            break
        elif [ $EXIT_CODE -eq 42 ]; then
            log_message "REIPL requested. Restarting immediately..."
            continue
        else
            log_message "TSU exited with error code $EXIT_CODE. Restarting in 2 seconds..."
            sleep 2
        fi
    done
    
    log_message "TSU BBS shutdown complete"
else
    # Non-Linux machine - run without logging
    echo "=== TSU BBS Startup Script ==="
    echo "Non-Linux system detected - logging disabled"
    echo "Logging is only available on Linux systems"
    echo "========================================"
    echo
    
    while true; do
        time ./tsu
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            echo "tsu exited successfully. Not restarting."
            break
        elif [ $EXIT_CODE -eq 42 ]; then
            echo "REIPL requested. Restarting immediately..."
            continue
        else
            echo "tsu exited with error $EXIT_CODE. Restarting in 2 seconds..."
            sleep 2
        fi
    done
fi
