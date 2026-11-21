// Original temporary sunrise/horizon mark. No external image inputs or fonts.
// Regenerate with: swift scripts/render-temporary-app-icon.swift
import AppKit
import Foundation
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let directory = root.appendingPathComponent("Civilization/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
let size = 1024
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { CGColor(red: r, green: g, blue: b, alpha: 1) }
context.setFillColor(color(0.14, 0.23, 0.25)); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
let gold = color(0.96, 0.76, 0.39)
context.saveGState(); context.clip(to: CGRect(x: 0, y: 442, width: 1024, height: 582))
context.setFillColor(gold); context.fillEllipse(in: CGRect(x: 278, y: 228, width: 468, height: 468)); context.restoreGState()
context.setStrokeColor(gold); context.setLineCap(.round)
for angle in [30.0, 60.0, 90.0, 120.0, 150.0] {
    let a = angle * .pi / 180
    context.setLineWidth(24); context.move(to: CGPoint(x: 512 + cos(a)*292, y: 462 + sin(a)*292))
    context.addLine(to: CGPoint(x: 512 + cos(a)*348, y: 462 + sin(a)*348)); context.strokePath()
}
for (y, width) in [(442.0, 700.0), (358.0, 480.0), (282.0, 250.0)] {
    context.setLineWidth(y == 442 ? 30 : 20)
    context.move(to: CGPoint(x: (1024-width)/2, y: y)); context.addLine(to: CGPoint(x: (1024+width)/2, y: y)); context.strokePath()
}
let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: directory.appendingPathComponent("sunrise-1024.png"))
let contents: [String: Any] = ["images": [["filename": "sunrise-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]], "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("Contents.json"))
print(directory.path)
