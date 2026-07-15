import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// App Store icon: 1024x1024, opaque (NO alpha channel), full-bleed.
let N = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: N, height: N, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { exit(1) }
func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r/255), CGFloat(g/255), CGFloat(b/255), CGFloat(a)])!
}
let W = CGFloat(N)
// draw in y-DOWN coordinates (flip like UIKit)
ctx.translateBy(x: 0, y: W); ctx.scaleBy(x: 1, y: -1)

func fillEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: CGColor, out: CGColor? = nil, lw: CGFloat = 26) {
    ctx.addEllipse(in: CGRect(x: cx-rx, y: cy-ry, width: rx*2, height: ry*2)); ctx.setFillColor(c); ctx.fillPath()
    if let o = out { ctx.addEllipse(in: CGRect(x: cx-rx, y: cy-ry, width: rx*2, height: ry*2)); ctx.setStrokeColor(o); ctx.setLineWidth(lw); ctx.strokePath() }
}
let ink = rgb(22, 16, 30)
let body = rgb(138, 75, 214), bodyDk = rgb(122, 62, 198)
let face = rgb(255, 226, 34)
let fart = rgb(124, 255, 90)

// ---- background: radial purple ----
let bg = CGGradient(colorsSpace: cs, colors: [rgb(74, 42, 138), rgb(32, 17, 66)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(bg, startCenter: CGPoint(x: 512, y: 430), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 512), endRadius: 760, options: [.drawsAfterEndLocation])
// halftone dots
ctx.setFillColor(rgb(255, 61, 127, 0.16))
var yy: CGFloat = 40
while yy < W { var xx: CGFloat = 40; while xx < W { ctx.fillEllipse(in: CGRect(x: xx-9, y: yy-9, width: 18, height: 18)); xx += 64 }; yy += 64 }
// soft glow behind the monkey
let glow = CGGradient(colorsSpace: cs, colors: [rgb(176, 107, 255, 0.55), rgb(176, 107, 255, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 470), startRadius: 40, endCenter: CGPoint(x: 512, y: 470), endRadius: 470, options: [])

// ---- fart clouds (behind the monkey) ----
func puffCluster(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) {
    ctx.setShadowWithColor(offset: .zero, blur: 34, color: rgb(124, 255, 90, 0.9))
    for (dx, dy, r) in [(-1.0, 0.2, 1.0), (0.7, -0.3, 0.85), (0.1, 0.8, 0.7), (-0.6, 0.9, 0.6), (1.0, 0.6, 0.55)] {
        ctx.setFillColor(fart)
        ctx.fillEllipse(in: CGRect(x: cx + CGFloat(dx)*s*0.7 - s*CGFloat(r), y: cy + CGFloat(dy)*s*0.7 - s*CGFloat(r), width: s*CGFloat(r)*2, height: s*CGFloat(r)*2))
    }
    ctx.setShadowWithColor(offset: .zero, blur: 0, color: nil)
    // highlights
    ctx.setFillColor(rgb(190, 255, 160, 0.9))
    for (dx, dy, r) in [(-1.0, -0.1, 0.35), (0.6, -0.5, 0.28)] {
        ctx.fillEllipse(in: CGRect(x: cx + CGFloat(dx)*s*0.7 - s*CGFloat(r), y: cy + CGFloat(dy)*s*0.7 - s*CGFloat(r), width: s*CGFloat(r)*2, height: s*CGFloat(r)*2))
    }
}
puffCluster(770, 830, 95)
puffCluster(285, 855, 80)

// ---- banana (top-left accent) ----
ctx.saveGState()
ctx.translateBy(x: 250, y: 250); ctx.rotate(by: -0.7); ctx.scaleBy(x: 8.5, y: 8.5); ctx.translateBy(x: -10, y: -17)
let bp = CGMutablePath()
bp.move(to: CGPoint(x: 0, y: 0))
bp.addCurve(to: CGPoint(x: 21, y: 17), control1: CGPoint(x: 10, y: -2), control2: CGPoint(x: 20, y: 5))
bp.addCurve(to: CGPoint(x: 3, y: 35), control1: CGPoint(x: 22, y: 29), control2: CGPoint(x: 14, y: 36))
bp.addCurve(to: CGPoint(x: 11, y: 12), control1: CGPoint(x: 13, y: 29), control2: CGPoint(x: 15, y: 20))
bp.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 8, y: 6), control2: CGPoint(x: 4, y: 2))
bp.closeSubpath()
ctx.setShadowWithColor(offset: CGSize(width: 0, height: 3), blur: 3, color: rgb(0, 0, 0, 0.4))
ctx.addPath(bp); ctx.setFillColor(rgb(255, 226, 52)); ctx.fillPath()
ctx.setShadowWithColor(offset: .zero, blur: 0, color: nil)
ctx.addPath(bp); ctx.setStrokeColor(ink); ctx.setLineWidth(2.6); ctx.setLineJoin(.round); ctx.strokePath()
ctx.setFillColor(rgb(184, 134, 11)); ctx.fillEllipse(in: CGRect(x: 1, y: -1, width: 5, height: 5))
ctx.restoreGState()

// ---- monkey ----
// drop shadow behind head
ctx.setShadowWithColor(offset: CGSize(width: 0, height: 14), blur: 26, color: rgb(0, 0, 0, 0.4))
// ears
fillEllipse(212, 430, 120, 120, body, out: ink, lw: 26)
fillEllipse(812, 430, 120, 120, body, out: ink, lw: 26)
ctx.setShadowWithColor(offset: .zero, blur: 0, color: nil)
fillEllipse(212, 430, 62, 62, bodyDk)
fillEllipse(812, 430, 62, 62, bodyDk)
// head
ctx.setShadowWithColor(offset: CGSize(width: 0, height: 16), blur: 30, color: rgb(0, 0, 0, 0.45))
fillEllipse(512, 480, 300, 282, body, out: ink, lw: 28)
ctx.setShadowWithColor(offset: .zero, blur: 0, color: nil)
// face / muzzle
fillEllipse(512, 548, 210, 182, face, out: ink, lw: 22)
// cheek highlight
ctx.setFillColor(rgb(255, 255, 255, 0.22)); ctx.fillEllipse(in: CGRect(x: 360, y: 300, width: 150, height: 90))
// eyes
func eye(_ cx: CGFloat, _ cy: CGFloat) {
    fillEllipse(cx, cy, 86, 92, rgb(255, 255, 255), out: ink, lw: 16)
    fillEllipse(cx + 10, cy + 20, 40, 44, ink)           // pupil (looking down-cheeky)
    ctx.setFillColor(rgb(255, 255, 255)); ctx.fillEllipse(in: CGRect(x: cx - 14, y: cy - 6, width: 26, height: 26)) // glint
}
eye(410, 452); eye(614, 452)
// brows (raised, mischievous)
ctx.setStrokeColor(ink); ctx.setLineWidth(26); ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: 320, y: 356)); ctx.addQuadCurve(to: CGPoint(x: 470, y: 342), control: CGPoint(x: 395, y: 318)); ctx.strokePath()
ctx.move(to: CGPoint(x: 704, y: 356)); ctx.addQuadCurve(to: CGPoint(x: 554, y: 342), control: CGPoint(x: 629, y: 318)); ctx.strokePath()
// nostrils
ctx.setFillColor(rgb(120, 70, 20)); ctx.fillEllipse(in: CGRect(x: 470, y: 556, width: 26, height: 34)); ctx.fillEllipse(in: CGRect(x: 528, y: 556, width: 26, height: 34))
// grin (open, cheeky)
let mp = CGMutablePath()
mp.move(to: CGPoint(x: 402, y: 612))
mp.addQuadCurve(to: CGPoint(x: 512, y: 628), control: CGPoint(x: 457, y: 636))
mp.addQuadCurve(to: CGPoint(x: 622, y: 612), control: CGPoint(x: 567, y: 636))
mp.addQuadCurve(to: CGPoint(x: 512, y: 726), control: CGPoint(x: 590, y: 726))
mp.addQuadCurve(to: CGPoint(x: 402, y: 612), control: CGPoint(x: 434, y: 726))
mp.closeSubpath()
ctx.addPath(mp); ctx.setFillColor(rgb(42, 15, 34)); ctx.fillPath()
ctx.addPath(mp); ctx.setStrokeColor(ink); ctx.setLineWidth(14); ctx.setLineJoin(.round); ctx.strokePath()
// teeth
ctx.setFillColor(rgb(255, 255, 255))
let teeth = CGPath(roundedRect: CGRect(x: 430, y: 606, width: 164, height: 34), cornerWidth: 12, cornerHeight: 12, transform: nil)
ctx.addPath(teeth); ctx.fillPath()
// tongue
ctx.setFillColor(rgb(255, 107, 154)); ctx.fillEllipse(in: CGRect(x: 456, y: 668, width: 112, height: 60))

// subtle edge vignette
let vig = CGGradient(colorsSpace: cs, colors: [rgb(0, 0, 0, 0), rgb(0, 0, 0, 0.28)] as CFArray, locations: [0.62, 1])!
ctx.drawRadialGradient(vig, startCenter: CGPoint(x: 512, y: 512), startRadius: 120, endCenter: CGPoint(x: 512, y: 512), endRadius: 760, options: [.drawsAfterEndLocation])

guard let img = ctx.makeImage() else { exit(1) }
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outURL.path)")

extension CGContext {
    func setShadowWithColor(offset: CGSize, blur: CGFloat, color: CGColor?) {
        if let c = color { setShadow(offset: offset, blur: blur, color: c) } else { setShadow(offset: .zero, blur: 0, color: nil) }
    }
}
