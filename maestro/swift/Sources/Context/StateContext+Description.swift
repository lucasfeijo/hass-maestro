import Foundation

extension StateContext: CustomStringConvertible {
    public var description: String {
        let sceneName = String(describing: scene)
        return """
        autoMode: \(environment.autoMode)
        scene: \(sceneName)
        timeOfDay: \(environment.timeOfDay)
        """
    }
}
