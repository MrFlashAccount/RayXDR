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
    private let legacyFileURL: URL

    init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.fileURL = homeDirectory
            .appendingPathComponent("Library/Application Support/RayXDR", isDirectory: true)
            .appendingPathComponent("state.json")
        self.legacyFileURL = homeDirectory
            .appendingPathComponent("Library/Application Support/ExtraBrightness", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    func load() throws -> ExtraBrightnessState? {
        for url in [fileURL, legacyFileURL] {
            guard FileManager.default.fileExists(atPath: url.path) else {
                continue
            }

            let data = try Data(contentsOf: url)
            return try JSONDecoder.extraBrightness.decode(ExtraBrightnessState.self, from: data)
        }

        return nil
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
        for url in [fileURL, legacyFileURL] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
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
