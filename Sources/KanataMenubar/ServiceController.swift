import Foundation
import MenubarCore

/// Talks to the `local.kanata` LaunchDaemon via `launchctl`.
///
/// Reading its state doesn't need privileges. Changing it does, because it's a system-domain
/// LaunchDaemon owned by root — so every change goes through an admin prompt.
struct ServiceController: Sendable {
    static let label = "local.kanata"
    static let serviceTarget = "system/\(label)"
    static let plistPath = "/Library/LaunchDaemons/local.kanata.plist"

    private let launchctl = URL(fileURLWithPath: "/bin/launchctl")
    private let environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]

    func fetchStatus() async -> KanataStatus {
        let result = await Shell.run(launchctl, ["print", Self.serviceTarget], environment: environment)
        return KanataStatus.parse(exitCode: result.status, output: String(decoding: result.stdout, as: UTF8.self))
    }

    /// Whether launchd loads kanata at boot, i.e. it isn't `launchctl disable`d.
    func fetchStartsAtBoot() async -> Bool {
        let result = await Shell.run(launchctl, ["print-disabled", "system"], environment: environment)
        return !LaunchdOverrides.isDisabled(Self.label, inPrintDisabled: String(decoding: result.stdout, as: UTF8.self))
    }

    /// Persists across reboots and doesn't touch the running instance.
    func setStartsAtBoot(_ on: Bool) async throws {
        try await PrivilegedShell.run("/bin/launchctl \(on ? "enable" : "disable") \(Self.serviceTarget)")
    }

    /// Kills and reloads the running instance. Only meaningful while it's loaded.
    func restart(startsAtBoot: Bool) async throws {
        try await runEnabled("/bin/launchctl kickstart -k \(Self.serviceTarget)", startsAtBoot: startsAtBoot)
    }

    /// Unloads the job. `KeepAlive` would otherwise relaunch a merely-killed process.
    func stop() async throws {
        try await PrivilegedShell.run("/bin/launchctl bootout \(Self.serviceTarget)")
    }

    /// Reloads the job; `RunAtLoad` in the plist starts it immediately.
    func start(startsAtBoot: Bool) async throws {
        try await runEnabled("/bin/launchctl bootstrap system \(Self.plistPath)", startsAtBoot: startsAtBoot)
    }

    /// launchd refuses to load a disabled service. While "at boot" is off, enable it just long
    /// enough to run `command`, then disable it again (even if `command` failed), in one prompt.
    private func runEnabled(_ command: String, startsAtBoot: Bool) async throws {
        guard !startsAtBoot else {
            try await PrivilegedShell.run(command)
            return
        }
        try await PrivilegedShell.run(
            "/bin/launchctl enable \(Self.serviceTarget) && { \(command); s=$?; /bin/launchctl disable \(Self.serviceTarget); exit $s; }"
        )
    }
}
