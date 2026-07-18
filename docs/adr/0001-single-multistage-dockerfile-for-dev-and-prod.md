# 0001. Single multi-stage Dockerfile for dev and prod

- Status: Accepted
- Date: 2026-07-18
- Deciders: Hafidz Mahrus

## Context and problem statement

PneumoScan-Junior is a Streamlit app that depends on TensorFlow, Keras, and
OpenCV, plus a ~320 MB trained model (`Xception_final_gradcam.keras`). We need
two container workflows:

- **Development** — fast feedback: edit source on the host and see the change
  without rebuilding the image (bind-mount the working directory, Streamlit
  live-reload).
- **Production** — a self-contained, reproducible, non-root image with the
  model and source baked in.

The question: should development and production be built from **one shared
multi-stage Dockerfile**, or from **two separate Dockerfiles**
(`Dockerfile.dev` and `Dockerfile`)?

Relevant forces specific to this project:

- Dev and prod share almost everything: the same base image
  (`python:3.11-slim`), the same OS libraries (`libgomp1`, `libglib2.0-0`),
  and the same Python dependency set installed into a venv.
- The only real differences are the final `CMD` (dev adds
  `--server.runOnSave` and `--server.fileWatcherType=poll`) and whether the
  source and model are **baked in** (prod) or **bind-mounted** (dev).
- Dockerfiles cannot `include` or import one another, so anything two files
  have in common must be physically duplicated.

## Considered options

1. **Single multi-stage Dockerfile** with a shared `base` stage and two final
   targets, `dev` and `runtime`, selected via `--target` / Compose `target:`.
2. **Separate `Dockerfile.dev` and `Dockerfile`** (one per environment).

## Decision outcome

Chosen option: **"Single multi-stage Dockerfile"**, because dev and prod share
~95% of the build. Splitting into two files would duplicate the builder / base
/ dependency-install layers with no way to share them, and that duplication is
the primary source of "works in dev, breaks in prod" drift. A shared `base`
stage gives dev/prod environment parity for free: the dev image is literally
`FROM base`, the same base production ships.

Readability — the stated motivation for considering a split — is preserved
through clear `Stage N — …` banner comments, and is arguably *better* in one
file: a reader sees `dev` and `runtime` side by side and can read off exactly
what differs between the two environments.

### Consequences

- Good — one source of truth for how the image is built; dependency/version
  bumps apply to both environments automatically.
- Good — guaranteed dev/prod parity (dev inherits prod's exact `base`).
- Good — BuildKit builds only the requested target's stages, so a dev build
  skips the ~320 MB model stage entirely.
- Bad — a single, longer Dockerfile with dev and prod concerns interleaved.
- Bad — requires understanding the `--target` mechanism and the extra Compose
  wiring (`docker-compose.dev.yml`).

## Pros and cons of the options

### Option 1 — Single multi-stage Dockerfile

- Good — no duplication of builder/libs/venv setup.
- Good — dev/prod parity by construction; no drift.
- Good — dev and prod differences are visible in one place, easy to audit.
- Good — idiomatic Docker (`--target`), already supported by our tooling.
- Bad — one longer file to scan.

### Option 2 — Separate Dockerfile.dev and Dockerfile

- Good — each file is short and single-purpose.
- Good — dev can diverge freely (extra debug tooling, different base) without
  touching prod, and there is no risk of dev-only flags leaking into prod.
- Bad — builder/base/dependency layers are duplicated across both files.
- Bad — every dependency or version change must be applied in two places;
  forgetting one causes environment drift and parity bugs.
- Bad — loses the single source of truth for the image build.

## How it works

The Dockerfile has five stages:

- `model` — resolves the trained model: uses the local file from the build
  context if present, otherwise downloads it from GitHub Releases.
- `builder` — installs Python dependencies into an isolated venv (`/opt/venv`).
- `base` — shared runtime environment: `python:3.11-slim` + OS libraries +
  the venv copied from `builder` + `EXPOSE` + `HEALTHCHECK`.
- `dev` — `FROM base`; bakes in **nothing** (source and model are bind-mounted
  from the host). Runs Streamlit with `--server.runOnSave=true` and
  `--server.fileWatcherType=poll` (polling because inotify events do not
  reliably cross the VM / bind-mount boundary on macOS, Windows, or Podman).
  Runs as root to avoid permission friction with host-owned mounted files.
- `runtime` — `FROM base`; bakes in the model (own layer) and source, runs as
  a non-root user. This is the default build target.

Environment selection:

- **Production:** `docker-compose.yml` builds `target: runtime`.
  Driven by `make build` / `make start`.
- **Development:** `docker-compose.dev.yml` overrides `target: dev`,
  bind-mounts the working directory to `/app` (the venv at `/opt/venv` is
  outside `/app`, so it is not shadowed), and uses a separate image tag,
  container name, and Compose project so it never clashes with production.
  Driven by `make dev` / `make dev-down` / `make dev-logs` / `make dev-exec`.

Consequently, code edits in development require no image rebuild; only
dependency changes (`requirements.txt`) do.

## When to revisit

Reconsider splitting into separate Dockerfiles if the **development image
begins to diverge substantially from production** — for example if dev needs a
heavy toolchain that production must not contain (compilers, debuggers,
notebook servers, test frameworks, SSH). At that point the shared `base` stops
being a genuine common base and the anti-duplication argument weakens.
