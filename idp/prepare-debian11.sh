#!/bin/bash
# This script is meant for quick & easy install via:
#   $ curl -fsSL https://raw.githubusercontent.com/wireless-broadband-alliance/openroaming-oss/main/prepare-debian11.sh -o prepare-debian11.sh
#   $ chmod +x prepare-debian11.sh
#   $ ./prepare-debian11.sh

REPO_URL="https://github.com/wireless-broadband-alliance/openroaming-oss.git"
CERTS_PATH="/root/openroaming-oss/certs"

if [ "$EUID" -ne 0 ]
  then echo "You must run this script as root, you can either sudo the script directly or become root with a command such as 'sudo su'"
  exit
fi

if [[ ! -f "$CERTS_PATH/freeradius/cert.pem" ]]
then
    echo "Please upload your FreeRadius (LetsEncrypt) certificate to $CERTS_PATH/freeradius/cert.pem"
    exit 1
fi
if [[ ! -f "$CERTS_PATH/freeradius/chain.pem" ]]
then
    echo "Please upload your FreeRadius (LetsEncrypt) chain to $CERTS_PATH/freeradius/chain.pem"
    exit 1
fi
if [[ ! -f "$CERTS_PATH/freeradius/fullchain.pem" ]]
then
    echo "Please upload your FreeRadius (LetsEncrypt) fullchain to $CERTS_PATH/freeradius/fullchain.pem"
    exit 1
fi
if [[ ! -f "$CERTS_PATH/freeradius/privkey.pem" ]]
then
    echo "Please upload your FreeRadius (LetsEncrypt) private key to $CERTS_PATH/freeradius/privkey.pem"
    exit 1
fi

# Prompt for user input
read -p "Enter REALM name: " realm_name
read -p "Enter the client CIDR (default: 0.0.0.0/0): " client_cidr
client_cidr=${client_cidr:-0.0.0.0/0}
read -p "Enter the client secret (default: radsec): " client_secret
client_secret=${client_secret:-radsec}
read -p "Enter MySQL root password [admin]: " MYSQL_ROOT_PASSWORD
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-admin}

# Prompt for MySQL user name
read -p "Enter MySQL user name [admin]: " MYSQL_USER
MYSQL_USER=${MYSQL_USER:-admin}

# Prompt for MySQL password
read -p "Enter MySQL password [admin]: " MYSQL_PASSWORD
MYSQL_PASSWORD=${MYSQL_PASSWORD:-admin}

# Save the values to a .env file
cat > .env <<EOL
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
EOL

# Replace placeholders in the sql file
sed -i "s/-RSQLUSER-/${MYSQL_USER}/g" /root/openroaming-oss/idp/configs/freeradius/mods-available/sql
sed -i "s/-RSQLPASS-/${MYSQL_PASSWORD}/g" /root/openroaming-oss/idp/configs/freeradius/mods-available/sql

# Install dependencies
apt-get update -y
apt-get install curl wget nano git python3 python3-pip -y

if ! command -v docker &> /dev/null
then
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
else
    echo "Docker is already installed. Skipping installation."
fi

pip3 install docker-compose

#Prepare the environment
cd /root
#git clone $REPO_URL
# Prepare certificates
rm -rf /root/openroaming-oss/idp/configs/freeradius/certs/*.pem
#Prepare FreeRADIUS Certs
cp $CERTS_PATH/freeradius/*.pem /root/openroaming-oss/idp/configs/freeradius/certs
# ready workdir
cd /root/openroaming-oss/idp/
docker compose up -d

echo "Reminder: Make sure UDP ports 11812 and 11813 are open on your firewall (on your cloud provider if applicable), refer to the documentation for more details"
