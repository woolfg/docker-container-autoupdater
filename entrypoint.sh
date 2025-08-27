#!/bin/bash

# Exit on any error
set -e

# Configuration variables
CHECK_INTERVAL=${CHECK_INTERVAL:-5}          # Check trigger file every N seconds
UPDATE_INTERVAL=${UPDATE_INTERVAL:-900}      # Run updater every N seconds (15 minutes)

# Function to handle cleanup on exit
cleanup() {
    echo "Shutting down..."
    # Kill all background jobs
    jobs -p | xargs -r kill
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start npm start in background
echo "Starting npm start..."
npm start > /proc/1/fd/1 2> /proc/1/fd/2 &
NPM_PID=$!

# Function to run the updater
run_updater() {
    echo "Running updater..."
    # Delete the trigger file if it exists
    if [ -f /tmp/run_updater ]; then
        echo "Trigger file found, removing /tmp/run_updater"
        rm -f /tmp/run_updater
    fi
    
    # Run the update script
    /app/update.sh
    echo "Updater finished"
}

# Initialize last update time
last_update=$(date +%s)

echo "Starting update loop..."
echo "Will check for trigger file every ${CHECK_INTERVAL} seconds"
echo "Will run updater every $((UPDATE_INTERVAL / 60)) minutes if no trigger file"

# Main loop
while true; do
    current_time=$(date +%s)
    time_since_last_update=$((current_time - last_update))
    
    # Check if trigger file exists
    if [ -f /tmp/run_updater ]; then
        echo "Trigger file /tmp/run_updater detected"
        run_updater
        last_update=$(date +%s)
    # Check if 15 minutes have passed
    elif [ $time_since_last_update -ge $UPDATE_INTERVAL ]; then
        echo "$((UPDATE_INTERVAL / 60)) minutes have passed, running scheduled update"
        run_updater
        last_update=$(date +%s)
    fi
    
    # Check if npm process is still running
    if ! kill -0 $NPM_PID 2>/dev/null; then
        echo "npm process died, restarting..."
        npm start &
        NPM_PID=$!
    fi
    
    # Wait before next check
    sleep $CHECK_INTERVAL
done
