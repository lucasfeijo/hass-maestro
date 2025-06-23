import XCTest
@testable import maestro

final class MaestroFactoryTests: XCTestCase {
    func testEmptyProgramNameUsesDefaultSteps() {
        let options = parseArguments(["maestro"])
        let maestroInstance = makeMaestro(from: options)
        let maestroMirror = Mirror(reflecting: maestroInstance)
        guard let program = maestroMirror.children.first(where: { $0.label == "program" })?.value as? LightProgramDefault else {
            XCTFail("Expected LightProgramDefault program")
            return
        }
        let programMirror = Mirror(reflecting: program)
        guard let factories = programMirror.children.first(where: { $0.label == "steps" })?.value as? [LightProgramDefault.StepFactory] else {
            XCTFail("Could not access steps")
            return
        }
        let dummy = StateContext(states: [:])
        let names = factories.map { $0(dummy).name }
        let defaultNames = LightProgramDefault.defaultSteps.map { $0(dummy).name }
        XCTAssertEqual(names, defaultNames)
    }

    func testSavedStepOrderOverridesProgram() {
        let path = NSTemporaryDirectory() + "steps.json"
        setenv("STEP_ORDER_PATH", path, 1)
        StepOrderStorage.save(["globalbrightness"])
        defer { unlink(path) }

        let options = parseArguments(["maestro", "--program", "basescene"])
        let maestroInstance = makeMaestro(from: options)
        let mirror = Mirror(reflecting: maestroInstance)
        let program = mirror.children.first { $0.label == "program" }!.value as! LightProgramDefault
        let programMirror = Mirror(reflecting: program)
        let factories = programMirror.children.first { $0.label == "steps" }!.value as! [LightProgramDefault.StepFactory]
        let dummy = StateContext(states: [:])
        let names = factories.map { $0(dummy).name }
        XCTAssertEqual(names.first, "globalBrightness")
    }

    func testFactoryInitializesStepOrderFile() {
        let path = NSTemporaryDirectory() + "steps.json"
        setenv("STEP_ORDER_PATH", path, 1)
        unlink(path)
        let options = parseArguments(["maestro", "--program", "globalbrightness"])
        _ = makeMaestro(from: options)
        let stored = StepOrderStorage.load()
        XCTAssertEqual(stored, ["globalbrightness"])
        StepOrderStorage.reset()
        unsetenv("STEP_ORDER_PATH")
    }
}
