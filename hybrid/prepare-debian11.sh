#!/bin/bash
# This script is meant for quick & easy install via:
#   $ curl -fsSL https://raw.githubusercontent.com/wireless-broadband-alliance/wba-openroaming-connector/main/prepare-debian11.sh -o prepare-debian11.sh
#   $ chmod +x prepare-debian11.sh
#   $ ./prepare-debian11.sh

REPO_URL="https://github.com/wireless-broadband-alliance/wba-openroaming-connector.git"
CERTS_PATH="/root/wba-openroaming-connector/certs"

if [ "$EUID" -ne 0 ]
  then echo "You must run this script as root, you can either sudo the script directly or become root with a command such as 'sudo su'"
  exit
fi

if [[ ! -f "$CERTS_PATH/wba/key.pem" ]]
then
    echo "Please upload your certificate private key to $CERTS_PATH/wba/key.pem"
    exit 1
fi


if [[ ! -f "$CERTS_PATH/wba/client.pem" ]]
then
    echo "Please upload your OpenRoaming certificate to $CERTS_PATH/wba/client.pem"
    exit 1
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
sed -i "s/-RSQLUSER-/${MYSQL_USER}/g" /root/wba-openroaming-connector/hybrid/configs/freeradius/mods-available/sql
sed -i "s/-RSQLPASS-/${MYSQL_PASSWORD}/g" /root/wba-openroaming-connector/hybrid/configs/freeradius/mods-available/sql

# Install dependencies
apt-get update -y
apt-get install curl wget nano git -y

if ! command -v docker &> /dev/null
then
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
else
    echo "Docker is already installed. Skipping installation."
fi

#Prepare the environment
cd /root
git clone $REPO_URL
# Prepare certificates
cd /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/chain
rm -rf /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/key.pem
rm -rf /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/client.pem
rm -rf /root/wba-openroaming-connector/hybrid/chybridonfigs/radsecproxy/certs/chain.pem
rm -rf /root/wba-openroaming-connector/hybrid/configs/freeradius/certs/*.pem
#Prepare RadSec Certs
cp $CERTS_PATH/wba/key.pem /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/key.pem
cp $CERTS_PATH/wba/client.pem /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/client.pem
cat /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/client.pem /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/chain/WBA_Issuing_CA.pem /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/chain/WBA_Cisco_Policy_CA.pem /root/wba-openroaming-connector/anp/configs/radsecproxy/certs/chain/WBA_Issuing7_CA.pem /root/wba-openroaming-connector/anp/configs/radsecproxy/certs/chain/WBA_Policy7_CA.pem > /root/wba-openroaming-connector/hybrid/configs/radsecproxy/certs/chain.pem
sed -i "s/-RNAME-/${realm_name//./\\.}/g" /root/wba-openroaming-connector/hybrid/configs/radsecproxy/radsecproxy.conf
sed -i "s/-RNAME-/${realm_name//./\\.}/g" /root/wba-openroaming-connector/hybrid/configs/freeradius/proxy.conf
sed -i "s|-RCLIENT-|${client_cidr}|g" /root/wba-openroaming-connector/hybrid/configs/radsecproxy/radsecproxy.conf
sed -i "s/-RSECRET-/${client_secret}/g" /root/wba-openroaming-connector/hybrid/configs/radsecproxy/radsecproxy.conf
#Prepare FreeRADIUS Certs
cp $CERTS_PATH/freeradius/*.pem /root/wba-openroaming-connector/hybrid/configs/freeradius/certs
# ready workdir
cd /root/wba-openroaming-connector/hybrid/
docker compose up -d

echo "Reminder: Make sure UDP ports 11812 and 11813 are open on your firewall (on your cloud provider if applicable), refer to the documentation for more details"
