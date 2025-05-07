#!/bin/bash

set -e

echo "Downloading server files..."

/home/steam/steamcmd/steamcmd.sh +force_install_dir $SERVER_DIR \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update $STEAMAPPID validate \
    +quit

# Check if the server directory is empty
if [ -z "$(ls -A "$SERVER_DIR")" ]; then
    echo "ERROR: $SERVER_DIR is empty! Please check your server directory."
    exit 1
fi

# List all files in the server directory and every directory inside it
echo "Listing all files in $SERVER_DIR"
ls -lR "$SERVER_DIR"
