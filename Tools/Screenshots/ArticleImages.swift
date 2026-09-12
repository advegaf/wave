import AppKit

/// Composites the README images: a drawn ground, and the real window captures
/// placed on it.
///
/// Run as `swift Tools/Screenshots/ArticleImages.swift <raw dir> <out dir>`,
/// where the raw directory holds the captures `make-docs-images.sh` takes.
///
/// Three things here are load bearing.
///
/// The 144 DPI tag is the last thing that happens to a bitmap. Setting the size
/// before drawing makes the context one point per two pixels while every
/// rectangle below is still in pixels, so the whole composite doubles and runs
/// off the canvas.
///
/// A capture carries its own shadow as transparent margin, so the alpha
/// bounding box is what has to be measured to place anything precisely. The
/// window's rounded corners and traffic lights come from the window server;
/// nothing here draws a window frame.
///
/// Text is drawn with AppKit rather than composited from an image because
/// ImageMagick on macOS is commonly built without Freetype, where `-annotate`
/// warns about a missing delegate and then renders nothing at all.

// MARK: - Canvas

func bitmap(_ width: Int, _ height: Int) -> NSBitmapImageRep {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("cannot allocate a \(width) by \(height) bitmap") }
    rep.size = NSSize(width: width, height: height)
    return rep
}

/// Paper. One flat colour behind everything. Wave's windows are dark, so they
/// cut out against this without a border drawn around them.
func ground(_ width: Int, _ height: Int) -> NSBitmapImageRep {
    let result = bitmap(width, height)
    guard let data = result.bitmapData else { fatalError("no bitmap data") }
    let paper: [UInt8] = [242, 242, 244, 255]
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * result.bytesPerRow + x * 4
            for channel in 0..<4 { data[offset + channel] = paper[channel] }
        }
    }
    return result
}

/// A canvas with nothing on it. The badge needs one: it sits on whatever colour
/// GitHub is painting behind the README, which is white in one theme and near
/// black in the other.
func clearCanvas(_ width: Int, _ height: Int) -> NSBitmapImageRep {
    let result = bitmap(width, height)
    guard let data = result.bitmapData else { fatalError("no bitmap data") }
    memset(data, 0, result.bytesPerRow * height)
    return result
}

func withCanvas(_ canvas: NSBitmapImageRep, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: canvas)
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

/// Half the pixel count means 144 DPI in the encoded file, so the PNG reads as
/// a retina asset rather than a very large 1x one.
func write(_ image: NSBitmapImageRep, to url: URL) {
    let pixels = NSSize(width: image.pixelsWide, height: image.pixelsHigh)
    image.size = NSSize(width: pixels.width / 2, height: pixels.height / 2)
    guard let png = image.representation(using: .png, properties: [:]) else {
        fatalError("cannot encode \(url.lastPathComponent)")
    }
    try! png.write(to: url)
    image.size = pixels
    print("\(url.lastPathComponent) \(image.pixelsWide)x\(image.pixelsHigh)")
}

// MARK: - Captures

struct Capture {
    let image: NSImage
    /// The part of the capture that is not fully transparent, in pixels with
    /// the origin at the top left.
    let content: CGRect
    let size: CGSize
}

func load(_ url: URL) -> Capture {
    guard let data = try? Data(contentsOf: url), let rep = NSBitmapImageRep(data: data) else {
        fatalError("cannot read \(url.path)")
    }
    let width = rep.pixelsWide
    let height = rep.pixelsHigh
    rep.size = NSSize(width: width, height: height)
    var minX = width, minY = height, maxX = 0, maxY = 0
    if let data = rep.bitmapData {
        let samples = rep.samplesPerPixel
        for y in 0..<height {
            for x in 0..<width {
                let alpha = data[y * rep.bytesPerRow + x * samples + 3]
                if alpha > 8 {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
    }
    let image = NSImage(size: NSSize(width: width, height: height))
    image.addRepresentation(rep)
    let content = minX <= maxX
        ? CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        : CGRect(x: 0, y: 0, width: width, height: height)
    return Capture(image: image, content: content, size: CGSize(width: width, height: height))
}

/// Draws a capture so its content box lands exactly on `target`, given with the
/// origin at the top left. The transparent shadow margin hangs outside it.
func place(_ capture: Capture, content target: CGRect, canvasHeight: CGFloat,
           interpolation: NSImageInterpolation = .high) {
    let scale = target.width / capture.content.width
    let full = CGRect(x: target.minX - capture.content.minX * scale,
                      y: target.minY - capture.content.minY * scale,
                      width: capture.size.width * scale,
                      height: capture.size.height * scale)
    let flipped = CGRect(x: full.minX, y: canvasHeight - full.maxY, width: full.width, height: full.height)
    NSGraphicsContext.current?.imageInterpolation = interpolation
    capture.image.draw(in: flipped, from: .zero, operation: .sourceOver, fraction: 1)
}

// MARK: - Type

func draw(_ text: String, at point: CGPoint, canvasHeight: CGFloat, size: CGFloat,
          weight: NSFont.Weight, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
    ]
    let string = text as NSString
    let measured = string.size(withAttributes: attributes)
    string.draw(at: NSPoint(x: point.x, y: canvasHeight - point.y - measured.height),
                withAttributes: attributes)
}

// MARK: - Run

let arguments = CommandLine.arguments
let rawDirectory = URL(fileURLWithPath: arguments.count > 1 ? arguments[1] : "artifacts/article/raw", isDirectory: true)
let outDirectory = URL(fileURLWithPath: arguments.count > 2 ? arguments[2] : "docs/images", isDirectory: true)
try? FileManager.default.createDirectory(at: outDirectory, withIntermediateDirectories: true)

func raw(_ name: String) -> Capture { load(rawDirectory.appendingPathComponent(name + ".png")) }

let ink = NSColor(srgbRed: 0.16, green: 0.19, blue: 0.26, alpha: 1)
let inkSoft = NSColor(srgbRed: 0.35, green: 0.39, blue: 0.47, alpha: 1)

// The hero. The window at a readable size with the name and the one line that
// says what the thing is, set on the ground beside it the way a magazine would.
// 2400x1600 is the shape the portfolio cards use, so the cover comes out of the
// same file rather than a second capture.
do {
    let canvas = CGSize(width: 2400, height: 1600)
    let image = ground(Int(canvas.width), Int(canvas.height))
    let home = raw("home")
    withCanvas(image) {
        // The brand block owns the top-left corner of the ground. The window
        // is then fitted into what is left, rather than centred first and
        // written over: an earlier pass did that and the title landed on top
        // of the sidebar.
        let blockTop: CGFloat = 120
        let blockHeight: CGFloat = 215

        if let icon = NSImage(contentsOf: rawDirectory.appendingPathComponent("logo.png")) {
            NSGraphicsContext.current?.imageInterpolation = .high
            icon.draw(in: CGRect(x: 150, y: canvas.height - blockTop - 118, width: 118, height: 118))
        }
        draw("Wave", at: CGPoint(x: 300, y: blockTop + 2), canvasHeight: canvas.height,
             size: 64, weight: .semibold, color: ink)
        draw("Talk at the speed you think.", at: CGPoint(x: 304, y: blockTop + 88),
             canvasHeight: canvas.height, size: 30, weight: .regular, color: inkSoft)

        // Fit inside the remaining box on both axes, so a tall capture is
        // bounded by the height rather than running off the canvas.
        let availableTop = blockTop + blockHeight
        let box = CGRect(x: 150, y: availableTop,
                         width: canvas.width - 300,
                         height: canvas.height - availableTop - 95)
        let scale = min(box.width / home.content.width, box.height / home.content.height)
        let width = home.content.width * scale
        let height = home.content.height * scale
        place(home, content: CGRect(x: box.midX - width / 2, y: box.maxY - height,
                                    width: width, height: height),
              canvasHeight: canvas.height)
    }
    write(image, to: outDirectory.appendingPathComponent("hero.png"))
}

// The download button the README links to releases with. Drawn rather than
// screenshotted: there is no such button anywhere in the app.
do {
    let canvas = CGSize(width: 950, height: 184)
    let image = clearCanvas(Int(canvas.width), Int(canvas.height))
    withCanvas(image) {
        let pill = NSBezierPath(roundedRect: CGRect(x: 0, y: 0, width: canvas.width, height: canvas.height),
                                xRadius: canvas.height / 2, yRadius: canvas.height / 2)
        NSColor(srgbRed: 0.11, green: 0.11, blue: 0.13, alpha: 1).setFill()
        pill.fill()

        // The Apple logo is U+F8FF, a private-use glyph that only the system
        // font carries. Ask for it by name so a fallback font cannot silently
        // substitute an empty box.
        let logo = "\u{F8FF}" as NSString
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "SF Pro Text", size: 72) ?? NSFont.systemFont(ofSize: 72),
            .foregroundColor: NSColor.white,
        ]
        let label = "Download for macOS" as NSString
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 60, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let logoSize = logo.size(withAttributes: logoAttributes)
        let labelSize = label.size(withAttributes: labelAttributes)
        let gap: CGFloat = 34
        let startX = (canvas.width - (logoSize.width + gap + labelSize.width)) / 2
        logo.draw(at: NSPoint(x: startX, y: (canvas.height - logoSize.height) / 2 + 4),
                  withAttributes: logoAttributes)
        label.draw(at: NSPoint(x: startX + logoSize.width + gap, y: (canvas.height - labelSize.height) / 2),
                   withAttributes: labelAttributes)
    }
    write(image, to: outDirectory.appendingPathComponent("download.png"))
}

// The windows on the ground, centred in a fixed canvas. No frame drawn: these
// are windows already, and a frame around a frame reads as a mistake.
//
// The canvas is a constant rather than the capture's own size plus a margin.
// macOS draws a key window a wider drop shadow than an inactive one, and a
// capture carries that shadow as transparent margin, so sizing the canvas off
// the measured content meant the same three figures came out 2176 wide on one
// run and 2110 on the next. Fixing the canvas and centring inside it makes the
// output the same every time, and a shadow that is 33px wider just sits 33px
// further into the margin.
// 1920 rather than the capture's own 2176. The README draws these at 960, so
// 1920 is exactly the two-to-one a retina display asks for and the rest was
// 200KB per figure that nobody can see.
let figureCanvas = CGSize(width: 1920, height: 1659)
let figureMargin: CGFloat = 106
for name in ["modes", "vocabulary", "history"] {
    let capture = raw(name)
    let image = ground(Int(figureCanvas.width), Int(figureCanvas.height))
    withCanvas(image) {
        let box = CGRect(x: figureMargin, y: figureMargin,
                         width: figureCanvas.width - figureMargin * 2,
                         height: figureCanvas.height - figureMargin * 2)
        let scale = min(box.width / capture.content.width, box.height / capture.content.height)
        let width = capture.content.width * scale
        let height = capture.content.height * scale
        place(capture,
              content: CGRect(x: box.midX - width / 2, y: box.midY - height / 2,
                              width: width, height: height),
              canvasHeight: figureCanvas.height)
    }
    write(image, to: outDirectory.appendingPathComponent(name + ".png"))
}
