import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class HomeAssistantLightController: LightController {
    private let baseURL: URL
    private let token: String?
    private let session: URLSession
    private let logger: Logger?

    public init(baseURL: URL,
                token: String? = nil,
                session: URLSession = .shared,
                logger: Logger? = nil) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
        self.logger = logger
    }

    public func setLightState(state: LightState) {
        let url = baseURL.appendingPathComponent("api/services/light/turn_\(state.on ? "on" : "off")")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        var body: [String: Any] = ["entity_id": state.entityId]
        if let b = state.brightness { body["brightness_pct"] = b }
        if let ct = state.colorTemperature { body["color_temp"] = ct }
        if let rgb = state.rgbColor { body["rgb_color"] = [rgb.0, rgb.1, rgb.2] }
        if let rgbw = state.rgbwColor { body["rgbw_color"] = [rgbw.0, rgbw.1, rgbw.2, rgbw.3] }
        if let effect = state.effect { body["effect"] = effect }
        if let t = state.transitionDuration { body["transition"] = t }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let semaphore = DispatchSemaphore(value: 0)
        let logger = self.logger
        let entityId = state.entityId
        let task = session.dataTask(with: request) { _, response, error in
            if let error {
                logger?.error("Failed to set state for \(entityId): \(error)")
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
                logger?.error("Failed to set state for \(entityId) - HTTP \(http.statusCode)")
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
    }

    public func stopAllDynamicScenes() {
        let url = baseURL.appendingPathComponent("api/services/scene_presets/stop_all_dynamic_scenes")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: [:])

        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        let action = state ? "turn_on" : "turn_off"
        let url = baseURL.appendingPathComponent("api/services/input_boolean/\(action)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["entity_id": entityId])

        let semaphore = DispatchSemaphore(value: 0)
        let logger = self.logger
        let task = session.dataTask(with: request) { _, response, error in
            if let error {
                logger?.error("Failed to set input_boolean for \(entityId): \(error)")
            } else if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
                logger?.error("Failed to set input_boolean for \(entityId) - HTTP \(http.statusCode)")
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .now() + 5)
    }
}
