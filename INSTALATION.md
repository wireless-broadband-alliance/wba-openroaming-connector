# ⚙️ Installation Guide

This guide is intended solely to assist in setting up the **OpenRoaming Connector** project. It provides
step-by-step instructions for configuring it.

Please follow the instructions below, starting from the **root** folder of the project, to prepare it:

## 1. Make sure to copy your certificate files to the following folders:
    - "foldername: e.g. openroaming-oss"/**hybrid/configs/radsecproxy/certs/chain**
        - key.pem
        - client.pem
        - chain.pem
    - "foldername: e.g. openroaming-oss"/**hybrid/configs/freeradius/certs**
        - ca.pem (Let's Encrypt "https://letsencrypt.org/certificates/")
        - cert.pem (Your Own certificate)
        - chain.pem (Let's Encrypt certificated created from the ca.pem)
        - fullchain.pem (Combination of cert.pem with chain.pem)
        - privkey.pem (Belongs to the cert.pem)

## 2. Run the prepare-debian11.sh script:

Make sure to correctly set up your credentials when running this file. After making changes and providing the required information, all variables will be overwritten, and it will only be possible to change them again manually by editing each file within **prepare-debian11.sh**.

For deployment, always use **prepare-debian11.sh** and **only edit the following files as necessary**:

1. Separate the following files for editing, all of which are located inside the 'hybrid' folder."
    1. **radsecproxy.conf**;
    2. **proxy.conf**;
    3. **sql**;
2. And you need to have installed on your machine **Docker** to build all the three containers
    1. **Mysql** -> to save all the data from the radius table used by freeradius container;
    2. **Freeradius**-> to authenticate users on your have;
    3. **Radsecproxy**-> is a generic RADIUS proxy that in addition to usual RADIUS UDP transport, this container is
       depended on the freeradius.
3. Add the following section near on the **radsecproxy.conf** file:

```yaml
client 0.0.0.0/0 {
  host 0.0.0.0/0
  type udp
  secret radsec
} 
```

And remember to add this above, near to the **realm section**:

```yaml
realm /.*@example\.com$/ { this is the realm defined on your certificates
  server localproxy
  accountingServer localproxy-acct
  accountingResponse on
}
```

4. Edit the **proxy.conf** file, and add this (Make sure to define the same realm as the radsecproxy.conf file)

```yaml
realm example.com {

}
```

5. If you're running **hybrid** or **idp** Go to the `freeradius/mods-available/sql` file and edit the following credentials section, to let the freeradius know what is the name of the docker container and the credentials of the mysql user to be able to edit the radius table.

```yaml
server = "hybrid_mysql_1"
port = 3306
login = "root"
password = "admin"
```

**Note**: For server property please define the name of the container of the IP of the current machine

6. Next you have to enable the ports being used by the containers on your machine. For Ubuntu server systems, you can
   type the following line.

Also, make sure to install the **ufw** package with **"apt update"**, **apt upgrade"** and **"apt install ufw"**.

```bash
for port in 11812/tcp 11812/udp 11813/tcp 11813/udp 2083/tcp 2083/udp; do sudo ufw allow $port; done
```

After following all these steps, remember to create the containers and ensure they are working properly. Please run the following command in the terminal:

```bash
docker compose up -d
```
