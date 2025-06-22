struct InitialEffectsStep: ProgramStep {
    let name = "initialEffects"

    func apply(changes: [LightState], effects: [SideEffect], context: StateContext) -> ([LightState], [SideEffect]) {
        var effects = effects

        if !context.environment.kitchenPresence {
            effects.append(.setInputBoolean(entityId: "input_boolean.kitchen_extra_brightness", state: false))
        }

        if context.environment.autoMode && context.scene != .preset {
            effects.append(.stopAllDynamicScenes)
        }

        return (changes, effects)
    }
}

