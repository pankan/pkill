#!/usr/bin/env swift
import AppKit

// Renders the pkill app icon at every required size and builds AppIcon.icns.
// Blue-grey glass squircle + the same powerplug.portrait SF Symbol as the menu bar.

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let iconset = "\(outDir)/AppIcon.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

func draw(_ size: CGFloat) -> CGImage {
    let s = size
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: Int(s), height: Int(s),
                        bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.interpolationQuality = .high

    // --- Squircle background (continuous-corner rounded rect) ---
    let inset = s * 0.06
    let rect = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let radius = rect.width * 0.2237
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()

    // blue-grey slate gradient (lighter at top)
    let grad = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.52, green: 0.58, blue: 0.66, alpha: 1),
        CGColor(red: 0.40, green: 0.46, blue: 0.55, alpha: 1),
        CGColor(red: 0.30, green: 0.35, blue: 0.44, alpha: 1),
    ] as CFArray, locations: [0, 0.5, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

    // top glossy highlight (liquid glass sheen)
    let sheen = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.38),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 0, y: s),
                           end: CGPoint(x: 0, y: s * 0.52), options: [])
    ctx.restoreGState()

    // subtle inner stroke for the glass edge
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.22))
    ctx.setLineWidth(s * 0.006)
    ctx.strokePath()
    ctx.restoreGState()

    // --- powerplug.portrait SF Symbol, white, centered ---
    let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.48, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let sym = NSImage(systemSymbolName: "powerplug.portrait", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let g = NSGraphicsContext(cgContext: ctx, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = g
        let sz = sym.size
        let r = CGRect(x: (s - sz.width) / 2, y: (s - sz.height) / 2,
                       width: sz.width, height: sz.height)
        sym.draw(in: r)
        NSGraphicsContext.restoreGraphicsState()
    }

    return ctx.makeImage()!
}

func write(_ img: CGImage, _ name: String) {
    let rep = NSBitmapImageRep(cgImage: img)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
}

let specs: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]
for (px, name) in specs { write(draw(CGFloat(px)), name) }
print("wrote \(iconset)")
