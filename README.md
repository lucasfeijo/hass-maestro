<div align="center">
<h1>maestro</h1>
Home assistant lights orchestrator
</div>

&nbsp;

<p align="center">
  <a href="https://github.com/lucasfeijo/hass-maestro/actions/workflows/builder.yaml">
    <img alt="Builder" src="https://github.com/lucasfeijo/hass-maestro/actions/workflows/builder.yaml/badge.svg" />
  </a>
  <a href="https://github.com/lucasfeijo/hass-maestro/actions/workflows/lint.yaml">
    <img alt="Lint" src="https://github.com/lucasfeijo/hass-maestro/actions/workflows/lint.yaml/badge.svg" />
  </a>
  <a href="https://github.com/lucasfeijo/hass-maestro/actions/workflows/swift-tests.yaml">
    <img alt="Swift Tests" src="https://github.com/lucasfeijo/hass-maestro/actions/workflows/swift-tests.yaml/badge.svg" />
  </a>
</p>

## Compiling on macOS

```sh
swift build
```

See [docs/compile-macos.md](docs/compile-macos.md) for instructions on building
this package using Swift Package Manager on macOS.

## Running the server

Build and run the executable with Swift Package Manager. You can provide the
Home Assistant base URL and an optional long‑lived access token. There is also
an option to simulate light commands instead of sending them:

```sh
swift run maestro
 --baseurl http://homeassistant.local:8123/ # base URL for the Home Assistant instance. The default is `http://homeassistant.local:8123/`
 --token YOUR_TOKEN # long lived Home Assistant token used for API calls
 --simulate # print light commands to stdout instead of sending them
 --verbose # print commands while also sending them
 --no-notify # disable Home Assistant persistent notifications on failures
 --program baseScene,kitchenSink,tvShelfGroup,globalBrightness,wledMain \
    # configure which pipeline steps run (omit to run the full program)
 --port 8080 # port for the HTTP server (default 8080)
```

The package builds on Linux and macOS. On macOS the POSIX server code uses the
`Darwin` module, so the same command works there as well.

## Requesting the server

### `GET /run`

This route triggers a run of the maestro pipeline and then responds with a
`302 Found` redirect to `/`.

Example request:

```bash
curl http://localhost:8080/run
```
Replace `8080` with the port specified by `--port` if different.

If the path is anything other than `/run` or `/`, the server responds with
`404 Not Found`.

### `GET /`

Opens a simple HTML page displaying the current maestro options. This page
includes links to trigger `/run` directly.

## Pipeline

The maestro pipeline consists of 5 steps:

1. **STATE**: Fetches the current state of all entities from Home Assistant via the API. This includes light states, sensors, input selects, etc.

2. **CONTEXT**: Interprets the raw states into a structured `StateContext` that represents the current scene and environment. This includes:
   - Active scene (off, calm night, normal, bright, etc.)
   - Time of day (day/night)
   - Presence detection
   - TV/Hyperion status
   - Other environmental factors

3. **PROGRAM**: Uses the `StateContext` to compute the desired light states based on the current conditions. The program implements the lighting logic and rules for different scenes and situations.

4. **CHANGESET**: Optimizes the state changes to minimize unnecessary transitions. This ensures smooth operation and prevents lights from changing unnecessarily.

5. **LIGHTS**: Applies the final computed states to the physical lights through the Home Assistant API (or simulates the changes if in simulation mode).

This pipeline runs each time the `/run` endpoint is called, ensuring the lights always match the desired state based on current conditions.
