# Nexora Docker Image

Nexora is a branded AI API gateway platform for distributing and managing AI product subscription API quotas.

## Quick Start

```bash
docker build -f deploy/Dockerfile -t nexora/gateway:local .

docker run -d \
  --name nexora \
  -p 8080:8080 \
  --env-file deploy/.env.production.example \
  nexora/gateway:local
```

## Docker Compose

For production-style compose deployment, use the dedicated files in `deploy/`:

```bash
cd deploy
cp .env.production.example .env.production
./docker-deploy-prod.sh
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `POSTGRES_PASSWORD` | PostgreSQL password | Yes | - |
| `REDIS_PASSWORD` | Redis password | Yes | - |
| `ADMIN_PASSWORD` | Bootstrap admin password | Yes | - |
| `JWT_SECRET` | Fixed JWT signing secret | Yes | - |
| `TOTP_ENCRYPTION_KEY` | Fixed TOTP encryption key | Yes | - |
| `SERVER_PORT` | Nexora listen port | No | `8080` |
| `BIND_HOST` | Host bind address | No | `127.0.0.1` in prod compose |

## Supported Architectures

- `linux/amd64`
- `linux/arm64`

## Tags

- `latest` - Latest stable release
- `x.y.z` - Specific version
- `x.y` - Latest patch of minor version
- `x` - Latest minor of major version

## Links

- Local deploy guide: `deploy/README.md`
- Hong Kong VPS guide: `deploy/HONGKONG_SERVER_DEPLOY.md`
- Production checklist: `deploy/PRODUCTION_CHECKLIST.md`
- Payment guide: `docs/PAYMENT.md`
