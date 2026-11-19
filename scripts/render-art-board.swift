import AppKit
import Foundation
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let catalog=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("Packages/GameCore/Sources/GameApplication/Resources/art-catalog.json"))) as! [String:Any]
let entries=catalog["buildings"] as! [[String:Any]]
let width=1600,height=1360,cellWidth=320,cellHeight=310
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:width*4,bitsPerPixel:32)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
NSColor(calibratedRed:0.085,green:0.135,blue:0.11,alpha:1).setFill();NSRect(x:0,y:0,width:width,height:height).fill()
let titleAttributes:[NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:28,weight:.semibold),.foregroundColor:NSColor(calibratedRed:0.94,green:0.88,blue:0.74,alpha:1)]
("RIVERBEND · STONE AGE · CANDIDATE BUILDING SET" as NSString).draw(at:NSPoint(x:30,y:height-60),withAttributes:titleAttributes)
let attributes:[NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:16,weight:.medium),.foregroundColor:NSColor(calibratedRed:0.90,green:0.86,blue:0.73,alpha:1)]
for (index,entry) in entries.enumerated(){
 let x=(index%5)*cellWidth,y=height-100-(index/5+1)*cellHeight
 NSColor(calibratedRed:0.14,green:0.20,blue:0.16,alpha:1).setFill();NSBezierPath(roundedRect:NSRect(x:x+12,y:y+12,width:296,height:286),xRadius:12,yRadius:12).fill()
 let path=root.appendingPathComponent("Civilization/Art").appendingPathComponent(entry["file"] as! String)
 if let image=NSImage(contentsOf:path){image.draw(in:NSRect(x:x+40,y:y+50,width:240,height:240))}
 else {("PENDING" as NSString).draw(at:NSPoint(x:x+100,y:y+155),withAttributes:attributes)}
 (entry["id"] as! NSString).draw(at:NSPoint(x:x+26,y:y+24),withAttributes:attributes)
}
NSGraphicsContext.restoreGraphicsState()
let out=root.appendingPathComponent("docs/art/building-board.png")
try rep.representation(using:.png,properties:[:])!.write(to:out)
print(out.path)
