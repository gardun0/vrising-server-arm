#!/bin/bash

server_directory=/home/vrising/server
server_data=/home/vrising/data
LOG_COUNT=30

cleanup_logs() {
    echo "Keeping only the latest $LOG_COUNT log files"

    # Find all log files and sort them by modification time (newest first)
    log_files=$(find "$server_data" -name "*.log" -type f -printf "%T@ %p\n" | sort -rn | cut -d' ' -f2-)

    # Keep only the latest $LOGDAYS log files
    latest_logs=$(echo "$log_files" | head -n $LOG_COUNT)

    # Remove the rest of the log files
    for log in $log_files; do
        if ! echo "$latest_logs" | grep -q "$log"; then
            echo "Removing old log: $log"
            rm "$log"
        fi
    done
}

main() {
  # Check if the script is run as root
  if [ ! -r "$server_directory" ] || [ ! -w "$server_directory" ]; then
      echo "ERROR: I do not have read/write permissions to $server_directory! Please run "chown -R 1000:1000 $server_directory" on host machine, then try again."
      exit 1
  fi

  # Validate server settings directory and files
  mkdir "$server_data/Settings" 2>/dev/null
  if [ ! -f "$server_data/Settings/ServerGameSettings.json" ]; then
          echo "$server_data/Settings/ServerGameSettings.json not found. Copying default file."
          cp "$server_directory/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json" "$server_data/Settings/"
  fi
  if [ ! -f "$server_data/Settings/ServerHostSettings.json" ]; then
          echo "$server_data/Settings/ServerHostSettings.json not found. Copying default file."
          cp "$server_directory/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json" "$server_data/Settings/"
  fi

  cleanup_logs

  # Checks if log file exists, if not creates it
  current_date=$(date +"%Y%m%d-%H%M")
  logfile="$current_date-VRisingServer.log"
  if ! [ -f "${server_data}/$logfile" ]; then
          echo "Creating ${server_data}/$logfile"
          touch $server_data/$logfile
  fi

  echo -e '
   __      _______  _____  _____ _____ _   _  _____
   \ \    / /  __ \|_   _|/ ____|_   _| \ | |/ ____|
    \ \  / /| |__) | | | | (___   | | |  \| | |  __
     \ \/ / |  _  /  | |  \___ \  | | | . ` | | |_ |
      \  /  | | \ \ _| |_ ____) |_| |_| |\  | |__| |
       \/   |_|  \_\_____|_____/|_____|_| \_|\_____|
  '
  echo "Preparing to launch V Rising Dedicated Server"
  echo " "

  bash -c "WINEARCH=win64 wineboot --init"
  bash -c "WINEARCH=win32 wineboot --init"

  echo "Launching V Rising Dedicated Server"
  echo " "
  # Start server
  v() {
    hangover_cmd="$server_directory/VRisingServer.exe -persistentDataPath $server_data -logFile $server_data/$logfile -nographics -batchmode"
    xvfb-run sh -c "WINEARCH=win64 HODLL64=libarm64ecfex.dll HODLL=libwow64fex.dll wine '$hangover_cmd' 2>&1" &
    echo $!
  }

  v

  ServerPID=$!

  # Tail log file and waits for Server PID to exit
  tail -n 0 -f $server_data/$logfile &
  wait $ServerPID
}

main