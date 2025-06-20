import XCTest
@testable import maestro

final class StateContextDescriptionTests: XCTestCase {
    func testDescriptionShowsSceneAndSunsetProgress() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nextSetting = formatter.string(from: Date().addingTimeInterval(30 * 60))
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "normal"],
            "sun.sun": ["state": "above_horizon", "attributes": ["next_setting": nextSetting]]
        ])
        XCTAssertEqual(context.description, "scene: normal sunset: 0.50")
    }
}
