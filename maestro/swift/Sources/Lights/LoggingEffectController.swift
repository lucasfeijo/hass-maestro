import Foundation

/// `EffectController` implementation that prints light commands instead of
/// sending them to Home Assistant. Useful for debugging.
public final class LoggingEffectController: EffectController {
    private let logger: Logger

    public init(logger: Logger = Logger(pusher: nil)) {
        self.logger = logger
    }

    public func setLightState(state: LightState) {
        var message = "\(state.entityId) -> \(state.on ? "on" : "off")"
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
        logger.log(message)
    }

    public func stopAllDynamicScenes() {
        logger.log("scene_presets.stop_all_dynamic_scenes")
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        logger.log("\(entityId) -> \(state ? "on" : "off")")
    }
}
