struct BaseSceneStep: ProgramStep {
    let name = "baseScene"

    func apply(changes: [LightState], effects: [SideEffect], context: StateContext, transition: Double) -> ([LightState], [SideEffect]) {
        var changes = changes
        changes = sceneChanges(scene: context.scene, environment: context.environment)
        return (changes, effects)
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
