#!/bin/bash
s=/home/vrising/server
p=/home/vrising/data

GAMEPORT=9876
QUERYPORT=9877

term_handler() {
	echo "Shutting down Server"

	PID=$(pgrep -f "^${s}/VRisingServer.exe")
	if [[ -z $PID ]]; then
		echo "Could not find VRisingServer.exe pid. Assuming server is dead..."
	else
		kill -n 15 "$PID"
		wait "$PID"
	fi
	wineserver -k
	sleep 1
	exit
}

cleanup_logs() {
	echo "Cleaning up logs older than $LOGDAYS days"
	find "$p" -name "*.log" -type f -mtime +$LOGDAYS -exec rm {} \;
}

trap 'term_handler' SIGTERM

if [ -z "$LOGDAYS" ]; then
	LOGDAYS=30
fi
if [[ -n $UID ]]; then
	usermod -u "$UID" docker 2>&1
fi
if [[ -n $GID ]]; then
	groupmod -g "$GID" docker 2>&1
fi
if [ -z "$SERVERNAME" ]; then
	SERVERNAME="Test Server"
fi
override_savename=""
if [[ -n "$WORLDNAME" ]]; then
	override_savename="-saveName $WORLDNAME"
fi
game_port=""
if [[ -n $GAMEPORT ]]; then
	game_port=" -gamePort $GAMEPORT"
fi
query_port=""
if [[ -n $QUERYPORT ]]; then
	query_port=" -queryPort $QUERYPORT"
fi

cleanup_logs

echo " "
mkdir "$p/Settings" 2>/dev/null
if [ ! -f "$p/Settings/ServerGameSettings.json" ]; then
	echo "$p/Settings/ServerGameSettings.json not found. Copying default file."
	cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$p/Settings/" 2>&1
fi
if [ ! -f "$p/Settings/ServerHostSettings.json" ]; then
	echo "$p/Settings/ServerHostSettings.json not found. Copying default file."
	cp "$s/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$p/Settings/" 2>&1
fi

# Checks if log file exists, if not creates it
current_date=$(date +"%Y%m%d-%H%M")
logfile="$current_date-VRisingServer.log"
if ! [ -f "${p}/$logfile" ]; then
	echo "Creating ${p}/$logfile"
	touch "$p/$logfile"
fi

# Also check if $server_directory/VRisingServer.exe exists
if [ ! -f "$s/VRisingServer.exe" ]; then
  echo "ERROR: $s/VRisingServer.exe not found! Please check your server directory."
  exit 1
fi

echo "Launching V Rising Dedicated Server"
echo " "
# Start server in a headless X environment
v() {
  xvfb-run -a \
    --server-args="-screen 0 1280x720x24" \
    env WINEARCH=win64 \
        HODLL64=libarm64ecfex.dll \
        HODLL=libwow64fex.dll \
        WINEDEBUG=+loaddll,+seh \
    wine /home/vrising/server/VRisingServer.exe \
      -persistentDataPath "$p" \
      -serverName "$SERVERNAME" \
      "$override_savename" \
      -logFile "$p/$logfile" \
      -nographics \
      -batchmode \
      "$game_port" "$query_port" \
    2>&1 &
}

v

# Gets the PID of the last command
ServerPID=$!

# Tail log file and waits for Server PID to exit
/usr/bin/tail -n 0 -f "$p/$logfile" &
wait $ServerPID