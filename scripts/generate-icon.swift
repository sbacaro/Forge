import AppKit

// Generates the Forge app icon in all required sizes.
// Usage: swift scripts/generate-icon.swift <output-dir>

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let designSize: CGFloat = 1024

func drawIcon(atPixelSize pixelSize: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixelSize, height: pixelSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let size = CGFloat(pixelSize)

    // macOS 27 squircle background with warm forge gradient.
    let inset = size * 0.08
    let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = rect.width * 0.225
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.addClip()

    let gradient = NSGradient(colors: [
        NSColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1),
        NSColor(red: 0.92, green: 0.28, blue: 0.45, alpha: 1),
    ])!
    gradient.draw(in: path, angle: -60)

    // Anvil silhouette.
    let anvil = NSBezierPath()
    let base = size * 0.30
    anvil.move(to: NSPoint(x: size * 0.22, y: base + size * 0.22))
    anvil.curve(
        to: NSPoint(x: size * 0.78, y: base + size * 0.22),
        controlPoint1: NSPoint(x: size * 0.38, y: base + size * 0.34),
        controlPoint2: NSPoint(x: size * 0.62, y: base + size * 0.34)
    )
    anvil.line(to: NSPoint(x: size * 0.72, y: base + size * 0.08))
    anvil.curve(
        to: NSPoint(x: size * 0.60, y: base + size * 0.02),
        controlPoint1: NSPoint(x: size * 0.68, y: base + size * 0.12),
        controlPoint2: NSPoint(x: size * 0.60, y: base + size * 0.06)
    )
    anvil.line(to: NSPoint(x: size * 0.40, y: base + size * 0.02))
    anvil.curve(
        to: NSPoint(x: size * 0.28, y: base + size * 0.22),
        controlPoint1: NSPoint(x: size * 0.40, y: base + size * 0.12),
        controlPoint2: NSPoint(x: size * 0.22, y: base + size * 0.12)
    )
    anvil.close()
    NSColor(white: 1.0, alpha: 0.95).setFill()
    anvil.fill()

    // Hammer head above the anvil.
    let hammer = NSBezierPath(
        roundedRect: NSRect(x: size * 0.36, y: base + size * 0.40, width: size * 0.30, height: size * 0.14),
        xRadius: size * 0.03, yRadius: size * 0.03
    )
    NSColor(white: 1.0, alpha: 0.92).setFill()
    hammer.fill()

    // Hammer handle.
    let handle = NSBezierPath(
        roundedRect: NSRect(x: size * 0.47, y: base + size * 0.16, width: size * 0.06, height: size * 0.28),
        xRadius: size * 0.02, yRadius: size * 0.02
    )
    NSColor(red: 1.0, green: 0.92, blue: 0.80, alpha: 0.95).setFill()
    handle.fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let rep = drawIcon(atPixelSize: size)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Failed to render icon \(size)\n".utf8))
        continue
    }
    try png.write(to: URL(fileURLWithPath: "\(outDir)/icon_\(size)x\(size).png"))
}
print("Icons written to \(outDir)")
