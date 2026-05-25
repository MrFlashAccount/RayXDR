import CoreGraphics
import Darwin
import Foundation

public struct DisplayServicesSnapshot: Codable {
    public var canChangeBrightness: Bool?
    public var brightness: Float?
    public var linearBrightness: Float?
    public var coreDisplayUserBrightness: Double?
    public var coreDisplayLinearBrightness: Double?
    public var errors: [String]
}

public final class PrivateDisplayServices: @unchecked Sendable {
    public static let shared = PrivateDisplayServices()

    private typealias DSCanChangeBrightness = @convention(c) (CGDirectDisplayID) -> Bool
    private typealias DSGetBrightness = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias CoreDisplayGetBrightness = @convention(c) (CGDirectDisplayID) -> Double

    private let displayServicesHandle: UnsafeMutableRawPointer?
    private let coreDisplayHandle: UnsafeMutableRawPointer?

    private let canChangeBrightnessFn: DSCanChangeBrightness?
    private let getBrightnessFn: DSGetBrightness?
    private let getLinearBrightnessFn: DSGetBrightness?
    private let coreDisplayGetUserBrightnessFn: CoreDisplayGetBrightness?
    private let coreDisplayGetLinearBrightnessFn: CoreDisplayGetBrightness?

    private init() {
        displayServicesHandle = dlopen(
            "/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices",
            RTLD_LAZY
        )
        coreDisplayHandle = dlopen(
            "/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay",
            RTLD_LAZY
        )

        canChangeBrightnessFn = Self.load(
            handle: displayServicesHandle,
            symbol: "DisplayServicesCanChangeBrightness",
            as: DSCanChangeBrightness.self
        )
        getBrightnessFn = Self.load(
            handle: displayServicesHandle,
            symbol: "DisplayServicesGetBrightness",
            as: DSGetBrightness.self
        )
        getLinearBrightnessFn = Self.load(
            handle: displayServicesHandle,
            symbol: "DisplayServicesGetLinearBrightness",
            as: DSGetBrightness.self
        )
        coreDisplayGetUserBrightnessFn = Self.load(
            handle: coreDisplayHandle,
            symbol: "CoreDisplay_Display_GetUserBrightness",
            as: CoreDisplayGetBrightness.self
        )
        coreDisplayGetLinearBrightnessFn = Self.load(
            handle: coreDisplayHandle,
            symbol: "CoreDisplay_Display_GetLinearBrightness",
            as: CoreDisplayGetBrightness.self
        )
    }

    deinit {
        if let displayServicesHandle {
            dlclose(displayServicesHandle)
        }
        if let coreDisplayHandle {
            dlclose(coreDisplayHandle)
        }
    }

    public func snapshot(displayID: CGDirectDisplayID) -> DisplayServicesSnapshot {
        var errors: [String] = []
        var canChange: Bool?
        var brightness: Float?
        var linearBrightness: Float?
        var coreUser: Double?
        var coreLinear: Double?

        if let canChangeBrightnessFn {
            canChange = canChangeBrightnessFn(displayID)
        } else {
            errors.append("DisplayServicesCanChangeBrightness unavailable")
        }

        if let getBrightnessFn {
            var value: Float = 0
            let result = getBrightnessFn(displayID, &value)
            if result == KERN_SUCCESS {
                brightness = value
            } else {
                errors.append("DisplayServicesGetBrightness failed: \(result)")
            }
        } else {
            errors.append("DisplayServicesGetBrightness unavailable")
        }

        if let getLinearBrightnessFn {
            var value: Float = 0
            let result = getLinearBrightnessFn(displayID, &value)
            if result == KERN_SUCCESS {
                linearBrightness = value
            } else {
                errors.append("DisplayServicesGetLinearBrightness failed: \(result)")
            }
        } else {
            errors.append("DisplayServicesGetLinearBrightness unavailable")
        }

        if let coreDisplayGetUserBrightnessFn {
            coreUser = coreDisplayGetUserBrightnessFn(displayID)
        } else {
            errors.append("CoreDisplay_Display_GetUserBrightness unavailable")
        }

        if let coreDisplayGetLinearBrightnessFn {
            coreLinear = coreDisplayGetLinearBrightnessFn(displayID)
        } else {
            errors.append("CoreDisplay_Display_GetLinearBrightness unavailable")
        }

        return DisplayServicesSnapshot(
            canChangeBrightness: canChange,
            brightness: brightness,
            linearBrightness: linearBrightness,
            coreDisplayUserBrightness: coreUser,
            coreDisplayLinearBrightness: coreLinear,
            errors: errors
        )
    }

    private static func load<T>(
        handle: UnsafeMutableRawPointer?,
        symbol: String,
        as type: T.Type
    ) -> T? {
        guard let handle, let rawSymbol = dlsym(handle, symbol) else {
            return nil
        }
        return unsafeBitCast(rawSymbol, to: T.self)
    }
}
