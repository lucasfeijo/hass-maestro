import Foundation

// PROGRAM:

public struct ProgramOutput {
    public let changeset: LightStateChangeset
    public let sideEffects: [SideEffect]

    public init(changeset: LightStateChangeset, sideEffects: [SideEffect] = []) {
        self.changeset = changeset
        self.sideEffects = sideEffects
    }
}

public protocol LightProgram {
    /// Human readable identifier for the program.
    var name: String { get }

    /// Compute the desired light state set and side effects for the given context.
    func compute(context: StateContext) -> ProgramOutput
}
