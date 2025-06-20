import Foundation

public struct Logger: @unchecked Sendable {
    let pusher: NotificationPusher?
    private static let formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

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
        let ts = Logger.formatter.string(from: Date())
        print(colored("[\(ts)] [LOG] \(message)", color: Color.cyan))
    }

    public func error(_ message: String) {
        let ts = Logger.formatter.string(from: Date())
        print(colored("[\(ts)] [ERROR] \(message)", color: Color.red))
        pusher?.push(title: "Maestro Error", message: message)
    }
}
