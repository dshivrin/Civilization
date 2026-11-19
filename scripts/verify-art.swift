import Foundation
import ImageIO
import CoreGraphics

// Offline native validation of every shipped sprite, alpha and theoretical decoded budget.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let data = try Data(contentsOf: root.appendingPathComponent("Packages/GameCore/Sources/GameApplication/Resources/art-catalog.json"))
let catalog = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let buildings = catalog["buildings"] as! [[String: Any]]
var failures: [String] = []
var decoded = 0
for building in buildings {
    let id = building["id"] as! String
    for (key, limit) in [("file", 512), ("thumbnail", 144)] {
        let file = root.appendingPathComponent("Civilization/Art").appendingPathComponent(building[key] as! String)
        guard let source = CGImageSourceCreateWithURL(file as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { failures.append("Missing/invalid \(id) \(key)"); continue }
        if image.width > limit || image.height > limit { failures.append("Oversized \(id) \(key)") }
        let width=image.width, height=image.height
        var pixels=[UInt8](repeating: 0,count:width*height*4)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context=CGContext(data:buffer.baseAddress,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else{return false}
            context.draw(image,in:CGRect(x:0,y:0,width:width,height:height));return true
        }
        if !rendered { failures.append("Cannot inspect \(id)"); continue }
        let alpha = stride(from:3,to:pixels.count,by:4).map { pixels[$0] }
        if !alpha.contains(0) || !alpha.contains(where: {$0 > 220}) { failures.append("No genuine transparent/opaque content \(id) \(key)") }
        let covered=alpha.filter { $0 > 32 }.count
        if covered < width*height/30 || covered > width*height*9/10 { failures.append("Implausible alpha coverage \(id) \(key)") }
        decoded += width*height*4
        print("\(id) \(key): \(width)x\(height), alpha coverage \(covered*100/(width*height))%")
    }
}
print("Theoretical RGBA image pixels (sprites+thumbnails): \(decoded/1024/1024) MiB; excludes GPU copies/mipmaps/cache/terrain")
if decoded > 24*1024*1024 { failures.append("Sprite+thumbnail pixel budget exceeds 24 MiB") }
if !failures.isEmpty { for failure in failures { fputs("FAIL: \(failure)\n",stderr) };exit(1) }
print("PASS: complete \(buildings.count)-building sprite/thumbnail catalog")
