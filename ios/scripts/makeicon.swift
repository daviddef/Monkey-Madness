import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let N = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: N, height: N, bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [CGFloat(r/255), CGFloat(g/255), CGFloat(b/255), CGFloat(a)])!
}
let W = CGFloat(N)
// background gradient purple
let grad = CGGradient(colorsSpace: cs, colors: [rgb(58,25,110), rgb(28,12,70)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: W), end: CGPoint(x: W, y: 0), options: [])
// halftone dots
ctx.setFillColor(rgb(255,61,127,0.5))
var y: CGFloat = 40
while y < W { var x: CGFloat = 40; while x < W { ctx.fillEllipse(in: CGRect(x: x-9, y: y-9, width: 18, height: 18)); x += 90 }; y += 90 }
// fart puff
ctx.setFillColor(rgb(124,255,90,0.9))
for (dx, dy, r) in [(-60.0, -40.0, 150.0), (90.0, -10.0, 120.0), (10.0, 90.0, 110.0)] {
    ctx.fillEllipse(in: CGRect(x: W/2 + CGFloat(dx) - CGFloat(r), y: W/2 + CGFloat(dy) - CGFloat(r), width: CGFloat(r*2), height: CGFloat(r*2)))
}
// banana (scaled bezier), yellow with dark outline
ctx.saveGState()
ctx.translateBy(x: W/2, y: W/2); ctx.rotate(by: -0.5); ctx.scaleBy(x: 15, y: 15); ctx.translateBy(x: -10, y: -17)
let p = CGMutablePath()
p.move(to: CGPoint(x: 0, y: 0))
p.addCurve(to: CGPoint(x: 21, y: 17), control1: CGPoint(x: 10, y: -2), control2: CGPoint(x: 20, y: 5))
p.addCurve(to: CGPoint(x: 3, y: 35), control1: CGPoint(x: 22, y: 29), control2: CGPoint(x: 14, y: 36))
p.addCurve(to: CGPoint(x: 11, y: 12), control1: CGPoint(x: 13, y: 29), control2: CGPoint(x: 15, y: 20))
p.addCurve(to: CGPoint(x: 0, y: 0), control1: CGPoint(x: 8, y: 6), control2: CGPoint(x: 4, y: 2))
p.closeSubpath()
ctx.addPath(p); ctx.setFillColor(rgb(255,226,52)); ctx.fillPath()
ctx.addPath(p); ctx.setStrokeColor(rgb(20,20,16)); ctx.setLineWidth(2.4); ctx.setLineJoin(.round); ctx.strokePath()
ctx.restoreGState()

guard let img = ctx.makeImage() else { exit(1) }
let outURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(outURL.path)")
