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
        guard let steps = programMirror.children.first(where: { $0.label == "steps" })?.value as? [any ProgramStep] else {
            XCTFail("Could not access steps")
            return
        }
        let stepNames = steps.map { type(of: $0).self }
        let defaultNames = LightProgramDefault.defaultSteps.map { type(of: $0).self }
        XCTAssertEqual(stepNames.count, defaultNames.count)
        for (idx, type) in defaultNames.enumerated() {
            XCTAssertTrue(stepNames[idx] == type, "Step \(idx) should be \(type)")
        }
    }
}
