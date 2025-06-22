struct TvShelfGroupStep: ProgramStep {
    let name = "tvShelfGroup"

    func apply(changes: [LightState], effects: [SideEffect], context: StateContext) -> ([LightState], [SideEffect]) {
        let result = expandTvShelfGroup(changes: changes, environment: context.environment, transition: context.environment.lightTransition)
        return (result, effects)
    }

    private func expandTvShelfGroup(changes: [LightState], environment: StateContext.Environment, transition: Double) -> [LightState] {
        var expanded: [LightState] = []
        let shelfIds = (1...5).map { "light.wled_tv_shelf_\($0)" }
        for state in changes {
            if state.entityId == "light.tv_shelf_group" {
                var group = LightGroup.group(
                    Dictionary(uniqueKeysWithValues: shelfIds.map { id in
                        (id, LightGroup.light(LightState(entityId: id, on: false)))
                    })
                )
                for (index, id) in shelfIds.enumerated() {
                    let enabled = environment.tvShelvesEnabled[index]
                    let shelfState: LightState
                    if enabled {
                        shelfState = LightState(entityId: id,
                                               on: state.on,
                                               brightness: state.brightness,
                                               colorTemperature: state.colorTemperature,
                                               rgbColor: state.rgbColor,
                                               rgbwColor: state.rgbwColor,
                                               effect: state.effect,
                                               transitionDuration: transition)
                    } else {
                        shelfState = LightState(entityId: id,
                                               on: false,
                                               transitionDuration: transition)
                    }
                    group.update(entityId: id, with: shelfState)
                }
                expanded.append(contentsOf: group.flattened())
            } else {
                expanded.append(state)
            }
        }
        return expanded
    }
}
