public enum SideEffect {
    case setLight(LightState)
    case stopAllDynamicScenes
    case setInputBoolean(entityId: String, state: Bool)
}

extension SideEffect {
    func perform(using lights: LightController) {
        switch self {
        case .setLight(let state):
            lights.setLightState(state: state)
        case .stopAllDynamicScenes:
            lights.stopAllDynamicScenes()
        case .setInputBoolean(let entityId, let state):
            lights.setInputBoolean(entityId: entityId, to: state)
        }
    }
}
