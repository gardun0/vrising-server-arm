# VRising ARM Ubuntu Dedicated Server
---
## Description
This is a Containerfile for running a VRising dedicated server on an ARM-based Ubuntu system using [Hangover](https://github.com/AndreRH/hangover?tab=readme-ov-file). It uses the SteamCMD tool to install and update the game server, and it is designed to be run in a Docker container.

## Prerequisites
- Podman installed on your system.
- ARM emulator installed on your system so that you can run x86_64 binaries on ARM architecture. You can use [qemu](https://www.qemu.org/) for this purpose.
