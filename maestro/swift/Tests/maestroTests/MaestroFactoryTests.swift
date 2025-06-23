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
}
