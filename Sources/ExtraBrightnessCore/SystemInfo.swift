import Foundation
import IOKit

public enum SystemInfo {
    public static func modelIdentifier() -> String? {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard service != 0 else {
            return nil
        }
        defer { IOObjectRelease(service) }

        guard let modelData = IORegistryEntryCreateCFProperty(
            service,
            "model" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Data else {
            return nil
        }

        return String(data: modelData, encoding: .utf8)?
            .trimmingCharacters(in: .controlCharacters)
    }
}
