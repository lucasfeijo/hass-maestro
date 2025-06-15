<div align="center">
<h1>maestro</h1>
Home assistant lights orchestrator
</div>

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
 --program secondary # choose the light program to run (`default` or `secondary`)
 --port 8080 # port for the HTTP server (default 8080)
```

The package builds on Linux and macOS. On macOS the POSIX server code uses the
`Darwin` module, so the same command works there as well.

### Runtime dependencies

When running the Home Assistant add-on the container image is based on Alpine
Linux. The server executable is built against glibc, so the runtime image needs
glibc compatibility libraries. The provided Dockerfile installs `libc6-compat`
and `gcompat` to supply these libraries. If you maintain a custom image ensure
these packages are present or compile the server against musl instead.

## Requesting the server

### `GET /run`

This route triggers a run of the maestro pipeline.

Example request:

```bash
curl http://localhost:8080/run
```
Replace `8080` with the port specified by `--port` if different.

If the path is anything other than `/run`, the server responds with `404 Not
Found`.

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
