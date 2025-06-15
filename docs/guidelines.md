# Contribution Guidelines

This document collects the core ideals of the project. Following these
principles keeps the code base approachable and predictable.

## Separation of Concerns

- Each module should focus on a single area of responsibility.
  - `State` handles communication with Home Assistant and fetching raw states.
  - `Context` interprets raw states into a structured `StateContext`.
  - `Programs` decide the desired light states from the context.
  - `Lights` applies the final states to Home Assistant.
- Avoid mixing responsibilities across modules. Keeping the pipeline
  boundaries clear makes changes safer and debugging simpler.

## Pipeline Structure

The `Maestro` class runs a five step pipeline whenever the `/run` endpoint
is called:

1. **STATE** – Fetch all Home Assistant states.
2. **CONTEXT** – Build a `StateContext` from those states.
3. **PROGRAM** – Compute the desired light states.
4. **CHANGESET** – Simplify the changes to avoid unnecessary updates.
5. **LIGHTS** – Apply the new states to Home Assistant.

All new features should fit into this flow. When adding functionality,
consider which step it belongs to and keep the transitions explicit.

## Unit Tests

Comprehensive tests are used to document behaviour and guard against
regressions. Each feature should include unit tests under
`Tests/maestroTests`.

- Prefer testing small pieces of logic in isolation.
- Use descriptive test names that clarify the behaviour being verified.
- Run `swift test` before submitting changes and ensure all tests pass.

## General Practices

- Document new commands or behaviours in the README or under `docs/`.
- Keep commits focused; smaller changes are easier to review.
- Maintain consistency with the existing Swift style and naming
  conventions found in the code base.

Adhering to these guidelines will help keep the project maintainable and
approachable as it grows.
