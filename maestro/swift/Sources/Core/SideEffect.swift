public enum SideEffect {
    case setLight(LightState)
    case stopAllDynamicScenes
    case setInputBoolean(entityId: String, state: Bool)
}

extension SideEffect: CustomStringConvertible {
    public var description: String {
        switch self {
        case .setLight(let state):
            return "setLight(\(state.description))"
        case .stopAllDynamicScenes:
            return "stopAllDynamicScenes"
        case .setInputBoolean(let entityId, let state):
            return "setInputBoolean(\(entityId) -> \(state))"
        }
    }
}

extension SideEffect {
    func perform(using lights: EffectController) {
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
