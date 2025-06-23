# Collecting Side Effects

Maestro separates decision making from performing actions. During the PROGRAM step each `ProgramStep` may append side effects that should happen later. A side effect is anything other than returning the final light state (for example updating helper booleans or stopping dynamic scenes).

`ProgramStep` instances are created with a `StateContext` and expose a `process` method that takes and returns a single `[SideEffect]` array. Each step appends new effects, including `.setLight` actions for desired light states. After all steps have run, `LightProgram.compute` builds a `LightStateChangeset` from that array which automatically splits light updates from other side effects. The simplified light updates are then executed after any other side effects. All HTTP requests are dispatched concurrently so that network latency does not slow down the loop.
