# Nexora Production Hardening Checklist

Use this checklist before exposing the service to real users.

## 1. Secrets

- [ ] `./runtime/.env.production` exists and is `0600`-style readable only by the deploy user
- [ ] `./runtime/secrets/` exists and is not tracked by git
- [ ] `ADMIN_PASSWORD`, `JWT_SECRET`, `TOTP_ENCRYPTION_KEY`, `POSTGRES_PASSWORD`, and `REDIS_PASSWORD` live in `./runtime/secrets/`
- [ ] `./finalize-production-bootstrap.sh` has been run after first login so `AUTO_SETUP=false`
- [ ] Any OAuth client secrets are injected only on the server

## 2. Host and network

- [ ] The VPS only exposes `22`, `80`, and `443` to the public internet
- [ ] Nexora binds to `127.0.0.1:8080`, not `0.0.0.0`
- [ ] PostgreSQL is not published to the host
- [ ] Redis is not published to the host
- [ ] SSH password login is disabled or tightly restricted after key access is confirmed

## 3. Reverse proxy and TLS

- [ ] A real domain is configured for the service
- [ ] TLS is terminated by Nginx or Caddy on the host
- [ ] HTTP traffic is redirected to HTTPS
- [ ] Proxy timeouts and buffering are configured for long streaming responses
- [ ] `client_max_body_size` matches your upload expectations

## 4. App configuration

- [ ] `SERVER_MODE=release`
- [ ] `RUN_MODE=standard`
- [ ] `BOOTSTRAP_REGISTRATION_MODE=invite_only` or `closed` unless open signup is an intentional business choice
- [ ] `BOOTSTRAP_RISK_CONTROL_ENABLED=true`
- [ ] `BOOTSTRAP_TOTP_ENABLED=true`
- [ ] `LOG_FORMAT=json` and log retention settings are configured
- [ ] `SECURITY_URL_ALLOWLIST_ALLOW_INSECURE_HTTP=false`
- [ ] `SECURITY_URL_ALLOWLIST_ALLOW_PRIVATE_HOSTS=false`
- [ ] `SECURITY_URL_ALLOWLIST_ENABLED=true` and the host allowlists are populated
- [ ] If `BOOTSTRAP_TURNSTILE_ENABLED=true`, the site key and secret are present in runtime config

## 5. Data safety

- [ ] `deploy/backups/` exists and is writable only by the deploy user
- [ ] `deploy/backup-postgres.sh` runs successfully
- [ ] `deploy/restore-postgres.sh` has been tested once with a non-production dump
- [ ] `nexora-backup.timer` or an equivalent scheduled PostgreSQL backup job exists
- [ ] Backup restore steps have been written down and tested at least once
- [ ] `data/`, `postgres_data/`, and `redis_data/` are included in server snapshot policy if you use provider snapshots

## 6. Health and observability

- [ ] `docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml ps` shows healthy services
- [ ] `curl http://127.0.0.1:8080/readyz` returns HTTP `200` on the server
- [ ] Application logs rotate and do not fill the disk
- [ ] Host disk usage, memory, and container restart count are being checked
- [ ] `nexora-monitor.timer` or an equivalent schedule runs `deploy/monitor-stack.sh`
- [ ] The monitor posts to a webhook or paging target
- [ ] Ops alert bootstrap is enabled for repeated `5xx` / low success rate
- [ ] There is a tested way to alert on readiness failures or database connection failures

## 7. First-login workflow

- [ ] First admin login succeeds
- [ ] A second long-term admin account is created
- [ ] The generated bootstrap `ADMIN_PASSWORD` is changed in the UI and retired via `./finalize-production-bootstrap.sh`
- [ ] 2FA is enabled for privileged accounts if your operation model requires it

## 8. Launch gate

- [ ] Public DNS resolves to the Hong Kong server
- [ ] HTTPS certificate issuance and renewal are working
- [ ] Reverse proxy config passes syntax check
- [ ] One complete user flow has been tested from the public domain
- [ ] Rollback plan is written: previous image, backup path, and restart commands
