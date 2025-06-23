public protocol ProgramStep {
    var name: String { get }
    init(context: StateContext)
    func process(_ effects: [SideEffect]) -> [SideEffect]
}
