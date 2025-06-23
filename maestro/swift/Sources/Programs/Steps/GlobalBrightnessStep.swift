import Foundation

struct GlobalBrightnessStep: ProgramStep {
    let name = "globalBrightness"
    let context: StateContext

    init(context: StateContext) {
        self.context = context
    }

    func process(_ effects: [SideEffect]) -> [SideEffect] {
        let lights = effects.lights
        var nonLight = effects.nonLights

        let adjusted = scaleBrightness(changes: lights,
                                       states: context.states,
                                       transition: context.environment.lightTransition)

        nonLight.appendLights(adjusted)
        return nonLight
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
