// Usage: make-icon <out.png> [simple] [pixels]   -- draws the 1024px Daily Log icon (docs/DESIGN_SYSTEM.md section 9).
// "simple" omits the ruled lines and sheet shadow (for pixel sizes <= 64).
import Foundation
import CoreGraphics
import ImageIO

let args = CommandLine.arguments
guard args.count >= 2 else { print("usage: make-icon out.png [simple]"); exit(1) }
let simple = args.count > 2 && args[2] == "simple"
let S: CGFloat = 1024
let px = args.count > 3 ? Int(args[3]) ?? 1024 : 1024

func col(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: a)
}
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                    space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
ctx.setAllowsAntialiasing(true); ctx.interpolationQuality = .high

// Brief coordinates are top-left origin; CG is bottom-left, so convert y.
func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
    CGPath(roundedRect: CGRect(x: x, y: S - y - h, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)
}
func Y(_ y: CGFloat) -> CGFloat { S - y }

func fill(_ p: CGPath, _ c: CGColor, shadowY: CGFloat = 0, blur: CGFloat = 0, shadow: CGColor? = nil) {
    ctx.saveGState()
    if let s = shadow { ctx.setShadow(offset: CGSize(width: 0, height: -shadowY), blur: blur, color: s) }
    ctx.addPath(p); ctx.setFillColor(c); ctx.fillPath()
    ctx.restoreGState()
}

// Plate: shadow pass, then gradient fill clipped to the plate.
let plate = rr(100, 100, 824, 824, 185)
fill(plate, col(0x1B4A3E), shadowY: 12, blur: 24, shadow: col(0, 0.28))
ctx.saveGState()
ctx.addPath(plate); ctx.clip()
let grad = CGGradient(colorsSpace: cs, colors: [col(0x1B4A3E), col(0x102E27)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: Y(100)), end: CGPoint(x: 0, y: Y(924)), options: [])
ctx.restoreGState()

// Top light: thin inner stroke along the top half.
ctx.saveGState()
ctx.addPath(plate); ctx.clip()
ctx.clip(to: CGRect(x: 0, y: Y(512), width: S, height: 412))
ctx.addPath(rr(101, 101, 822, 822, 184)); ctx.setStrokeColor(col(0xFFFFFF, 0.14)); ctx.setLineWidth(2); ctx.strokePath()
ctx.restoreGState()

// Paper sheet
fill(rr(272, 232, 480, 560, 36), col(0xF6F8F6),
     shadowY: simple ? 0 : 8, blur: simple ? 0 : 20, shadow: simple ? nil : col(0, 0.25))
if !simple {
    for (w, y) in [(380.0, 320.0), (300, 404), (160, 488)] as [(CGFloat, CGFloat)] {
        fill(rr(336, y, w, 36, 18), col(0xCBD6D0))
    }
}

// Check badge + mark
ctx.setFillColor(col(0x45C29C))
ctx.fillEllipse(in: CGRect(x: 624 - 116, y: Y(656) - 116, width: 232, height: 232))
ctx.setStrokeColor(col(0x0B2A22)); ctx.setLineWidth(40); ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.move(to: CGPoint(x: 570, y: Y(660))); ctx.addLine(to: CGPoint(x: 608, y: Y(700))); ctx.addLine(to: CGPoint(x: 682, y: Y(608)))
ctx.strokePath()

let url = URL(fileURLWithPath: args[1]) as CFURL
let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
var out = ctx.makeImage()!
if px != 1024 { // downscale with high-quality interpolation
    let c2 = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                       space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c2.interpolationQuality = .high
    c2.draw(out, in: CGRect(x: 0, y: 0, width: px, height: px))
    out = c2.makeImage()!
}
CGImageDestinationAddImage(dest, out, nil)
guard CGImageDestinationFinalize(dest) else { print("write failed"); exit(1) }
