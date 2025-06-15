// LIGHTS:
public protocol LightController {
    func setLightState(state: LightState)
    func stopAllDynamicScenes()
    func setInputBoolean(entityId: String, to state: Bool)
}