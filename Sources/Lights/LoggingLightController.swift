import Foundation

/// `LightController` implementation that prints light commands instead of
/// sending them to Home Assistant. Useful for debugging.
public final class LoggingLightController: LightController {
    public init() {}

    public func setLightState(state: LightState) {
        var message = "[LOG] \(state.entityId) -> \(state.on ? "on" : "off")"
        if let b = state.brightness { message += " brightness:\(b)" }
        if let ct = state.colorTemperature { message += " colorTemp:\(ct)" }
        if let rgb = state.rgbColor {
            message += " rgb:(\(rgb.0),\(rgb.1),\(rgb.2))"
        }
        if let rgbw = state.rgbwColor {
            message += " rgbw:(\(rgbw.0),\(rgbw.1),\(rgbw.2),\(rgbw.3))"
        }
        if let effect = state.effect { message += " effect:\(effect)" }
        if let t = state.transitionDuration { message += " transition:\(t)" }
        print(message)
    }

    public func stopAllDynamicScenes() {
        print("[LOG] scene_presets.stop_all_dynamic_scenes")
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        print("[LOG] \(entityId) -> \(state ? "on" : "off")")
    }
}
