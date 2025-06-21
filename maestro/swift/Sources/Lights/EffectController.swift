// LIGHTS:
public protocol EffectController {
    func setLightState(state: LightState)
    func stopAllDynamicScenes()
    func setInputBoolean(entityId: String, to state: Bool)
}