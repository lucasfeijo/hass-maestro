public protocol ProgramStep {
    var name: String { get }
    func apply(changes: [LightState], effects: [SideEffect], context: StateContext, transition: Double) -> ([LightState], [SideEffect])
}
