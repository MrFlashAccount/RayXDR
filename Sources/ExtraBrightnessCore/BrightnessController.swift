import Foundation
import CoreGraphics
import Darwin

public enum BrightnessMode: String, Codable {
    case unsupported
    case direct
    case overlay
    case edrGammaOverlay
}

public struct BrightnessStatus: Codable {
    public var implementationMode: BrightnessMode
    public var enabled: Bool
    public var requestedLevel: Int?
    public var unsupportedReason: String?
    public var updatedAt: Date?
}

public enum BrightnessError: Error, CustomStringConvertible {
    case unsupported(String)
    case invalidLevel(String)

    public var description: String {
        switch self {
        case .unsupported(let reason):
            return "Unsupported: \(reason)"
        case .invalidLevel(let reason):
            return "Invalid level: \(reason)"
        }
    }
}

public protocol BrightnessControlling {
    func status() throws -> BrightnessStatus
    func set(levelOrPreset: String) throws -> String
    func toggle() throws -> String
    func reset() throws -> String
    func on(level: Int) throws -> String
    func off() throws -> String
    func probe(json: Bool) throws -> String
}

public struct ProcessBrightnessController: BrightnessControlling {
    private let store = StateStore()

    public init() {}

    public func status() throws -> BrightnessStatus {
        guard let state = try store.load(), let pid = state.helperPID, isProcessRunning(pid) else {
            return BrightnessStatus(
                implementationMode: .edrGammaOverlay,
                enabled: false,
                requestedLevel: nil,
                unsupportedReason: nil,
                updatedAt: nil
            )
        }

        return BrightnessStatus(
            implementationMode: state.implementationMode,
            enabled: true,
            requestedLevel: state.lastRequestedLevel,
            unsupportedReason: nil,
            updatedAt: state.updatedAt
        )
    }

    public func set(levelOrPreset: String) throws -> String {
        let level = try LevelParser.parse(levelOrPreset)
        if level <= 100 {
            return try off()
        }
        return try on(level: level)
    }

    public func toggle() throws -> String {
        let current = try status()
        if current.enabled {
            return try off()
        }
        return try on(level: 150)
    }

    public func reset() throws -> String {
        _ = try? off()
        killStaleHelpers()
        CGDisplayRestoreColorSyncSettings()
        try? store.remove()
        return "Normal brightness restored"
    }

    public func on(level: Int = 150) throws -> String {
        guard BuiltInDisplay.info() != nil else {
            throw BrightnessError.unsupported("built-in display not found")
        }

        if let state = try store.load(), let pid = state.helperPID, isProcessRunning(pid) {
            return "RayXDR already on: \(state.lastRequestedLevel)%"
        }

        try? store.remove()
        let helperURL = try helperExecutableURL()
        guard FileManager.default.isExecutableFile(atPath: helperURL.path) else {
            throw BrightnessError.unsupported("helper not built at \(helperURL.path)")
        }

        let process = Process()
        process.executableURL = helperURL
        process.arguments = ["\(level)"]
        process.standardOutput = FileHandle(forWritingAtPath: "/dev/null")
        process.standardError = FileHandle(forWritingAtPath: "/dev/null")
        try process.run()

        let pid = process.processIdentifier
        try store.save(ExtraBrightnessState(
            enabled: true,
            lastRequestedLevel: level,
            previousSystemBrightness: nil,
            implementationMode: .edrGammaOverlay,
            helperPID: pid,
            updatedAt: Date()
        ))

        return "RayXDR on: \(level)%"
    }

    public func off() throws -> String {
        if let state = try? store.load(), let pid = state.helperPID, isProcessRunning(pid) {
            Darwin.kill(pid, SIGTERM)
            waitUntilStopped(pid: pid, timeout: 1.5)
            if isProcessRunning(pid) {
                Darwin.kill(pid, SIGKILL)
            }
        }

        CGDisplayRestoreColorSyncSettings()
        try? store.remove()
        return "RayXDR off: normal mode restored"
    }

    public func probe(json: Bool) throws -> String {
        let report = Probe.collect()
        if json {
            let data = try JSONEncoder.extraBrightness.encode(report)
            return String(decoding: data, as: UTF8.self)
        }
        return Probe.plainText(report)
    }

    private func helperExecutableURL() throws -> URL {
        var size: UInt32 = 0
        _NSGetExecutablePath(nil, &size)
        var buffer = [CChar](repeating: 0, count: Int(size))
        guard _NSGetExecutablePath(&buffer, &size) == 0 else {
            throw BrightnessError.unsupported("could not locate current executable")
        }

        let executablePath = FileManager.default.string(
            withFileSystemRepresentation: buffer,
            length: Int(strlen(buffer))
        )
        return URL(fileURLWithPath: executablePath)
            .deletingLastPathComponent()
            .appendingPathComponent("rayxdr-helper")
    }

    private func isProcessRunning(_ pid: Int32) -> Bool {
        guard pid > 0 else {
            return false
        }
        return Darwin.kill(pid, 0) == 0
    }

    private func waitUntilStopped(pid: Int32, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !isProcessRunning(pid) {
                return
            }
            usleep(50_000)
        }
    }

    private func killStaleHelpers() {
        for processName in ["rayxdr-helper", "extra-brightness-helper"] {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            process.arguments = ["-TERM", "-x", processName]
            try? process.run()
            process.waitUntilExit()
        }
    }
}

public enum LevelParser {
    public static func parse(_ rawValue: String) throws -> Int {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let presets = [
            "low": 120,
            "medium": 140,
            "high": 160,
            "max": 160
        ]

        if let preset = presets[normalized] {
            return preset
        }

        guard let level = Int(normalized) else {
            throw BrightnessError.invalidLevel("use 100, 120, 140, 160, low, medium, high, or max")
        }

        guard (100...160).contains(level) else {
            throw BrightnessError.invalidLevel("expected 100...160")
        }

        return level
    }
}
