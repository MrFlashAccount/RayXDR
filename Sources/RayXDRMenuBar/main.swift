import AppKit
import ExtraBrightnessCore
import ServiceManagement
import Sparkle

private enum PreferredBrightnessMode: String {
    case standard
    case rayxdr150
}

private final class AppPreferences {
    private static let preferredBrightnessModeKey = "preferredBrightnessMode"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var preferredBrightnessMode: PreferredBrightnessMode {
        get {
            guard let rawValue = defaults.string(forKey: Self.preferredBrightnessModeKey),
                  let mode = PreferredBrightnessMode(rawValue: rawValue) else {
                return .standard
            }

            return mode
        }
        set {
            defaults.set(newValue.rawValue, forKey: Self.preferredBrightnessModeKey)
        }
    }
}

@MainActor final class StatusMenuView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let modeLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(status: BrightnessStatus) {
        if status.enabled {
            titleLabel.stringValue = "RayXDR running"
            detailLabel.stringValue = "Target: \(status.requestedLevel ?? 150)%"
        } else {
            titleLabel.stringValue = "Standard brightness"
            detailLabel.stringValue = "Target: normal"
        }

        modeLabel.stringValue = "Mode: \(status.implementationMode.rawValue)"
    }

    func update(error: Error) {
        titleLabel.stringValue = "RayXDR error"
        detailLabel.stringValue = String(describing: error)
        modeLabel.stringValue = "Mode: unavailable"
    }

    private func setup() {
        frame = NSRect(x: 0, y: 0, width: 240, height: 72)

        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        detailLabel.font = .systemFont(ofSize: 12)
        modeLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        modeLabel.textColor = .tertiaryLabelColor

        let stack = NSStackView(views: [titleLabel, detailLabel, modeLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}

@MainActor final class RayXDRMenuBarApp: NSObject, NSApplicationDelegate, NSMenuDelegate, SPUUpdaterDelegate {
    private let controller = ProcessBrightnessController()
    private let preferences = AppPreferences()
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: nil
    )
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusView = StatusMenuView(frame: NSRect(x: 0, y: 0, width: 240, height: 72))
    private let standardItem = NSMenuItem(title: "Standard", action: #selector(selectStandard), keyEquivalent: "")
    private let rayxdrItem = NSMenuItem(title: "RayXDR 150%", action: #selector(selectRayXDR), keyEquivalent: "")
    private let resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
    private let checkUpdatesItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var baseStatusTitle = "XDR"
    private var availableUpdateVersion: String?
    private var lastProbeAt: Date?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem.button?.title = "XDR"
        statusItem.button?.toolTip = "RayXDR"

        let statusMenuItem = NSMenuItem()
        statusMenuItem.view = statusView
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        standardItem.target = self
        rayxdrItem.target = self
        resetItem.target = self
        checkUpdatesItem.target = self
        launchAtLoginItem.target = self
        menu.addItem(standardItem)
        menu.addItem(rayxdrItem)
        menu.addItem(.separator())
        menu.addItem(resetItem)
        menu.addItem(.separator())
        menu.addItem(checkUpdatesItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self

        menu.delegate = self
        statusItem.menu = menu
        applyPreferredBrightnessMode()
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        resetBrightnessBeforeExit()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        checkForUpdatesIfNeeded()
    }

    @objc private func selectStandard() {
        run(preferredMode: .standard) { try controller.off() }
    }

    @objc private func selectRayXDR() {
        run(preferredMode: .rayxdr150) { try controller.on(level: 150) }
    }

    @objc private func reset() {
        run(preferredMode: .standard) { try controller.reset() }
    }

    @objc private func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            switch SMAppService.mainApp.status {
            case .enabled:
                try SMAppService.mainApp.unregister()
            case .requiresApproval:
                openLoginItemsSettings()
            case .notRegistered, .notFound:
                try SMAppService.mainApp.register()
            @unknown default:
                try SMAppService.mainApp.register()
            }
        } catch {
            present(error: error)
        }

        refreshLaunchAtLogin()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func run(preferredMode: PreferredBrightnessMode? = nil, _ action: () throws -> String) {
        do {
            _ = try action()
            if let preferredMode {
                preferences.preferredBrightnessMode = preferredMode
            }
        } catch {
            present(error: error)
        }
        refresh()
    }

    private func applyPreferredBrightnessMode() {
        do {
            switch preferences.preferredBrightnessMode {
            case .standard:
                _ = try controller.off()
            case .rayxdr150:
                _ = try controller.on(level: 150)
            }
        } catch {
            present(error: error)
        }
    }

    private func resetBrightnessBeforeExit() {
        _ = try? controller.reset()
    }

    private func refresh() {
        do {
            let status = try controller.status()
            statusView.update(status: status)
            standardItem.state = status.enabled ? .off : .on
            rayxdrItem.state = status.enabled ? .on : .off
            baseStatusTitle = status.enabled ? "XDR+" : "XDR"
        } catch {
            statusView.update(error: error)
            standardItem.state = .off
            rayxdrItem.state = .off
            baseStatusTitle = "XDR!"
        }

        refreshUpdateStatus()
        refreshLaunchAtLogin()
    }

    private func checkForUpdatesIfNeeded(now: Date = Date()) {
        let updater = updaterController.updater
        guard updater.canCheckForUpdates,
              !updater.sessionInProgress,
              lastProbeAt.map({ now.timeIntervalSince($0) >= 60 * 60 }) ?? true else {
            return
        }

        lastProbeAt = now
        updater.checkForUpdateInformation()
        refreshUpdateStatus()
    }

    private func refreshUpdateStatus() {
        statusItem.button?.title = availableUpdateVersion == nil ? baseStatusTitle : "\(baseStatusTitle) •"
        checkUpdatesItem.title = availableUpdateVersion.map { "Update to \($0)..." } ?? "Check for Updates..."
        checkUpdatesItem.isEnabled = updaterController.updater.canCheckForUpdates
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        availableUpdateVersion = item.displayVersionString
        refreshUpdateStatus()
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        availableUpdateVersion = nil
        refreshUpdateStatus()
    }

    func updater(
        _ updater: SPUUpdater,
        didFinishUpdateCycleFor updateCheck: SPUUpdateCheck,
        error: Error?
    ) {
        refreshUpdateStatus()
    }

    private func refreshLaunchAtLogin() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .on
        case .requiresApproval:
            launchAtLoginItem.title = "Launch at Login (Needs Approval)"
            launchAtLoginItem.state = .off
        case .notRegistered, .notFound:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        @unknown default:
            launchAtLoginItem.title = "Launch at Login"
            launchAtLoginItem.state = .off
        }
    }

    private func openLoginItemsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func present(error: Error) {
        let alert = NSAlert()
        alert.messageText = "RayXDR failed"
        alert.informativeText = String(describing: error)
        alert.alertStyle = .warning
        alert.runModal()
    }
}

@MainActor
func runMenuBarApp() {
    let app = NSApplication.shared
    let delegate = RayXDRMenuBarApp()
    app.delegate = delegate
    app.run()
}

MainActor.assumeIsolated {
    runMenuBarApp()
}
