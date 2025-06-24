import Foundation

/// Builds a fully configured ``Maestro`` instance from command line options.
func makeMaestro(from options: MaestroOptions) -> Maestro {
    let notificationPusher: NotificationPusher? = options.notificationsEnabled ?
        HomeAssistantNotificationPusher(baseURL: options.baseURL, token: options.token) : nil
    let logger = Logger(pusher: notificationPusher)

    let states = HomeAssistantStateProvider(baseURL: options.baseURL, token: options.token)

    let effects: EffectController
    if options.simulate {
        effects = LoggingEffectController(logger: logger)
    } else {
        let haEffects = HomeAssistantEffectController(baseURL: options.baseURL,
                                                     token: options.token,
                                                     logger: logger)
        effects = options.verbose ?
            MultiEffectController([haEffects, LoggingEffectController(logger: logger)]) :
            haEffects
    }

    let stepStrings = options.programName?
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) } ?? []

    let factories: [LightProgramDefault.StepFactory] = stepStrings.compactMap { str in
        let skip = str.hasPrefix("!")
        let name = skip ? String(str.dropFirst()).lowercased() : str.lowercased()
        guard let base = LightProgramDefault.step(named: name) else { return nil }
        return { context in
            var step = base(context)
            step.skipped = skip
            return step
        }
    }

    let program = LightProgramDefault(
        steps: factories.isEmpty ? LightProgramDefault.defaultSteps : factories,
        logger: options.verbose ? logger : nil
    )

    return Maestro(states: states,
                   effects: effects,
                   program: program,
                   logger: logger,
                   verbose: options.verbose)
}
