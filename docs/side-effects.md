# Collecting Side Effects

Maestro separates decision making from performing actions. During the PROGRAM step each `ProgramStep` may append side effects that should happen later. A side effect is anything other than returning the final light state (for example updating helper booleans or stopping dynamic scenes).

`ProgramStep.apply` returns `(changes: [LightState], effects: [SideEffect])`. The pipeline passes the current lists to each step so it can append new effects without modifying earlier ones. After every step has run, `LightProgram.compute` executes the gathered effects followed by the light updates. All side effect HTTP requests are dispatched concurrently so that network latency does not slow down the loop.
