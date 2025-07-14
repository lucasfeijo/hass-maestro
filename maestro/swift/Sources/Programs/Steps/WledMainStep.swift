struct WledMainStep: ProgramStep {
    let name = "wledMain"
    let context: StateContext
    var skipped: Bool = false

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
        let tvShelfMainId = "light.wled_tv_shelf_main"
        let wledMainId = "light.wled_main"
        
        var filtered = changes.filter { $0.entityId != tvShelfMainId && $0.entityId != wledMainId }
        
        // Sempre ativa TV shelf main
        filtered.append(LightState(entityId: tvShelfMainId,
                                  on: true,
                                  brightness: 100,
                                  transitionDuration: transition))
        
        // Sempre ativa WLED main
        filtered.append(LightState(entityId: wledMainId,
                                  on: true,
                                  brightness: 100,
                                  transitionDuration: transition))
        
        return filtered
    }
}
