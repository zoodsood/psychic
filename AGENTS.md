# AGENTS.md – GooseRelay + GOST Stealth Container

## Context Summary

We are building a stealth Docker container that runs two renamed binaries inside an intranet environment (Iranian national network). The container exposes a **Shadowsocks port** (`chacha20-ietf-poly1305` on `0.0.0.0:5000`) that chains internally to a SOCKS5 proxy provided by the GooseRelay client. The GooseRelay client uses domain fronting through Google Apps Script to exit to a user‑owned VPS.

All Docker‑related files (Dockerfile, docker‑compose.yml, entrypoint script, GitHub Actions workflow) avoid suspicious keywords: `GooseRelay`, `VPN`, `GOST`, `proxy`, `tunnel`. Binaries are downloaded during build and renamed to generic names (`app1`, `app2`). Environment variables are obfuscated (e.g., `AUTH_KEY`, `DEPLOY_IDS`, `SS_PASS`).

## Technical Decisions

| Area | Decision |
|------|----------|
| **Base image** | Alpine 3.20 |
| **GOST version** | 2.12.0 (renamed to `app1`) |
| **GooseRelay version** | 1.7.1 client (renamed to `app2`) |
| **Inbound protocol** | Shadowsocks – `chacha20-ietf-poly1305` |
| **Internal chain** | `app1` → SOCKS5 on `127.0.0.1:1080` (provided by `app2`) |
| **Configuration** | `client_config.json` generated at runtime from environment variables – no file stored in image |
| **Process management** | Entrypoint shell script launches both processes in background, traps signals |
| **Health check** | `nc -z 127.0.0.1 1080` |
| **Build automation** | GitHub Actions on push to `main` or tags; pushes to GHCR |
| **Deployment** | `docker-compose.yml` on the intranet host |
| **Obfuscation** | Binaries renamed, config vars renamed, no banned strings in any Docker‑related file |

## Obfuscated Names Mapping

| Original | Obfuscated / Neutral |
|----------|----------------------|
| `goose-client` | `app2` |
| `gost` | `app1` |
| `tunnel_key` (env) | `AUTH_KEY` |
| `script_keys` (env) | `DEPLOY_IDS` |
| `SS_PASSWORD` (env) | `SS_PASS` |
| `GOOGLE_HOST` (env) | unchanged |
| `client_config.json` | generated as `/cfg.json` |
| Docker image name | any generic name (e.g., `app_runner`) |

## Environment Variables (Runtime)

| Variable | Required | Purpose |
|----------|----------|---------|
| `AUTH_KEY` | Yes | 64‑char hex key shared with VPS |
| `DEPLOY_IDS` | Yes | JSON array of Apps Script deployment IDs (string or object form) |
| `SS_PASS` | Yes | Shadowsocks password for inbound |
| `GOOGLE_HOST` | No | Override Google edge IP (default `216.239.38.120`) |

## Files in Repository

```
.github/workflows/docker-build.yml   # CI: builds on push, pushes to GHCR
Dockerfile                            # Multi‑stage build, downloads & renames binaries
entrypoint.sh                         # Generates config, launches both processes
docker-compose.yml                    # Deployment template for intranet host
README.md                             # Build & run instructions (optional)
```

## GitHub Actions Workflow Highlights

- Trigger: `push` to `main` branch or tags (`v*`), plus `workflow_dispatch`.
- Logs into `ghcr.io` using `${{ secrets.GITHUB_TOKEN }}`.
- Builds and pushes two tags: `latest` and the commit SHA.
- No secrets other than the automatic GITHUB_TOKEN are needed.

## Deployment on Intranet Host

1. Pull image: `docker pull ghcr.io/<user>/<repo>:latest`
2. Create `docker-compose.yml` with environment variables (never commit secrets).
3. Run: `docker-compose up -d`
4. Test with any Shadowsocks client pointing to host IP:port `5000`, method `chacha20-ietf-poly1305`, password from `SS_PASS`.

## Known Constraints & Considerations

- **GooseRelay client** has no Docker image originally – we embed it.
- **UDP not supported** – GooseRelay only handles TCP streams.
- **Latency** – 200–1000 ms due to Apps Script dispatch.
- **Quota** – ~20k requests/day per Google account; use multiple accounts / deployments to scale.
- **Domain fronting** – Works as of 2026, but Google may close the loophole. Censors have difficulty blocking without breaking Google.
- **Resource usage** – Container fits comfortably in 512 MB RAM / 1 vCPU.

## Development & Build Process (First‑time Docker user)

- No local Docker required if using GitHub Actions.
- Push the four files to a GitHub repository (private recommended).
- GitHub builds the image automatically and stores it in GHCR.
- On the intranet host, log in to GHCR (`docker login ghcr.io -u <user>`) and pull.
- Use `docker-compose` to run.

## Future Modifications

- To update binary versions, change the `ARG` URLs in the Dockerfile.
- To change the inbound protocol (e.g., SOCKS5 instead of Shadowsocks), modify the `app1` command line in `entrypoint.sh`.
- To add more obfuscation, rename `app1`/`app2` or the entrypoint script.
- To support ARM hosts, adjust download URLs to `arm64` variants.

