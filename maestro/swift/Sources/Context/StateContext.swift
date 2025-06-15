import Foundation

// CONTEXT:
/// A context that represents the current state of the home automation system.
///
/// StateContext interprets raw Home Assistant states into a structured representation
/// of the current scene and environment. The context includes:
///
/// - The active scene (off, calm night, normal, etc)
/// - Environmental factors like time of day and presence detection
///
/// This structured representation allows for consistent and centralized handling
/// of light state calculations based on the current conditions.
public struct StateContext {
    public let scene: Scene
    public let environment: Environment
    public let states: HomeAssistantStateMap

    public init(states: HomeAssistantStateMap) {
        let sceneStr = (states["input_select.living_scene"]?["state"] as? String) ?? "off"
        let scene: Scene
        switch sceneStr {
        case "calm night": scene = .calmNight
        case "normal": scene = .normal
        case "bright": scene = .bright
        case "brightest": scene = .brightest
        case "preset": scene = .preset
        default: scene = .off
        }

        let sunState = states["sun.sun"]?["state"] as? String ?? "below_horizon"
        var timeOfDay: TimeOfDay = .nighttime
        if sunState == "above_horizon" {
            if let attrs = states["sun.sun"]?["attributes"] as? [String: Any],
               let nextSettingStr = attrs["next_setting"] as? String {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let nextSetting = formatter.date(from: nextSettingStr) {
                    let now = Date()
                    let oneHourBefore = nextSetting.addingTimeInterval(-3600)
                    let twoHoursBefore = nextSetting.addingTimeInterval(-7200)
                    let eighteenHoursBefore = nextSetting.addingTimeInterval(-64800)
                    if now > oneHourBefore {
                        timeOfDay = .sunset
                    } else if now > twoHoursBefore {
                        timeOfDay = .preSunset
                    } else if now < eighteenHoursBefore {
                        timeOfDay = .nighttime
                    } else {
                        timeOfDay = .daytime
                    }
                } else {
                    timeOfDay = .daytime
                }
            } else {
                timeOfDay = .daytime
            }
        }
        let hyperionRunning = states["binary_sensor.living_tv_hyperion_running_condition_for_the_scene"]?["state"] as? String == "on"
        let diningPresence = states["binary_sensor.dining_espresence"]?["state"] as? String == "on"
        let kitchenPresenceEspresence = states["binary_sensor.kitchen_espresence"]?["state"] as? String == "on"
        let kitchenPresenceOccupancy = states["binary_sensor.kitchen_presence_occupancy"]?["state"] as? String == "on"
        let kitchenPresence = kitchenPresenceEspresence || kitchenPresenceOccupancy
        let kitchenExtraBrightness = states["input_boolean.kitchen_extra_brightness"]?["state"] as? String == "on"
        let autoMode = states["input_boolean.living_scene_auto"]?["state"] as? String != "off"
        var tvShelves: [Bool] = []
        for i in 1...5 {
            let key = "input_boolean.wled_tv_shelf_\(i)"
            let enabled = states[key]?["state"] as? String != "off"
            tvShelves.append(enabled)
        }
        let env = Environment(timeOfDay: timeOfDay,
                            hyperionRunning: hyperionRunning,
                            diningPresence: diningPresence,
                            kitchenPresence: kitchenPresence,
                            kitchenExtraBrightness: kitchenExtraBrightness,
                            autoMode: autoMode,
                            tvShelvesEnabled: tvShelves)

        self.scene = scene
        self.environment = env
        self.states = states
    }
}

