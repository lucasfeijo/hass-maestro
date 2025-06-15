import Foundation

/// A recursive structure representing either a single light state or a group of lights.
public indirect enum LightGroup {
    case light(LightState)
    case group([String: LightGroup])
}

public extension LightGroup {
    /// Flattens the group into a list of `LightState` objects.
    func flattened() -> [LightState] {
        switch self {
        case .light(let state):
            return [state]
        case .group(let children):
            return children.values.flatMap { $0.flattened() }
        }
    }

    /// Recursively updates the specified entity or group. Returns true if any entry was updated.
    @discardableResult
    mutating func update(entityId: String, with state: LightState) -> Bool {
        switch self {
        case .light:
            return false
        case .group(var children):
            if var entry = children[entityId] {
                entry.updateAllLeaves(with: state)
                children[entityId] = entry
                self = .group(children)
                return true
            }
            var updated = false
            for key in children.keys {
                var entry = children[key]!
                if entry.update(entityId: entityId, with: state) {
                    children[key] = entry
                    updated = true
                    break
                }
            }
            if updated { self = .group(children) }
            return updated
        }
    }

    /// Updates all leaf light states within this group to the provided state.
    private mutating func updateAllLeaves(with state: LightState) {
        switch self {
        case .light:
            self = .light(state)
        case .group(var children):
            for key in children.keys {
                var entry = children[key]!
                entry.updateAllLeaves(with: state)
                children[key] = entry
            }
            self = .group(children)
        }
    }

    /// Convenience wrapper to update multiple entity identifiers.
    @discardableResult
    mutating func update(entityIds: [String], with state: LightState) -> Bool {
        var updated = false
        for id in entityIds {
            if update(entityId: id, with: state) { updated = true }
        }
        return updated
    }
}
