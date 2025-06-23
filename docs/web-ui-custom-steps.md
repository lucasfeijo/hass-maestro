# Web UI for Custom Program Steps

This document outlines a future feature to expose a small web interface for configuring which `ProgramStep` instances run in the Maestro pipeline. The goal is to allow users to change the order of steps, or disable certain steps entirely, without modifying command line arguments.

## Goals

- Provide a simple UI served by Maestro that lists available steps.
- Allow users to enable/disable steps and reorder them via drag-and-drop or arrow buttons.
- Let users remove steps by clicking an "x" and re-add them from a separate list.
- Provide a "Reset" button to restore the command-line default order.
- Persist the selected order so that subsequent runs reuse it.
- Use the `--program` command line argument as the initial default sequence. Once the user saves a configuration through the UI, that configuration overrides the default until changed again.

## Proposed Approach

1. **Expose an HTTP page**
   - Add `webui: http://[HOST]:[PORT:8080]/configure` to `maestro/config.yaml` so Home Assistant shows an "Open Web UI" link.
   - Provide a `GET /configure` route which serves an HTML/JS interface styled with [Bootstrap](https://getbootstrap.com/).
   - The page should read `/data/step_order.json` on load so it shows the last saved order (or the command-line defaults if the file doesn't exist).
   - Include an endpoint like `POST /configure` to accept the chosen step list. The page sends this request asynchronously using `fetch` so the UI doesn't reload.
   - Offer a `POST /configure/reset` endpoint that clears any saved list and reverts to the command line defaults.

2. **List available steps**
   - Read step names from `LightProgramDefault.defaultSteps` using the same lookup logic as the `--program` option.
   - Display them with controls to reorder or remove each item. Removed steps
     appear in a separate list where they can be clicked to be re-added.

3. **Persist configuration**
   - Save the selected list under `/data/step_order.json` (or similar) inside the add-on data directory.
   - Save the command-line `--program` order to the file the first time Maestro starts.
   - On startup, if this file exists, load the steps from it instead of the `--program` argument.

4. **Fallback behaviour**
   - If no saved configuration is found, build the program from the command line `--program` option.
   - The first time the UI is used and saved, the stored value replaces the command line default for future runs.


This feature will make it easier to experiment with different step combinations without editing configuration files or restarting the add-on with new arguments.

