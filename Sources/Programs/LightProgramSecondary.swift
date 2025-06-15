import Foundation

public struct LightProgramSecondary: LightProgram {
    public let name = "secondary"
    public init() {}

    public func compute(context: StateContext) -> ProgramOutput {
        let change = LightState(entityId: "light.secondary",
                               on: true,
                               brightness: 1,
                               transitionDuration: 2)
        let changeset = LightStateChangeset(currentStates: context.states, desiredStates: [change])
        return ProgramOutput(changeset: changeset)
    }

    // Preserving previous API for tests
    public func computeStateSet(context: StateContext) -> LightStateChangeset {
        compute(context: context).changeset
    }
}
