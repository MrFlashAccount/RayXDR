import AppKit
import CoreGraphics

extension NSScreen {
    public var extraBrightnessDisplayID: CGDirectDisplayID? {
        deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

public struct BuiltInDisplayInfo: Codable {
    public var displayID: UInt32
    public var localizedName: String
    public var frame: String
    public var isMain: Bool
    public var isBuiltIn: Bool
    public var maximumEDR: Double
}

public enum BuiltInDisplay {
    public static func screen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let displayID = screen.extraBrightnessDisplayID else {
                return false
            }
            return CGDisplayIsBuiltin(displayID) != 0
        }
    }

    public static func info() -> BuiltInDisplayInfo? {
        guard let screen = screen(), let displayID = screen.extraBrightnessDisplayID else {
            return nil
        }

        return BuiltInDisplayInfo(
            displayID: displayID,
            localizedName: screen.localizedName,
            frame: "\(Int(screen.frame.origin.x)),\(Int(screen.frame.origin.y)) \(Int(screen.frame.width))x\(Int(screen.frame.height))",
            isMain: CGDisplayIsMain(displayID) != 0,
            isBuiltIn: CGDisplayIsBuiltin(displayID) != 0,
            maximumEDR: screen.maximumExtendedDynamicRangeColorComponentValue
        )
    }
}
