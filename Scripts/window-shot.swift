import AppKit

/// Captures one app window to a file, and refuses to write a file that is not
/// that window.
///
/// Run as `swift Scripts/window-shot.swift <ownerName> <out.png> [--shadow]`.
///
/// `screencapture -l` sizes its output from `CGWindowListCopyWindowInfo`
/// bounds, and those are a stale stub rect for a freshly created window until
/// something makes the window server redraw it. Activating the app is what
/// refreshes them, so this activates, waits, reads the real frame through
/// Accessibility, and matches that against the window list to pick the number
/// to capture.
///
/// A region capture (`-R`) would be geometrically honest but photographs
/// whatever is on that patch of screen. It is not used: `-l` composites the one
/// window and can catch nothing else.
func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

guard CommandLine.arguments.count > 2 else {
    fail("usage: window-shot.swift <ownerName> <out.png> [--shadow]")
}
let owner = CommandLine.arguments[1]
let out = CommandLine.arguments[2]
/// Keeps the window's own drop shadow, which is what a page wants. The capture
/// then measures larger than the window by the shadow's margin, so the size
/// check below allows for that rather than demanding an exact match.
let keepsShadow = CommandLine.arguments.contains("--shadow")

guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == owner }) else {
    fail("no running app named \(owner)")
}
let element = AXUIElementCreateApplication(app.processIdentifier)

func attribute(_ element: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}

func frame(_ window: AXUIElement) -> CGRect {
    var origin = CGPoint.zero
    var size = CGSize.zero
    if let value = attribute(window, kAXPositionAttribute) { AXValueGetValue(value as! AXValue, .cgPoint, &origin) }
    if let value = attribute(window, kAXSizeAttribute) { AXValueGetValue(value as! AXValue, .cgSize, &size) }
    return CGRect(origin: origin, size: size)
}

/// The largest window wide enough to be the main window. Wave also puts up a
/// borderless overlay panel and the menu bar popover; neither is this.
func mainFrame() -> CGRect? {
    guard let windows = attribute(element, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
    return windows.map(frame).filter { $0.width >= 400 }
        .max { $0.width * $0.height < $1.width * $1.height }
}

func windowNumber(matching wanted: CGRect) -> Int? {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] ?? []
    for window in list where (window[kCGWindowOwnerName as String] as? String) == owner {
        guard (window[kCGWindowLayer as String] as? Int ?? -1) != 25,
              let bounds = window[kCGWindowBounds as String],
              let rect = CGRect(dictionaryRepresentation: bounds as! CFDictionary),
              abs(rect.width - wanted.width) <= 2, abs(rect.height - wanted.height) <= 2,
              let number = window[kCGWindowNumber as String] as? Int
        else { continue }
        return number
    }
    return nil
}

let scale = NSScreen.main?.backingScaleFactor ?? 2

for attempt in 1...3 {
    app.activate(options: [.activateAllWindows])
    // Park the pointer off the window first. SwiftUI paints a hover highlight
    // under wherever the cursor is sitting, and a row lit up for no reason is
    // the kind of thing a reader notices without being able to say why.
    CGWarpMouseCursorPosition(CGPoint(x: 4, y: 4))
    // Wait for the app to actually be frontmost, not just asked to be. macOS
    // draws a key window a wider drop shadow than an inactive one, so a
    // capture taken mid-activation comes back 66 pixels narrower and the run
    // stops being reproducible.
    for _ in 0..<40 where NSWorkspace.shared.frontmostApplication != app {
        usleep(50_000)
    }
    usleep(useconds_t(600_000 * attempt))
    guard let wanted = mainFrame() else {
        fail("no main window for \(owner); Accessibility permission may be missing for this terminal")
    }
    guard let number = windowNumber(matching: wanted) else { continue }

    let capture = Process()
    capture.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    capture.arguments = keepsShadow ? ["-x", "-l", "\(number)", out] : ["-x", "-o", "-l", "\(number)", out]
    try? capture.run()
    capture.waitUntilExit()

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: out)),
          let rep = NSBitmapImageRep(data: data) else { continue }
    let slack: CGFloat = keepsShadow ? 400 : 4
    if CGFloat(rep.pixelsWide) >= wanted.width * scale - 4,
       CGFloat(rep.pixelsWide) <= wanted.width * scale + slack,
       CGFloat(rep.pixelsHigh) >= wanted.height * scale - 4,
       CGFloat(rep.pixelsHigh) <= wanted.height * scale + slack {
        print(out)
        exit(0)
    }
    // The stale bounds case: the right window squeezed into the wrong size.
    // Deleted rather than left for someone to read as evidence.
    try? FileManager.default.removeItem(atPath: out)
}

fail("could not capture a file matching the \(owner) window; nothing written")
