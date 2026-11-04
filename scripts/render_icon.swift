// Renders the 1024×1024 app icon with Core Graphics (no external dependencies).
// Usage: swift scripts/render_icon.swift <output.png>
import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

let side = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}

let inkBlue = color(0.10, 0.45, 0.94)      // #1A73F0
let deepBlue = color(0.04, 0.22, 0.62)     // #0A389E
let cream = color(0.980, 0.969, 0.953)     // #FAF7F2

guard let ctx = CGContext(
    data: nil,
    width: side,
    height: side,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("cannot create context") }

// Work in top-left origin coordinates.
ctx.translateBy(x: 0, y: CGFloat(side))
ctx.scaleBy(x: 1, y: -1)

// MARK: Background gradient
let bg = CGGradient(colorsSpace: space, colors: [inkBlue, deepBlue] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: CGFloat(side), y: CGFloat(side)), options: [])
ctx.restoreGState()

// MARK: Soft radial glow behind the mark
let glow = CGGradient(
    colorsSpace: space,
    colors: [color(1, 1, 1, 0.18), color(1, 1, 1, 0)] as CFArray,
    locations: [0, 1]
)!
ctx.saveGState()
ctx.drawRadialGradient(
    glow,
    startCenter: CGPoint(x: 420, y: 330), startRadius: 0,
    endCenter: CGPoint(x: 420, y: 330), endRadius: 640,
    options: [.drawsAfterEndLocation]
)
ctx.restoreGState()

// MARK: Mark geometry — speech bubble + speed streaks
let bubble = CGRect(x: 330, y: 240, width: 570, height: 400)
let bubblePath = CGMutablePath()
bubblePath.addRoundedRect(in: bubble, cornerWidth: 130, cornerHeight: 130, transform: .identity)

// Tail: a rounded wedge hanging from the bubble's bottom-left. Its base sits
// inside the bubble so the two shapes merge without a seam.
let tail = CGMutablePath()
tail.move(to: CGPoint(x: 488, y: 600))
tail.addLine(to: CGPoint(x: 470, y: 716))
tail.addQuadCurve(to: CGPoint(x: 540, y: 686), control: CGPoint(x: 488, y: 728))
tail.addLine(to: CGPoint(x: 612, y: 600))
tail.closeSubpath()

let streaks: [(CGFloat, CGFloat, CGFloat)] = [   // (startX, endX, centerY)
    (150, 268, 322),
    (150, 306, 440),
    (150, 246, 558),
]

// MARK: Drop shadow for the mark
if let shadow = ctx.makeImage() {
    let mask = CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8,
        bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    mask.translateBy(x: 0, y: CGFloat(side))
    mask.scaleBy(x: 1, y: -1)
    mask.setFillColor(color(0, 0, 0, 0.9))
    mask.addPath(tail)
    mask.fillPath()
    mask.addPath(bubblePath)
    mask.fillPath()
    mask.setStrokeColor(color(0, 0, 0, 0.9))
    mask.setLineCap(.round)
    mask.setLineWidth(48)
    for (startX, endX, y) in streaks {
        mask.move(to: CGPoint(x: startX, y: y))
        mask.addLine(to: CGPoint(x: endX, y: y))
    }
    mask.strokePath()

    if let maskImage = mask.makeImage() {
        let blurred = CIImage(cgImage: maskImage)
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 26])
            .transformed(by: CGAffineTransform(translationX: 0, y: -22))
        if let out = CIContext().createCGImage(blurred, from: CGRect(x: 0, y: 0, width: side, height: side)) {
            ctx.saveGState()
            ctx.setAlpha(0.26)
            ctx.draw(out, in: CGRect(x: 0, y: 0, width: side, height: side))
            ctx.restoreGState()
        }
    }
    _ = shadow
}

// MARK: Fill the mark
ctx.setFillColor(cream)
ctx.addPath(tail)
ctx.fillPath()
ctx.addPath(bubblePath)
ctx.fillPath()

ctx.setStrokeColor(cream)
ctx.setLineCap(.round)
ctx.setLineWidth(48)
for (startX, endX, y) in streaks {
    ctx.move(to: CGPoint(x: startX, y: y))
    ctx.addLine(to: CGPoint(x: endX, y: y))
}
ctx.strokePath()

// MARK: Write PNG
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon-1024.png"
let url = URL(fileURLWithPath: outPath)
guard let image = ctx.makeImage(),
      let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("cannot write \(outPath)")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("finalize failed") }
print("wrote \(outPath)")
