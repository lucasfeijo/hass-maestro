import Foundation

public final class Maestro {
    private let states: StateProvider
    private let lights: LightController
    private let program: LightProgram
    private let logger: Logger
    private let verbose: Bool

    public init(states: StateProvider,
                lights: LightController,
                program: LightProgram,
                logger: Logger,
                verbose: Bool = false) {
        self.states = states
        self.lights = lights
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
        if verbose {
            logger.log("Running program \(program.name)")
        }

        let result = states.fetchAllStates()
        switch result {
        case .success(let states):
            let context = StateContext(states: states)
            let output = program.compute(context: context)
            let lightEffects = output.changeset.simplified.map { SideEffect.setLight($0) }
            let allEffects = output.sideEffects + lightEffects
            allEffects.forEach { $0.perform(using: lights) }
        case .failure(let error):
            logger.error("Failed to fetch home assistant states: \(error)")
        }
    }
}
