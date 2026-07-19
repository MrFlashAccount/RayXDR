import AppKit
import ExtraBrightnessCore
import Foundation

@MainActor
final class ExtraBrightnessHelper {
    private let targetLevel: Int
    private var overlayController: EDROverlayWindowController?
    private var gammaController: GammaController?
    private var pollTimer: Timer?
    private var lastAppliedFactor: Float?
    private var notificationObservers: [NSObjectProtocol] = []

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
        installNotificationObservers()

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(force: false)
            }
        }
        pollTimer?.tolerance = 0.2

        tick(force: true)

        print("RayXDR helper running: \(targetLevel)%")
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        removeNotificationObservers()
        gammaController?.restore()
        gammaController = nil
        overlayController?.close()
        overlayController = nil
        NSApp.terminate(nil)
    }

    private func tick(force: Bool) {
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
        if !force,
           let lastAppliedFactor,
           abs(lastAppliedFactor - factor) <= 0.001 {
            return
        }

        gammaController?.apply(factor: factor)
        lastAppliedFactor = factor
    }

    private func installNotificationObservers() {
        let screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick(force: true)
                self?.overlayController?.window?.contentView?.needsDisplay = true
            }
        }

        let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.tick(force: true)
                self?.overlayController?.window?.contentView?.needsDisplay = true
            }
        }

        notificationObservers = [screenObserver, wakeObserver]
    }

    private func removeNotificationObservers() {
        guard notificationObservers.count == 2 else {
            return
        }

        NotificationCenter.default.removeObserver(notificationObservers[0])
        NSWorkspace.shared.notificationCenter.removeObserver(notificationObservers[1])
        notificationObservers.removeAll()
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
