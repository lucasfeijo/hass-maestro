struct FlattenGroupsStep: ProgramStep {
    let name = "flattenGroups"
    let context: StateContext
    var skipped: Bool = false

    init(context: StateContext) {
        self.context = context
    }

    func process(_ effects: [SideEffect]) -> [SideEffect] {
        let lights = flatten(changes: effects.lights)
        var other = effects.nonLights
        other.appendLights(lights)
        return other
    }

    private func flatten(changes: [LightState]) -> [LightState] {
        var explicit: [String: LightState] = [:]
        var explicitOrder: [String: Int] = [:]
        var groups: [(LightState, [String])] = []
        for (index, state) in changes.enumerated() {
            if let members = FlattenGroupsStep.allLeaves(of: state.entityId) {
                groups.append((state, members))
            } else {
                explicit[state.entityId] = state
                explicitOrder[state.entityId] = index
            }
        }
        var result: [LightState] = []
        for (state, members) in groups {
            let anyExplicit = members.contains { explicit[$0] != nil }
            if anyExplicit {
                for m in members {
                    if explicit[m] == nil {
                        explicit[m] = LightState(entityId: m,
                                                on: state.on,
                                                brightness: state.brightness,
                                                colorTemperature: state.colorTemperature,
                                                rgbColor: state.rgbColor,
                                                rgbwColor: state.rgbwColor,
                                                effect: state.effect,
                                                transitionDuration: state.transitionDuration)
                        explicitOrder[m] = explicitOrder[state.entityId] ?? Int.max
                    }
                }
            } else {
                result.append(state)
            }
        }
        for id in explicitOrder.keys.sorted(by: { explicitOrder[$0]! < explicitOrder[$1]! }) {
            if let st = explicit[id] {
                result.append(st)
            }
        }
        return result
    }

    private static let groupMap: [String: [String]] = [
        "light.tv_shelf_group": [
            "light.wled_tv_shelf_1",
            "light.wled_tv_shelf_2",
            "light.wled_tv_shelf_3",
            "light.wled_tv_shelf_4",
            "light.wled_tv_shelf_5"
        ],
        "light.zigbee_hub_estante_lights": [
            "light.estante_1_light",
            "light.estante_2_light"
        ],
        "light.color_lights_without_tv_light": [
            "light.dining_table_light",
            "light.living_art_wall_light",
            "light.desk_light",
            "light.corner_light",
            "light.tripod_lamp",
            "light.estante_1_light",
            "light.estante_2_light"
        ],
        "light.color_lights": [
            "light.tv_light",
            "light.dining_table_light",
            "light.living_art_wall_light",
            "light.desk_light",
            "light.corner_light",
            "light.tripod_lamp",
            "light.estante_1_light",
            "light.estante_2_light"
        ],
        "light.living_temperature_lights": [
            "light.chaise_light",
            "light.shoes_light",
            "light.corredor_door_light",
            "light.entrance_dining_light",
            "light.living_entry_door_light",
            "light.living_fireplace_spot"
        ]
    ]

    private static func allLeaves(of id: String) -> [String]? {
        guard let members = groupMap[id] else { return nil }
        var leaves: [String] = []
        for m in members {
            if let sub = allLeaves(of: m) {
                leaves.append(contentsOf: sub)
            } else {
                leaves.append(m)
            }
        }
        return leaves
    }
}
