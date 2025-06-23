struct HyperionStep: ProgramStep {
    let name = "hyperion"
    let context: StateContext

    init(context: StateContext) {
        self.context = context
    }

    func process(_ effects: [SideEffect]) -> [SideEffect] {
        var effects = effects
        var lights: [LightState] = []
        apply(scene: context.scene, environment: context.environment, changes: &lights)
        effects.appendLights(lights)
        return effects
    }

    private func apply(scene: StateContext.Scene, environment: StateContext.Environment, changes: inout [LightState]) {
        if environment.hyperionRunning {
            switch scene {
            case .calmNight:
                changes.off("light.tv_shelf_group")
            case .normal:
                if environment.timeOfDay == .daytime || environment.timeOfDay == .preSunset {
                    changes.off(["light.tv_light", "light.tv_shelf_group", "light.wled_tv_shelf_4"])
                } else {
                    changes.off("light.tv_light")
                }
            case .bright, .brightest:
                changes.off(["light.tv_light", "light.tv_shelf_group"])
            default:
                break
            }
        } else {
            switch scene {
            case .calmNight:
                if environment.timeOfDay != .daytime && environment.timeOfDay != .preSunset {
                    changes.on("light.tv_shelf_group", brightness: 2, effect: "solid")
                }
            case .normal:
                if environment.timeOfDay == .daytime || environment.timeOfDay == .preSunset {
                    changes.on("light.tv_light", brightness: 50, colorTemperature: 224)
                    changes.on("light.wled_tv_shelf_4", brightness: 20, rgbwColor: (7, 106, 168, 255), effect: "solid")
                } else {
                    changes.on("light.tv_light", brightness: 51, colorTemperature: 394)
                    changes.on("light.tv_shelf_group", brightness: 20, rgbwColor: (255, 158, 64, 255), effect: "solid")
                }
            case .bright:
                changes.on("light.tv_light", brightness: 75)
                changes.on("light.tv_shelf_group", brightness: 100, effect: "solid")
            case .brightest:
                changes.on("light.tv_light", brightness: 100)
                changes.on("light.tv_shelf_group", brightness: 100, effect: "solid")
            default:
                break
            }
        }
    }
}
