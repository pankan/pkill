#!/usr/bin/env swift
import AppKit

// Renders the DMG window background at 1x and 2x (for retina via a multi-rep tiff).
// Blue-grey glass to match the app icon, a title, and an arrow app -> Applications.

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let W: CGFloat = 640, H: CGFloat = 400

func render(scale: CGFloat, to file: String) {
    let s = scale
    let pw = Int(W * s), ph = Int(H * s)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.scaleBy(x: s, y: s)
    ctx.interpolationQuality = .high

    // background gradient (lighter at top), matching the icon palette
    let grad = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 0.51, green: 0.57, blue: 0.65, alpha: 1),
        CGColor(red: 0.34, green: 0.39, blue: 0.48, alpha: 1),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: 0), options: [])

    // soft vignette top sheen
    let sheen = CGGradient(colorsSpace: cs, colors: [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.16),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 0, y: H), end: CGPoint(x: 0, y: H * 0.55), options: [])

    let g = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = g

    // --- text (drawn in a flipped space so it's upright) ---
    func text(_ str: String, _ size: CGFloat, _ weight: NSFont.Weight,
              _ alpha: CGFloat, centerY: CGFloat) {
        let p = NSMutableParagraphStyle(); p.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: NSColor(white: 1, alpha: alpha),
            .paragraphStyle: p,
        ]
        let a = NSAttributedString(string: str, attributes: attrs)
        let h = a.size().height
        a.draw(in: CGRect(x: 0, y: centerY - h / 2, width: W, height: h))
    }
    // CG y-up: higher y = nearer the top
    text("Install pkill", 30, .bold, 1.0, centerY: 352)
    text("Drag the app into your Applications folder", 14, .regular, 0.78, centerY: 320)

    NSGraphicsContext.restoreGraphicsState()

    // --- arrow from the app (left) to Applications (right), at icon height ---
    let y: CGFloat = 195            // visual middle-ish, aligned with icons
    let x0: CGFloat = 258, x1: CGFloat = 382
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    ctx.setLineWidth(7)
    ctx.setLineCap(.round)
    ctx.setShadow(offset: .zero, blur: 6, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.25))
    ctx.beginPath()
    ctx.move(to: CGPoint(x: x0, y: y))
    ctx.addLine(to: CGPoint(x: x1, y: y))
    ctx.strokePath()
    // arrowhead
    let tip = CGPoint(x: x1 + 18, y: y), hw: CGFloat = 16
    ctx.beginPath()
    ctx.move(to: tip)
    ctx.addLine(to: CGPoint(x: x1 - 2, y: y + hw))
    ctx.addLine(to: CGPoint(x: x1 - 2, y: y - hw))
    ctx.closePath()
    ctx.fillPath()

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: file))
}

render(scale: 1, to: "\(outDir)/bg_1x.png")
render(scale: 2, to: "\(outDir)/bg_2x.png")
print("wrote bg_1x.png bg_2x.png")
