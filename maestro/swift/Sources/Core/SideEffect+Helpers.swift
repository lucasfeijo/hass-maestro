public extension Array where Element == SideEffect {
    var lights: [LightState] {
        compactMap { effect in
            if case .setLight(let state) = effect { return state } else { return nil }
        }
    }

    var nonLights: [SideEffect] {
        filter { effect in
            if case .setLight = effect { return false } else { return true }
        }
    }

    mutating func appendLights(_ states: [LightState]) {
        append(contentsOf: states.map { .setLight($0) })
    }
}
