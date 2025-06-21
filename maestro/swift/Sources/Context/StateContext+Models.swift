extension StateContext {
    public enum Scene {
        case off, calmNight, normal, bright, brightest, preset
    }

    public enum TimeOfDay {
        case daytime, preSunset, sunset, nighttime
    }

    public struct Environment {
        public var timeOfDay: TimeOfDay
        public var hyperionRunning: Bool
        public var diningPresence: Bool
        public var kitchenPresence: Bool
        public var kitchenExtraBrightness: Bool
        public var autoMode: Bool
        /// Transition duration in seconds for light changes
        public var lightTransition: Double
        /// Individual shelf enable switches. Index 0 corresponds to shelf 1.
        public var tvShelvesEnabled: [Bool]

        public init(timeOfDay: TimeOfDay,
                    hyperionRunning: Bool,
                    diningPresence: Bool,
                    kitchenPresence: Bool,
                    kitchenExtraBrightness: Bool,
                    autoMode: Bool,
                    tvShelvesEnabled: [Bool],
                    lightTransition: Double) {
            self.timeOfDay = timeOfDay
            self.hyperionRunning = hyperionRunning
            self.diningPresence = diningPresence
            self.kitchenPresence = kitchenPresence
            self.kitchenExtraBrightness = kitchenExtraBrightness
            self.autoMode = autoMode
            self.tvShelvesEnabled = tvShelvesEnabled
            self.lightTransition = lightTransition
        }
    }
}