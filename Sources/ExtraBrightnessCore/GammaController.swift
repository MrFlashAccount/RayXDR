import CoreGraphics
import Foundation

public final class GammaController {
    private let tableSize: UInt32 = 256
    private let displayID: CGDirectDisplayID
    private var redTable: [CGGammaValue]
    private var greenTable: [CGGammaValue]
    private var blueTable: [CGGammaValue]
    private var captured = false

    public init(displayID: CGDirectDisplayID) {
        self.displayID = displayID
        redTable = [CGGammaValue](repeating: 0, count: Int(tableSize))
        greenTable = [CGGammaValue](repeating: 0, count: Int(tableSize))
        blueTable = [CGGammaValue](repeating: 0, count: Int(tableSize))
    }

    public func capture() -> Bool {
        var sampleCount: UInt32 = 0
        let result = CGGetDisplayTransferByTable(
            displayID,
            tableSize,
            &redTable,
            &greenTable,
            &blueTable,
            &sampleCount
        )
        captured = result == .success
        return captured
    }

    public func apply(factor: Float) {
        guard captured else {
            return
        }

        var red = redTable
        var green = greenTable
        var blue = blueTable

        for index in red.indices {
            red[index] = min(red[index] * factor, 1.0)
            green[index] = min(green[index] * factor, 1.0)
            blue[index] = min(blue[index] * factor, 1.0)
        }

        CGSetDisplayTransferByTable(displayID, tableSize, &red, &green, &blue)
    }

    public func restore() {
        if captured {
            var red = redTable
            var green = greenTable
            var blue = blueTable
            CGSetDisplayTransferByTable(displayID, tableSize, &red, &green, &blue)
        }
        CGDisplayRestoreColorSyncSettings()
    }
}
