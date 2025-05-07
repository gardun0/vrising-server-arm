# ─── SteamCMD Stage ─────────────────────────────────────────────────────────────
FROM ghcr.io/sonroyaalmerol/steamcmd-arm64 AS steamcmd

# Allow passing in a custom AppID; V Rising Dedicated Server is 1829350
ENV STEAMAPPID=1829350 \
    SERVER_DIR=/home/steam/vrisingserver

# Create and switch into the install directory
USER root
COPY scripts/download-server.sh /home/steam/download-server.sh

# Download & install the server with SteamCMD
USER steam
CMD ["/home/steam/download-server.sh"]
#RUN bash /home/steam/steamcmd/steamcmd.sh +login anonymous \
#    +@sSteamCmdForcePlatformType windows \
#    +force_install_dir ${SERVER_DIR} \
#    +app_update ${STEAMAPPID} validate \
#    +quit

# List the contents of the directory
#RUN set -eux; \
#    echo "Contents of ${SERVER_DIR}:"; \
#    ls -l ${SERVER_DIR}; \
#    # Echo full path to the server directory
#    echo "Server directory: $(readlink -f ${SERVER_DIR})";

# ─── Builder Stage ─────────────────────────────────────────────────────────────
FROM arm64v8/ubuntu:jammy AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    WINEDEBUG=-all \
    STEAMAPPID=1829350 \
    WINEPREFIX=/home/vrising/.wine-vrising \
    WINEARCH=win64

# Install dependencies
RUN apt-get update && apt-get install -y \
    qemu-user-static binfmt-support \
    ca-certificates curl unzip \
    libfreetype6-dev libfontconfig1 libgl1-mesa-glx \
    libpulse0 libasound2 libopenal1 \
    libssl-dev libxml2 jq xvfb \
    && rm -rf /var/lib/apt/lists/*

# Install Hangover
WORKDIR /tmp

RUN set -eux; \
    # 1. Download the tar as before…
    HANGOVER_URL="$(curl -sSL https://api.github.com/repos/AndreRH/hangover/releases/latest \
                   | grep browser_download_url \
                   | grep jammy_arm64\\.tar \
                   | head -n1 \
                   | cut -d '"' -f4)"; \
    curl -sSL "$HANGOVER_URL" -o hangover.tar; \
    \
    tar -tvf hangover.tar; \
    # 2. Extract ONLY the .deb files (ignore dxvk-v*.tar.gz)
    tar -xvf hangover.tar --wildcards '*.deb'; \
    # List the .deb files
    echo "The following .deb files were extracted:"; \
    ls -l; \
    # 3. Install them via dpkg, then fix deps
    apt-get update; \
    apt install -y ./*.deb; \
    \
    # 4. Cleanup
    rm -f hangover.tar ./*.deb; \
    rm -rf /var/lib/apt/lists/*

# 4) Create non-root vrising user, init a Wine prefix under Hangover
#RUN useradd -m vrising
#USER vrising
WORKDIR /home/vrising

COPY --from=steamcmd /home/steam/vrisingserver /home/vrising/server

USER root
# Chown the server and data directories to the vrising user
RUN chown -R 1000:1000 /home/vrising/server

# List the contents of the server directory and steamapps folder if it exists
RUN set -eux; \
    echo "Contents of /home/vrising/server:"; \
    ls -l /home/vrising/server; \
    # Echo full path to the server directory
    echo "Server directory: $(readlink -f /home/vrising/server)"; \
    # List the contents of the steamapps folder if it exists
    if [ -d "/home/vrising/server/steamapps" ]; then \
        echo "Contents of /home/vrising/server/steamapps:"; \
        ls -l /home/vrising/server/steamapps; \
    fi

# Give read/write access to the server directory to the vrising user
# RUN chmod -R 755 /home/vrising/server

COPY scripts/start_server.sh /home/vrising/start_server.sh
RUN chmod +x /home/vrising/start_server.sh

## Healthcheck to ensure the server is running on ports 9876 and 9877
#HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#    CMD curl -f http://localhost:9876/ || exit 1

EXPOSE 9876/udp 9877/udp

VOLUME ["/home/vrising/data"]

ENTRYPOINT ["/home/vrising/start_server.sh"]
