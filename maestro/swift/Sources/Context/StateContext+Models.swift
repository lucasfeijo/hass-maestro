extension StateContext {
    public enum Scene {
        case off, calmNight, normal, bright, brightest, preset
    }

    public enum TimeOfDay {
        case daytime, preSunset, sunset, nighttime
    }

    public struct Environment {
        public var timeOfDay: TimeOfDay
        /// Progress of the sunset transition, between 0 and 1 when `timeOfDay`
        /// is `.sunset`. Zero represents the start of the fade and one means
        /// sunset has been reached.
        public var sunsetProgress: Double
        public var hyperionRunning: Bool
        public var diningPresence: Bool
        public var kitchenPresence: Bool
        public var kitchenExtraBrightness: Bool
        public var autoMode: Bool
        /// Individual shelf enable switches. Index 0 corresponds to shelf 1.
        public var tvShelvesEnabled: [Bool]

        public init(timeOfDay: TimeOfDay,
                    sunsetProgress: Double = 0,
                    hyperionRunning: Bool,
                    diningPresence: Bool,
                    kitchenPresence: Bool,
                    kitchenExtraBrightness: Bool,
                    autoMode: Bool,
                    tvShelvesEnabled: [Bool]) {
            self.timeOfDay = timeOfDay
            self.sunsetProgress = sunsetProgress
            self.hyperionRunning = hyperionRunning
            self.diningPresence = diningPresence
            self.kitchenPresence = kitchenPresence
            self.kitchenExtraBrightness = kitchenExtraBrightness
            self.autoMode = autoMode
            self.tvShelvesEnabled = tvShelvesEnabled
        }
    }
}