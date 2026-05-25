import Foundation
import ExtraBrightnessCore

enum CLIExitCode: Int32 {
    case success = 0
    case userError = 1
    case unsupported = 2
    case internalFailureAfterRollback = 3
}

let controller: BrightnessControlling = ProcessBrightnessController()
let arguments = Array(CommandLine.arguments.dropFirst())

func printUsage() {
    print("""
    Usage:
      rayxdr status [--json]
      rayxdr probe [--json]
      rayxdr on [level]
      rayxdr off
      rayxdr set <100|120|140|160|low|medium|high|max>
      rayxdr toggle
      rayxdr reset
    """)
}

func exit(_ code: CLIExitCode) -> Never {
    Foundation.exit(code.rawValue)
}

do {
    guard let command = arguments.first else {
        printUsage()
        exit(.userError)
    }

    switch command {
    case "status":
        let status = try controller.status()
        if arguments.contains("--json") {
            let data = try JSONEncoder.extraBrightness.encode(status)
            print(String(decoding: data, as: UTF8.self))
        } else if let reason = status.unsupportedReason {
            print("Unsupported: \(reason)")
        } else if status.enabled, let level = status.requestedLevel {
            print("RayXDR on: \(level)%")
        } else {
            print("RayXDR off")
        }
        exit(.success)

    case "set":
        guard arguments.count >= 2 else {
            throw BrightnessError.invalidLevel("missing level")
        }
        print(try controller.set(levelOrPreset: arguments[1]))
        exit(.success)

    case "on":
        let level = try arguments.dropFirst().first.map(LevelParser.parse) ?? 150
        print(try controller.on(level: level))
        exit(.success)

    case "off":
        print(try controller.off())
        exit(.success)

    case "toggle":
        print(try controller.toggle())
        exit(.success)

    case "reset":
        print(try controller.reset())
        exit(.success)

    case "probe":
        print(try controller.probe(json: arguments.contains("--json")))
        exit(.success)

    case "-h", "--help", "help":
        printUsage()
        exit(.success)

    default:
        print("Unknown command: \(command)")
        printUsage()
        exit(.userError)
    }
} catch let error as BrightnessError {
    print(error.description)
    switch error {
    case .unsupported:
        exit(.unsupported)
    case .invalidLevel:
        exit(.userError)
    }
} catch {
    print("Internal failure: \(error)")
    exit(.internalFailureAfterRollback)
}
