import Foundation

struct ExtraBrightnessState: Codable {
    var enabled: Bool
    var lastRequestedLevel: Int
    var previousSystemBrightness: Double?
    var implementationMode: BrightnessMode
    var helperPID: Int32?
    var updatedAt: Date
}

struct StateStore {
    private let fileURL: URL

    init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.fileURL = homeDirectory
            .appendingPathComponent("Library/Application Support/ExtraBrightness", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    func load() throws -> ExtraBrightnessState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder.extraBrightness.decode(ExtraBrightnessState.self, from: data)
    }

    func save(_ state: ExtraBrightnessState) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try JSONEncoder.extraBrightness.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }

    func remove() throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}

extension JSONEncoder {
    static var extraBrightness: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var extraBrightness: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
