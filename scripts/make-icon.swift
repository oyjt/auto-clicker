import AppKit

// Reference-led mark: an open ring and cursor, in readable green on a light gray-white tile.
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
let tile = NSBezierPath(roundedRect: CGRect(x: 96, y: 96, width: 832, height: 832), xRadius: 184, yRadius: 184)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.14)
shadow.shadowBlurRadius = 22
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor(srgbRed: 0.96, green: 0.97, blue: 0.96, alpha: 1).setFill()
tile.fill()
NSShadow().set()

// Balance the complete mark optically, rather than centering the circle alone.
let alignment = NSAffineTransform()
alignment.translateX(by: 12, yBy: -12)
alignment.concat()

// Match the readable light-mode green used by the app.
let green = NSColor(srgbRed: 3 / 255, green: 125 / 255, blue: 62 / 255, alpha: 1)
let ring = NSBezierPath()
ring.appendArc(withCenter: CGPoint(x: 492, y: 546), radius: 214, startAngle: 0, endAngle: 244, clockwise: false)
green.setStroke()
ring.lineWidth = 32
ring.lineCapStyle = .round
ring.stroke()

let cursor = NSBezierPath()
cursor.move(to: CGPoint(x: 492, y: 554))
cursor.line(to: CGPoint(x: 492, y: 366))
cursor.line(to: CGPoint(x: 537, y: 412))
cursor.line(to: CGPoint(x: 578, y: 318))
cursor.line(to: CGPoint(x: 629, y: 341))
cursor.line(to: CGPoint(x: 587, y: 434))
cursor.line(to: CGPoint(x: 674, y: 434))
cursor.close()
green.setFill()
cursor.fill()
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
