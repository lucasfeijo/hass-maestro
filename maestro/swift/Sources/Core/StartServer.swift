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

private func configureHTML(stepNames: [String]) -> String {
    let data = try! JSONEncoder().encode(stepNames)
    let json = String(data: data, encoding: .utf8) ?? "[]"
    return """
    <!DOCTYPE html>
    <html><head><meta charset='utf-8'/>
    <title>Configure Maestro</title>
    <style>li{list-style:none;padding:4px;margin:2px;background:#eee;}li.drag{opacity:0.5;}</style>
    </head><body>
    <h1>Program Steps</h1>
    <ul id='list'></ul>
    <button id='save'>Save</button>
    <script>
    const list=document.getElementById('list');
    const names = \(json);
    function render(){list.innerHTML='';names.forEach(n=>{const li=document.createElement('li');li.textContent=n;li.draggable=true;li.dataset.name=n;list.appendChild(li);});}
    let drag;list.addEventListener('dragstart',e=>{drag=e.target;e.target.classList.add('drag');});
    list.addEventListener('dragend',e=>{e.target.classList.remove('drag');});
    list.addEventListener('dragover',e=>e.preventDefault());
    list.addEventListener('drop',e=>{e.preventDefault();if(e.target.tagName==='LI'&&drag){list.insertBefore(drag,e.target.nextSibling);}});
    document.getElementById('save').onclick=async()=>{const ordered=Array.from(list.children).map(li=>li.dataset.name);await fetch('/configure',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(ordered)});};
    render();
    </script></body></html>
    """
}

/// Minimal HTTP server handling GET/POST requests from Home Assistant.
func startServer(on port: Int32, maestro: Maestro) throws {
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

        var buffer = [UInt8](repeating: 0, count: 2048)
        let count = read(clientFD, &buffer, 2048)

        var statusLine = "HTTP/1.1 200 OK"
        var body = "OK"

        if count > 0 {
            let request = String(decoding: buffer[0..<count], as: UTF8.self)
            if request.hasPrefix("GET ") || request.hasPrefix("POST ") {
                if let firstLine = request.components(separatedBy: "\r\n").first,
                   let range = firstLine.range(of: " ") {
                    let start = firstLine.index(after: range.lowerBound)
                    let end = firstLine.range(of: " ", range: start..<firstLine.endIndex)?.lowerBound ?? firstLine.endIndex
                    let path = String(firstLine[start..<end])

                    if request.hasPrefix("GET ") {
                        if path == "/run" {
                            maestro.run()
                        } else if path == "/configure" {
                            let dummy = StateContext(states: [:])
                            let names = LightProgramDefault.defaultSteps.map { $0(dummy).name }
                            body = configureHTML(stepNames: names)
                        } else {
                            statusLine = "HTTP/1.1 404 Not Found"
                            body = "Not Found"
                        }
                    } else if request.hasPrefix("POST ") {
                        if path == "/configure" {
                            if let bodyRange = request.range(of: "\r\n\r\n") {
                                let jsonBody = request[bodyRange.upperBound...]
                                if let data = jsonBody.data(using: .utf8),
                                   let names = try? JSONDecoder().decode([String].self, from: data) {
                                    StepOrderStorage.save(names)
                                }
                            }
                        } else {
                            statusLine = "HTTP/1.1 404 Not Found"
                            body = "Not Found"
                        }
                    }
                }
            }
        }

        let response = "\(statusLine)\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
        _ = response.withCString { send(clientFD, $0, strlen($0), 0) }
        close(clientFD)
    }
}
