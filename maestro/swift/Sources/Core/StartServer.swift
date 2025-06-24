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
func startServer(on port: Int32, maestro: Maestro, options: MaestroOptions) throws {
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

    while true {
        var clientAddr = sockaddr()
        var len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        let clientFD = accept(serverFD, &clientAddr, &len)
        if clientFD < 0 { continue }

        var buffer = [UInt8](repeating: 0, count: 1024)
        let count = read(clientFD, &buffer, 1024)

        var statusLine = "HTTP/1.1 200 OK"
        var headers = ["Content-Type: text/plain; charset=utf-8"]
        var body = "OK"

        if count > 0 {
            let request = String(decoding: buffer[0..<count], as: UTF8.self)
            if request.hasPrefix("GET ") {
                if let firstLine = request.components(separatedBy: "\r\n").first,
                   let range = firstLine.range(of: " ") {
                    let start = firstLine.index(after: range.lowerBound)
                    let end = firstLine.range(of: " ", range: start..<firstLine.endIndex)?.lowerBound ?? firstLine.endIndex
                    let path = firstLine[start..<end]
                    switch path {
                    case "/run":
                        maestro.run()
                    case "/":
                        statusLine = "HTTP/1.1 200 OK"
                        headers = ["Content-Type: text/html; charset=utf-8"]
                        body = """
                        <html>
                        <head><title>Hass Maestro</title></head>
                        <body>
                        <h1>Maestro Options</h1>
                        <ul>
                        <li>Base URL: \(options.baseURL)</li>
                        <li>Token: \(options.token ?? "")</li>
                        <li>Simulate: \(options.simulate)</li>
                        <li>Program: \(options.programName ?? "")</li>
                        <li>Notifications Enabled: \(options.notificationsEnabled)</li>
                        <li>Port: \(options.port)</li>
                        <li>Verbose: \(options.verbose)</li>
                        </ul>
                        <p><a href=\"/run\">Run now</a></p>
                        </body>
                        </html>
                        """
                    default:
                        statusLine = "HTTP/1.1 404 Not Found"
                        body = "Not Found"
                    }
                }
            }
        }

        let headerString = headers.joined(separator: "\r\n")
        let response = "\(statusLine)\r\n\(headerString)\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        _ = response.withCString { send(clientFD, $0, strlen($0), 0) }
        close(clientFD)
    }
}
