import Foundation

/// `LightController` that forwards commands to multiple controllers.
public final class MultiLightController: LightController {
    private let controllers: [LightController]

    public init(_ controllers: [LightController]) {
        self.controllers = controllers
    }

    public func setLightState(state: LightState) {
        for controller in controllers {
            controller.setLightState(state: state)
        }
    }

    public func stopAllDynamicScenes() {
        for controller in controllers {
            controller.stopAllDynamicScenes()
        }
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        for controller in controllers {
            controller.setInputBoolean(entityId: entityId, to: state)
        }
    }
}
