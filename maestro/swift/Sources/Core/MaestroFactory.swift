import Foundation

/// Builds a fully configured ``Maestro`` instance from command line options.
func makeMaestro(from options: MaestroOptions) -> Maestro {
    let notificationPusher: NotificationPusher? = options.notificationsEnabled ?
        HomeAssistantNotificationPusher(baseURL: options.baseURL, token: options.token) : nil
    let logger = Logger(pusher: notificationPusher)

    let states = HomeAssistantStateProvider(baseURL: options.baseURL, token: options.token)

    let lights: LightController
    if options.simulate {
        lights = LoggingLightController(logger: logger)
    } else {
        let haLights = HomeAssistantLightController(baseURL: options.baseURL,
                                                   token: options.token,
                                                   logger: logger)
        lights = options.verbose ?
            MultiLightController([haLights, LoggingLightController(logger: logger)]) :
            haLights
    }

    let stepStrings = options.programName
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
    let steps = stepStrings.compactMap(LightProgramDefault.step(named:))
    let program = LightProgramDefault(steps: steps.isEmpty ? LightProgramDefault.defaultSteps : steps)

    return Maestro(states: states,
                   lights: lights,
                   program: program,
                   logger: logger,
                   verbose: options.verbose)
}
