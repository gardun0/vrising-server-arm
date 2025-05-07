#!/bin/bash

set -e

echo "Downloading server files..."

/home/steam/steamcmd/steamcmd.sh +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir $SERVER_DIR \
    +app_update $STEAMAPPID validate \
    +quit

printf "steam_appid: "
cat "$SERVER_DIR/steam_appid.txt