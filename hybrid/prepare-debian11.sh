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

if [[ ! -f "$CERTS_PATH/wba/key.pem" ]]
then
    echo "Please upload your certificate private key to $CERTS_PATH/wba/key.pem"
    exit 1
fi


if [[ ! -f "$CERTS_PATH/wba/client.cer" ]]
then
    echo "Please upload your OpenRoaming certificate to $CERTS_PATH/wba/client.cer"
    exit 1
fi

# Install dependencies
apt-get update -y
apt-get install curl wget nano git python3 python3-pip -y

#Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
pip3 install docker-compose

#Prepare the environment
cd /root
git clone $REPO_URL
# Prepare certificates
cd /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain
rm -rf /root/openroaming-oss/hybrid/configs/radsecproxy/certs/key.pem
rm -rf /root/openroaming-oss/hybrid/configs/radsecproxy/certs/client.cer
rm -rf /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain.pem
cp $CERTS_PATH/wba/key.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/key.pem
cp $CERTS_PATH/wba/client.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/client.pem
cat /root/openroaming-oss/hybrid/configs/radsecproxy/certs/client.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain/WBA_Issuing_CA.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain/WBA_Cisco_Policy_CA.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain/WBA_Kyrio_Issuing_CA.pem /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain/WBA_OpenRoaming_Root.pem > /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain.pem

# ready workdir
cd /root/openroaming-oss/hybrid/

echo " =============================================="
echo " =============================================="
echo " =============================================="


echo "Next steps:"
echo "1 - Run the command 'nano /root/openroaming-oss/hybrid/configs/radsecproxy/radsecproxy.conf' and update the IP address and secret according to the documentation"
echo "2 - [LEGANCY, YOU PROBABLY CAN DISREGARD] Before starting the service make sure your cert-chain.pem was generated correctly, refer to the documentation for images of how it should look like (you can open the file the same way as the step before 'nano /root/openroaming-oss/hybrid/configs/radsecproxy/certs/chain/cert-chain.pem')"
echo "3 - Run the command 'cd /root/openroaming-oss/hybrid/' to make sure you are on the correct folder"
echo "4 - Run the command 'docker-compose up -d' and you should be up and running"

echo "Reminder: Make sure UDP ports 11812 and 11813 are open on your firewall (on your cloud provider if applicable), refer to the documentation for more details"
