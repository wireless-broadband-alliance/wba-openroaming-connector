# 🌐︎ OpenRoaming Connector

Welcome to the Openroaming Connector! This repository offers a **reference implementation to establish an industry baseline** for the necessary components to develop FreeRadius and RadSecProxy machines capable of authenticating Passpoint profiles for Openroaming.

## Why it was created?

The project was developed to simplify the setup process for FreeRadius, RadSecProxy, and MySQL configurations in Openroaming. It also aims to ensure that all necessary components are in place to support the generation and synchronization of Passpoint provisioning profiles.

## How it works?

OpenRoaming is an **open standard developed to enable global, secure, and automatic Wi-Fi connectivity**. With OpenRoaming, users can connect to Wi-Fi networks without being prompted for login credentials, while carrying a unique embedded identity.

The script (prepare-debian11.sh) provided in this project simplifies the setup of FreeRadius, RadSecProxy, and MySQL servers by automating the process of preparing the necessary certificates, realm names, IP addresses, and other required information.

The are currently three possible scenarios:
- Access Network Provider Connector (ANP)
- Identity Provider Connector (IDP)
- Hybrid Connector (combination of ANP and IDP)

The script prompts the user for input and saves the values to a .env file, which is then used to configure the Docker containers for FreeRadius, RadSecProxy, and MySQL. This makes it easy for users to set up a secure and
automatic Wi-Fi connectivity environment using the OpenRoaming standard.

For more information about OpenRoaming Technology please visit: https://openroaming.org

## Prerequisites:
- Git (optional and highly recommended for easier updates, if the user prefers to clone the repository)
- Linux based system - Ubuntu 22.04 LTS (tested for the reference implementation)
- Knowledge about Linux OS (required to set up the project)
- Docker (required for running the application and managing the multiple containers)

### How to get the Project

There are two options to retrieve the project:

1. **Clone the Repository**: If the you are familiar with Git and want to access the complete source code, can clone the
   repository using the following command:

```bash
- git clone https://github.com/wireless-broadband-alliance/wba-openroaming-connector.git
```

2. **Download Release Package**: Or if you can just download the release package from the releases section on GitHub. This package contains
   only the required components to run,
   including `.env.sample`, `docker-compose.yml`, and other necessary files.

   
# ⚙️ Installation Guide

Follow this link for more information on installing this project: [Installation Guide](INSTALATION.md).

