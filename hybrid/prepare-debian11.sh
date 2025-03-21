#!/bin/bash
REPO_URL="https://github.com/wireless-broadband-alliance/openroaming-oss.git"

# Determine the base directory one level up from this script's location
BASE_DIR="$(realpath "$(dirname "$0")/..")"
CERTS_PATH="$BASE_DIR/certs"


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
sed -i "s/-RSQLUSER-/${MYSQL_USER}/g" ./configs/freeradius/mods-available/sql
sed -i "s/-RSQLPASS-/${MYSQL_PASSWORD}/g" ./configs/freeradius/mods-available/sql

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
#cd /root
#git clone $REPO_URL
# Prepare certificates
# First, make sure we're in the hybrid directory
cd "$(dirname "$0")"

# Clean up existing certificates
rm -rf ./configs/radsecproxy/certs/key.pem
rm -rf ./configs/radsecproxy/certs/client.pem
rm -rf ./configs/radsecproxy/certs/chain.pem
rm -rf ./configs/freeradius/certs/*.pem

# Prepare RadSec Certs
cp $CERTS_PATH/wba/key.pem ./configs/radsecproxy/certs/key.pem
cp $CERTS_PATH/wba/client.pem ./configs/radsecproxy/certs/client.pem
cat ./configs/radsecproxy/certs/client.pem ./configs/radsecproxy/certs/chain/WBA_Issuing_CA.pem ./configs/radsecproxy/certs/chain/WBA_Cisco_Policy_CA.pem > ./configs/radsecproxy/certs/chain.pem

# Update configuration files
sed -i "s/-RNAME-/${realm_name//./\\.}/g" ./configs/radsecproxy/radsecproxy.conf
sed -i "s/-RNAME-/${realm_name//./\\.}/g" ./configs/freeradius/proxy.conf
sed -i "s|-RCLIENT-|${client_cidr}|g" ./configs/radsecproxy/radsecproxy.conf
sed -i "s/-RSECRET-/${client_secret}/g" ./configs/radsecproxy/radsecproxy.conf

# Prepare FreeRADIUS Certs
cp $CERTS_PATH/freeradius/*.pem ./configs/freeradius/certs
# ready workdir
cd ./
# Stop any running containers first
docker compose down
# Build and Start the Containers
docker compose build --no-cache
docker compose up -d

echo "Reminder: Make sure UDP ports 11812 and 11813 are open on your firewall (on your cloud provider if applicable), refer to the documentation for more details"
