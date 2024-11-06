#!/bin/bash

# Directory to monitor (set to root if you want to monitor the entire filesystem)
MONITORED_DIR="/"

# Start monitoring and scanning for new files
inotifywait -m -r -e create --format '%w%f' "$MONITORED_DIR" | while read NEWFILE
do
    echo "New file detected: $NEWFILE"
    clamdscan --fdpass "$NEWFILE"
done