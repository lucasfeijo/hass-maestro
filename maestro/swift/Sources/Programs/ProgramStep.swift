public protocol ProgramStep {
    var name: String { get }
    /// When true this step is skipped during the program execution.
    var skipped: Bool { get set }
    init(context: StateContext)
    func process(_ effects: [SideEffect]) -> [SideEffect]
}
