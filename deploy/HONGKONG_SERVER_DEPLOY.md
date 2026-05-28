# Deploying Nexora on a Hong Kong VPS

This guide assumes:

- Ubuntu 24.04 LTS
- a fresh Hong Kong VPS
- Docker deployment
- host-level Nginx termination on ports `80/443`
- Nexora bound to `127.0.0.1:8080`

## Recommended starting server

For first production rollout:

- CPU: `2 vCPU` minimum, `4 vCPU` recommended
- RAM: `4 GB` minimum, `8 GB` recommended if you expect sustained streaming traffic
- Disk: `80 GB` NVMe minimum
- Network: public IPv4, stable outbound bandwidth, Hong Kong region

When selecting the VPS, prefer:

- good Mainland China route quality if your users are mainly in China
- snapshots or block-storage backup support
- the ability to open only `22`, `80`, and `443`

## 1. Prepare DNS

Point your domain to the VPS public IP:

- `A` record: `ai.example.com -> <server-ip>`

Wait until `ping ai.example.com` or `nslookup ai.example.com` resolves to the new IP.

## 2. Initial OS setup

SSH into the server and install base packages:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-plugin nginx certbot python3-certbot-nginx ufw git
sudo systemctl enable --now docker nginx
```

If you want a dedicated deploy user:

```bash
sudo adduser nexora
sudo usermod -aG docker nexora
sudo su - nexora
```

## 3. Firewall

Allow only SSH, HTTP, and HTTPS:

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status
```

Do not open `5432` or `6379` publicly.

## 4. Upload the project

Place the code on the server, for example:

```bash
sudo mkdir -p /opt/nexora
sudo chown "$USER":"$USER" /opt/nexora
git clone <your-repo-url> /opt/nexora
cd /opt/nexora/deploy
```

If you are not using git on the server, upload the repository archive and extract it into `/opt/nexora`.

## 5. Generate production config

```bash
chmod +x docker-deploy-prod.sh backup-postgres.sh
./docker-deploy-prod.sh
```

This creates:

- `runtime/.env.production`
- `runtime/secrets/`
- `data/`
- `postgres_data/`
- `redis_data/`
- `backups/`

Now edit `runtime/.env.production` and set at least:

- `ADMIN_EMAIL`
- `PUBLIC_DOMAIN`
- `BOOTSTRAP_FRONTEND_URL` / `BOOTSTRAP_API_BASE_URL`
- any OAuth client secrets you actually use
- `SECURITY_URL_ALLOWLIST_*` values for strict upstream allowlisting
- optional `BOOTSTRAP_SMTP_*` values if you want email delivery

If you enable Turnstile or SMTP password auth, write the secrets into:

- `runtime/secrets/turnstile_secret_key`
- `runtime/secrets/smtp_password`

## 6. Start the stack

```bash
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml up -d --build
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml ps
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml logs -f nexora
```

Local health checks from the server:

```bash
curl -fsS http://127.0.0.1:8080/livez
curl -fsS http://127.0.0.1:8080/readyz
```

`/readyz` must return `200` before you put public traffic on the server.

## 7. Configure Nginx

Copy the example config:

```bash
sudo cp /opt/nexora/deploy/nginx.nexora.conf.example /etc/nginx/sites-available/nexora.conf
sudo nano /etc/nginx/sites-available/nexora.conf
```

Replace:

- `ai.example.com` with your real domain
- certificate paths after Certbot issues the cert

Enable the site:

```bash
sudo ln -sf /etc/nginx/sites-available/nexora.conf /etc/nginx/sites-enabled/nexora.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 8. Issue TLS certificate

Run Certbot after the Nginx server block is in place and DNS already points to the server:

```bash
sudo certbot --nginx -d ai.example.com
```

Then verify renewal:

```bash
sudo certbot renew --dry-run
```

## 9. Smoke test from the public domain

From your laptop:

```bash
curl -I https://ai.example.com
```

Then log into the web UI from the public domain, change the bootstrap admin password immediately, and complete one real admin workflow.

After that, retire bootstrap mode:

```bash
./finalize-production-bootstrap.sh
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml up -d --build nexora
```

## 10. Backups and monitoring

Run a manual PostgreSQL backup:

```bash
cd /opt/nexora/deploy
./backup-postgres.sh
```

Install the provided systemd timers:

```bash
chmod +x install-prod-systemd.sh backup-postgres.sh monitor-stack.sh restore-postgres.sh finalize-production-bootstrap.sh
sudo ./install-prod-systemd.sh
systemctl status nexora-backup.timer nexora-monitor.timer
```

If you prefer cron instead of systemd timers:

```bash
crontab -e
```

Example:

```cron
0 3 * * * cd /opt/nexora/deploy && ./backup-postgres.sh >> /opt/nexora/deploy/backups/backup.log 2>&1
*/2 * * * * cd /opt/nexora/deploy && ./monitor-stack.sh >> /opt/nexora/deploy/backups/monitor.log 2>&1
```

`backup-postgres.sh` already prunes `postgres_*.sql.gz` older than `BACKUP_RETENTION_DAYS` days. The default is `7`.

## 11. Routine operations

Update the stack:

```bash
cd /opt/nexora/deploy
git pull
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml up -d --build
```

Check current state:

```bash
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml ps
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml logs --tail=200 nexora
```

Restart only the gateway:

```bash
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml restart nexora
```

## 12. Immediate post-launch tasks

- create a second permanent admin account
- disable bootstrap mode with `./finalize-production-bootstrap.sh`
- confirm backups are actually being written
- confirm `./monitor-stack.sh` is scheduled and can reach the alert webhook
- monitor disk growth under `data/`, `postgres_data/`, `redis_data/`, and `backups/`
- verify invite-only signup / risk control / TOTP flags match your intended policy
