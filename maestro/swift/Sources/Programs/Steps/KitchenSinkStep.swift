struct KitchenSinkStep: ProgramStep {
    let name = "kitchenSink"

    func apply(changes: [LightState], effects: [SideEffect], context: StateContext) -> ([LightState], [SideEffect]) {
        var changes = changes
        applyKitchenSink(scene: context.scene, environment: context.environment, changes: &changes)
        return (changes, effects)
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
