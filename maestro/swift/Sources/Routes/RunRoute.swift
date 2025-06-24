import Foundation

func handleRunRoute(maestro: Maestro) -> (statusLine: String, headers: [String], body: String) {
    maestro.run()
    return ("HTTP/1.1 302 Found", ["Location: /"], "")
}
