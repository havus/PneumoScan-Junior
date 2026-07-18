# ==========================================================
# PneumoScan-Junior — Multi-stage Docker build
# ==========================================================
#
# Base image note:
#   TensorFlow only publishes manylinux (glibc) wheels, so an
#   Alpine (musl libc) base would have no compatible wheel and
#   would try to build from source. "python:3.11-slim" (Debian)
#   is the smallest base that still installs the TF wheel cleanly.
#
#   The trained model (~320 MB) is baked into the image via COPY
#   in its own layer, so the container is fully self-contained and
#   needs no network at startup. model_utils.py detects the local
#   file and skips the GitHub Releases download automatically.
#
#   The model stage below uses the local model file from the build
#   context if present (it is gitignored, so a fresh clone won't have
#   it); otherwise it downloads the same file from GitHub Releases at
#   build time, so the build works either way.
#
#   Build-time variables (override with --build-arg NAME=value):
#     MODEL_FILENAME  name of the trained model file
#     MODEL_URL       GitHub Releases URL to download it from if
#                      missing locally (keep in sync with MODEL_URL
#                      in model_utils.py)
#     APP_PORT        port Streamlit listens on inside the container
# ==========================================================

ARG MODEL_FILENAME=Xception_final_gradcam.keras
ARG MODEL_URL=https://github.com/harishmuh/PneumoScan-Junior/releases/download/v1.0.0/${MODEL_FILENAME}
ARG APP_PORT=8501


# ==========================================================
# Stage 1 — Model: use the local model file if present,
# otherwise download it from GitHub Releases.
# ==========================================================

FROM alpine:3.20 AS model

ARG MODEL_FILENAME
ARG MODEL_URL

WORKDIR /model

# The wildcard matches the model file only if it exists in the build
# context; ".dockerplaceholder" always exists, so this COPY never
# fails even when the model file is absent.
COPY ${MODEL_FILENAME}* .dockerplaceholder ./

RUN set -eux; \
    rm -f .dockerplaceholder; \
    if [ -f "$MODEL_FILENAME" ]; then \
        echo "Using local $MODEL_FILENAME"; \
    else \
        echo "Local model not found, downloading from GitHub Releases"; \
        apk add --no-cache curl; \
        curl -fL --retry 5 --retry-delay 5 \
            -o "$MODEL_FILENAME" \
            "$MODEL_URL"; \
    fi


# ==========================================================
# Stage 2 — Builder: install dependencies into a venv
# ==========================================================

FROM python:3.11-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Isolated virtual environment we can copy wholesale later.
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app

COPY requirements.txt .

RUN pip install --upgrade pip setuptools wheel && \
    pip install \
        --default-timeout=1000 \
        --retries=10 \
        -r requirements.txt


# ==========================================================
# Stage 3 — Base: shared runtime environment for both the
# development and production images (system libs + venv).
# ==========================================================

FROM python:3.11-slim AS base

ARG APP_PORT

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH" \
    APP_PORT=${APP_PORT}

# Runtime shared libraries required by TensorFlow (libgomp1)
# and OpenCV headless (libglib2.0-0). curl backs the healthcheck.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libgomp1 \
        libglib2.0-0 \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Bring in the pre-built virtual environment from the builder.
COPY --from=builder /opt/venv /opt/venv

WORKDIR /app

EXPOSE ${APP_PORT}

# Streamlit exposes a health endpoint we can probe. Shell form so it
# can read $APP_PORT from the container's runtime environment.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl --fail http://localhost:$APP_PORT/_stcore/health || exit 1


# ==========================================================
# Stage 4 — Development: no source or model baked in; both are
# bind-mounted from the host (see docker-compose.dev.yml) so
# code edits are picked up live without rebuilding the image.
# Build with:  --target dev
# ==========================================================

FROM base AS dev

# Runs as root (the default) to avoid permission friction between
# host-owned files and the container user on the bind mount.
#
# --server.runOnSave      rerun the app whenever a source file changes.
# --server.fileWatcherType=poll
#                         inotify events often do not cross the VM /
#                         bind-mount boundary (macOS, Windows, Podman),
#                         so poll the filesystem to detect edits.
#
# The model file is provided by the bind mount; if it is missing,
# model_utils.py downloads it at runtime into the mounted directory.
CMD exec streamlit run app.py \
    --server.port=$APP_PORT \
    --server.address=0.0.0.0 \
    --server.runOnSave=true \
    --server.fileWatcherType=poll


# ==========================================================
# Stage 5 — Runtime (production): self-contained image with the
# model and source baked in, running as a non-root user.
# This is the default build target.
# ==========================================================

FROM base AS runtime

ARG MODEL_FILENAME

# Run as a non-root user for safety.
RUN useradd --create-home --uid 1000 appuser

# Trained model first, in its own layer. It rarely changes, so
# editing the source below will not invalidate this 320 MB layer.
COPY --from=model --chown=appuser:appuser /model/${MODEL_FILENAME} ./

# Application source (small, changes often — cheap to rebuild).
COPY --chown=appuser:appuser *.py *.txt README.md ./
COPY --chown=appuser:appuser assets ./assets
COPY --chown=appuser:appuser sample_images ./sample_images

USER appuser

# Shell form (with "exec") so $APP_PORT is expanded at runtime while
# still replacing the shell as PID 1, preserving signal forwarding.
CMD exec streamlit run app.py --server.port=$APP_PORT --server.address=0.0.0.0
