public struct Logger: @unchecked Sendable {
    let pusher: NotificationPusher?

    enum Color {
        static let red = "\u{001B}[31m"
        static let cyan = "\u{001B}[36m"
        static let reset = "\u{001B}[0m"
    }

    public init(pusher: NotificationPusher?) {
        self.pusher = pusher
    }

    private func colored(_ text: String, color: String) -> String {
        return color + text + Color.reset
    }

    public func log(_ message: String) {
        print(colored("[LOG] \(message)", color: Color.cyan))
    }

    public func error(_ message: String) {
        print(colored("[ERROR] \(message)", color: Color.red))
        pusher?.push(title: "Maestro Error", message: message)
    }
}
