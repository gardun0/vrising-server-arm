FROM ubuntu:jammy

VOLUME ["/home/steam/vrising-data", "/home/steam/vrising-server"]

USER root

ARG DEBIAN_FRONTEND="noninteractive"

ENV TZ=UTC \
    WINEDEBUG=-all \
    STEAMAPPID=1829350 \
    WINEPREFIX=/home/steam/.wine

# Add user for steamcmd (Steam user)
RUN useradd -m steam && \
    mkdir -p /home/steam/vrising-server /home/steam/vrising-data && \
    chown -R steam:steam /home/steam && \
    chmod -R u+rwX /home/steam


# Install dependencies and SteamCMD
RUN apt-get update && apt-get install -y \
    software-properties-common wget && \
    dpkg --add-architecture i386 && \
    add-apt-repository multiverse && \
    apt-get update && \
    echo steam steam/question select "I AGREE" | debconf-set-selections && \
    echo steam steam/license note '' | debconf-set-selections && \
    apt-get install steamcmd -y \
    && rm -rf /var/lib/apt/lists/*

# Install Wine and dependencies
RUN mkdir -pm755 /etc/apt/keyrings && \
    wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key && \
    wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/dists/$(lsb_release -cs)/winehq-$(lsb_release -cs).sources && \
    apt-get update && \
    apt-get install --install-recommends winehq-staging -y && \
    apt-get install cabextract winbind screen xvfb -y && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /home/steam/.wine && \
    chown -R steam:steam /home/steam/.wine

# WORKDIR on steamcmd
USER steam
WORKDIR /home/steam

COPY scripts/boot_server.sh /home/steam/boot_server.sh
RUN chmod +x /home/steam/boot_server.sh

## Healthcheck to ensure the server is running on ports 9876 and 9877
#HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#    CMD curl -f http://localhost:9876/ || exit 1

EXPOSE 9876/udp 9877/udp

ENTRYPOINT ["/home/steam/boot_server.sh"]
