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

        let desired: [LightState]
        if scene == .normal && environment.timeOfDay == .sunset {
            var preEnv = environment
            preEnv.timeOfDay = .preSunset
            preEnv.sunsetProgress = 0
            let preStates = computeChanges(scene: scene, environment: preEnv, states: states, transition: transition)

            var sunsetEnv = environment
            sunsetEnv.sunsetProgress = 1
            let sunsetStates = computeChanges(scene: scene, environment: sunsetEnv, states: states, transition: transition)

            desired = blendStates(from: preStates, to: sunsetStates, progress: environment.sunsetProgress, transition: transition)
        } else {
            desired = computeChanges(scene: scene, environment: environment, states: states, transition: transition)
        }

        return LightStateChangeset(currentStates: states,
                                   desiredStates: desired)
    }

    private func computeChanges(scene: StateContext.Scene,
                                environment: StateContext.Environment,
                                states: HomeAssistantStateMap,
                                transition: Double) -> [LightState] {
        var changes = baseSceneChanges(scene: scene, environment: environment)
        applyKitchenSink(scene: scene, environment: environment, changes: &changes)
        let expanded = expandTvShelfGroup(changes: changes, environment: environment, transition: transition)
        return scaleBrightness(changes: expanded, states: states, transition: transition)
    }

    private func baseSceneChanges(scene: StateContext.Scene, environment: StateContext.Environment) -> [LightState] {
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
                    changes.on("light.tv_light", brightness: 50, colorTemperature: 224)
                    changes.on("light.wled_tv_shelf_4", brightness: 20, rgbwColor: (7, 106, 168, 255), effect: "solid")
                } else {
                    changes.off(["light.tv_light", "light.tv_shelf_group"])
                }
                changes.on("light.dining_table_light", brightness: 100, colorTemperature: 206)
                changes.off("light.corner_light")
                changes.on("light.desk_light", brightness: 40, colorTemperature: 199)
                changes.on(["light.corredor_door_light", "light.entrance_dining_light", "light.living_entry_door_light"], brightness: 60, colorTemperature: 250)
                changes.on("light.shoes_light", brightness: 50, colorTemperature: 250)
                changes.off(["light.chaise_light", "light.window_led_strip"])
                changes.on("light.living_art_wall_light", brightness: 60, colorTemperature: 196)
                changes.on("light.tripod_lamp", brightness: 49, colorTemperature: 206)
                changes.off("light.living_fireplace_spot")
                changes.on("light.zigbee_hub_estante_lights", brightness: 55, colorTemperature: 198)
                changes.on("light.kitchen_led", brightness: 50, rgbwColor: (0, 0, 0, 255), effect: "solid")
            } else {
                if !environment.hyperionRunning {
                    changes.on("light.tv_light", brightness: 51, colorTemperature: 394)
                    changes.on("light.tv_shelf_group", brightness: 20, rgbwColor: (255, 158, 64, 255), effect: "solid")
                } else {
                    changes.off("light.tv_light")
                }
                changes.on("light.color_lights_without_tv_light", brightness: 51, colorTemperature: 394)
                changes.on("light.corner_light", brightness: 30, colorTemperature: 394)
                changes.on("light.window_led_strip", brightness: 40, rgbColor: (189, 157, 112), effect: "solid")
                changes.on(["light.living_fireplace_spot", "light.living_entry_door_light", "light.shoes_light", "light.entrance_dining_light", "light.corredor_door_light"], brightness: 20, colorTemperature: 404)
                changes.off("light.chaise_light")
                changes.on("light.kitchen_led", brightness: 26, rgbwColor: (230, 170, 30, 150), effect: "solid")
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

    private func blendStates(from pre: [LightState],
                             to sunset: [LightState],
                             progress: Double,
                             transition: Double) -> [LightState] {
        let preMap = Dictionary(uniqueKeysWithValues: pre.map { ($0.entityId, $0) })
        let sunMap = Dictionary(uniqueKeysWithValues: sunset.map { ($0.entityId, $0) })
        var blended: [LightState] = []
        for id in Set(preMap.keys).union(sunMap.keys) {
            let a = preMap[id]
            let b = sunMap[id]
            let brightnessA = a?.brightness ?? (a?.on == true ? 0 : nil)
            let brightnessB = b?.brightness ?? (b?.on == true ? 0 : nil)

            var brightness: Int?
            if let ba = brightnessA, let bb = brightnessB {
                brightness = Int(round((1 - progress) * Double(ba) + progress * Double(bb)))
            } else if let bb = brightnessB {
                brightness = Int(round(progress * Double(bb)))
            } else if let ba = brightnessA {
                brightness = Int(round((1 - progress) * Double(ba)))
            }

            let ct: Int?
            if let cta = a?.colorTemperature, let ctb = b?.colorTemperature {
                ct = Int(round((1 - progress) * Double(cta) + progress * Double(ctb)))
            } else {
                ct = a?.colorTemperature ?? b?.colorTemperature
            }

            let rgbColor = progress < 0.5 ? a?.rgbColor : b?.rgbColor
            let rgbwColor = progress < 0.5 ? a?.rgbwColor : b?.rgbwColor
            let effect = progress < 0.5 ? a?.effect : b?.effect
            let isOn = (brightness ?? 0) > 0 || (a?.on ?? false && progress < 1) || (b?.on ?? false && progress > 0)

            blended.append(LightState(entityId: id,
                                     on: isOn,
                                     brightness: brightness,
                                     colorTemperature: ct,
                                     rgbColor: rgbColor,
                                     rgbwColor: rgbwColor,
                                     effect: effect,
                                     transitionDuration: transition))
        }
        return blended
    }
}
