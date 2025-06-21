import Foundation

public struct LightProgramDefault: LightProgram {
    public let name = "default"
    private let steps: [any ProgramStep]

    public static let defaultSteps: [any ProgramStep] = [
        BaseSceneStep(),
        KitchenSinkStep(),
        TvShelfGroupStep(),
        GlobalBrightnessStep(),
        WledMainStep()
    ]

    public static func step(named name: String) -> (any ProgramStep)? {
        defaultSteps.first { $0.name.lowercased() == name.lowercased() }
    }

    public init(steps: [any ProgramStep] = LightProgramDefault.defaultSteps) {
        self.steps = steps
    }

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
        let states = context.states
        let transition = 2.0

        guard context.environment.autoMode else {
            return LightStateChangeset(currentStates: states, desiredStates: [])
        }

        var changes: [LightState] = []
        for step in steps {
            changes = step.apply(changes: changes, context: context, transition: transition)
        }
        return LightStateChangeset(currentStates: states, desiredStates: changes)
    }
}

// MARK: - Pipeline Steps

struct BaseSceneStep: ProgramStep {
    let name = "baseScene"

    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState] {
        var changes = changes
        changes = sceneChanges(scene: context.scene, environment: context.environment)
        return changes
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
}

struct KitchenSinkStep: ProgramStep {
    let name = "kitchenSink"

    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState] {
        var changes = changes
        applyKitchenSink(scene: context.scene, environment: context.environment, changes: &changes)
        return changes
    }

    private func applyKitchenSink(scene: StateContext.Scene, environment: StateContext.Environment, changes: inout [LightState]) {
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
}

struct TvShelfGroupStep: ProgramStep {
    let name = "tvShelfGroup"

    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState] {
        expandTvShelfGroup(changes: changes, environment: context.environment, transition: transition)
    }

    private func expandTvShelfGroup(changes: [LightState], environment: StateContext.Environment, transition: Double) -> [LightState] {
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
}

struct GlobalBrightnessStep: ProgramStep {
    let name = "globalBrightness"

    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState] {
        scaleBrightness(changes: changes, states: context.states, transition: transition)
    }

    private func scaleBrightness(changes: [LightState], states: HomeAssistantStateMap, transition: Double) -> [LightState] {
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

struct WledMainStep: ProgramStep {
    let name = "wledMain"

    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState] {
        ensureWledMain(changes: changes, transition: transition)
    }

    private func ensureWledMain(changes: [LightState], transition: Double) -> [LightState] {
        let mainId = "light.wled_tv_shelf_main"
        let hasShelfOn = changes.contains { state in
            state.entityId.hasPrefix("light.wled_tv_shelf_") &&
            state.entityId != mainId &&
            state.on
        }
        var filtered = changes.filter { $0.entityId != mainId }
        if hasShelfOn {
            filtered.append(LightState(entityId: mainId,
                                      on: true,
                                      brightness: 100,
                                      transitionDuration: transition))
        }
        return filtered
    }
}
