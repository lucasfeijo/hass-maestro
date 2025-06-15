# Maestro Feature Roadmap

The original Home Assistant Python automation includes a variety of capabilities that are not yet represented in the Swift implementation. Below is a prioritized list of features to implement in future versions.

## Open ended questions

### a: Given that Changeset simplified ignores changes of 1% or less in brightness, does that mean we cannot perform a smooth 1% at a time transition in a light, ever? Do we need to rework that part of simplified? It was added for a reason, I think.

## Quick Wins (Low Complexity)

### 1. Auto Mode Toggle *(implemented)*
- Add support for `input_boolean.living_scene_auto` to freeze all changes when auto=off
- Simple boolean check added to the program flow
- No complex state management required

### 2. Error Reporting and Logging (implemented)
- Implement structured logging for failures *(implemented)*
- Add support for Home Assistant persistent notifications *(implemented)*
- Create a `NotificationPusher` protocol for sending notifications to hass *(implemented)*
- Add command-line option to disable notifications *(implemented)*

## Medium Complexity

### 3. Transition Support *(implemented)*
- Add transition duration field to `LightState`
- Update `LightController` implementations to handle transitions
- Implement 2-second fade support for relevant actions

### 4. Advanced Time-of-Day Handling *(implemented)*
- Extend `StateContext` to support additional states:
  - `daytime`
  - `pre_sunset`
  - `sunset`
  - `nighttime`
- Implement sun-based time detection logic

The Python automation in Examples/python_script.py already implements this logic. Around lines 320‑352, the script reads the sun state and computes the time_of_day value with several thresholds:

When the sun is above the horizon, it compares the current time to next_setting.

More than 2 hours before sunset → daytime

Between 2 hours and 1 hour before sunset → pre_sunset

Within the last hour before sunset → sunset

Otherwise → nighttime

This can be seen in the script output.

The script uses time_of_day later (e.g., around lines 424‑464) to adjust lighting scenes. For example, in the “calm night” scene:

If time_of_day is daytime or pre_sunset, it turns on certain lights with cooler color temperatures.

If it is sunset or nighttime, it selects warmer colors and lower brightness, or turns some lights off.

This behavior is visible in lines 420‑464 of the Python script.

Summary

Feature 4 of the roadmap calls for more refined time-of-day logic within the Swift project. The existing Python script already performs sun-based checks that produce four discrete periods—daytime, pre_sunset, sunset, and nighttime—using offsets from the sun’s next setting time. Lighting scenes are then tailored based on these periods. To match this behavior, the Swift StateContext should be extended so that it generates similar TimeOfDay values and exposes them to the rest of the program, enabling transitions and scene choices that mirror the automation logic of python_script.py.

### 5. Per-Shelf TV Light Control *(implemented)*
- Add support for individual shelf control via `input_boolean.wled_tv_shelf_n`
- Update `light.tv_shelf_group` handling to support per-shelf adjustments
- Implement shelf-specific state management

## High Complexity

### 6.1. Light Colors (implemented)
- Extend `LightState` to support:
  - `rgb_color`
  - `rgbw_color`
- Update `LightStateChangeset` to compare color values
- Modify light controller implementations accordingly

### 6.2. Effects (implemented)
- Extend `LightState` to support `effect` values
- Update `LightStateChangeset` to compare effect values
- Modify light controller implementations accordingly
- In the original Python automation, WLED strips were always sent
  `effect: "solid"` whenever turned on. Without this, the lights might resume
  whatever dynamic effect was previously active. The comparison should ignore
  case so `"Solid"` and `"solid"` are treated the same.

### 7. Nested Group Updates *(implemented)*
- Implement recursive group handling similar to `process_light_group`
- Add support for `update_specific_light` functionality
- Create helper functions for group operations

### 8. Preset/Dynamic Scenes *(implemented)*
- Implement `preset` scene handling in `LightProgramDefault`
- Add support for `scene_presets` interaction
- Implement dynamic scene stopping logic

### 9. Presence-Based Kitchen Sink Behavior *(implemented)*
- Add support for multiple presence sensors:
  - `kitchen_espresence`
  - `kitchen_presence_occupancy`
- Implement brightness and RGBW color adjustments
- Add `kitchen_extra_brightness` helper state management

### 10. Side effects that require service calls that aren't light controls are cluttering maestro.swift, we need a structured way of collecting the side effects from the program step and performing them later in the light step (maybe rename light step?)

`Maestro.run()` currently performs several service calls inline:

- `setInputBoolean` is used to reset helper booleans like `kitchen_extra_brightness` when presence is lost.
- `scene_presets.stop_all_dynamic_scenes` is triggered whenever a new scene is selected.
- Every computed `LightState` is sent immediately through `setLightState`.
- Errors from state fetching are logged on the spot.

These actions are all side effects of deciding what the lights should do. Because they're executed directly, any new behaviour would further crowd `Maestro.run()` with additional service calls. A more maintainable approach is to collect all side effects during the PROGRAM step (lights, helper booleans, scene preset commands, logs, etc.) and execute them in the final LIGHTS step. This keeps decision making separate from performing the actions and declutters the core loop.

## Implementation Strategy

1. Start with Quick Wins to build momentum and improve usability
2. Move to Medium Complexity items to enhance core functionality
3. Tackle High Complexity items last, as they require more architectural changes

Each feature should be implemented with:
- Comprehensive testing
- Documentation updates
- Backward compatibility where possible
- Performance considerations
