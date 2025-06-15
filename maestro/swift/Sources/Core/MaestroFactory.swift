import Foundation

/// Builds a fully configured ``Maestro`` instance from command line options.
func makeMaestro(from options: MaestroOptions) -> Maestro {
    let notificationPusher: NotificationPusher? = options.notificationsEnabled ?
        HomeAssistantNotificationPusher(baseURL: options.baseURL, token: options.token) : nil
    let logger = Logger(pusher: notificationPusher)

    let states = HomeAssistantStateProvider(baseURL: options.baseURL, token: options.token)

    let lights: LightController
    if options.simulate {
        lights = LoggingLightController()
    } else {
        let haLights = HomeAssistantLightController(baseURL: options.baseURL,
                                                   token: options.token,
                                                   logger: logger)
        lights = options.verbose ?
            MultiLightController([haLights, LoggingLightController()]) :
            haLights
    }

    let program: LightProgram
    switch options.programName.lowercased() {
    case LightProgramSecondary().name:
        program = LightProgramSecondary()
    default:
        program = LightProgramDefault()
    }

    return Maestro(states: states,
                   lights: lights,
                   program: program,
                   logger: logger,
                   verbose: options.verbose)
}
