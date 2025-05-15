#!/bin/bash

set -e

s=/home/steam/vrising-server

echo "Downloading server files..."

/usr/games/steamcmd +force_install_dir "$s" \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update "$STEAMAPPID" validate \
    +quit

# Check if the server directory is empty
if [ -z "$(ls -A "$s")" ]; then
    echo "ERROR: $s is empty! Please check your server directory."
    exit 1
fi

exit 0
