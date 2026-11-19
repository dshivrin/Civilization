import UIKit
import SwiftUI
import SpriteKit
import ImageIO
import GameApplication
import GameCore

/// On-demand downsampled images/textures. All files are visual-only and safely replaceable.
@MainActor enum EraArt {
    static let catalog: ArtCatalog? = {
        guard let value = try? ArtCatalog.bundled(), let config = try? GameConfiguration.bundled(),
              (try? value.validate(configuration: config)) != nil else { return nil }
        return value
    }()
    private static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>(); cache.totalCostLimit = 32 * 1024 * 1024; return cache
    }()
    private static var textures: [String: SKTexture] = [:]
    private static var masks: [String: SpriteAlphaMask] = [:]
    static func image(_ relativePath: String, maximumPixels: Int = 512) -> UIImage? {
        guard !relativePath.contains(".."), !relativePath.hasPrefix("/") else { return nil }
        let key = (relativePath + "-\(maximumPixels)") as NSString
        if let image = images.object(forKey: key) { return image }
        guard let root = Bundle.main.resourceURL?.appendingPathComponent("Art"),
              let source = CGImageSourceCreateWithURL(root.appendingPathComponent(relativePath) as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: maximumPixels, kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        images.setObject(image, forKey: key, cost: cg.width * cg.height * 4)
        return image
    }
    static func thumbnail(_ kind: BuildingKind) -> UIImage? {
        guard let visual = catalog?.building(kind) else { return nil }
        return image(visual.thumbnail, maximumPixels: 144) ?? image(visual.file, maximumPixels: 144)
    }
    static func resourceTexture(_ resource: Resource) -> SKTexture? {
        let key = "resource-" + resource.rawValue
        if let texture = textures[key] { return texture }
        let renderer = ImageRenderer(content: EraIcon(domain: .resource, id: resource.rawValue, size: 30))
        renderer.scale = 2
        guard let image = renderer.uiImage else { return nil }
        let texture = SKTexture(image: image);textures[key] = texture;return texture
    }
    static func texture(_ kind: BuildingKind) -> SKTexture? {
        if let texture = textures[kind.rawValue] { return texture }
        guard let visual = catalog?.building(kind), let image = image(visual.file) else { return nil }
        let texture = SKTexture(image: image); texture.filteringMode = .linear
        textures[kind.rawValue] = texture
        return texture
    }
    static func contains(_ kind: BuildingKind, point: CGPoint) -> Bool {
        guard let visual = catalog?.building(kind) else { return true }
        if masks[kind.rawValue] == nil, let cg = image(visual.file, maximumPixels: 64)?.cgImage {
            var rgba = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
            let made = rgba.withUnsafeMutableBytes { buffer -> Bool in
                guard let context = CGContext(data: buffer.baseAddress, width: cg.width, height: cg.height, bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height)); return true
            }
            if made { masks[kind.rawValue] = try? SpriteAlphaMask(width: cg.width, height: cg.height, alpha: stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }) }
        }
        guard let mask = masks[kind.rawValue] else { return true }
        return mask.contains(normalizedX: point.x / visual.worldWidth + visual.anchorX,
                             normalizedY: 1 - (point.y / visual.worldHeight + visual.anchorY))
    }
}
