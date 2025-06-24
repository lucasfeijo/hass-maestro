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
                maestro.run()
                statusLine = "HTTP/1.1 302 Found"
                headers = ["Location: /"]
                body = ""
            case "/":
                if method == "POST" {
                    if let bodyPart = request.components(separatedBy: "\r\n\r\n").last {
                        var order: [String] = []
                        var skips: Set<String> = []
                        for pair in bodyPart.split(separator: "&") {
                            let kv = pair.split(separator: "=", maxSplits: 1)
                            guard let name = kv.first else { continue }
                            let value = kv.count > 1 ? String(kv[1]).removingPercentEncoding ?? "" : ""
                            let key = String(name)
                            if key == "step" {
                                order.append(value)
                            } else if key.hasPrefix("skip_") {
                                skips.insert(String(key.dropFirst(5)))
                            }
                        }
                        if !order.isEmpty {
                            let programString = order.map { skips.contains($0) ? "!\($0)" : $0 }.joined(separator: ",")
                            options.programName = programString
                            maestro = makeMaestro(from: options)
                        }
                    }
                    statusLine = "HTTP/1.1 302 Found"
                    headers = ["Location: /"]
                    body = ""
                } else {
                    let steps = currentProgramSteps()
                    let listItems = steps.map { name, skip in
                        "<li class=\"list-group-item d-flex justify-content-between align-items-center\">" +
                        "<input type=\"hidden\" name=\"step\" value=\"\(name)\">" +
                        "<span>\(name)</span>" +
                        "<div>" +
                        "<label class=\"form-check-label me-2\"><input class=\"form-check-input me-1\" type=\"checkbox\" name=\"skip_\(name)\" \(skip ? "checked" : "")>Skip</label>" +
                        "<button type=\"button\" class=\"btn btn-sm btn-secondary move-up\">&#8679;</button>" +
                        "<button type=\"button\" class=\"btn btn-sm btn-secondary move-down ms-1\">&#8681;</button>" +
                        "</div></li>"
                    }.joined()

                    body = """
                    <html>
                    <head>
                    <title>Hass Maestro</title>
                    <link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\">
                    </head>
                    <body class=\"container py-3\">
                    <h1>Maestro Options</h1>
                    <form method=\"POST\" action=\"/\">
                    <ul class=\"list-group mb-3\" id=\"step-list\">\(listItems)</ul>
                    <button type=\"submit\" class=\"btn btn-primary\">Save</button>
                    <a href=\"/run\" class=\"btn btn-success ms-2\">Run now</a>
                    </form>
                    <script>
                    document.querySelectorAll('.move-up').forEach(function(btn){
                      btn.addEventListener('click', function(){
                        var li = this.closest('li');
                        if(li.previousElementSibling){ li.parentNode.insertBefore(li, li.previousElementSibling); }
                      });
                    });
                    document.querySelectorAll('.move-down').forEach(function(btn){
                      btn.addEventListener('click', function(){
                        var li = this.closest('li');
                        if(li.nextElementSibling){ li.parentNode.insertBefore(li.nextElementSibling, li); }
                      });
                    });
                    </script>
                    </body>
                    </html>
                    """
                    statusLine = "HTTP/1.1 200 OK"
                    headers = ["Content-Type: text/html; charset=utf-8"]
                }
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
