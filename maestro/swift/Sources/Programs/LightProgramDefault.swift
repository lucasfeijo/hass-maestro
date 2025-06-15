import Foundation

public struct LightProgramDefault: LightProgram {
    public let name = "default"
    public init() {}

    public func compute(context: StateContext) -> ProgramOutput {
        var sideEffects: [SideEffect] = []
        if !context.environment.kitchenPresence {
            sideEffects.append(.setInputBoolean(entityId: "input_boolean.kitchen_extra_brightness", state: false))
        }
        if context.environment.autoMode && context.scene != .preset {
            sideEffects.append(.stopAllDynamicScenes)
        }

        let changeset = computeStateSet(context: context)
        return ProgramOutput(changeset: changeset, sideEffects: sideEffects)
    }

    // Original method preserved for direct tests
    public func computeStateSet(context: StateContext) -> LightStateChangeset {
        let scene = context.scene
        let environment = context.environment
        let states = context.states
        let transition = 2.0

        guard environment.autoMode else {
            return LightStateChangeset(currentStates: states, desiredStates: [])
        }

        var changes = sceneChanges(scene: scene, environment: environment)
        applyKitchenSink(scene: scene, environment: environment, changes: &changes)
        let expanded = expandTvShelfGroup(changes: changes, environment: environment, transition: transition)
        let scaled = scaleBrightness(changes: expanded, states: states, transition: transition)

        return LightStateChangeset(currentStates: states,
                                   desiredStates: scaled)
    }

    private func sceneChanges(scene: StateContext.Scene, environment: StateContext.Environment) -> [LightState] {
        var changes: [LightState] = []

        switch scene {
        case .off:
            changes.off(["light.living_temperature_lights", "light.color_lights", "light.window_led_strip", "light.kitchen_led"])

        case .calmNight:
            if environment.timeOfDay == .daytime || environment.timeOfDay == .preSunset {
                changes.on("light.kitchen_led", brightness: 50, effect: "solid")
                changes.on("light.tripod_lamp", brightness: 10, colorTemperature: 200)
            } else {
                if !environment.hyperionRunning {
                    changes.on("light.tv_shelf_group", brightness: 2, effect: "solid")
                } else {
                    changes.off("light.tv_shelf_group")
                }
                changes.on("light.window_led_strip", brightness: 17, effect: "solid")
                changes.on(["light.entrance_dining_light", "light.living_entry_door_light", "light.living_fireplace_spot"], brightness: 10)
                changes.on("light.desk_light", brightness: 5)
                changes.off(["light.shoes_light", "light.tv_light", "light.chaise_light", "light.corredor_door_light"])
                changes.on("light.tripod_lamp", brightness: 10)
                changes.on("light.zigbee_hub_estante_lights", brightness: 8)
                changes.on("light.living_art_wall_light", brightness: 10)
                changes.on("light.kitchen_led", brightness: 50, effect: "solid")
                if environment.diningPresence {
                    changes.on("light.dining_table_light", brightness: 30)
                } else {
                    changes.on("light.dining_table_light", brightness: 10)
                }
            }

        case .normal:
            if environment.timeOfDay == .daytime || environment.timeOfDay == .preSunset {
                if !environment.hyperionRunning {
                    changes.on("light.tv_light", brightness: 50)
                    changes.on("light.wled_tv_shelf_4", brightness: 20, effect: "solid")
                } else {
                    changes.off(["light.tv_light", "light.tv_shelf_group"])
                }
                changes.on("light.dining_table_light", brightness: 100)
                changes.off("light.corner_light")
                changes.on("light.desk_light", brightness: 40)
                changes.on(["light.corredor_door_light", "light.entrance_dining_light", "light.living_entry_door_light"], brightness: 60)
                changes.on("light.shoes_light", brightness: 50)
                changes.off(["light.chaise_light", "light.window_led_strip"])
                changes.on("light.living_art_wall_light", brightness: 60)
                changes.on("light.tripod_lamp", brightness: 49)
                changes.off("light.living_fireplace_spot")
                    changes.on("light.zigbee_hub_estante_lights", brightness: 55)
                    changes.on("light.kitchen_led", brightness: 50, effect: "solid")
            } else {
                if !environment.hyperionRunning {
                    changes.on("light.tv_light", brightness: 51)
                    changes.on("light.tv_shelf_group", brightness: 20, effect: "solid")
                } else {
                    changes.off("light.tv_light")
                }
                changes.on("light.color_lights_without_tv_light", brightness: 51)
                changes.on("light.corner_light", brightness: 30)
                changes.on("light.window_led_strip", brightness: 40, effect: "solid")
                changes.on(["light.living_fireplace_spot", "light.living_entry_door_light", "light.shoes_light", "light.entrance_dining_light", "light.corredor_door_light"], brightness: 20)
                changes.off("light.chaise_light")
                changes.on("light.kitchen_led", brightness: 26, effect: "solid")
            }

        case .bright:
            if !environment.hyperionRunning {
                changes.on("light.tv_light", brightness: 75)
                changes.on("light.tv_shelf_group", brightness: 100, effect: "solid")
            } else {
                changes.off(["light.tv_light", "light.tv_shelf_group"])
            }
            changes.on("light.living_temperature_lights", brightness: 60)
            changes.on("light.color_lights_without_tv_light", brightness: 75)
            changes.on("light.window_led_strip", brightness: 100, effect: "solid")
            changes.on("light.zigbee_hub_estante_lights", brightness: 75)
            changes.on("light.kitchen_led", brightness: 100, effect: "solid")

        case .brightest:
            if !environment.hyperionRunning {
                changes.on("light.tv_light", brightness: 100)
                changes.on("light.tv_shelf_group", brightness: 100, effect: "solid")
            } else {
                changes.off(["light.tv_light", "light.tv_shelf_group"])
            }
            changes.on(["light.living_temperature_lights", "light.color_lights_without_tv_light", "light.window_led_strip", "light.zigbee_hub_estante_lights", "light.kitchen_led"], brightness: 100)

        case .preset:
            changes.off("light.living_temperature_lights")
        }

        return changes
    }

    private func applyKitchenSink(scene: StateContext.Scene,
                                  environment: StateContext.Environment,
                                  changes: inout [LightState]) {
        let sinkColor: (Int, Int, Int, Int)
        if environment.timeOfDay == .daytime || environment.timeOfDay == .preSunset {
            sinkColor = (0, 0, 0, 255)
        } else {
            sinkColor = (230, 170, 30, 150)
        }
        let kitchenOnBrightness: Int
        if environment.kitchenPresence {
            if (scene == .calmNight || scene == .normal || scene == .off) && !environment.kitchenExtraBrightness {
                kitchenOnBrightness = 60
            } else {
                kitchenOnBrightness = 100
            }
            changes.on("light.kitchen_sink_light", brightness: kitchenOnBrightness, rgbwColor: sinkColor, effect: "solid")
            changes.on("light.kitchen_sink_light_old", brightness: 20)
        } else if scene != .off {
            changes.on("light.kitchen_sink_light", brightness: 10, rgbwColor: sinkColor, effect: "solid")
            changes.on("light.kitchen_sink_light_old", brightness: 10)
        }
    }

    private func expandTvShelfGroup(changes: [LightState],
                                    environment: StateContext.Environment,
                                    transition: Double) -> [LightState] {
        var expanded: [LightState] = []
        let shelfIds = (1...5).map { "light.wled_tv_shelf_\($0)" }
        for state in changes {
            if state.entityId == "light.tv_shelf_group" {
                var group = LightGroup.group(
                    Dictionary(uniqueKeysWithValues: shelfIds.map { id in
                        (id, LightGroup.light(LightState(entityId: id, on: false)))
                    })
                )
                for (index, id) in shelfIds.enumerated() {
                    let enabled = environment.tvShelvesEnabled[index]
                    let shelfState: LightState
                    if enabled {
                        shelfState = LightState(entityId: id,
                                               on: state.on,
                                               brightness: state.brightness,
                                               colorTemperature: state.colorTemperature,
                                               rgbColor: state.rgbColor,
                                               rgbwColor: state.rgbwColor,
                                               effect: state.effect,
                                               transitionDuration: transition)
                    } else {
                        shelfState = LightState(entityId: id,
                                               on: false,
                                               transitionDuration: transition)
                    }
                    group.update(entityId: id, with: shelfState)
                }
                expanded.append(contentsOf: group.flattened())
            } else {
                expanded.append(state)
            }
        }
        return expanded
    }

    private func scaleBrightness(changes: [LightState],
                                 states: HomeAssistantStateMap,
                                 transition: Double) -> [LightState] {
        let scaleStr = states["input_number.living_scene_brightness_percentage"]?["state"] as? String ?? "100"
        let scalePct = Double(scaleStr) ?? 100
        let scale = max(0.0, min(scalePct, 100.0)) / 100.0
        return changes.map { state -> LightState in
            var brightness = state.brightness
            if let b = state.brightness {
                let scaled = Int(round(Double(b) * scale))
                brightness = max(1, min(100, scaled))
            }
            return LightState(entityId: state.entityId,
                              on: state.on,
                              brightness: brightness,
                              colorTemperature: state.colorTemperature,
                              rgbColor: state.rgbColor,
                              rgbwColor: state.rgbwColor,
                              effect: state.effect,
                              transitionDuration: transition)
        }
    }
}
