IMAGE_NAME := pneumoscan-junior
SERVICE_NAME := pneumoscan

# Host port the app is reachable on.
# `export` is required so docker-compose.yml's "${PORT:-8501}" can read
# this value from the environment when Make invokes the compose CLI —
# Make variables are not visible to child processes otherwise.
PORT := 58501
export PORT

# Port Streamlit listens on *inside* the container. This is passed to
# the build as --build-arg APP_PORT=... (below) AND exported so
# docker-compose.yml's "${APP_PORT:-8501}" (the container side of the
# port mapping) resolves to the same value. Both must agree, since
# the image only listens on whatever port it was built with — hence
# a single variable feeding both, rather than hardcoding it twice.
# Override together with PORT if you need a non-default internal
# port, e.g.:
#   make dev APP_PORT=9000 PORT=9000
APP_PORT := 8501
export APP_PORT

# Support both the "docker compose" plugin and the standalone
# "docker-compose" binary, whichever is available.
COMPOSE := $(if $(shell docker compose version >/dev/null 2>&1 && echo yes),docker compose,docker-compose)

# Development uses the base compose file plus the dev override, which
# targets the Dockerfile's "dev" stage and bind-mounts the source.
# A separate project name (-p) isolates dev from prod so the two can
# coexist without recreating each other's containers/networks.
COMPOSE_DEV := $(COMPOSE) -p pneumoscan-dev -f docker-compose.yml -f docker-compose.dev.yml

# DOCKER_BUILDKIT selects which builder engine `docker build`/
# `docker compose build` uses:
#   =1  BuildKit — required for this project's Dockerfile. Builds
#       independent stages in parallel, skips stages the target
#       doesn't need (e.g. the "model" stage is skipped if unused),
#       and supports the pre-FROM ARG syntax the Dockerfile relies
#       on. Default in modern Docker CLI/Docker Desktop; pinned here
#       explicitly so it also works on older setups.
#   =0  Legacy builder — builds every stage sequentially even if
#       unused, and may not reliably support that ARG syntax. Avoid.
export DOCKER_BUILDKIT := 1

# Optional build knobs, override on invocation, e.g.:
#   make build PLATFORM=linux/amd64 NO_CACHE=1
#   make build BUILD_ARGS="--build-arg MODEL_FILENAME=my.keras"
# To change the internal port, use APP_PORT (above), not BUILD_ARGS —
# APP_PORT is already wired into both the build and the port mapping.
PLATFORM :=
NO_CACHE :=
BUILD_ARGS :=

ifneq ($(PLATFORM),)
export DOCKER_DEFAULT_PLATFORM := $(PLATFORM)
endif

BUILD_FLAGS := --progress=plain --build-arg APP_PORT=$(APP_PORT)
ifneq ($(NO_CACHE),)
BUILD_FLAGS += --no-cache
endif
BUILD_FLAGS += $(BUILD_ARGS)

.PHONY: help build start stop remove restart logs exec clean \
        dev dev-down dev-logs dev-exec

help:
	@echo "Production targets:"
	@echo "  make build    - Build the Docker image"
	@echo "                  (override: APP_PORT=8080 PLATFORM=linux/amd64"
	@echo "                   NO_CACHE=1 BUILD_ARGS=\"--build-arg MODEL_FILENAME=my.keras\")"
	@echo "  make start    - Start the application (builds if needed)"
	@echo "  make stop     - Stop the running container"
	@echo "  make remove   - Stop and remove the container"
	@echo "  make restart  - Restart the application"
	@echo "  make logs     - Follow application logs"
	@echo "  make exec     - Open a shell inside the running container"
	@echo "  make clean    - Remove container and image"
	@echo ""
	@echo "Development targets (live reload via bind mount):"
	@echo "  make dev      - Build + run dev container in the foreground"
	@echo "  make dev-down - Stop and remove the dev container"
	@echo "  make dev-logs - Follow dev container logs"
	@echo "  make dev-exec - Open a shell inside the dev container"

# make build
# make build APP_PORT=8080             # change the internal container port
# make build PLATFORM=linux/amd64      # cross-build for x86_64 hosts
# make build NO_CACHE=1                # force a clean rebuild
# make build BUILD_ARGS="--build-arg MODEL_FILENAME=my.keras"
build:
	$(COMPOSE) build $(BUILD_FLAGS)

# make start
# make start PORT=9000                 # run on a different host port
# open http://localhost:58501 once started
start:
	$(COMPOSE) up -d
	@echo ""
	@echo "-----------------------------------------------------------------"
	@echo "  PneumoScan-Junior -> http://localhost:$(PORT)"
	@echo ""
	@echo "  (make logs will show the container's own \"http://0.0.0.0:$(APP_PORT)\""
	@echo "   line — that's the internal bind address, not your host URL)"
	@echo "-----------------------------------------------------------------"
	@echo ""

# make stop
stop:
	$(COMPOSE) stop

# make remove
remove:
	$(COMPOSE) down

# make restart
restart: remove start

# make logs
logs:
	$(COMPOSE) logs -f

# make exec
exec:
	$(COMPOSE) exec $(SERVICE_NAME) bash

# make clean
clean: remove
	docker image rm $(IMAGE_NAME):latest 2>/dev/null || true

# ----------------------------------------------------------
# Development
# ----------------------------------------------------------

# make dev
# make dev PORT=9000 APP_PORT=9000     # run on a different port
# make dev BUILD_ARGS="--build-arg MODEL_FILENAME=my.keras"
# Foreground so you see reload logs; Ctrl-C stops it. Edit any .py
# file on the host and Streamlit reruns automatically.
dev:
	$(COMPOSE_DEV) build $(BUILD_FLAGS)
	@echo ""
	@echo "-----------------------------------------------------------------"
	@echo "  PneumoScan-Junior (dev) -> http://localhost:$(PORT)"
	@echo ""
	@echo "  (ignore the container's own \"http://0.0.0.0:$(APP_PORT)\" line"
	@echo "   below — that's the internal bind address, not your host URL)"
	@echo "-----------------------------------------------------------------"
	@echo ""
	$(COMPOSE_DEV) up

# make dev-down
dev-down:
	$(COMPOSE_DEV) down

# make dev-logs
dev-logs:
	$(COMPOSE_DEV) logs -f

# make dev-exec
dev-exec:
	$(COMPOSE_DEV) exec $(SERVICE_NAME) bash
