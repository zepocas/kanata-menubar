import Foundation

/// Start at Login, as a LaunchAgent plist this app writes into ~/Library/LaunchAgents.
///
/// Not SMAppService: for an ad-hoc signed app it pins the registration to the binary's exact
/// cdhash, so after every update launchd refuses to spawn the new build (EX_CONFIG). A plain plist
/// has no such pin. Toggling only writes or deletes the file — launchd picks it up at the next
/// login — so it never has to bootout a job whose process may be this app.
@MainActor
enum LoginItem {
    static let label = "io.github.zepocas.kanata-menubar"
    private static let plistURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/\(label).plist")

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func toggle() throws {
        if isEnabled {
            try FileManager.default.removeItem(at: plistURL)
        } else {
            try enable()
        }
    }

    private static func enable() throws {
        let log = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/kanata-menubar.log").path
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [Bundle.main.executablePath!],
            "RunAtLoad": true,
            // Relaunch after a crash; "Quit" from the menu is a clean exit and stays quit.
            "KeepAlive": ["SuccessfulExit": false],
            "ProcessType": "Interactive",
            "LimitLoadToSessionType": "Aqua",
            "StandardOutPath": log,
            "StandardErrorPath": log,
        ]
        try FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: plistURL, options: .atomic)
    }
}
