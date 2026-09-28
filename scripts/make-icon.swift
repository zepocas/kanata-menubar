// Renders the app icon (a "K" keycap) directly with AppKit at every macOS icon size, into an
// .iconset for iconutil. No external image assets: the glyph uses the system font, so it's always
// crisp and correctly shaped.
// Usage: swift scripts/make-icon.swift <output.iconset>
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset>\n".utf8))
    exit(1)
}
let output = URL(fileURLWithPath: arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let capColor = NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.23, alpha: 1)
let faceTop = NSColor(calibratedRed: 0.34, green: 0.38, blue: 0.47, alpha: 1)
let faceBottom = NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.28, alpha: 1)
let glyphColor = NSColor(calibratedRed: 0.97, green: 0.98, blue: 1.0, alpha: 1)

func render(pixels: Int) -> NSBitmapImageRep {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("couldn't allocate bitmap") }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(pixels) / 1024

    // macOS icon grid: 824pt body inset 100pt either side, continuous-corner radius ~185pt.
    capColor.setFill()
    NSBezierPath(
        roundedRect: NSRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale),
        xRadius: 185 * scale, yRadius: 185 * scale
    ).fill()

    // Inset key face, like a keycap sculpt.
    let faceRect = NSRect(x: 176 * scale, y: 176 * scale, width: 672 * scale, height: 672 * scale)
    let facePath = NSBezierPath(roundedRect: faceRect, xRadius: 130 * scale, yRadius: 130 * scale)
    NSGradient(starting: faceTop, ending: faceBottom)?.draw(in: facePath, angle: -90)

    let glyph = "K" as NSString
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 440 * scale, weight: .bold),
        .foregroundColor: glyphColor,
    ]
    let glyphSize = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(x: faceRect.midX - glyphSize.width / 2, y: faceRect.midY - glyphSize.height / 2 - 6 * scale),
        withAttributes: attributes
    )

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

for points in [16, 32, 128, 256, 512] {
    for scaleFactor in [1, 2] {
        let pixels = points * scaleFactor
        let name = scaleFactor == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try render(pixels: pixels).representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
    }
}
