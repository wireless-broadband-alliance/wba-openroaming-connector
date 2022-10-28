#!/bin/bash
# This script is meant for quick & easy install via:
#   $ curl -fsSL https://raw.githubusercontent.com/wireless-broadband-alliance/openroaming-oss/main/prepare-debian11.sh -o prepare-debian11.sh
#   $ chmod +x prepare-debian11.sh
#   $ ./prepare-debian11.sh

if [ "$EUID" -ne 0 ]
  then echo "You must run this script as root, you can either sudo the script directly or become root with a command such as 'sudo su'"
  exit
fi

if [[ ! -f "/root/private_key.pem" ]]
then
    echo "Please upload your certificate private key to /root/private_key.pem"
    echo "Please make sure the file is named as private_key.pem"
    exit 1
fi


if [[ ! -f "/root/or-client.cer" ]]
then
    echo "Please upload your OpenRoaming certificate to /root/or-client.cer"
    echo "Please make sure the file is named as or-client.cer"
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
git clone https://github.com/wireless-broadband-alliance/openroaming-oss.git
# Prepare certificates
cd /root/openroaming-oss/configs/radsecproxy/certs/chain
mv /root/private_key.pem /root/openroaming-oss/configs/radsecproxy/certs/private_key.pem
mv /root/or-client.cer /root/openroaming-oss/configs/radsecproxy/certs/or-client.cer
cat /root/openroaming-oss/configs/radsecproxy/certs/or-client.cer /root/openroaming-oss/configs/radsecproxy/certs/chain/WBA_Kyrio_Issuing_CA.pem /root/openroaming-oss/configs/radsecproxy/certs/chain/WBA_Cisco_Policy_CA.pem > /root/openroaming-oss/configs/radsecproxy/certs/chain/cert-chain.pem

# ready workdir
cd /root/openroaming-oss/

echo "Next steps:"
echo "1 - Run the command 'nano /root/openroaming-oss/configs/radsecproxy/radsecproxy.conf' and change the IP address and secret according to the documentation"
echo "2 - Before starting the service make sure your cert-chain.pem was generated correctly, refer to the documentation for images of how it should look like (you can open the file the same way as the step before 'nano /root/openroaming-oss/configs/radsecproxy/certs/chain/cert-chain.pem')"
echo "3 - Run the command 'docker-compose up -d' and you should be up and running"

echo "Reminder: Make sure UDP ports 1812 and 1813, and TCP port 2083 are open on your firewall (on your cloud provider if applicable), refer to the documentation for more details"
