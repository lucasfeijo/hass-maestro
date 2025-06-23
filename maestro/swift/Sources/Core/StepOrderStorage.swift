import Foundation

enum StepOrderStorage {
    private static var fileURL: URL {
        if let env = ProcessInfo.processInfo.environment["STEP_ORDER_PATH"], !env.isEmpty {
            return URL(fileURLWithPath: env)
        }
        return URL(fileURLWithPath: "/data/step_order.json")
    }

    static func load() -> [String]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    static func save(_ steps: [String]) {
        let url = fileURL
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir,
                                                withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(steps) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    /// Saves `steps` only if no file already exists.
    static func initialize(with steps: [String]) {
        guard load() == nil else { return }
        save(steps)
    }

    static func reset() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
