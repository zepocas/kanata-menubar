import AppKit

/// A small template image of "K" inside a keycap outline, drawn at runtime so the menubar item
/// doesn't need a bundled asset. Template images are recolored automatically for light/dark menu
/// bars and for the "greyed out" look `NSStatusBarButton.appearsDisabled` applies.
enum KeycapIcon {
    static func statusBarImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let outline = NSBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), xRadius: 3.5, yRadius: 3.5)
            outline.lineWidth = 1.4
            NSColor.black.setStroke()
            outline.stroke()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.black,
            ]
            let glyph = "K" as NSString
            let glyphSize = glyph.size(withAttributes: attributes)
            glyph.draw(
                at: NSPoint(x: rect.midX - glyphSize.width / 2, y: rect.midY - glyphSize.height / 2 - 0.5),
                withAttributes: attributes
            )
            return true
        }
        image.isTemplate = true
        return image
    }
}
