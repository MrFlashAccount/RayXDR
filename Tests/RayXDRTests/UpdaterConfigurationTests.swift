import Foundation
import XCTest

final class UpdaterConfigurationTests: XCTestCase {
    func testUpdaterIsManualAndRequiresSignedArtifacts() throws {
        let info = try loadInfoPlist()

        XCTAssertEqual(info["SUEnableAutomaticChecks"] as? Bool, false)
        XCTAssertEqual(info["SUAllowsAutomaticUpdates"] as? Bool, false)
        XCTAssertEqual(info["SUAutomaticallyUpdate"] as? Bool, false)
        XCTAssertEqual(info["SUVerifyUpdateBeforeExtraction"] as? Bool, true)
        XCTAssertEqual(info["SURequireSignedFeed"] as? Bool, true)
    }

    func testUpdaterUsesPinnedRayXDRFeedAndPublicKey() throws {
        let info = try loadInfoPlist()

        XCTAssertEqual(
            info["SUFeedURL"] as? String,
            "https://github.com/MrFlashAccount/RayXDR/releases/latest/download/appcast.xml"
        )
        XCTAssertEqual(
            info["SUPublicEDKey"] as? String,
            "aFQQjBmKgfSVCPsOmtzS4KEOWG/L1vjqCA76y+Zb4ks="
        )
    }

    private func loadInfoPlist() throws -> [String: Any] {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: repositoryRoot.appendingPathComponent("Resources/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }
}
