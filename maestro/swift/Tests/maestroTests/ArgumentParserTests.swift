import XCTest
@testable import maestro

final class ArgumentParserTests: XCTestCase {
    func testNoNotifyFlagDisablesNotifications() {
        let opts = parseArguments(["maestro", "--no-notify"]) 
        XCTAssertFalse(opts.notificationsEnabled)
    }

    func testNotificationsEnabledByDefault() {
        let opts = parseArguments(["maestro"])
        XCTAssertTrue(opts.notificationsEnabled)
        XCTAssertEqual(opts.port, 8080)
    }

    func testPortFlagWithEquals() {
        let opts = parseArguments(["maestro", "--port=9000"])
        XCTAssertEqual(opts.port, 9000)
    }

    func testPortFlagWithSpace() {
        let opts = parseArguments(["maestro", "--port", "1234"])
        XCTAssertEqual(opts.port, 1234)
    }

    func testVerboseFlagEnablesLogging() {
        let opts = parseArguments(["maestro", "--verbose"])
        XCTAssertTrue(opts.verbose)
    }

    func testVerboseDisabledByDefault() {
        let opts = parseArguments(["maestro"])
        XCTAssertFalse(opts.verbose)
    }
}
