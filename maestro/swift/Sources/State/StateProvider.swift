// STATE:
public protocol StateProvider {
    func fetchAllStates() -> Result<HomeAssistantStateMap, Error>
}

public typealias HomeAssistantStateResponse = [[String: Any]]

public typealias HomeAssistantStateMap = [String: [String: Any]]

extension HomeAssistantStateResponse {
    public func toMap() -> HomeAssistantStateMap {
        reduce(into: [:]) { map, state in
            if let id = state["entity_id"] as? String {
                map[id] = state
            }
        }
    }
}
