#!/bin/bash

# Exit on any error
set -e

# Configuration variables
CHECK_INTERVAL=${CHECK_INTERVAL:-5}          # Check trigger file every N seconds
UPDATE_INTERVAL=${UPDATE_INTERVAL:-900}      # Run updater every N seconds (15 minutes)
TRIGGER_FILE=${TRIGGER_FILE:-}               # Optional trigger file path

echo "Docker Swarm Autoupdater starting..."
if [ -n "$TRIGGER_FILE" ]; then
    echo "Trigger file: $TRIGGER_FILE"
    echo "Check interval: ${CHECK_INTERVAL} seconds"
    
    # Ensure shared directory has correct permissions for trigger container (node user UID 1000)
    shared_dir=$(dirname "$TRIGGER_FILE")
    if [ -d "$shared_dir" ]; then
        echo "Setting up shared directory permissions: $shared_dir"
        chmod 777 "$shared_dir"
    fi
else
    echo "Running in standalone mode (no trigger file)"
fi
echo "Auto update interval: $((UPDATE_INTERVAL / 60)) minutes"

# Function to handle cleanup on exit
cleanup() {
    echo "Shutting down updater..."
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Function to run the updater
run_updater() {
    echo "===================="
    echo "Running updater at $(date)"
    
    # Delete the trigger file if it exists
    if [ -n "$TRIGGER_FILE" ] && [ -f "$TRIGGER_FILE" ]; then
        echo "Trigger file found, removing $TRIGGER_FILE"
        rm -f "$TRIGGER_FILE"
    fi
    
    # Run the update script
    /app/update.sh
    echo "Updater finished at $(date)"
    echo "===================="
}

# Initialize last update time
last_update=$(date +%s)

echo "Starting update monitoring loop..."

# Main loop
while true; do
    current_time=$(date +%s)
    time_since_last_update=$((current_time - last_update))
    
    # Check if trigger file exists (only if TRIGGER_FILE is set)
    if [ -n "$TRIGGER_FILE" ] && [ -f "$TRIGGER_FILE" ]; then
        echo "Trigger file $TRIGGER_FILE detected"
        run_updater
        last_update=$(date +%s)
    # Check if scheduled update interval has passed
    elif [ $time_since_last_update -ge $UPDATE_INTERVAL ]; then
        echo "$((UPDATE_INTERVAL / 60)) minutes have passed, running scheduled update"
        run_updater
        last_update=$(date +%s)
    fi
    
    # Wait before next check
    sleep $CHECK_INTERVAL
done
