import XCTest
@testable import maestro

final class LightStateChangesetTests: XCTestCase {
    func testSimplifiedFiltersUnchangedStates() {
        let simplified = LightStateChangeset(
            currentStates: ["light.tv_light": ["state": "on", "attributes": ["brightness": 50]]],
            desiredStates: [LightState(entityId: "light.tv_light", on: true, brightness: 50)]
        ).simplified
        XCTAssertTrue(simplified.isEmpty)
    }

    func testSimplifiedIncludesChangedStates() {
        let simplified = LightStateChangeset(
            currentStates: ["light.tv_light": ["state": "on", "attributes": ["brightness": 102]]],
            desiredStates: [LightState(entityId: "light.tv_light", on: true, brightness: 50)]
        ).simplified
        let tvLight = simplified.first { $0.entityId == "light.tv_light" }
        XCTAssertEqual(tvLight?.brightness, 50)
    }

    func testSimplifiedIncludesOnOffChanges() {
        let simplified = LightStateChangeset(
            currentStates: ["light.corner_light": ["state": "on"]],
            desiredStates: [LightState(entityId: "light.corner_light", on: false)]
        ).simplified
        let corner = simplified.first { $0.entityId == "light.corner_light" }
        XCTAssertEqual(corner?.on, false)
    }

    func testSimplifiedIgnoresSmallBrightnessDifference() {
        let simplified = LightStateChangeset(
            currentStates: ["light.tv_light": ["state": "on", "attributes": ["brightness": 51]]],
            desiredStates: [LightState(entityId: "light.tv_light", on: true, brightness: 50)]
        ).simplified
        XCTAssertTrue(simplified.isEmpty)
    }

    func testSimplifiedIncludesColorChanges() {
        let simplified = LightStateChangeset(
            currentStates: ["light.color_light": ["state": "on", "attributes": ["rgb_color": [255, 0, 0]]]],
            desiredStates: [LightState(entityId: "light.color_light", on: true, rgbColor: (0, 255, 0))]
        ).simplified
        let color = simplified.first { $0.entityId == "light.color_light" }
        XCTAssertEqual(color?.rgbColor?.1, 255)
    }

    func testSimplifiedFiltersUnchangedColors() {
        let simplified = LightStateChangeset(
            currentStates: ["light.color_light": ["state": "on", "attributes": ["rgb_color": [1, 2, 3]]]],
            desiredStates: [LightState(entityId: "light.color_light", on: true, rgbColor: (1, 2, 3))]
        ).simplified
        XCTAssertTrue(simplified.isEmpty)
    }

    func testSimplifiedIncludesEffectChanges() {
        let simplified = LightStateChangeset(
            currentStates: ["light.effect_light": ["state": "on", "attributes": ["effect": "blink"]]],
            desiredStates: [LightState(entityId: "light.effect_light", on: true, effect: "solid")]
        ).simplified
        XCTAssertEqual(simplified.first?.effect, "solid")
    }

    func testSimplifiedFiltersUnchangedEffectsCaseInsensitive() {
        let simplified = LightStateChangeset(
            currentStates: ["light.effect_light": ["state": "on", "attributes": ["effect": "Solid"]]],
            desiredStates: [LightState(entityId: "light.effect_light", on: true, effect: "solid")]
        ).simplified
        XCTAssertTrue(simplified.isEmpty)
    }
}
