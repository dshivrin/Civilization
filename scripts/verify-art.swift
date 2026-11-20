import Foundation
import ImageIO
import CoreGraphics
import CryptoKit
import Darwin

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

// Optional read-only Gate 1 evidence. A fresh output directory prevents overwriting prior reviews.
let args = Array(CommandLine.arguments.dropFirst())
if !args.isEmpty {
    guard args.count == 4, args[0] == "--audit-output", args[2] == "--media-root" else {
        fatalError("Usage: swift scripts/verify-art.swift [--audit-output NEW_DIR --media-root MEDIA_DIR]")
    }
    // Foundation may leave parent symlinks unresolved when the leaf does not exist.
    func resolveFuturePath(_ url: URL) -> URL {
        var existing = url.standardizedFileURL, tail: [String] = []
        while !FileManager.default.fileExists(atPath: existing.path) && existing.path != "/" {
            tail.insert(existing.lastPathComponent, at: 0); existing.deleteLastPathComponent()
        }
        return tail.reduce(existing.resolvingSymlinksInPath()) { $0.appendingPathComponent($1) }
    }
    let output = resolveFuturePath(URL(fileURLWithPath: args[1]))
    let media = URL(fileURLWithPath: args[3]).standardizedFileURL.resolvingSymlinksInPath()
    guard output.path != media.path, !output.path.hasPrefix(media.path + "/") else { fatalError("Audit output must be outside the read-only media repository") }
    guard !FileManager.default.fileExists(atPath: output.path) else { fatalError("Audit output already exists") }
    func hash(_ url: URL) throws -> String { try SHA256.hash(data: Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined() }
    func measure(_ url: URL) throws -> [String: Any] {
        let bytes = try Data(contentsOf: url)
        guard let source = CGImageSourceCreateWithData(bytes as CFData, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("Invalid PNG: \(url.path)") }
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: w*h*4)
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            // CGImage decode into this bitmap preserves top-left PNG row order.
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h)); return true
        }
        guard rendered else { fatalError("Cannot measure \(url.path)") }
        var minX=w, minY=h, maxX = -1, maxY = -1, covered=0, clear=0, edge=0
        for y in 0..<h { for x in 0..<w {
            let a = pixels[(y*w+x)*4+3]
            if a == 0 { clear += 1 }
            if a > 32 {
                covered += 1; minX=min(minX,x); minY=min(minY,y); maxX=max(maxX,x); maxY=max(maxY,y)
                if x == 0 || y == 0 || x == w-1 || y == h-1 { edge += 1 }
            }
        } }
        guard covered > 0, clear > 0 else { fatalError("Missing alpha content: \(url.path)") }
        return ["width":w,"height":h,"bytes":bytes.count,"sha256":try hash(url),"alphaThreshold":32,
                "silhouetteBoundsTopLeftInclusive":[minX,minY,maxX,maxY],"coveredFraction":Double(covered)/Double(w*h),
                "transparentFraction":Double(clear)/Double(w*h),"coveredEdgePixels":edge]
    }
    // A 2×2 PNG with only its top-left pixel opaque pins the coordinate contract.
    let fixtureURL = FileManager.default.temporaryDirectory.appendingPathComponent("art-alpha-" + UUID().uuidString + ".png")
    defer { try? FileManager.default.removeItem(at: fixtureURL) }
    try Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAD0lEQVR4nGP4z8AAREgAAB7zAf9qN12tAAAAAElFTkSuQmCC")!.write(to: fixtureURL)
    let fixture = try measure(fixtureURL)
    guard fixture["silhouetteBoundsTopLeftInclusive"] as? [Int] == [0,0,0,0] else { fatalError("Top-left alpha-bound regression") }
    let configURL = root.appendingPathComponent("Packages/GameCore/Sources/GameCore/Resources/seed.json")
    let config = try JSONSerialization.jsonObject(with: Data(contentsOf: configURL)) as! [String:Any]
    let definitions = config["buildings"] as! [[String:Any]]
    let registryURL = media.appendingPathComponent("registry/asset-registry.json")
    let registry = try JSONSerialization.jsonObject(with: Data(contentsOf: registryURL)) as! [String:Any]
    let assets = registry["assets"] as! [[String:Any]]
    guard buildings.count == 20, Set(buildings.map { $0["id"] as! String }) == Set(definitions.map { $0["kind"] as! String }) else { fatalError("Catalog mismatch") }
    var records: [[String:Any]] = [], cards = ""
    for art in buildings {
        let id = art["id"] as! String
        let definition = definitions.first { $0["kind"] as? String == id }!
        let masters = assets.filter { $0["id"] as? String == "building.\(id).master" }
        guard masters.count == 1 else { fatalError("Missing/duplicate master \(id)") }
        let master = masters[0], relative = master["file"] as! String
        let masterURL = media.appendingPathComponent(relative), sourceURL = root.appendingPathComponent("docs/art/sources/buildings/\(id).png")
        let spriteURL = root.appendingPathComponent("Civilization/Art").appendingPathComponent(art["file"] as! String)
        let thumbURL = root.appendingPathComponent("Civilization/Art").appendingPathComponent(art["thumbnail"] as! String)
        let masterMetrics = try measure(masterURL), spriteMetrics = try measure(spriteURL), thumbMetrics = try measure(thumbURL)
        guard try hash(sourceURL) == masterMetrics["sha256"] as? String,
              master["sha256"] as? String == masterMetrics["sha256"] as? String else { fatalError("Master/source/registry mismatch \(id)") }
        for (role, url) in [("world",spriteURL),("thumbnail",thumbURL)] {
            let relativeExport = role == "world" ? "runtime-exports/\(art["file"] as! String)" : "runtime-exports/\(art["thumbnail"] as! String)"
            let matches = assets.filter { $0["id"] as? String == "building.\(id).\(role)" }
            guard matches.count == 1, let source = matches[0]["source"] as? [String:Any],
                  matches[0]["derivedFrom"] as? String == "building.\(id).master",
                  matches[0]["file"] as? String == relativeExport,
                  let digest = matches[0]["sha256"] as? String,
                  source["sha256"] as? String == digest,
                  try hash(media.appendingPathComponent(relativeExport)) == digest,
                  try hash(url) == digest else { fatalError("Per-kind media export linkage mismatch \(id) \(role)") }
        }
        let w = definition["width"] as! Int, h = definition["height"] as! Int
        let ww = art["worldWidth"] as! Double, wh = art["worldHeight"] as! Double
        let ax = art["anchorX"] as! Double, ay = art["anchorY"] as! Double
        let record: [String:Any] = ["id":id,"masterAssetID":master["id"]!,"masterFile":relative,"licenseID":master["licenseID"]!,
            "master":masterMetrics,"sprite":spriteMetrics,"thumbnail":thumbMetrics,"footprint":[w,h],"art":art,
            "orientations":definition["allowedOrientations"] ?? ["north"],"maximumLevel":(config["economyRules"] as! [String:Any])["maximumUpgradeLevel"]!,
            "requiresResearch":definition["requiresResearch"]!,"contactMaskStatus":"missing-semantic-ground-mask",
            "directionalAndLevelExports":"one-kind-sprite-reused-for-all-levels-and-directions"]
        records.append(record)
        let points = "\(16*(h-w)),\(-8*(w+h)) \(16*(w+h)),\(8*(w-h)) \(16*(w-h)),\(8*(w+h)) \(-16*(w+h)),\(8*(h-w))"
        let encoded = try Data(contentsOf: spriteURL).base64EncodedString()
        cards += "<article><h2>\(id)</h2><svg viewBox='-100 -155 200 210' role='img' aria-label='\(id) actual runtime scale and footprint'><image x='\(-ax*ww)' y='\(-(1-ay)*wh)' width='\(ww)' height='\(wh)' href='data:image/png;base64,\(encoded)'/><polygon points='\(points)'/><path d='M-5 0H5M0 -5V5'/></svg><p>\(w)×\(h) · sprite \(Int(ww))×\(Int(wh))<br>Anchor \(ax), \(ay) · L1–L3 share art</p></article>"
    }
    let map = config["map"] as! [String:Any], rows = (map["rows"] as! [String]).map(Array.init)
    let mw = map["width"] as! Int, mh = map["height"] as! Int
    let directions = [(0,-1,"N"),(1,0,"E"),(0,1,"S"),(-1,0,"W")]
    var edges: [[String:Any]] = []
    for y in 0..<mh { for x in 0..<mw where rows[y][x] == "w" {
        for (dx,dy,name) in directions where (0..<mw).contains(x+dx) && (0..<mh).contains(y+dy) && rows[y+dy][x+dx] != "w" {
            edges.append(["water":[x,y],"land":[x+dx,y+dy],"waterToLand":name,"landTerrain":String(rows[y+dy][x+dx])])
        }
    } }
    // Named review fixtures use actual Riverbend land; they do not place buildings or alter discovery.
    let fixtureOrigins = [("west-bank",19,8),("east-bank",23,8),("bend",21,1),("annex-west",50,28),("annex-east",54,28),("horizontal-north",35,22),("horizontal-south",35,26)]
    var fixtures: [[String:Any]] = []
    for (name,x,y) in fixtureOrigins {
        guard (0..<mw-1).contains(x), (0..<mh-1).contains(y), (0..<2).allSatisfy({ dy in (0..<2).allSatisfy { dx in rows[y+dy][x+dx] == "." || rows[y+dy][x+dx] == "c" } }) else { fatalError("River fixture no longer matches actual map: \(name)") }
        let contacts = edges.filter { edge in let land = edge["land"] as! [Int]; return (x...x+1).contains(land[0]) && (y...y+1).contains(land[1]) }
        guard !contacts.isEmpty else { fatalError("River fixture has no bank contact: \(name)") }
        fixtures.append(["id":name,"origin":[x,y],"footprint":[2,2],"bankEdges":contacts,"discovery":"assume revealed for visual fixture only","occupancy":"terrain-only; no live save inspected"])
    }
    let river: [String:Any] = ["mapID":map["id"]!,"size":[mw,mh],"configSHA256":try hash(configURL),"directions":"logical N=(0,-1), E=(1,0), S=(0,1), W=(-1,0); not screen compass","bankEdges":edges,"fixtures":fixtures]
    var riverSVG = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='-1600 -50 3700 1900'><rect x='-1600' y='-50' width='3700' height='1900' fill='#182a25'/>"
    for y in 0..<mh { for x in 0..<mw {
        let color: String
        switch rows[y][x] { case "w": color="#498b9b"; case "f": color="#45633d"; case "h": color="#888573"; case "c": color="#a39459"; default: color="#70834f" }
        let px = (x-y)*32, py = (x+y)*16
        riverSVG += "<path d='M\(px) \(py-16)L\(px+32) \(py)L\(px) \(py+16)L\(px-32) \(py)Z' fill='\(color)' stroke='#182a25' stroke-width='.3'/>"
    } }
    for (name,x,y) in fixtureOrigins {
        let px=(x-y)*32, py=(x+y)*16+16
        riverSVG += "<path d='M\(px) \(py-32)L\(px+64) \(py)L\(px) \(py+32)L\(px-64) \(py)Z' fill='none' stroke='#ff70d0' stroke-width='4'/><text x='\(px+70)' y='\(py)' fill='white' font-size='20'>\(name) (\(x),\(y))</text>"
    }
    riverSVG += "</svg>"
    let report: [String:Any] = ["schemaVersion":1,"configSHA256":try hash(configURL),"artCatalogSHA256":try hash(root.appendingPathComponent("Packages/GameCore/Sources/GameApplication/Resources/art-catalog.json")),"mediaRegistrySHA256":try hash(registryURL),"boundsConvention":"top-left inclusive; alpha >32; silhouette, NOT semantic ground contact","buildings":records]
    let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted,.sortedKeys])
    let html = "<!doctype html><meta charset='utf-8'><title>Building Gate 1 measured atlas</title><style>body{margin:24px;background:#182a25;color:#f4eddb;font:16px system-ui}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}article{background:#293e35;padding:12px;border-radius:12px}h2{font-size:17px}svg{width:100%;height:250px}polygon,path{fill:none;stroke:#ff70d0;stroke-width:1.5}p{font-size:13px;line-height:1.5}</style><h1>Gate 1 · actual runtime scale and anchors</h1><p>Magenta: authoritative footprint hull and center. All assets drawn at the same scale. Roof/silhouette may overhang; no semantic ground-contact mask exists. This is a diagnostic projection, not an in-game screenshot or accepted art.</p><main>\(cards)</main>"
    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
    // Reserve the leaf exclusively: a second concurrent audit must never replace prior evidence.
    guard Darwin.mkdir(output.path, 0o755) == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: [NSLocalizedDescriptionKey:"Cannot reserve new audit directory: \(output.path)"]) }
    try json.write(to: output.appendingPathComponent("inventory.json"), options: .atomic)
    try JSONSerialization.data(withJSONObject: river, options: [.prettyPrinted,.sortedKeys]).write(to: output.appendingPathComponent("river-fixtures.json"), options: .atomic)
    try riverSVG.write(to: output.appendingPathComponent("river-fixtures.svg"), atomically: true, encoding: .utf8)
    try html.write(to: output.appendingPathComponent("atlas.html"), atomically: true, encoding: .utf8)
    print("PASS: measured \(records.count) source/export mappings; audit: \(output.path)")
}
