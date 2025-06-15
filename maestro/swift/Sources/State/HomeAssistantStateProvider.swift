import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class HomeAssistantStateProvider: StateProvider {
    private let baseURL: URL
    private let session: URLSession
    private let token: String?

    public init(baseURL: URL, token: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    public func fetchAllStates() -> Result<HomeAssistantStateMap, Error> {
        let url = baseURL.appendingPathComponent("api/states")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let semaphore = DispatchSemaphore(value: 0)
        final class Box: @unchecked Sendable { var value: Result<HomeAssistantStateMap, Error> = .failure(NSError(domain: "HomeAssistantStateProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch all states"])) }
        let box = Box()
        let task = session.dataTask(with: request) { data, urlResponse, error in
            if let httpResponse = urlResponse as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               let data,
               let json = try? JSONSerialization.jsonObject(with: data) as? HomeAssistantStateResponse {
                box.value = .success(json.toMap())
            } else {
                box.value = .failure(error ?? NSError(domain: "HomeAssistantStateProvider", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch all states"]))
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 10)
        return box.value
    }
}
