import Foundation
import ArgumentParser

extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}

struct MaestroOptions: ParsableArguments {
    @Option(name: .customLong("baseurl"), help: "Base URL for the Home Assistant instance")
    var baseURL: URL = URL(string: "http://homeassistant.local:8123/")!

    @Option(name: .long, help: "Long-lived Home Assistant token used for API calls")
    var token: String?

    @Flag(name: .long, help: "Print light commands instead of sending them")
    var simulate: Bool = false

    @Option(name: .customLong("program"), help: "Light program to run")
    var programName: String?

    @Flag(name: [.customLong("no-notify"), .customLong("disable-notifications")], help: "Disable Home Assistant persistent notifications on failures")
    var noNotify: Bool = false

    @Option(name: .long, help: "Port for the HTTP server")
    var port: Int32 = 8080

    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false

    var notificationsEnabled: Bool { !noNotify }
}

func parseArguments(_ args: [String]) -> MaestroOptions {
    do {
        var options = try MaestroOptions.parse(Array(args.dropFirst()))
        if options.token == nil {
            if let envToken = ProcessInfo.processInfo.environment["SUPERVISOR_TOKEN"], !envToken.isEmpty {
                options.token = envToken
            }
        }
        return options
    } catch {
        fatalError("Failed to parse arguments: \(error)")
    }
}


