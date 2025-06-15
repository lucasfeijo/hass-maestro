import Foundation

struct MaestroOptions {
    var baseURL: URL = URL(string: "http://homeassistant.local:8123/")!
    var token: String? = nil
    var simulate: Bool = false
    var programName: String = "default"
    var notificationsEnabled: Bool = true
    var port: Int32 = 8080
    var verbose: Bool = false
}

func parseArguments(_ args: [String]) -> MaestroOptions {
    var options = MaestroOptions()
    var idx = 1
    while idx < args.count {
        let arg = args[idx]
        if arg.hasPrefix("--baseurl=") {
            let value = String(arg.dropFirst("--baseurl=".count))
            if let url = URL(string: value) { options.baseURL = url }
        } else if arg == "--baseurl", idx + 1 < args.count {
            idx += 1
            if let url = URL(string: args[idx]) { options.baseURL = url }
        } else if arg.hasPrefix("--token=") {
            options.token = String(arg.dropFirst("--token=".count))
        } else if arg == "--token", idx + 1 < args.count {
            idx += 1
            options.token = args[idx]
        } else if arg == "--simulate" {
            options.simulate = true
        } else if arg.hasPrefix("--program=") {
            options.programName = String(arg.dropFirst("--program=".count))
        } else if arg == "--program", idx + 1 < args.count {
            idx += 1
            options.programName = args[idx]
        } else if arg == "--no-notify" || arg == "--disable-notifications" {
            options.notificationsEnabled = false
        } else if arg == "--verbose" {
            options.verbose = true
        } else if arg.hasPrefix("--port=") {
            let value = String(arg.dropFirst("--port=".count))
            if let p = Int32(value) { options.port = p }
        } else if arg == "--port", idx + 1 < args.count {
            idx += 1
            if let p = Int32(args[idx]) { options.port = p }
        }
        idx += 1
    }
    return options
}
