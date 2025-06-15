import XCTest
@testable import maestro

final class MaestroDynamicScenesTests: XCTestCase {
    final class DummyStateProvider: StateProvider {
        let states: HomeAssistantStateMap
        init(states: HomeAssistantStateMap) { self.states = states }
        func fetchAllStates() -> Result<HomeAssistantStateMap, Error> { .success(states) }
    }

    final class DummyLightController: LightController {
        var stopCount = 0
        var boolChanges: [(String, Bool)] = []
        func setLightState(state: LightState) {}
        func stopAllDynamicScenes() { stopCount += 1 }
        func setInputBoolean(entityId: String, to state: Bool) {
            boolChanges.append((entityId, state))
        }
    }

    final class StubProgram: LightProgram {
        let name = "stub"
        func compute(context: StateContext) -> ProgramOutput {
            var effects: [SideEffect] = []
            if context.environment.autoMode && context.scene != .preset {
                effects.append(.stopAllDynamicScenes)
            }
            if !context.environment.kitchenPresence {
                effects.append(.setInputBoolean(entityId: "input_boolean.kitchen_extra_brightness", state: false))
            }
            return ProgramOutput(changeset: LightStateChangeset(currentStates: context.states, desiredStates: []), sideEffects: effects)
        }
        // maintain old method for convenience
        func computeStateSet(context: StateContext) -> LightStateChangeset { .init(currentStates: context.states, desiredStates: []) }
    }

    func testStopsDynamicScenesWhenNotPreset() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "normal"],
            "input_boolean.living_scene_auto": ["state": "on"]
        ])
        let lights = DummyLightController()
        let maestro = Maestro(states: provider, lights: lights, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(lights.stopCount, 1)
    }

    func testDoesNotStopDynamicScenesForPreset() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "preset"],
            "input_boolean.living_scene_auto": ["state": "on"]
        ])
        let lights = DummyLightController()
        let maestro = Maestro(states: provider, lights: lights, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(lights.stopCount, 0)
    }

    func testTurnsOffKitchenExtraBrightnessWhenNoPresence() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "normal"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "on"]
        ])
        let lights = DummyLightController()
        let maestro = Maestro(states: provider, lights: lights, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(lights.boolChanges.first?.0, "input_boolean.kitchen_extra_brightness")
        XCTAssertEqual(lights.boolChanges.first?.1, false)
    }
}
