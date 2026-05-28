# Custom Update Source

This deployment supports branded online updates by changing the GitHub release
repository used by the updater.

## What This Solves

The in-app updater downloads a release archive and replaces the running binary.
Because the frontend is embedded in that binary, updating from the upstream
repository also replaces the branded UI.

Set `UPDATE_GITHUB_REPO` to your own fork/repository so the updater downloads
your branded release instead.

## Server Setting

In `deploy/runtime/.env.production`:

```env
UPDATE_GITHUB_REPO=liaorenhua1998-commits/nexora-custom
```

Then restart the stack:

```bash
cd /data/sub2api-main/deploy
docker compose --env-file ./runtime/.env.production -f docker-compose.prod.yml up -d --build
```

The admin version popover shows the active update source so you can confirm the
server is using your repository.

## Release Requirements

Your GitHub repository must publish releases with the same archive names as the
updater expects. The included GitHub Actions release workflow already does this
when you tag a release:

```bash
git tag v0.1.133
git push origin v0.1.133
```

For the current Linux x86_64 server, the release assets must include:

```text
sub2api_0.1.133_linux_amd64.tar.gz
checksums.txt
```

The archive must contain the `sub2api` binary with your branded frontend
embedded.

## Recommended Workflow

1. Keep your branded repository as the update source.
2. When upstream releases a useful version, merge/rebase upstream changes into
   your branded repository.
3. Resolve any UI or branding conflicts locally.
4. Push a new tag in your branded repository.
5. Use the in-app updater; it will download your branded release.

Do not point `UPDATE_GITHUB_REPO` back to the upstream repository unless you
intentionally want the upstream UI.
