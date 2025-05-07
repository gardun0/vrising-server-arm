#!/bin/bash

set -e

echo "Downloading server files..."

/home/steam/steamcmd/steamcmd.sh +force_install_dir $SERVER_DIR \
    +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +app_update $STEAMAPPID validate \
    +quit

printf "steam_appid: "
cat "$SERVER_DIR/steam_appid.txt