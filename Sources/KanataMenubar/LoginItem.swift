import ServiceManagement

/// Registers this app to launch at login. The LaunchAgent plist ships inside the app bundle
/// (Resources/LoginItem.plist, copied to Contents/Library/LaunchAgents by bundle.sh); SMAppService
/// registers/unregisters it with launchd, so there's no separate install script to run.
@MainActor
enum LoginItem {
    private static let service = SMAppService.agent(plistName: "io.github.zepocas.kanata-menubar.plist")

    static var isEnabled: Bool {
        service.status == .enabled
    }

    static func toggle() throws {
        if isEnabled {
            try service.unregister()
        } else {
            try service.register()
        }
    }
}
