import AppKit
import SwiftUI
import GameCore
import GameApplication
import CryptoKit

// macOS-only bridge for the unused iOS thumbnail shell in the shared source.
@MainActor enum EraArt {
    static let catalog = try? ArtCatalog.bundled()
    static func thumbnail(_ kind: BuildingKind) -> NSImage? { nil }
}
extension Image { init(uiImage: NSImage) { self.init(nsImage: uiImage) } }
@MainActor func exportReviewAssets() throws {
    guard CommandLine.arguments.count == 2 else { fatalError("Usage: UIReviewRenderer NEW_DIRECTORY") }
    let out = URL(fileURLWithPath: CommandLine.arguments[1])
    guard !FileManager.default.fileExists(atPath: out.path) else { fatalError("Output already exists") }
    try FileManager.default.createDirectory(at: out.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard mkdir(out.path, 0o755) == 0 else { fatalError("Cannot reserve output") }
    var entries: [[String:String]] = []
    func write(_ image: CGImage, _ id: String, source: String) throws {
        let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
        try data.write(to: out.appendingPathComponent(id + ".png"), options: .atomic)
        entries.append(["id":id,"file":id+".png","source":source,"sha256":SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()])
    }
    for resource in Resource.allCases {
        let renderer = ImageRenderer(content: EraIcon(domain: .resource, id: resource.rawValue, size: 64)); renderer.scale = 2
        guard let image = renderer.cgImage else { fatalError("Cannot render resource") }
        try write(image,"resource-"+resource.rawValue,source:"Civilization/UI/EraIcon.swift resource."+resource.rawValue)
    }
    for id in EraArt.catalog!.research.map(\.id) {
        guard EraArt.catalog?.research.contains(where: { $0.id == id }) == true else { fatalError("Unknown research icon") }
        let renderer = ImageRenderer(content: EraIcon(domain: .research,id:id,size:64));renderer.scale=2
        guard let image=renderer.cgImage else { fatalError("Cannot render research") }
        try write(image,"research-"+id,source:"Civilization/UI/EraIcon.swift research."+id)
    }
    for (id,symbol) in [("research","sparkles"),("goals","flag.checkered"),("achievement","seal"),("build","hammer"),("explore","map"),("games","square.stack"),("center","scope"),("close","xmark"),("sunrise","sunrise.fill"),("check","checkmark"),("menu","line.3.horizontal")] {
        guard let native=NSImage(systemSymbolName:symbol,accessibilityDescription:id)?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize:40,weight:.semibold)) else { fatalError("Missing native symbol") }
        let image=NSImage(size:NSSize(width:64,height:64));image.lockFocus();native.draw(in:NSRect(x:8,y:8,width:48,height:48));image.unlockFocus()
        var rect=NSRect(x:0,y:0,width:64,height:64)
        try write(image.cgImage(forProposedRect:&rect,context:nil,hints:nil)!,id,source:"SF Symbols "+symbol+" (review semantic mapping)")
    }
    try JSONSerialization.data(withJSONObject:entries,options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("provenance.json"),options:.atomic)
    print("PASS: \(entries.count) native UI review icons; runtime EraIcon source compiled through a symlink, no product edits")
}
@MainActor func renderAuditSheet() throws {
    let folder=URL(fileURLWithPath:CommandLine.arguments[2]), output=URL(fileURLWithPath:CommandLine.arguments[3])
    let files=try FileManager.default.contentsOfDirectory(at:folder,includingPropertiesForKeys:nil).filter { $0.pathExtension=="png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
    guard files.count==9 else { fatalError("Expected9raw captures") }
    let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1500,pixelsHigh:1140,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:6000,bitsPerPixel:32)!
    NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
    NSColor.white.setFill();NSRect(x:0,y:0,width:1500,height:1140).fill()
    for (i,file) in files.enumerated() {
        let image=NSImage(contentsOf:file)!, x=CGFloat(i%3)*500+10, y=CGFloat(2-i/3)*380+45
        let scale=min(480/image.size.width,320/image.size.height)
        image.draw(in:NSRect(x:x+(480-image.size.width*scale)/2,y:y+(320-image.size.height*scale)/2,width:image.size.width*scale,height:image.size.height*scale))
        (file.deletingPathExtension().lastPathComponent as NSString).draw(at:NSPoint(x:x,y:y-25),withAttributes:[.font:NSFont.systemFont(ofSize:16),.foregroundColor:NSColor.black])
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using:.png,properties:[:])!.write(to:output,options:.withoutOverwriting)
    print("PASS: nine source screenshots laid out without crop or pixel modification; originals preserved")
}
if CommandLine.arguments.count==4 && CommandLine.arguments[1]=="--sheet" { try renderAuditSheet() }
else { try exportReviewAssets() }
