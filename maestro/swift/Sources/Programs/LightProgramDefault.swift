import Foundation

public struct LightProgramDefault: LightProgram {
    public let name = "default"
    public typealias StepFactory = (StateContext) -> any ProgramStep
    private let steps: [StepFactory]
    private let logger: Logger?

    public static let defaultSteps: [StepFactory] = [
        { InitialEffectsStep(context: $0) },
        { BaseSceneStep(context: $0) },
        { KitchenSinkStep(context: $0) },
        { TvShelfGroupStep(context: $0) },
        { GlobalBrightnessStep(context: $0) },
        { WledMainStep(context: $0) },
        { FlattenGroupsStep(context: $0) }
    ]

    public static func step(named name: String) -> StepFactory? {
        let dummy = StateContext(states: [:])
        return defaultSteps.first { factory in
            factory(dummy).name.lowercased() == name.lowercased()
        }
    }

    public init(steps: [StepFactory] = LightProgramDefault.defaultSteps,
                logger: Logger? = nil) {
        self.steps = steps
        self.logger = logger
    }

    public func compute(context: StateContext) -> ProgramOutput {
        let states = context.states
        var effects: [SideEffect] = []

        for factory in steps {
            let step = factory(context)
            effects = step.process(effects)
            logger?.log("--- STEP: \(step.name) (\(effects.count) effects) ---")
            effects.forEach { logger?.log($0.description) }
            if !context.environment.autoMode { break }
        }

        let changeset = LightStateChangeset(currentStates: states, effects: effects)

        guard context.environment.autoMode else {
            let trimmed = LightStateChangeset(currentStates: states, effects: changeset.sideEffects)
            return ProgramOutput(changeset: trimmed)
        }

        return ProgramOutput(changeset: changeset)
    }
}
