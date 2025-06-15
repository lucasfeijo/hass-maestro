import XCTest
@testable import maestro

final class StateContextTimeOfDayTests: XCTestCase {
    func testDaytimeMoreThanTwoHoursBeforeSunset() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nextSetting = formatter.string(from: Date().addingTimeInterval(3 * 3600))
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "off"],
            "sun.sun": ["state": "above_horizon", "attributes": ["next_setting": nextSetting]]
        ])
        XCTAssertEqual(context.environment.timeOfDay, .daytime)
    }

    func testPreSunsetBetweenTwoAndOneHoursBeforeSunset() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nextSetting = formatter.string(from: Date().addingTimeInterval(90 * 60))
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "off"],
            "sun.sun": ["state": "above_horizon", "attributes": ["next_setting": nextSetting]]
        ])
        XCTAssertEqual(context.environment.timeOfDay, .preSunset)
    }

    func testSunsetWithinOneHourBeforeSunset() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nextSetting = formatter.string(from: Date().addingTimeInterval(30 * 60))
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "off"],
            "sun.sun": ["state": "above_horizon", "attributes": ["next_setting": nextSetting]]
        ])
        XCTAssertEqual(context.environment.timeOfDay, .sunset)
    }

    func testNighttimeWhenSunBelowHorizon() {
        let context = StateContext(states: [
            "input_select.living_scene": ["state": "off"],
            "sun.sun": ["state": "below_horizon", "attributes": ["next_setting": ""]]
        ])
        XCTAssertEqual(context.environment.timeOfDay, .nighttime)
    }
}
