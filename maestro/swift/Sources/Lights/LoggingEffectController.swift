import Foundation

/// `EffectController` implementation that prints light commands instead of
/// sending them to Home Assistant. Useful for debugging.
public final class LoggingEffectController: EffectController {
    private let logger: Logger

    public init(logger: Logger = Logger(pusher: nil)) {
        self.logger = logger
    }

    public func setLightState(state: LightState) {
        logger.log(state.description)
    }

    public func stopAllDynamicScenes() {
        logger.log("scene_presets.stop_all_dynamic_scenes")
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        logger.log("\(entityId) -> \(state ? "on" : "off")")
    }
}
