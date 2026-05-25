import AppKit
import ExtraBrightnessCore
import Foundation

@MainActor
final class ExtraBrightnessHelper {
    private let targetLevel: Int
    private var overlayController: EDROverlayWindowController?
    private var gammaController: GammaController?
    private var pollTimer: Timer?
    private var applied = false

    init(targetLevel: Int) {
        self.targetLevel = targetLevel
    }

    func start() {
        guard let screen = BuiltInDisplay.screen(),
              let displayID = screen.extraBrightnessDisplayID else {
            fputs("Unsupported: built-in display not found\n", stderr)
            Foundation.exit(2)
        }

        guard CGDisplayIsBuiltin(displayID) != 0 else {
            fputs("Unsupported: selected display is not built-in\n", stderr)
            Foundation.exit(2)
        }

        let gamma = GammaController(displayID: displayID)
        guard gamma.capture() else {
            fputs("Unsupported: could not capture gamma table\n", stderr)
            Foundation.exit(2)
        }

        gammaController = gamma
        overlayController = EDROverlayWindowController(screen: screen)
        overlayController?.show()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        print("RayXDR helper running: \(targetLevel)%")
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        gammaController?.restore()
        gammaController = nil
        overlayController?.close()
        overlayController = nil
        NSApp.terminate(nil)
    }

    private func tick() {
        guard let screen = BuiltInDisplay.screen() else {
            stop()
            return
        }

        overlayController?.reposition()

        let maxEDR = screen.maximumExtendedDynamicRangeColorComponentValue
        guard maxEDR > 1.05 else {
            return
        }

        let requested = Float(targetLevel) / 100.0
        let factor = min(max(requested, 1.0), Float(maxEDR))
        gammaController?.apply(factor: factor)
        applied = true
    }
}

let targetLevel = CommandLine.arguments.dropFirst().first.flatMap(Int.init) ?? 150

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let helper = ExtraBrightnessHelper(targetLevel: targetLevel)

func installSignalHandler(_ signalNumber: Int32) {
    signal(signalNumber, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
    source.setEventHandler {
        Task { @MainActor in
            helper.stop()
        }
    }
    source.resume()
}

installSignalHandler(SIGTERM)
installSignalHandler(SIGINT)

Task { @MainActor in
    helper.start()
}

app.run()
