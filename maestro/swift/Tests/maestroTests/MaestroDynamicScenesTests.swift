import XCTest
@testable import maestro

final class MaestroDynamicScenesTests: XCTestCase {
    final class DummyStateProvider: StateProvider {
        let states: HomeAssistantStateMap
        init(states: HomeAssistantStateMap) { self.states = states }
        func fetchAllStates() -> Result<HomeAssistantStateMap, Error> { .success(states) }
    }

    final class DummyEffectController: EffectController {
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
            return ProgramOutput(changeset: LightStateChangeset(currentStates: context.states, effects: effects))
        }
    }

    func testStopsDynamicScenesWhenNotPreset() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "normal"],
            "input_boolean.living_scene_auto": ["state": "on"]
        ])
        let effects = DummyEffectController()
        let maestro = Maestro(states: provider, effects: effects, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(effects.stopCount, 1)
    }

    func testDoesNotStopDynamicScenesForPreset() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "preset"],
            "input_boolean.living_scene_auto": ["state": "on"]
        ])
        let effects = DummyEffectController()
        let maestro = Maestro(states: provider, effects: effects, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(effects.stopCount, 0)
    }

    func testTurnsOffKitchenExtraBrightnessWhenNoPresence() {
        let provider = DummyStateProvider(states: [
            "input_select.living_scene": ["state": "normal"],
            "binary_sensor.kitchen_espresence": ["state": "off"],
            "input_boolean.kitchen_extra_brightness": ["state": "on"]
        ])
        let effects = DummyEffectController()
        let maestro = Maestro(states: provider, effects: effects, program: StubProgram(), logger: Logger(pusher: nil))
        maestro.run()
        XCTAssertEqual(effects.boolChanges.first?.0, "input_boolean.kitchen_extra_brightness")
        XCTAssertEqual(effects.boolChanges.first?.1, false)
    }
}
