import Foundation

public struct LightProgramDefault: LightProgram {
    public let name = "default"
    private let steps: [any ProgramStep]
    private let logger: Logger?

    public static let defaultSteps: [any ProgramStep] = [
        InitialEffectsStep(),
        BaseSceneStep(),
        KitchenSinkStep(),
        TvShelfGroupStep(),
        GlobalBrightnessStep(),
        WledMainStep()
    ]

    public static func step(named name: String) -> (any ProgramStep)? {
        defaultSteps.first { $0.name.lowercased() == name.lowercased() }
    }

    public init(steps: [any ProgramStep] = LightProgramDefault.defaultSteps,
                logger: Logger? = nil) {
        self.steps = steps
        self.logger = logger
    }

    public func compute(context: StateContext) -> ProgramOutput {
        let states = context.states

        var changes: [LightState] = []
        var effects: [SideEffect] = []

        for step in steps {
            if let logger = logger {
                logger.log("PROGRAM: \(step.name)")
            }
            let result = step.apply(changes: changes,
                                    effects: effects,
                                    context: context)
            changes = result.0
            effects = result.1
            if !context.environment.autoMode { break }
        }

        guard context.environment.autoMode else {
            return ProgramOutput(changeset: LightStateChangeset(currentStates: states, desiredStates: []),
                                 sideEffects: effects)
        }


        let changeset = LightStateChangeset(currentStates: states, desiredStates: changes)
        return ProgramOutput(changeset: changeset, sideEffects: effects)
    }
}
