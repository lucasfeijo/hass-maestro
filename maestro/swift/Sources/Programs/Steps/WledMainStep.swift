struct WledMainStep: ProgramStep {
    let name = "wledMain"
    let context: StateContext

    init(context: StateContext) {
        self.context = context
    }

    func process(_ effects: [SideEffect]) -> [SideEffect] {
        let lights = ensureWledMain(changes: effects.lights, transition: context.environment.lightTransition)
        var otherEffects = effects.nonLights
        otherEffects.appendLights(lights)
        return otherEffects
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
