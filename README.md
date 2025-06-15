# hass-maestro

Home Assistant add-on containing the **Hass Maestro** service.

The add-on exposes a Swift HTTP server on port 8080 which responds to `GET /run`.
Currently, the add-on targets **aarch64** and **amd64** architectures, matching the
available Swift base images.
