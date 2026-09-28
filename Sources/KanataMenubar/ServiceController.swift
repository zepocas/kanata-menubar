import Foundation
import MenubarCore

/// Talks to the `local.kanata` LaunchDaemon via `launchctl`.
///
/// Reading status doesn't need privileges. Starting, stopping and restarting it does, because it's
/// a system-domain LaunchDaemon owned by root — so those three go through an admin prompt.
struct ServiceController: Sendable {
    static let serviceTarget = "system/local.kanata"
    static let plistPath = "/Library/LaunchDaemons/local.kanata.plist"

    private let launchctl = URL(fileURLWithPath: "/bin/launchctl")
    private let environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]

    func fetchStatus() async -> KanataStatus {
        let result = await Shell.run(launchctl, ["print", Self.serviceTarget], environment: environment)
        return KanataStatus.parse(exitCode: result.status, output: String(decoding: result.stdout, as: UTF8.self))
    }

    /// Kills and reloads the running instance. Only meaningful while it's loaded.
    func restart() async throws {
        try await PrivilegedShell.run("/bin/launchctl kickstart -k \(Self.serviceTarget)")
    }

    /// Unloads the job. `KeepAlive` would otherwise relaunch a merely-killed process.
    func stop() async throws {
        try await PrivilegedShell.run("/bin/launchctl bootout \(Self.serviceTarget)")
    }

    /// Reloads the job; `RunAtLoad` in the plist starts it immediately.
    func start() async throws {
        try await PrivilegedShell.run("/bin/launchctl bootstrap system \(Self.plistPath)")
    }
}
