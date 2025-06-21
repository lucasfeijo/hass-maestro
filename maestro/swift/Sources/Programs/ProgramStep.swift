public protocol ProgramStep {
    var name: String { get }
    func apply(changes: [LightState], context: StateContext, transition: Double) -> [LightState]
}
