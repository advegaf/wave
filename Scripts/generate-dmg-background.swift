#!/usr/bin/env swift
//
//  generate-dmg-background.swift
//
//  Renders the Wave DMG background image in the Notion design language.
//  Warm white canvas, clean SF Pro typography, restrained composition.
//
//  Writes both a 144-DPI PNG (for visual review) and a 144-DPI TIFF (for
//  embedding in the DMG as `.bg.tiff`). The 144-DPI tag is required so Finder
//  treats the 1320x800 pixel image as a 660x400 logical retina background;
//  without it the window renders the bg @1x and clips the bottom-right.
//
//  Usage:
//    swift Scripts/generate-dmg-background.swift <output-path>
//
//  The output path's extension is ignored. Both `.png` and `.tiff` files are
//  written next to it (e.g. `dist/dmg-background.png` produces both
//  `dist/dmg-background.png` and `dist/dmg-background.tiff`).
//

import AppKit
import CoreText
import Foundation

// MARK: - Geometry

let logicalSize = CGSize(width: 660, height: 400)
let scale: CGFloat = 2.0
let pixelSize = CGSize(width: logicalSize.width * scale, height: logicalSize.height * scale)

// MARK: - Color tokens (Notion warm palette)

let bgWarmWhite   = NSColor(srgbRed: 0.965, green: 0.961, blue: 0.957, alpha: 1)  // #f6f5f4
let textPrimary   = NSColor(white: 0.0, alpha: 0.85)
let textSecondary = NSColor(srgbRed: 0.380, green: 0.365, blue: 0.349, alpha: 1)  // #615d59
let textTertiary  = NSColor(srgbRed: 0.639, green: 0.620, blue: 0.596, alpha: 1)  // #a39e98
let borderSubtle  = NSColor(white: 0.0, alpha: 0.08)
let accentBlue    = NSColor(srgbRed: 0.0, green: 0.459, blue: 0.871, alpha: 1)    // #0075de

// MARK: - CLI args

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: generate-dmg-background.swift <output-png>\n".data(using: .utf8)!)
    exit(2)
}
let outputURL = URL(fileURLWithPath: args[1])

// MARK: - Font helpers

func sysFont(_ weight: NSFont.Weight, size: CGFloat) -> NSFont {
    NSFont.systemFont(ofSize: size * scale, weight: weight)
}

// MARK: - Drawing helpers

func drawCenteredText(_ text: String,
                      centerXLogical cx: CGFloat,
                      baselineYLogical by: CGFloat,
                      font: NSFont,
                      color: NSColor,
                      tracking: CGFloat = 0) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: tracking * scale,
    ]
    let attr = NSAttributedString(string: text, attributes: attrs)
    let w = attr.size().width
    let xPixel = cx * scale - w / 2
    let yPixel = (logicalSize.height - by) * scale
    attr.draw(at: CGPoint(x: xPixel, y: yPixel))
}

func drawCenteredHRule(centerXLogical cx: CGFloat,
                       yLogical y: CGFloat,
                       lengthLogical length: CGFloat,
                       color: NSColor) {
    color.setStroke()
    let path = NSBezierPath()
    path.lineWidth = 1 * scale
    let half = length / 2
    path.move(to: CGPoint(x: (cx - half) * scale, y: (logicalSize.height - y) * scale))
    path.line(to: CGPoint(x: (cx + half) * scale, y: (logicalSize.height - y) * scale))
    path.stroke()
}

func drawArrow(fromLogical start: CGPoint, toLogical end: CGPoint, color: NSColor) {
    let s = CGPoint(x: start.x * scale, y: (logicalSize.height - start.y) * scale)
    let e = CGPoint(x: end.x * scale, y: (logicalSize.height - end.y) * scale)
    color.setStroke()
    let line = NSBezierPath()
    line.lineWidth = 1.5 * scale
    line.lineCapStyle = .round
    line.move(to: s)
    line.line(to: e)
    line.stroke()
    let headLen: CGFloat = 5 * scale
    let head = NSBezierPath()
    head.lineWidth = 1.5 * scale
    head.lineCapStyle = .round
    head.move(to: CGPoint(x: e.x - headLen, y: e.y - headLen * 0.7))
    head.line(to: e)
    head.line(to: CGPoint(x: e.x - headLen, y: e.y + headLen * 0.7))
    head.stroke()
}

// MARK: - Compose

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(pixelSize.width),
    pixelsHigh: Int(pixelSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 32
)!

// Tag the bitmap as @2x so the encoded image carries 144 DPI metadata.
// Finder uses this to render the bg as 660x400 logical points instead of
// 1320x800 — without it the DMG window clips the bottom-right of the image.
rep.size = logicalSize

let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let cx: CGFloat = logicalSize.width / 2

// 1) Warm white background
bgWarmWhite.setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: pixelSize)).fill()

// 2) Subtle whisper border at the very edge (Notion's 1px border motif)
borderSubtle.setStroke()
let borderPath = NSBezierPath(rect: CGRect(x: 1, y: 1, width: pixelSize.width - 2, height: pixelSize.height - 2))
borderPath.lineWidth = 1
borderPath.stroke()

// 3) "Wave" hero title — centered near top
drawCenteredText("Wave",
                 centerXLogical: cx,
                 baselineYLogical: 65,
                 font: sysFont(.bold, size: 38),
                 color: textPrimary,
                 tracking: -1.0)

// 4) Version subtitle
drawCenteredText("v0.7.2",
                 centerXLogical: cx,
                 baselineYLogical: 92,
                 font: sysFont(.regular, size: 13),
                 color: textTertiary)

// 5) Whisper hairline divider
drawCenteredHRule(centerXLogical: cx, yLogical: 106, lengthLogical: 60, color: borderSubtle)

// 6) "Drag to install" hint with arrow — sits between hero and icon row
drawCenteredText("Drag to Applications",
                 centerXLogical: cx - 8,
                 baselineYLogical: 206,
                 font: sysFont(.medium, size: 11),
                 color: textSecondary,
                 tracking: 0.5)

drawArrow(fromLogical: CGPoint(x: cx + 65, y: 202),
          toLogical:   CGPoint(x: cx + 82, y: 202),
          color: textSecondary)

// 7) Bottom accent line (Notion Blue, very subtle)
accentBlue.withAlphaComponent(0.15).setStroke()
let accentPath = NSBezierPath()
accentPath.lineWidth = 2 * scale
accentPath.move(to: CGPoint(x: 0, y: 1))
accentPath.line(to: CGPoint(x: pixelSize.width, y: 1))
accentPath.stroke()

NSGraphicsContext.restoreGraphicsState()

// MARK: - Save (PNG + TIFF, both 144 DPI)

let pngURL  = outputURL.deletingPathExtension().appendingPathExtension("png")
let tiffURL = outputURL.deletingPathExtension().appendingPathExtension("tiff")

try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

func writeOrDie(_ data: Data?, to url: URL, label: String) {
    guard let data else {
        FileHandle.standardError.write("error: failed to encode \(label)\n".data(using: .utf8)!)
        exit(1)
    }
    do {
        try data.write(to: url)
        print("wrote \(url.path) (\(Int(pixelSize.width))x\(Int(pixelSize.height)) @\(Int(scale))x)")
    } catch {
        FileHandle.standardError.write("error: failed to write \(url.path): \(error)\n".data(using: .utf8)!)
        exit(1)
    }
}

writeOrDie(rep.representation(using: .png, properties: [:]),
           to: pngURL,  label: "PNG")
writeOrDie(rep.tiffRepresentation,
           to: tiffURL, label: "TIFF")
