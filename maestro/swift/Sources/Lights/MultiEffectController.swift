import Foundation

/// `EffectController` that forwards commands to multiple controllers.
public final class MultiEffectController: EffectController {
    private let controllers: [EffectController]

    public init(_ controllers: [EffectController]) {
        self.controllers = controllers
    }

    public func setLightState(state: LightState) {
        let group = DispatchGroup()
        for controller in controllers {
            group.enter()
            DispatchQueue.global().async {
                controller.setLightState(state: state)
                group.leave()
            }
        }
        group.wait()
    }

    public func stopAllDynamicScenes() {
        let group = DispatchGroup()
        for controller in controllers {
            group.enter()
            DispatchQueue.global().async {
                controller.stopAllDynamicScenes()
                group.leave()
            }
        }
        group.wait()
    }

    public func setInputBoolean(entityId: String, to state: Bool) {
        let group = DispatchGroup()
        for controller in controllers {
            group.enter()
            DispatchQueue.global().async {
                controller.setInputBoolean(entityId: entityId, to: state)
                group.leave()
            }
        }
        group.wait()
    }
}
