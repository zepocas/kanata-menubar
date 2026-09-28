import AppKit
import MenubarCore

/// Owns the menubar item itself: a static keycap icon that dims when kanata isn't running.
@MainActor
final class StatusItemController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    init(menu: NSMenu) {
        // A stable, unique name (instead of the default "Item-0") so macOS and menubar managers
        // like Thaw/Ice can remember this item's position and section.
        item.autosaveName = "io.github.zepocas.kanata-menubar.status"
        item.menu = menu
        if let button = item.button {
            button.image = KeycapIcon.statusBarImage()
            button.toolTip = "Kanata"
        }
        show(.unknown)
    }

    func show(_ status: KanataStatus) {
        item.button?.appearsDisabled = status != .running
    }
}
