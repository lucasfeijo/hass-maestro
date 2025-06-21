struct WledMainStep: ProgramStep {
    let name = "wledMain"

    func apply(changes: [LightState], effects: [SideEffect], context: StateContext, transition: Double) -> ([LightState], [SideEffect]) {
        let result = ensureWledMain(changes: changes, transition: transition)
        return (result, effects)
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
