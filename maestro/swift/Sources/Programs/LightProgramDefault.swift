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
        let states = context.states
        let transition = 2.0

        var changes: [LightState] = []
        var effects: [SideEffect] = []

        if !context.environment.kitchenPresence {
            effects.append(.setInputBoolean(entityId: "input_boolean.kitchen_extra_brightness", state: false))
        }
        if context.environment.autoMode && context.scene != .preset {
            effects.append(.stopAllDynamicScenes)
        }

        guard context.environment.autoMode else {
            return ProgramOutput(changeset: LightStateChangeset(currentStates: states, desiredStates: []),
                                 sideEffects: effects)
        }

        for step in steps {
            let result = step.apply(changes: changes,
                                    effects: effects,
                                    context: context,
                                    transition: transition)
            changes = result.0
            effects = result.1
        }

        let changeset = LightStateChangeset(currentStates: states, desiredStates: changes)
        return ProgramOutput(changeset: changeset, sideEffects: effects)
    }
}
