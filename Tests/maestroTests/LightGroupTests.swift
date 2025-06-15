import XCTest
@testable import maestro

final class LightGroupTests: XCTestCase {
    func testFlattenedReturnsAllLeafStates() {
        let group = LightGroup.group([
            "light.a": .light(LightState(entityId: "light.a", on: true)),
            "grp": .group([
                "light.b": .light(LightState(entityId: "light.b", on: false)),
                "light.c": .light(LightState(entityId: "light.c", on: true))
            ])
        ])
        let ids = Set(group.flattened().map { $0.entityId })
        XCTAssertEqual(ids, ["light.a", "light.b", "light.c"])
    }

    func testUpdateLeafEntity() {
        var group = LightGroup.group([
            "light.a": .light(LightState(entityId: "light.a", on: false))
        ])
        group.update(entityId: "light.a", with: LightState(entityId: "light.a", on: true))
        let state = group.flattened().first { $0.entityId == "light.a" }
        XCTAssertEqual(state?.on, true)
    }

    func testUpdateGroupUpdatesAllChildren() {
        var group = LightGroup.group([
            "parent": .group([
                "child1": .light(LightState(entityId: "child1", on: false)),
                "child2": .light(LightState(entityId: "child2", on: false))
            ])
        ])
        let newState = LightState(entityId: "child1", on: true, brightness: 10)
        group.update(entityId: "parent", with: newState)
        let states = group.flattened()
        for st in states {
            XCTAssertEqual(st.on, true)
            XCTAssertEqual(st.brightness, 10)
        }
    }
}
