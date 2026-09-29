import AppKit
import MenubarCore

/// The menu is rebuilt each time it opens so the status line is always current.
extension AppDelegate: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        watcher.poll()
        let status = watcher.status
        menu.removeAllItems()

        menu.addItem(statusItem(for: status))
        menu.addItem(.separator())

        let restart = ActionMenuItem(title: "Restart Kanata") { [weak self] in self?.restart() }
        restart.isEnabled = status.isLoaded && !busy
        menu.addItem(restart)

        let stopResume = ActionMenuItem(title: status.isLoaded ? "Stop Kanata" : "Resume Kanata") { [weak self] in
            self?.toggleStop()
        }
        stopResume.isEnabled = !busy
        menu.addItem(stopResume)

        menu.addItem(.separator())
        let startup = NSMenuItem(title: "Start at Login", action: nil, keyEquivalent: "")
        startup.submenu = startupMenu()
        menu.addItem(startup)

        menu.addItem(.separator())
        menu.addItem(ActionMenuItem(title: "Quit Kanata Menubar", keyEquivalent: "q") {
            NSApp.terminate(nil)
        })
    }

    private func startupMenu() -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        let app = ActionMenuItem(title: "Kanata Menubar") { [weak self] in self?.toggleLoginItem() }
        app.state = LoginItem.isEnabled ? .on : .off
        submenu.addItem(app)

        let kanata = ActionMenuItem(title: "kanata (at boot)") { [weak self] in self?.toggleStartsAtBoot() }
        kanata.state = watcher.startsAtBoot ? .on : .off
        kanata.isEnabled = !busy
        kanata.toolTip = "Whether macOS starts the local.kanata LaunchDaemon at boot. Asks for your password."
        submenu.addItem(kanata)
        return submenu
    }

    private func statusItem(for status: KanataStatus) -> NSMenuItem {
        let item = NSMenuItem(title: status.label, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 8, weight: .regular).applying(.init(paletteColors: [dotColor(for: status)])))
        return item
    }

    private func dotColor(for status: KanataStatus) -> NSColor {
        switch status {
        case .running: return .systemGreen
        case .loadedNotRunning: return .systemYellow
        case .notLoaded: return .systemRed
        case .unknown: return .systemGray
        }
    }
}

/// NSMenuItem that runs a closure, avoiding a selector per action.
final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(title: String, keyEquivalent: String = "", handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: keyEquivalent)
        target = self
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func fire() {
        handler()
    }
}
