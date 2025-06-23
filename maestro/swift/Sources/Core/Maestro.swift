import Foundation

public final class Maestro {
    private let states: StateProvider
    private let effects: EffectController
    private let program: LightProgram
    private let logger: Logger
    private let verbose: Bool

    public init(states: StateProvider,
                effects: EffectController,
                program: LightProgram,
                logger: Logger,
                verbose: Bool = false) {
        self.states = states
        self.effects = effects
        self.program = program
        self.logger = logger
        self.verbose = verbose
    }


    /// Fetches state from Home Assistant and applies the current scene.
    /// 
    /// This method executes a 5-step process to synchronize light states:
    /// 1. STATE: Fetches all current states from Home Assistant using the API
    /// 2. CONTEXT: Derives a StateContext from the fetched states interpreting the scene and environment
    /// 3. PROGRAM: Computes the desired light states based on the current context
    /// 4. CHANGESET: Simplifies the state changes to minimize transitions
    /// 5. LIGHTS: Applies each new light state to the physical lights
    ///
    /// If any step fails, the error is logged and the process stops.
    public func run() {
        if verbose { logger.log("▶️ Running program \(program.name)") }

        if verbose { logger.log("STATE: fetching states") }
        let result = states.fetchAllStates()
        switch result {
        case .success(let states):
            if verbose { logger.log("STATE: fetched \(states.count) entries") }

            if verbose { logger.log("CONTEXT: building state context") }
            let context = StateContext(states: states)
            if verbose { logger.log("CONTEXT: \n\(context.description)") }

            if verbose { logger.log("PROGRAM: computing changes") }
            let output = program.compute(context: context)
            if verbose {
                logger.log("PROGRAM: produced \(output.changeset.desiredStates.count) light states and \(output.sideEffects.count) side effects")
            }

            if verbose { logger.log("CHANGESET: simplifying changes") }
            let lightEffects = output.changeset.simplified.map { SideEffect.setLight($0) }
            if verbose {
                logger.log("CHANGESET: \(lightEffects.count) changes after simplification")
                for effect in lightEffects {
                    logger.log("\(effect.description)")
                }
            }

            let allEffects = output.sideEffects + lightEffects
            
            for effect in allEffects {
                if verbose { logger.log("EFFECT: \(effect.description)") }
                effect.perform(using: self.effects)
            }

            if verbose { logger.log("✅ Maestro run completed") }
        case .failure(let error):
            logger.error("Failed to fetch home assistant states: \(error)")
        }
    }
}
