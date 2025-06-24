import Foundation
#if os(macOS) || os(iOS)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#elseif os(Windows)
import ucrt
#else
#error("Unknown platform")
#endif
/// Minimal HTTP server handling GET requests from Home Assistant.
func startServer(on port: Int32, maestro initialMaestro: Maestro, options initialOptions: MaestroOptions) throws {
    var options = initialOptions
    var maestro = initialMaestro

    let defaultStepNames: [String] = LightProgramDefault.defaultSteps.map { factory in
        factory(StateContext(states: [:])).name
    }
    // SOCK_STREAM may be an enum or an Int32 depending on the libc headers
    // being used. Convert it to Int32 in a way that works for both cases.
    let sockStream: Int32 = withUnsafeBytes(of: SOCK_STREAM) { $0.load(as: Int32.self) }
    let serverFD = socket(AF_INET, sockStream, 0)
    guard serverFD >= 0 else { fatalError("Unable to create socket") }

    var value: Int32 = 1
    setsockopt(serverFD, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size))

    var addr = sockaddr_in()
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = in_port_t(port).bigEndian
    addr.sin_addr = in_addr(s_addr: INADDR_ANY.bigEndian)

    var bindAddr = sockaddr()
    memcpy(&bindAddr, &addr, MemoryLayout<sockaddr_in>.size)
    guard bind(serverFD, &bindAddr, socklen_t(MemoryLayout<sockaddr_in>.size)) >= 0 else {
        fatalError("bind failed")
    }
    listen(serverFD, 10)
    print("Server listening on port \(port)")

    func currentProgramSteps() -> [(String, Bool)] {
        let raw = options.programName?.split(separator: ",").map(String.init) ?? defaultStepNames
        return raw.map { part in
            if part.hasPrefix("!") {
                return (String(part.dropFirst()), true)
            } else {
                return (part, false)
            }
        }
    }

    while true {
        var clientAddr = sockaddr()
        var len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        let clientFD = accept(serverFD, &clientAddr, &len)
        if clientFD < 0 { continue }

        var buffer = [UInt8](repeating: 0, count: 4096)
        let count = read(clientFD, &buffer, 4096)

        var statusLine = "HTTP/1.1 200 OK"
        var headers = ["Content-Type: text/plain; charset=utf-8"]
        var body = "OK"

        if count > 0 {
            let request = String(decoding: buffer[0..<count], as: UTF8.self)
            guard let firstLine = request.components(separatedBy: "\r\n").first else { continue }
            let parts = firstLine.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            guard parts.count >= 2 else { continue }
            let method = parts[0]
            let path = parts[1]

            switch String(path) {
            case "/run":
                (statusLine, headers, body) = handleRunRoute(maestro: maestro)
            case "/":
                (statusLine, headers, body) = handleRootRoute(method: method, request: request, maestro: &maestro, options: &options, defaultStepNames: defaultStepNames)
            default:
                statusLine = "HTTP/1.1 404 Not Found"
                body = "Not Found"
            }
        }

        let headerString = headers.joined(separator: "\r\n")
        let response = "\(statusLine)\r\n\(headerString)\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        _ = response.withCString { send(clientFD, $0, strlen($0), 0) }
        close(clientFD)
    }
}
