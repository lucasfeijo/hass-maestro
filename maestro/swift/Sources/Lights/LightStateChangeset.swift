import Foundation

// CHANGESET:
public struct LightStateChangeset {
    public let currentStates: HomeAssistantStateMap
    public let desiredStates: [LightState]

    public init(currentStates: HomeAssistantStateMap, desiredStates: [LightState]) {
        self.desiredStates = desiredStates
        self.currentStates = currentStates
    }

    /// A simplified list of states omitting changes that would not alter
    /// the current Home Assistant state.
    public var simplified: [LightState] {
        var simplified: [LightState] = []
        for change in desiredStates {

            if let current = currentStates[change.entityId],
               let state = current["state"] as? String {
                var shouldSend = false
                if (state == "on") != change.on {
                    shouldSend = true
                } else if let desired = change.brightness,
                          let attrs = current["attributes"] as? [String: Any],
                          let curr = attrs["brightness"] as? Int {
                    let pct: Int
                    if curr <= 100 {
                        pct = curr
                    } else {
                        pct = Int(round(Double(curr) * 100.0 / 255.0))
                    }
                    if abs(pct - desired) > 1 { shouldSend = true }
                } else if change.brightness != nil {
                    shouldSend = true
                } else if let desiredCT = change.colorTemperature,
                          let attrs = current["attributes"] as? [String: Any],
                          let curr = attrs["color_temp"] as? Int {
                    if curr != desiredCT { shouldSend = true }
                } else if change.colorTemperature != nil {
                    shouldSend = true
                } else if let desiredRGB = change.rgbColor,
                          let attrs = current["attributes"] as? [String: Any],
                          let curr = attrs["rgb_color"] as? [Int],
                          curr.count >= 3 {
                    if curr[0] != desiredRGB.0 || curr[1] != desiredRGB.1 || curr[2] != desiredRGB.2 {
                        shouldSend = true
                    }
                } else if change.rgbColor != nil {
                    shouldSend = true
                } else if let desiredRGBW = change.rgbwColor,
                          let attrs = current["attributes"] as? [String: Any],
                          let curr = attrs["rgbw_color"] as? [Int],
                          curr.count >= 4 {
                    if curr[0] != desiredRGBW.0 || curr[1] != desiredRGBW.1 || curr[2] != desiredRGBW.2 || curr[3] != desiredRGBW.3 {
                        shouldSend = true
                    }
                } else if change.rgbwColor != nil {
                    shouldSend = true
                } else if let desiredEffect = change.effect,
                          let attrs = current["attributes"] as? [String: Any],
                          let curr = attrs["effect"] as? String {
                    if curr.lowercased() != desiredEffect.lowercased() {
                        shouldSend = true
                    }
                } else if change.effect != nil {
                    shouldSend = true
                }
                if !shouldSend { continue }
            }
            simplified.append(change)
        }
        return simplified
    }
}
