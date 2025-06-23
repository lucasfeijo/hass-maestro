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

    let savedNames = StepOrderStorage.load()
    let stepStrings: [String]
    if let savedNames, !savedNames.isEmpty {
        stepStrings = savedNames
    } else if let program = options.programName {
        stepStrings = program
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    } else {
        stepStrings = []
    }
    let factories = stepStrings.compactMap(LightProgramDefault.step(named:))
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
