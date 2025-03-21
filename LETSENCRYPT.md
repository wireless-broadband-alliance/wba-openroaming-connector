# 🔐 Automating TLS Certificate Management for OpenRoaming RADIUS & RadSec Deployments

This guide explains how to obtain and auto-renew TLS certificates from **Let’s Encrypt** for use in **OpenRoaming**, **FreeRADIUS**, and **RadSecProxy** environments.

It covers both:
- ✅ **DNS-01 challenge** via **Cloudflare API**
- ✅ **HTTP-01 challenge** via **web server on port 80**

---

## 🧱 Prerequisites

- A system with **Certbot** installed
- A **publicly accessible domain** (e.g. `openroaming.example.com`)
- Either:
  - 🧩 **DNS access via Cloudflare API**, or
  - 🌐 A **web server on port 80** or **temporary standalone server** (with firewall allowing port 80)
- TLS support in FreeRADIUS or RadSecProxy (e.g., for EAP-TLS or RadSec)

---

## ✳️ Option 1: Issue Certificates via DNS-01 (Cloudflare)

### 🔹 Step 1: Install Certbot + Cloudflare Plugin
```bash
sudo apt install certbot python3-certbot-dns-cloudflare
```

### 🔹 Step 2: Configure API Credentials
Create:
```ini
# /etc/letsencrypt/cloudflare.ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
```
```bash
chmod 600 /etc/letsencrypt/cloudflare.ini
```

### 🔹 Step 3: Request the Certificate
```bash
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 60 \
  --cert-name openroaming \
  -d openroaming.example.com \
  -d idp.example.com
```

🔗 More on DNS plugins:  
👉 [https://certbot.eff.org/docs/using.html#dns-plugins](https://certbot.eff.org/docs/using.html#dns-plugins)

---

## ✳️ Option 2: Issue Certificates via HTTP-01 (Web Server)

### 🔹 Use Case: You have control over port 80 (e.g., Nginx, Apache, or can use Certbot standalone)

### 🔹 Step 1: Stop Existing Services on Port 80 (if any)
```bash
sudo systemctl stop nginx
```
Or open the port in your firewall.

### 🔹 Step 2: Run Certbot in Standalone Mode
```bash
certbot certonly \
  --standalone \
  --preferred-challenges http \
  --cert-name openroaming \
  -d openroaming.example.com \
  -d idp.example.com
```

Or use with webroot:
```bash
certbot certonly \
  --webroot -w /var/www/html \
  --cert-name openroaming \
  -d openroaming.example.com \
  -d idp.example.com
```

🔗 Certbot HTTP challenge docs:  
👉 [https://certbot.eff.org/docs/using.html#webroot](https://certbot.eff.org/docs/using.html#webroot)  
👉 [https://certbot.eff.org/docs/using.html#standalone](https://certbot.eff.org/docs/using.html#standalone)

---

## 📁 Standardize Output for FreeRADIUS / RadSec

Expected folder layout:
```
/path/to/your/radius/certs/
├── cert.pem
├── privkey.pem
├── chain.pem
├── fullchain.pem
└── ca.pem
```

---

## 🔄 Automate Updates via Deploy Hook

### 🔹 Create a deploy hook script:
```bash
sudo nano /usr/local/sbin/certbot-deploy-hook
```

```bash
#!/bin/bash

# Path to Let’s Encrypt live certs
SRC="/etc/letsencrypt/live/openroaming"

# Path to where RADIUS expects certs
DST="/path/to/your/radius/certs"

# Path to the folder that contains the docker-compose.yml file
DOCKER_DIR="/path/to/your/docker-compose-folder"

echo "[Certbot Hook] Copying updated certificates..."

mkdir -p "$DST"

cp -L "$SRC/cert.pem" "$DST/cert.pem"
cp -L "$SRC/chain.pem" "$DST/chain.pem"
cp -L "$SRC/fullchain.pem" "$DST/fullchain.pem"
cp -L "$SRC/privkey.pem" "$DST/privkey.pem"

echo "[Certbot Hook] Downloading ISRG Root X1 CA..."
curl -sS https://letsencrypt.org/certs/isrgrootx1.pem.txt -o "$DST/ca.pem"

# Set secure permissions
chown youruser:yourgroup "$DST"/*.pem
chmod 600 "$DST"/*.pem

echo "[Certbot Hook] Restarting RADIUS and RadSec services..."
cd "$DOCKER_DIR" && docker compose down && docker compose up -d

echo "[Certbot Hook] Completed successfully."
```

Make it executable:
```bash
chmod +x /usr/local/sbin/certbot-deploy-hook
```

---

## 🔁 Register the Deploy Hook

Edit:
```bash
/etc/letsencrypt/renewal/openroaming.conf
```

Add:
```ini
deploy_hook = /usr/local/sbin/certbot-deploy-hook
```

---

Here's an expanded and polished section that covers both **dry-run testing** and **forced live renewal** to verify the deploy hook works end-to-end:

---

## 🧪 Test Everything

### 🔄 Option 1: Dry-Run Renewal (No Actual Certs Changed)

Run a **safe test** to ensure Certbot and the deploy hook behave correctly:

```bash
certbot renew --dry-run
```

✅ What to check:
- Certbot logs indicate a simulated renewal
- The deploy hook runs and copies certs to `/path/to/your/radius/certs/`
- Docker services restart (if configured)

📝 **Note**: In a dry-run, Certbot **does not write real certs**, but the hook is still executed.

---

### 🔁 Option 2: Force a Real Renewal + Run the Hook

If you want to **force a real renewal** and run the deploy hook against live certs:

```bash
certbot renew --force-renewal --deploy-hook /usr/local/sbin/certbot-deploy-hook -v
```

✅ What this does:
- Forces renewal even if certs are not close to expiration
- Ensures the deploy hook is executed immediately
- Copies real, live certs to your destination directory
- Restarts any configured services (e.g., FreeRADIUS, RadSecProxy)

---

### 📂 Tip: Watch for These in Output
Look for lines like:
```
Running deploy-hook command: /usr/local/sbin/certbot-deploy-hook
Deploying certificate to /path/to/your/radius/certs/
Restarting services using docker compose...
```

If you don’t see them, double-check:
- The `deploy_hook` path is correct and executable
- It is registered in `/etc/letsencrypt/renewal/openroaming.conf`

---

## ✅ Done!

- Your OpenRoaming TLS certs are auto-renewed and deployed.
- Supports either **DNS-based** or **HTTP-based** issuance.
- Works for FreeRADIUS, RadSecProxy, and any federation-ready AAA setup.

---

### 📚 Additional References
- Let’s Encrypt docs: [https://letsencrypt.org/docs](https://letsencrypt.org/docs)
- Certbot docs: [https://certbot.eff.org/docs](https://certbot.eff.org/docs)
- OpenRoaming WBA: [https://wballiance.com/openroaming](https://wballiance.com/openroaming)

---
