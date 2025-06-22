public struct LightState {
    public let entityId: String
    public let on: Bool
    public let brightness: Int?
    public let colorTemperature: Int?
    public let rgbColor: (Int, Int, Int)?
    public let rgbwColor: (Int, Int, Int, Int)?
    public let effect: String?
    /// Optional transition duration in seconds
    public let transitionDuration: Double?

    public init(entityId: String,
                on: Bool,
                brightness: Int? = nil,
                colorTemperature: Int? = nil,
                rgbColor: (Int, Int, Int)? = nil,
                rgbwColor: (Int, Int, Int, Int)? = nil,
                effect: String? = nil,
                transitionDuration: Double? = nil) {
        self.entityId = entityId
        self.on = on
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.rgbColor = rgbColor
        self.rgbwColor = rgbwColor
        self.effect = effect
        self.transitionDuration = transitionDuration
    }
}

extension LightState: CustomStringConvertible {
    public var description: String {
        let stateStr = on ? "on" : "off"
        var parts: [String] = ["\(entityId) -> \(stateStr)"]
        if let b = brightness { parts.append("brightness:\(b)") }
        if let ct = colorTemperature { parts.append("colorTemp:\(ct)") }
        if let rgb = rgbColor { parts.append("rgb:(\(rgb.0),\(rgb.1),\(rgb.2))") }
        if let rgbw = rgbwColor {
            parts.append("rgbw:(\(rgbw.0),\(rgbw.1),\(rgbw.2),\(rgbw.3))")
        }
        if let effect = effect { parts.append("effect:\(effect)") }
        if let t = transitionDuration { parts.append("transition:\(t)") }
        return parts.joined(separator: " ")
    }
}

public extension Array where Element == LightState {
    mutating func on(_ entityId: String,
                     brightness: Int? = nil,
                     colorTemperature: Int? = nil,
                     rgbColor: (Int, Int, Int)? = nil,
                     rgbwColor: (Int, Int, Int, Int)? = nil,
                     effect: String? = nil,
                     transitionDuration: Double? = nil) {
        append(LightState(entityId: entityId,
                          on: true,
                          brightness: brightness,
                          colorTemperature: colorTemperature,
                          rgbColor: rgbColor,
                          rgbwColor: rgbwColor,
                          effect: effect,
                          transitionDuration: transitionDuration))
    }

    mutating func on(_ entityIds: [String],
                     brightness: Int? = nil,
                     colorTemperature: Int? = nil,
                     rgbColor: (Int, Int, Int)? = nil,
                     rgbwColor: (Int, Int, Int, Int)? = nil,
                     effect: String? = nil,
                     transitionDuration: Double? = nil) {
        for id in entityIds {
            on(id,
               brightness: brightness,
               colorTemperature: colorTemperature,
               rgbColor: rgbColor,
               rgbwColor: rgbwColor,
               effect: effect,
               transitionDuration: transitionDuration)
        }
    }

    mutating func off(_ entityId: String, transitionDuration: Double? = nil) {
        append(LightState(entityId: entityId,
                          on: false,
                          transitionDuration: transitionDuration))
    }

    mutating func off(_ entityIds: [String], transitionDuration: Double? = nil) {
        for id in entityIds { off(id, transitionDuration: transitionDuration) }
    }
}