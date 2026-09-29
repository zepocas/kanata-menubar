import AppKit
import MenubarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let services = ServiceController()
    lazy var watcher = ServiceWatcher(services: services)
    let menu = NSMenu()

    /// Whether a restart/stop/resume is in flight, to avoid stacking admin prompts.
    private(set) var busy = false
    private var statusItem: StatusItemController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start at Login (RunAtLoad) can race an already-running copy launched by hand or by macOS
        // reopening it, which would otherwise show two keycap icons. Defer to whichever started first.
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).count <= 1 else {
            NSApp.terminate(nil)
            return
        }

        menu.delegate = self
        menu.autoenablesItems = false
        statusItem = StatusItemController(menu: menu)

        watcher.onChange = { [weak self] status in self?.statusItem.show(status) }
        watcher.start()
    }

    func restart() {
        run { [services] in try await services.restart() }
    }

    func toggleStop() {
        let shouldStop = watcher.status.isLoaded
        run { [services] in
            if shouldStop {
                try await services.stop()
            } else {
                try await services.start()
            }
        }
    }

    func toggleLoginItem() {
        do {
            try LoginItem.toggle()
        } catch {
            presentError(error, title: "Couldn't change Start at Login")
        }
    }

    private func run(_ action: @escaping @Sendable () async throws -> Void) {
        guard !busy else { return }
        busy = true
        Task {
            defer {
                busy = false
                watcher.poll()
            }
            do {
                try await action()
            } catch is CancellationError {
                // The user cancelled the admin password/Touch ID prompt.
            } catch {
                presentError(error)
            }
        }
    }

    private func presentError(_ error: any Error, title: String = "Couldn't update Kanata") {
        NSApp.activate()
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
