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
        // Only one keycap icon: the newest copy wins and asks older ones to quit. Deferring to the
        // older one instead loses both during `brew upgrade`, which reopens the app while the old
        // copy is still quitting. A clean quit exits 0, so the login agent's KeepAlive leaves it be.
        let me = NSRunningApplication.current.processIdentifier
        for other in NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
        where other.processIdentifier != me {
            other.terminate()
        }

        menu.delegate = self
        menu.autoenablesItems = false
        statusItem = StatusItemController(menu: menu)

        watcher.onChange = { [weak self] status in self?.statusItem.show(status) }
        watcher.start()
    }

    func restart() {
        let startsAtBoot = watcher.startsAtBoot
        run { [services] in try await services.restart(startsAtBoot: startsAtBoot) }
    }

    func toggleStop() {
        let shouldStop = watcher.status.isLoaded
        let startsAtBoot = watcher.startsAtBoot
        run { [services] in
            if shouldStop {
                try await services.stop()
            } else {
                try await services.start(startsAtBoot: startsAtBoot)
            }
        }
    }

    func toggleStartsAtBoot() {
        let on = !watcher.startsAtBoot
        run { [services] in try await services.setStartsAtBoot(on) }
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
