import AppKit
import ExtraBrightnessCore
import ServiceManagement

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

@MainActor final class RayXDRMenuBarApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let controller = ProcessBrightnessController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusView = StatusMenuView(frame: NSRect(x: 0, y: 0, width: 240, height: 72))
    private let standardItem = NSMenuItem(title: "Standard", action: #selector(selectStandard), keyEquivalent: "")
    private let rayxdrItem = NSMenuItem(title: "RayXDR 150%", action: #selector(selectRayXDR), keyEquivalent: "")
    private let resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")

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
        launchAtLoginItem.target = self
        menu.addItem(standardItem)
        menu.addItem(rayxdrItem)
        menu.addItem(.separator())
        menu.addItem(resetItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self

        menu.delegate = self
        statusItem.menu = menu
        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
    }

    @objc private func selectStandard() {
        run { try controller.off() }
    }

    @objc private func selectRayXDR() {
        run { try controller.on(level: 150) }
    }

    @objc private func reset() {
        run { try controller.reset() }
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

    private func run(_ action: () throws -> String) {
        do {
            _ = try action()
        } catch {
            present(error: error)
        }
        refresh()
    }

    private func refresh() {
        do {
            let status = try controller.status()
            statusView.update(status: status)
            standardItem.state = status.enabled ? .off : .on
            rayxdrItem.state = status.enabled ? .on : .off
            statusItem.button?.title = status.enabled ? "XDR+" : "XDR"
        } catch {
            statusView.update(error: error)
            standardItem.state = .off
            rayxdrItem.state = .off
            statusItem.button?.title = "XDR!"
        }

        refreshLaunchAtLogin()
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
