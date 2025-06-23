struct InitialEffectsStep: ProgramStep {
    let name = "initialEffects"
    let context: StateContext

    init(context: StateContext) {
        self.context = context
    }

    func process(_ effects: [SideEffect]) -> [SideEffect] {
        var effects = effects

        if !context.environment.kitchenPresence {
            effects.append(.setInputBoolean(entityId: "input_boolean.kitchen_extra_brightness", state: false))
        }

        if context.environment.autoMode && context.scene != .preset {
            effects.append(.stopAllDynamicScenes)
        }

        return effects
    }
}

