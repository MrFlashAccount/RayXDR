import Foundation

public struct ProbeReport: Codable {
    public var modelIdentifier: String?
    public var builtInDisplay: BuiltInDisplayInfo?
    public var displayServices: DisplayServicesSnapshot?
}

public enum Probe {
    public static func collect() -> ProbeReport {
        let display = BuiltInDisplay.info()
        let displayServices = display.map {
            PrivateDisplayServices.shared.snapshot(displayID: $0.displayID)
        }

        return ProbeReport(
            modelIdentifier: SystemInfo.modelIdentifier(),
            builtInDisplay: display,
            displayServices: displayServices
        )
    }

    public static func plainText(_ report: ProbeReport) -> String {
        var lines: [String] = []
        lines.append("Model: \(report.modelIdentifier ?? "unknown")")

        if let display = report.builtInDisplay {
            lines.append("Built-in display: \(display.localizedName) id=\(display.displayID)")
            lines.append("Frame: \(display.frame), main=\(display.isMain), maxEDR=\(String(format: "%.3f", display.maximumEDR))")
        } else {
            lines.append("Built-in display: not found")
        }

        if let snapshot = report.displayServices {
            if let value = snapshot.canChangeBrightness {
                lines.append("DisplayServices canChangeBrightness: \(value)")
            }
            if let value = snapshot.brightness {
                lines.append("DisplayServices brightness: \(String(format: "%.4f", value))")
            }
            if let value = snapshot.linearBrightness {
                lines.append("DisplayServices linearBrightness: \(String(format: "%.4f", value))")
            }
            if let value = snapshot.coreDisplayUserBrightness {
                lines.append("CoreDisplay userBrightness: \(String(format: "%.4f", value))")
            }
            if let value = snapshot.coreDisplayLinearBrightness {
                lines.append("CoreDisplay linearBrightness: \(String(format: "%.4f", value))")
            }
            if !snapshot.errors.isEmpty {
                lines.append("Probe notes: \(snapshot.errors.joined(separator: "; "))")
            }
        }

        return lines.joined(separator: "\n")
    }
}
