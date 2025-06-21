import XCTest
@testable import maestro

final class LightProgramDefaultTests: XCTestCase {
    func testOffSceneTurnsAllLightsOff() {
        let context = StateContext(states: ["input_select.living_scene": ["state": "off"]])
        let diff = LightProgramDefault().compute(context: context).changeset
        
        // Verify all lights are turned off
        for lightState in diff.desiredStates {
            XCTAssertFalse(lightState.on, "Expected light \(lightState.entityId) to be off")
        }
    }

    func testNormalSceneHyperionRunning() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "above_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "on"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        
        let tvLight = diff.desiredStates.first { $0.entityId == "light.tv_light" }
        XCTAssertFalse(tvLight?.on ?? true)
        
        let shelves = diff.desiredStates.filter { $0.entityId.hasPrefix("light.wled_tv_shelf_") }
        XCTAssertEqual(shelves.count, 5)
        for shelf in shelves {
            XCTAssertFalse(shelf.on)
        }
    }

    func testBrightSceneHyperionRunning() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "bright"],
            "sun.sun": ["state": "above_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "on"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        
        let tvLight = diff.desiredStates.first { $0.entityId == "light.tv_light" }
        XCTAssertFalse(tvLight?.on ?? true)
    }

    func testCalmNightDiningPresenceLightsIncrease() {
        let contextWithPresence = StateContext(states: [
            "input_select.living_scene": ["state": "calm night"],
            "sun.sun": ["state": "below_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "on"],
            "binary_sensor.kitchen_espresence": ["state": "on"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let contextWithoutPresence = StateContext(states: [
            "input_select.living_scene": ["state": "calm night"],
            "sun.sun": ["state": "below_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"], 
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        
        let diffWithPresence = LightProgramDefault().compute(context: contextWithPresence).changeset
        let diffWithoutPresence = LightProgramDefault().compute(context: contextWithoutPresence).changeset
        
        // dining table brighter when presence detected
        let diningWithPresence = diffWithPresence.desiredStates.first { $0.entityId == "light.dining_table_light" }
        let diningWithoutPresence = diffWithoutPresence.desiredStates.first { $0.entityId == "light.dining_table_light" }
        XCTAssertGreaterThan(diningWithPresence?.brightness ?? 0, diningWithoutPresence?.brightness ?? 0)
    }

    func testAutoModeOffProducesNoChanges() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "input_boolean.living_scene_auto": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        XCTAssertTrue(diff.desiredStates.isEmpty)
    }

    func testStatesIncludeTransitionDuration() {
        let context = StateContext(states: ["input_select.living_scene": ["state": "normal"],
                                          "sun.sun": ["state": "above_horizon"],
                                          "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
                                          "binary_sensor.dining_espresence": ["state": "off"],
                                          "binary_sensor.kitchen_espresence": ["state": "off"],
                                          "input_boolean.kitchen_extra_brightness": ["state": "off"]])
        let diff = LightProgramDefault().compute(context: context).changeset
        for state in diff.desiredStates {
            XCTAssertEqual(state.transitionDuration, 2, "Expected transition of 2 seconds")
        }
    }

    func testTvShelfGroupRespectsIndividualSwitches() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "bright"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "binary_sensor.kitchen_presence_occupancy": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"],
            "input_boolean.wled_tv_shelf_1": ["state": "on"],
            "input_boolean.wled_tv_shelf_2": ["state": "off"],
            "input_boolean.wled_tv_shelf_3": ["state": "on"],
            "input_boolean.wled_tv_shelf_4": ["state": "on"],
            "input_boolean.wled_tv_shelf_5": ["state": "on"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset

        let shelf2 = diff.desiredStates.first { $0.entityId == "light.wled_tv_shelf_2" }
        XCTAssertFalse(shelf2?.on ?? true)

        let shelf3 = diff.desiredStates.first { $0.entityId == "light.wled_tv_shelf_3" }
        XCTAssertEqual(shelf3?.brightness, 100)
    }

    func testKitchenPresenceFromEitherSensor() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "above_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "binary_sensor.kitchen_presence_occupancy": ["state": "on"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        let sink = diff.desiredStates.first { $0.entityId == "light.kitchen_sink_light" }
        XCTAssertEqual(sink?.brightness, 60)
        XCTAssertEqual(sink?.rgbwColor?.3, 255)
    }

    func testKitchenSinkNightColor() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "below_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "on"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        let sink = diff.desiredStates.first { $0.entityId == "light.kitchen_sink_light" }
        XCTAssertEqual(sink?.rgbwColor?.0, 230)
        XCTAssertEqual(sink?.rgbwColor?.1, 170)
        XCTAssertEqual(sink?.rgbwColor?.2, 30)
        XCTAssertEqual(sink?.rgbwColor?.3, 150)
    }

    func testKitchenSinkNoPresenceProducesDimLight() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "above_horizon"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "on"]
        ])
        let diff = LightProgramDefault().compute(context: context).changeset
        let sink = diff.desiredStates.first { $0.entityId == "light.kitchen_sink_light" }
        XCTAssertEqual(sink?.brightness, 10)
    }

    func testMainSegmentOnWhenShelfOn() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "bright"],
            "binary_sensor.living_tv_hyperion_running_condition_for_the_scene": ["state": "off"],
            "binary_sensor.dining_espresence": ["state": "off"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "binary_sensor.kitchen_presence_occupancy": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "off"]
        ])

        let diff = LightProgramDefault().compute(context: context).changeset
        let main = diff.desiredStates.first { $0.entityId == "light.wled_tv_shelf_main" }
        XCTAssertEqual(main?.brightness, 100)
        XCTAssertTrue(main?.on ?? false)
    }
}
