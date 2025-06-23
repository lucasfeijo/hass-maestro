import XCTest
@testable import maestro

final class StepOrderStorageTests: XCTestCase {
    func testResetRemovesFile() throws {
        let path = NSTemporaryDirectory() + "steps.json"
        setenv("STEP_ORDER_PATH", path, 1)
        StepOrderStorage.save(["foo"])
        XCTAssertNotNil(StepOrderStorage.load())
        StepOrderStorage.reset()
        XCTAssertNil(StepOrderStorage.load())
        unsetenv("STEP_ORDER_PATH")
    }

    func testInitializeWritesFileIfMissing() throws {
        let path = NSTemporaryDirectory() + "steps.json"
        setenv("STEP_ORDER_PATH", path, 1)
        StepOrderStorage.reset()
        StepOrderStorage.initialize(with: ["a"])
        XCTAssertEqual(StepOrderStorage.load(), ["a"])
        StepOrderStorage.reset()
        unsetenv("STEP_ORDER_PATH")
    }

    func testInitializeDoesNotOverrideExistingFile() throws {
        let path = NSTemporaryDirectory() + "steps.json"
        setenv("STEP_ORDER_PATH", path, 1)
        StepOrderStorage.save(["b"])
        StepOrderStorage.initialize(with: ["a"])
        XCTAssertEqual(StepOrderStorage.load(), ["b"])
        StepOrderStorage.reset()
        unsetenv("STEP_ORDER_PATH")
    }
}
