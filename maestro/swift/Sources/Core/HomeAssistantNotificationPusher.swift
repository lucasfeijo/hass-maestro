import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class HomeAssistantNotificationPusher: NotificationPusher {
    private let baseURL: URL
    private let token: String?
    private let session: URLSession

    init(baseURL: URL, token: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    func push(title: String, message: String) {
        let url = baseURL.appendingPathComponent("api/services/persistent_notification/create")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: [String: Any] = ["title": title, "message": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
    }
}
