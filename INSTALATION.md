# Installation Guide

This guide is designed to help you set up a clean local installation for FreeRADIUS. Follow the steps carefully to ensure a proper and functional setup.  
This project is specifically designed to be executed in the root folder of **Debian-based systems**. Running it outside the root folder or on non-Debian systems will be blocked due to missing permissions or capabilities for a proper configuration.

## Table of Contents
[Get Started](#get-started)
1. [Project Clone and Environment Configuration](#1-project-clone-and-environment-configuration)
2. [Requirements](#2-requirements)
3. [Running the prepare-debian11.sh Script](#3-running-the-prepare-debian11sh-script)
4. [Verifying Docker Containers](#4-verifying-docker-containers)
---

## Get Started

Read [LETSENCRYPT](LETSENCRYPT.md) for instructions on how to automate certificate generation using Lets Encrypt.

Begin by preparing the system using the provided configuration script: **`prepare-debian11.sh`**.  
It configures FreeRADIUS by performing key steps such as installing dependencies, validating required certificates, and preparing the necessary configurations for deployment. This ensures a smooth and consistent installation process.

- All configurations for this project are applied inside the **hybrid** folder. The folders located at the same root level of the project are only used during the initial installation.
- Ensure that the **`prepare-debian11.sh`** script is run **only once**:
   - After the first run, the configuration variables will be removed and overwritten.
   - To rerun the script or fix issues, you must either start the entire guide again or selectively modify specific files to reapply changes to the Docker Compose setup.
   - For more details on which files to modify, review **Section Two** of the [WBA OpenRoaming Connector Installation Guide](#).

---

### 1. Project Clone and Environment Configuration

To begin, clone the project repository or download it directly from the official GitHub link below:

- **GitHub Repository**:  
  [https://github.com/wireless-broadband-alliance/wba-openroaming-connector](https://github.com/wireless-broadband-alliance/wba-openroaming-connector)

#### Steps to Retrieve the Project:
1. **Clone via Git**:
   ```bash
   git clone https://github.com/wireless-broadband-alliance/openroaming-oss.git
   ```

2. **Download as a ZIP file**:
   - Navigate to the repository on GitHub, select the **Code** button, and click **Download ZIP**.

3. After cloning or downloading the project, locate the `env.sample` file in the root of the repository.
   - This file contains critical environment variables that need to be updated before proceeding.

4. Rename the `env.sample` file to `.env`:
   ```bash
   mv env.sample .env
   ```

5. Open the `.env` file in a text editor and update the following values with your own database credentials:
   ```
   MYSQL_ROOT_PASSWORD=your_root_password
   MYSQL_USER=your_user
   MYSQL_PASSWORD=your_password
   ```

6. If you're running **hybrid** or **idp** Go to the `freeradius/mods-available/sql` file and edit the following credentials section, to let the freeradius know what is the name of the docker container and the credentials of the mysql user to be able to edit the radius table.

```yaml
server = "hybrid_mysql_1"
port = 3306
login = "root"
password = "admin"
```

**Note**: For server property please define the name of the container of the IP of the current machine

7. Save the file and ensure it remains in the project's root directory.

---

#### Notes:
- The `.env` file ensures that the database and associated services are configured correctly during the setup process. Make sure this is done before running any scripts.
- Use a strong password for `MYSQL_ROOT_PASSWORD` to secure your environment.

---


### 2. Requirements

Ensure the following requirements are met before starting the installation process:

1. **Run with Root Privileges**:
   - Use `sudo` or switch to the root user if not already running with root privileges:
     ```bash
     sudo su
     ```

2. **Certificates and Keys**:
   - Make sure the necessary certificates and keys are placed in their respective paths:

   **WBA Certificates**:
   - `/root/openroaming-oss/certs/wba/key.pem`: Your certificate private key.
   - `/root/openroaming-oss/certs/wba/client.pem`: Your OpenRoaming certificate.

   **FreeRADIUS Certificates**:
   - `/root/openroaming-oss/certs/freeradius/cert.pem`: FreeRADIUS certificate (e.g., Let's Encrypt certificate).
   - `/root/openroaming-oss/certs/freeradius/chain.pem`: FreeRADIUS chain file.
   - `/root/openroaming-oss/certs/freeradius/fullchain.pem`: FreeRADIUS full chain file.
   - `/root/openroaming-oss/certs/freeradius/privkey.pem`: FreeRADIUS private key.

#### Note:
Failing to provide these files in the correct locations will cause the installation process to halt.

---

### 3. Running the `prepare-debian11.sh` Script

After meeting the requirements, execute the **`prepare-debian11.sh`** script to perform configuration and installation tasks.

#### How to Run the Script:
1. Make sure you are in the root folder of the project:
   ```bash
   cd ~/openroaming-oss/hybrid
   ```

2. Execute the script:
   ```bash
   ./prepare-debian11.sh
   ```

#### Example:
```bash
root@tetrapi-XPS-15-7590:~/openroaming-oss/hybrid# ./prepare-debian11.sh
```

---

#### Notes:
- **Only Run Once**: Running the script multiple times may overwrite existing configurations.
- If interrupted or rerunning is required, ensure:
   - The environment is cleaned.
   - Certificates are correctly placed.
- The script validates the presence of all required certificates in `/root/openroaming-oss/certs`.

---

# 4. Verifying Docker Containers

Once the setup is complete, verify that all expected services are running using `docker ps`.

#### Command:
```bash
docker ps
```

#### Example Output:
```plaintext
CONTAINER ID   IMAGE                 COMMAND                  STATUS         PORTS                                         NAMES
642d2a23f456   hybrid-freeradius     "/docker-entrypoint.…"   Up 5 minutes   1812-1813/udp                                hybrid-freeradius-1
8f250ad4a907   hybrid-radsecproxy    "/sbin/tini -- /root…"   Up 5 minutes   0.0.0.0:2083->2083/tcp, 11812-11813/tcp      hybrid-radsecproxy-1
4cc3b65c2a51   mysql:8.0             "docker-entrypoint.s…"   Up 5 minutes   0.0.0.0:3306->3306/tcp                       hybrid-mysql_freeradius-1
```

---

#### Key Points to Verify:
- **Container Names**: Ensure the containers correspond to roles in the project:
   - `hybrid-freeradius-1`
   - `hybrid-radsecproxy-1`
   - `hybrid-mysql_freeradius-1`

- **Port Mapping**: Verify the following ports:
   - UDP ports `1812-1813` for FreeRADIUS.
   - TCP and UDP ports `2083` for RadSecProxy.
   - MySQL port `3306` for database access.

- **Status**: Confirm all containers display **Up** in the status field.

---

## 3. Connect
In the ANP and Hybrid configuration it is assumed that you will use ports `11812` and `11813` Radius for any access points trying to authenticate. 
For the IDP and Hybrid configurations it is assumed that you will use `2083` for IDP clients.

### Final Steps

After verifying everything is running correctly:
- Validate that relevant ports are open. Use the following command to allow required ports via UFW:
  ```bash
  for port in 11812/tcp 11812/udp 11813/tcp 11813/udp 2083/tcp 2083/udp; do sudo ufw allow $port; done
  ```

- Deploy the environment by running:
  ```bash
  docker compose up -d
  ```
---
