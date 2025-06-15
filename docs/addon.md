# Running maestro as a Home Assistant Add-on

This document outlines a high-level plan for packaging and running the `maestro` Swift program as a Home Assistant add-on. The goal is to build the project into a Docker-based add-on that can be installed from a custom repository and configured with command line arguments.

## 1. Add-on directory structure

Create a `docker` directory in this repository with the following files:

```
docker/
├── Dockerfile
├── run.sh
└── config.yaml
```

- **Dockerfile** – builds the Swift project and defines the container runtime.
- **run.sh** – entrypoint script that starts `maestro` using options supplied by the user.
- **config.yaml** – Home Assistant add-on manifest with option schema.

Home Assistant expects this structure when cloning the repository as an add-on source.

## 2. Dockerfile

The Dockerfile uses the Home Assistant base images provided in `build.yaml`:

```Dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM
```

`home-assistant/builder` supplies the `BUILD_FROM` argument when building for each architecture.

## 3. Entrypoint script

`run.sh` reads the add-on options provided by Home Assistant and forwards them to `maestro`. Example contents:

```bash
#!/bin/bash
set -e

ARGS=()
[ -n "$BASEURL" ] && ARGS+=(--baseurl "$BASEURL")
[ -n "$TOKEN" ] && ARGS+=(--token "$TOKEN")
[ "$SIMULATE" = "true" ] && ARGS+=(--simulate)
[ "$NO_NOTIFY" = "true" ] && ARGS+=(--no-notify)
[ -n "$PROGRAM" ] && ARGS+=(--program "$PROGRAM")
[ "$VERBOSE" = "true" ] && ARGS+=(--verbose)

if [[ -x /usr/local/bin/maestro ]]; then
  exec /usr/local/bin/maestro "${ARGS[@]}"
else
  exec swift run maestro "${ARGS[@]}"
fi
```

The environment variables (`BASEURL`, `TOKEN`, etc.) are injected by Home Assistant based on user configuration options.

## 4. config.yaml

The add-on manifest defines the image, startup behavior and option schema. Example:

```yaml
name: Maestro
version: "1.0.0"
slug: maestro
description: Home Assistant lights orchestrator
startup: application
boot: auto
options:
  baseurl: http://homeassistant.local:8123/
  token: ''
  simulate: false
  no_notify: false
  program: default
  verbose: false
schema:
  baseurl: str?
  token: str?
  simulate: bool
  no_notify: bool
  program: str?
  verbose: bool
image: ghcr.io/<owner>/{arch}-maestro
```

Users can adjust the options in the Home Assistant UI. They are exported as environment variables with the same names in uppercase.

## 5. Repository configuration

To distribute the add-on, include a `repository.yaml` at the repository root:

```yaml
name: Maestro Add-on
url: https://github.com/lucasfeijo/maestro
maintainer: lucasfeijo
```

Home Assistant uses this file when adding the repository URL to the Add-on Store.

## 6. Installing the add-on

1. Push the repository (including the new `maestro` directory and `repository.yaml`) to GitHub or another git host.
2. In Home Assistant, navigate to **Settings → Add-ons → Add-on Store → Repositories** and add the repository URL.
3. The "Maestro" add-on will appear in the store. Install it and configure the options (base URL, token, etc.).
4. Start the add-on. Home Assistant will pull/build the Docker image and run `maestro` inside the container.

## 7. Local development

For local testing without Home Assistant you can build the Docker image directly:

```bash
docker build -t maestro-addon ./docker
docker run --rm -e BASEURL=http://hass.local:8123/ -e TOKEN=YOUR_TOKEN maestro-addon
```

This mimics the environment that Home Assistant provides when running the add-on.

## 8. Automated Docker releases

Versioned Docker images can be published automatically using GitHub Actions.
The workflow in `.github/workflows/docker-publish.yml` builds the image from
the `maestro` directory and pushes it to GitHub Container Registry whenever a
new tag is pushed.

1. Commit the workflow to your repository.
2. Create a tag such as `v1.0.0` and push it to GitHub.
3. The action builds `ghcr.io/<owner>/maestro:<tag>` and pushes the image.

Home Assistant can then install the add-on using that image reference in
`config.yaml`.

## 9. Future considerations

- Extend `config.yaml` with more options as new command line arguments are added to `maestro`.
- Write documentation in the main README referencing this add-on guide.

