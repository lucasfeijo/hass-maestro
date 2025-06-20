import Foundation

extension StateContext: CustomStringConvertible {
    public var description: String {
        let sceneName = String(describing: scene)
        let progress = String(format: "%.2f", environment.sunsetProgress)
        return "scene: \(sceneName) sunset: \(progress)"
    }
}
