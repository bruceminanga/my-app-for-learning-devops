# 🐳 My App for Learning DevOps

> **Containerization Excellence** — A production-grade Docker architecture built on the **7-Phase Mission** standard: secure, scalable, reproducible, and developer-friendly.

[![Docker Multi-Arch](https://img.shields.io/badge/Docker-Multi--Arch-blue?logo=docker&logoColor=white)](https://docs.docker.com/buildx/working-with-buildx/)
[![Security](https://img.shields.io/badge/Security-Trivy%20%7C%20Snyk-success?logo=snyk)](https://trivy.dev)
[![Architecture](https://img.shields.io/badge/Architecture-12--Factor-orange)](https://12factor.net)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [The 7-Phase Architecture](#-the-7-phase-architecture-standard)
- [Getting Started Locally](#-getting-started-locally)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🔍 Overview

This repository is engineered from the ground up to adhere to strict, **production-grade containerization and DevOps best practices**. Every design decision — from base image selection to CI/CD pipeline configuration — is intentional, documented, and auditable.

---

## 🏗️ The 7-Phase Architecture Standard

### Phase 1 · Pre-Flight App Prep

Before a single container is built, the application source code is hardened for cloud-native deployment:

| Principle | Implementation |
|---|---|
| **Config & Secrets Hygiene** | All config via environment variables; no hardcoded credentials. `.env` for local dev, runtime injection for production. |
| **Deterministic Dependencies** | All packages strictly pinned (`package-lock.json`, `requirements.txt`, `go.sum`). |
| **Stateless by Design** | No container-local state. Sessions, uploads, and caches offloaded to Redis, S3, and external DBs. |
| **Liveness & Readiness** | Explicit `/health` and `/ready` endpoints implemented in the app. |
| **Graceful Shutdown** | `SIGTERM` handlers ensure in-flight requests complete and connections close cleanly. |
| **Stripped Dev Tooling** | Dev dependencies are strictly isolated from the production code path. |
| **Explicit Locales** | `tzdata` and locale dependencies are documented and installed explicitly. |
| **Log Aggregation** | All logs stream to `stdout`/`stderr`. Never written to local container log files. |

---

### Phase 2 · Build Perimeter

**`.dockerignore` First.** Before the Docker daemon touches any code, `.dockerignore` is applied to:

- 🔒 Protect secrets from leaking into the build context
- 🗑️ Strip `.git`, `node_modules`, `__pycache__`, and other junk
- ⚡ Keep the build context lean, secure, and fast

---

### Phase 3 · The Dockerfile

The Dockerfile is treated as **production code**, not an afterthought:

```
┌─────────────────────────────────────────────────────────┐
│  Stage 1: Builder                                       │
│  ├─ Pinned base image (SHA256 digest)                   │
│  ├─ Install dependencies (cached layer)                 │
│  └─ Compile / build artifacts                           │
│                                                         │
│  Stage 2: Production                                    │
│  ├─ Slim/Alpine base (minimal attack surface)           │
│  ├─ Copy artifacts only (no build tools)                │
│  ├─ Run as non-root user                                │
│  └─ OCI labels (version, git SHA, maintainer)           │
└─────────────────────────────────────────────────────────┘
```

**Key practices:**
- 🔒 **SHA256 image pinning** — base images pinned by immutable digest, not mutable tags
- ⚡ **Layer cache optimization** — dependency manifests copied and installed before source code
- 🧹 **Single-layer cleaning** — package manager caches wiped in the same `RUN` layer as installation
- 👤 **Non-root execution** — containers always run as a mapped non-root user

---

### Phase 4 · Execution Rules

```dockerfile
# PID 1 handled by tini for proper signal forwarding & zombie reaping
ENTRYPOINT ["/sbin/tini", "--", "your-app"]
CMD ["--default-flag"]

# Polls /health and /ready endpoints
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:PORT/health || exit 1

# Documentation-only: maps what the app listens on
EXPOSE PORT
```

---

### Phase 5 · Local Orchestration

`docker-compose.yml` mirrors production as closely as possible:

```
┌──────────────────────┐     ┌──────────────────────┐     ┌──────────────────────┐
│      App Service     │     │   Database Service   │     │    Cache Service     │
│  (bind mount: hot-   │────▶│  (named volume for   │     │  (named volume for   │
│   reload enabled)   │     │   data persistence)  │     │   data persistence)  │
└──────────────────────┘     └──────────────────────┘     └──────────────────────┘
         │                            │                            │
         └────────────────────────────┴────────────────────────────┘
                        Custom Isolated Network (no default bridge)
```

---

### Phase 6 · Security & Hardening

| Control | Tool / Method |
|---|---|
| **Vulnerability Scanning** | Trivy · Docker Scout · Snyk |
| **Layer Auditing** | `dive` for bloat and efficiency analysis |
| **Resource Quotas** | Hard memory and CPU limits set per container |
| **Privilege Dropping** | `cap_drop: [ALL]` + `no-new-privileges: true` |
| **Immutable Filesystem** | Read-only root filesystem; write access via explicit volume mounts only |

---

### Phase 7 · CI/CD Readiness

```
Code Push
    │
    ▼
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌────────────┐
│  Lint   │───▶│  Build  │───▶│  Test   │───▶│  Scan   │───▶│    Push    │
│         │    │         │    │         │    │ (Trivy) │    │ (SemVer /  │
│         │    │         │    │         │    │         │    │  Git SHA)  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └────────────┘
                                                                    │
                                                                    ▼
                                                          Multi-Arch (amd64 + arm64)
                                                          via docker buildx
```

- 🚫 **No `:latest`** — every deployment tagged via SemVer or Git SHA
- 🤖 **Fully automated** — lint → build → test → push, no manual steps
- 🔑 **Runtime secrets** — injected dynamically by the orchestrator (Kubernetes/ECS/Swarm), never baked into the image
- 🌍 **Multi-arch** — `amd64` and `arm64` targets via `docker buildx` — build once, run anywhere

---

## 🚀 Getting Started Locally

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)

### Steps

**1. Clone the repository**
```bash
git clone git@github.com:bruceminanga/My-app-for-learning-docker.git
cd your-repo
```

**2. Set up your environment**
```bash
cp .env.example .env
# Add any local overrides to your .env file
```

**3. Launch the stack**
```bash
# Starts the app, database, and cache with bind mounts for hot-reloading
docker-compose up --build
```

**4. Verify healthchecks**
```bash
# Wait a few seconds after startup, then:
curl http://localhost:PORT/health
curl http://localhost:PORT/ready
```

---

## 🤝 Contributing

When contributing, ensure your code complies with **Phase 1: Pre-Flight App Prep** requirements:

- ✅ Never commit secrets or credentials
- ✅ Keep all dependencies strictly pinned
- ✅ Verify that graceful shutdown handlers remain intact
- ✅ Ensure `/health` and `/ready` endpoints are functional



