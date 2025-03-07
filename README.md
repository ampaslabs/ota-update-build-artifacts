# Building Artifacts for SocketXP OTA Update
[SocketXP](https://www.socketxp.com) is an [IoT device management platform](https://www.socketxp.com/socketxp-iot-device-management-platform) that can be used to remotely manage, monitor, access, update and control IoT or any embedded Linux devices at massive scale.

[SocketXP OTA Update](/iot-ota-update) allows you to upload and deploy your artifacts such as IoT application, debian packages, docker containers, firmware, and configuration files, as software updates on a fleet of remote IoT devices.

Building an artifact is the first step in the OTA update process.

This repository has examples on how to build the following types of artifacts:
- Application binary
- Software Packages (deb, rpm)
- Program Files (Python, Go, Shell)
- Config Files (JSON, XML, YAML)
- Script Files (Shell, Python)
- Docker Container
- Firmware

The examples in this repo will show you how to build an artifact and package it as a tar.gz archive file, so that it can be uploaded to the SocketXP Cloud Artifact Registry.  Deploy OTA updates from the registry.
