import AppKit
import ExtraBrightnessCore
import ServiceManagement

private struct UpdateInfo {
    let version: String
    let tagName: String
    let dmgURL: URL
}

private enum UpdateError: LocalizedError {
    case invalidResponse
    case noCompatibleAsset
    case notInstalledInApplications
    case helperScriptFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "RayXDR could not read the latest GitHub release."
        case .noCompatibleAsset:
            "The latest GitHub release does not include a RayXDR DMG."
        case .notInstalledInApplications:
            "Move RayXDR to Applications before updating."
        case .helperScriptFailed:
            "RayXDR could not start the updater."
        }
    }
}

private struct UpdateChecker: Sendable {
    private struct GitHubRelease: Decodable {
        let tagName: String
        let assets: [GitHubAsset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case assets
        }
    }

    private struct GitHubAsset: Decodable {
        let name: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    private let releaseURL = URL(string: "https://api.github.com/repos/MrFlashAccount/RayXDR/releases/latest")!

    func latestUpdate(currentVersion: String) async throws -> UpdateInfo? {
        var request = URLRequest(url: releaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("RayXDR", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw UpdateError.invalidResponse
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        let latestVersion = release.tagName.removingVersionPrefix
        guard latestVersion.isNewer(than: currentVersion) else {
            return nil
        }

        guard let asset = release.assets.first(where: { asset in
            asset.name.lowercased().hasSuffix(".dmg") && asset.name.lowercased().contains("rayxdr")
        }) else {
            throw UpdateError.noCompatibleAsset
        }

        return UpdateInfo(version: latestVersion, tagName: release.tagName, dmgURL: asset.browserDownloadURL)
    }

    func install(_ update: UpdateInfo) async throws {
        let appURL = Bundle.main.bundleURL
        guard appURL.pathExtension == "app",
              !appURL.path.contains("/AppTranslocation/"),
              !appURL.path.hasPrefix("/Volumes/") else {
            throw UpdateError.notInstalledInApplications
        }

        let downloadURL = try await download(update.dmgURL)
        try startInstaller(downloadURL: downloadURL, targetAppURL: appURL)
    }

    private func download(_ url: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.setValue("RayXDR", forHTTPHeaderField: "User-Agent")

        let (temporaryURL, response) = try await URLSession.shared.download(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw UpdateError.invalidResponse
        }

        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RayXDR-update-\(UUID().uuidString)")
            .appendingPathExtension("dmg")
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    private func startInstaller(downloadURL: URL, targetAppURL: URL) throws {
        let scriptURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("rayxdr-update-\(UUID().uuidString)")
            .appendingPathExtension("sh")
        let script = """
        #!/bin/zsh
        set -euo pipefail

        app_pid="$1"
        dmg_path="$2"
        target_app="$3"
        mount_dir="$(/usr/bin/mktemp -d)"

        cleanup() {
          /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
          /bin/rm -rf "$mount_dir" "$dmg_path"
        }
        trap cleanup EXIT

        /usr/bin/hdiutil attach "$dmg_path" -readonly -nobrowse -noautoopen -mountpoint "$mount_dir" >/dev/null

        while /bin/kill -0 "$app_pid" >/dev/null 2>&1; do
          /bin/sleep 0.2
        done

        source_app="$mount_dir/RayXDR.app"
        if [ ! -d "$source_app" ]; then
          exit 1
        fi

        /bin/rm -rf "$target_app"
        /usr/bin/ditto "$source_app" "$target_app"
        /usr/bin/open "$target_app"
        /bin/rm -f "$0"
        """

        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [
            scriptURL.path,
            "\(ProcessInfo.processInfo.processIdentifier)",
            downloadURL.path,
            targetAppURL.path
        ]

        do {
            try process.run()
        } catch {
            throw UpdateError.helperScriptFailed
        }
    }
}

private extension String {
    var removingVersionPrefix: String {
        hasPrefix("v") || hasPrefix("V") ? String(dropFirst()) : self
    }

    func isNewer(than other: String) -> Bool {
        let lhs = versionParts
        let rhs = other.removingVersionPrefix.versionParts
        let count = max(lhs.count, rhs.count)

        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0

            if left != right {
                return left > right
            }
        }

        return false
    }

    private var versionParts: [Int] {
        removingVersionPrefix
            .split { !$0.isNumber }
            .map { Int($0) ?? 0 }
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

@MainActor final class RayXDRMenuBarApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let controller = ProcessBrightnessController()
    private let updateChecker = UpdateChecker()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let statusView = StatusMenuView(frame: NSRect(x: 0, y: 0, width: 240, height: 72))
    private let standardItem = NSMenuItem(title: "Standard", action: #selector(selectStandard), keyEquivalent: "")
    private let rayxdrItem = NSMenuItem(title: "RayXDR 150%", action: #selector(selectRayXDR), keyEquivalent: "")
    private let resetItem = NSMenuItem(title: "Reset", action: #selector(reset), keyEquivalent: "")
    private let updateItem = NSMenuItem(title: "Update...", action: #selector(installUpdate), keyEquivalent: "")
    private let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var updateInfo: UpdateInfo?
    private var isCheckingForUpdates = false
    private var isInstallingUpdate = false
    private var lastUpdateCheck: Date?
    private var baseStatusTitle = "XDR"

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
        updateItem.target = self
        launchAtLoginItem.target = self
        menu.addItem(standardItem)
        menu.addItem(rayxdrItem)
        menu.addItem(.separator())
        menu.addItem(resetItem)
        menu.addItem(.separator())
        menu.addItem(updateItem)
        menu.addItem(.separator())
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q").target = self

        menu.delegate = self
        statusItem.menu = menu
        refresh()
        checkForUpdatesIfNeeded(force: true)
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        checkForUpdatesIfNeeded()
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

    @objc private func installUpdate() {
        guard let updateInfo, !isInstallingUpdate else {
            return
        }

        isInstallingUpdate = true
        refreshUpdateItem()

        Task {
            do {
                try await updateChecker.install(updateInfo)
                await MainActor.run {
                    NSApp.terminate(nil)
                }
            } catch {
                await MainActor.run {
                    isInstallingUpdate = false
                    refreshUpdateItem()
                    present(error: error)
                }
            }
        }
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
            baseStatusTitle = status.enabled ? "XDR+" : "XDR"
        } catch {
            statusView.update(error: error)
            standardItem.state = .off
            rayxdrItem.state = .off
            baseStatusTitle = "XDR!"
        }

        refreshStatusTitle()
        refreshLaunchAtLogin()
        refreshUpdateItem()
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

    private func checkForUpdatesIfNeeded(force: Bool = false) {
        guard !isCheckingForUpdates else {
            return
        }

        if !force, let lastUpdateCheck, Date().timeIntervalSince(lastUpdateCheck) < 60 * 60 {
            return
        }

        isCheckingForUpdates = true
        refreshUpdateItem()

        Task {
            do {
                let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
                let latestUpdate = try await updateChecker.latestUpdate(currentVersion: currentVersion)

                await MainActor.run {
                    updateInfo = latestUpdate
                    isCheckingForUpdates = false
                    lastUpdateCheck = Date()
                    refreshStatusTitle()
                    refreshUpdateItem()
                }
            } catch {
                await MainActor.run {
                    isCheckingForUpdates = false
                    lastUpdateCheck = Date()
                    refreshUpdateItem()
                }
            }
        }
    }

    private func refreshStatusTitle() {
        statusItem.button?.title = updateInfo == nil ? baseStatusTitle : "\(baseStatusTitle) •"
    }

    private func refreshUpdateItem() {
        if isInstallingUpdate {
            updateItem.title = "Installing Update..."
            updateItem.isEnabled = false
            updateItem.isHidden = false
        } else if isCheckingForUpdates {
            updateItem.title = "Checking for Updates..."
            updateItem.isEnabled = false
            updateItem.isHidden = updateInfo == nil
        } else if let updateInfo {
            updateItem.title = "Update to \(updateInfo.tagName)..."
            updateItem.isEnabled = true
            updateItem.isHidden = false
        } else {
            updateItem.title = "Update..."
            updateItem.isEnabled = false
            updateItem.isHidden = true
        }
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
