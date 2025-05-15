FROM ubuntu:jammy

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    WINEDEBUG=-all \
    STEAMAPPID=1829350 \
    WINEPREFIX=/home/vrising/.wine-vrising

# Add user for steamcmd (Steam user)
RUN useradd -m steam && \
    mkdir -p /home/steam/vrising-server /home/steam/vrising-data && \
    chown -R steam:steam /home/steam


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


# WORKDIR on steamcmd
WORKDIR /home/steam

COPY scripts/start_server.sh /home/steam/start_server.sh
RUN chmod +x /home/steam/start_server.sh

COPY scripts/download-server.sh /home/steam/download-server.sh
RUN chmod +x /home/steam/download-server.sh

## Healthcheck to ensure the server is running on ports 9876 and 9877
#HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#    CMD curl -f http://localhost:9876/ || exit 1

USER steam

RUN /home/steam/download-server.sh

EXPOSE 9876/udp 9877/udp

VOLUME ["/home/steam/vrising-data"]

ENTRYPOINT ["/home/steam/start_server.sh"]
