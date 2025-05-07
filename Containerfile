# ─── SteamCMD Stage ─────────────────────────────────────────────────────────────
FROM ghcr.io/sonroyaalmerol/steamcmd-arm64 AS steamcmd

# Allow passing in a custom AppID; V Rising Dedicated Server is 1829350
ARG STEAMAPPID=1829350

# Create and switch into the install directory
USER root
RUN mkdir -p /v_rising_server && chown steam:steam /v_rising_server
USER steam
WORKDIR /v_rising_server

# List the contents of the directory
RUN set -eux; \
    echo "Contents of /v_rising_server:"; \
    ls -l /home/steam/steamcmd

# Download & install the server with SteamCMD
RUN bash /home/steam/steamcmd/steamcmd.sh +login anonymous \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir /v_rising_server \
    +app_update ${STEAMAPPID} validate \
    +quit

# ─── Builder Stage ─────────────────────────────────────────────────────────────
FROM ubuntu:jammy AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    WINEDEBUG=-all \
    STEAMAPPID=1829350

# Install dependencies
RUN apt-get update && apt-get install -y \
    qemu-user-static binfmt-support \
    ca-certificates curl unzip \
    libfreetype6-dev libfontconfig1 libgl1-mesa-glx \
    libpulse0 libasound2 libopenal1 \
    libssl-dev libxml2 jq \
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
RUN useradd -m vrising
USER vrising
WORKDIR /home/vrising

COPY --from=steamcmd /v_rising_server /home/vrising/server

# Create data directory
RUN mkdir -p ./data

USER root
# Chown the server and data directories to the vrising user
RUN chown -R vrising:vrising /home/vrising/server
RUN chown -R vrising:vrising /home/vrising/data


COPY start_server.sh /home/vrising/start_server.sh
RUN chmod +x /home/vrising/start_server.sh

# ─── Final Stage ──────────────────────────────────────────────────────────────
USER vrising

# Healthcheck to ensure the server is running on ports 9876 and 9877
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9876/ || exit 1

EXPOSE 9876/udp 9877/udp

ENTRYPOINT ["/home/vrising/start_server.sh"]
