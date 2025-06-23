import XCTest
@testable import maestro

final class FlattenGroupsStepTests: XCTestCase {
    func testGroupExpandedWhenIndividualOverrides() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "below_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        XCTAssertNil(diff.desiredStates.first { $0.entityId == "light.color_lights_without_tv_light" })
        let corner = diff.desiredStates.first { $0.entityId == "light.corner_light" }
        XCTAssertEqual(corner?.brightness, 30)
        let dining = diff.desiredStates.first { $0.entityId == "light.dining_table_light" }
        XCTAssertEqual(dining?.brightness, 51)
    }
}
