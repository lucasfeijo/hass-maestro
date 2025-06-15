public struct Logger: @unchecked Sendable {
    let pusher: NotificationPusher?

    public init(pusher: NotificationPusher?) {
        self.pusher = pusher
    }

    public func error(_ message: String) {
        print("[ERROR] \(message)")
        pusher?.push(title: "Maestro Error", message: message)
    }
}
