import SwiftUI
import GameCore
import GameApplication

struct RoadControlsView: View {
    let session: GameSession
    @State private var style: RoadStyle = .trodden
    @State private var expanded = true
    init(session: GameSession) {
        self.session = session
        _style = State(initialValue: session.roadTool?.style ?? .trodden)
    }
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
                HStack {
                    Text("Roads").font(.headline);Spacer()
                    Button { expanded.toggle() } label: { Image(systemName:expanded ? "chevron.up" : "chevron.down").frame(width:44,height:44) }
                        .accessibilityLabel(expanded ? "Collapse road details" : "Expand road details").accessibilityIdentifier("toggleRoadDetails")
                    Button { session.cancel() } label: { Image(systemName:"xmark").frame(width:44,height:44) }
                        .accessibilityLabel("Close roads").accessibilityIdentifier("closeRoads")
                }
                if expanded {
                ScrollView { VStack(alignment:.leading,spacing:8) {
                Text(session.usesConnectedPaths ? "Free paths · connect ordinary services" : "Free decoration · no era requirement").font(.caption).foregroundStyle(.mint)
                HStack(spacing:4) {
                    ForEach(RoadStyle.allCases,id:\.self) { value in
                        Button(value == .trodden ? "Path" : value == .dirt ? "Dirt" : "Stone") {
                            style = value
                            if case .replace = session.roadTool { session.chooseRoadTool(.replace(value)) }
                            else { session.chooseRoadTool(.draw(value)) }
                        }.font(.caption.bold()).frame(maxWidth:.infinity,minHeight:44)
                            .background(session.roadTool?.style == value ? .white.opacity(0.16) : .clear,in:RoundedRectangle(cornerRadius:8))
                            .accessibilityValue(session.roadTool?.style == value ? "Selected" : "Not selected")
                            .accessibilityLabel(value.title).accessibilityIdentifier("roadStyle-"+value.rawValue)
                    }
                }
                HStack(spacing:4) {
                    mode("Draw",id:"draw",tool:.draw(style))
                    mode("Replace",id:"replace",tool:.replace(style))
                    mode("Remove",id:"erase",tool:.erase)
                }
                HStack {
                    Text("\(session.state.roads?.count ?? 0) roads placed").accessibilityIdentifier("roadTileCount")
                    Spacer()
                    Text("\(session.roadDraft.count) preview tiles").accessibilityIdentifier("roadDraftCount")
                }.font(.caption2)
                Text(session.roadPreviewIssue?.localizedDescription ?? "Drag or tap open land, then Confirm. Pinch clears the preview; close Roads to pan.")
                    .font(.caption).foregroundStyle(session.roadPreviewIssue == nil ? parchment.opacity(0.8) : .orange)
                    .fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("roadPreviewHelp")
                Text("Draw adds. Replace changes surfaces. Remove erases roads. Clear roads before building here.")
                    .font(.caption2).foregroundStyle(parchment.opacity(0.65)).fixedSize(horizontal:false,vertical:true)
                } }
                HStack {
                    Button(action: session.undoRoadTile) {
                        Image(systemName: "arrow.uturn.backward").frame(width: 44, height: 44)
                    }.buttonStyle(.plain).background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        .disabled(session.roadDraft.isEmpty).accessibilityLabel("Undo last preview tile").accessibilityIdentifier("undoRoadTile")
                    Button("Clear",action:session.clearRoadStroke).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.85).frame(maxWidth:.infinity,minHeight:44).buttonStyle(.bordered)
                        .disabled(session.roadDraft.isEmpty).accessibilityIdentifier("clearRoadStroke")
                    Button("Confirm",action:session.confirmRoadStroke).font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.85).frame(maxWidth:.infinity,minHeight:44).buttonStyle(StonePrimaryActionStyle())
                        .disabled(session.roadDraft.isEmpty || session.roadPreviewIssue != nil).accessibilityIdentifier("confirmRoadStroke")
                }
                } else {
                    Text("\(session.roadDraft.count) preview tiles · free").font(.caption)
                }
            }.padding(12).background(panelColor.opacity(0.97),in:RoundedRectangle(cornerRadius:18))
    }
    private func mode(_ title:String,id:String,tool:RoadTool) -> some View {
        Button(title) { session.chooseRoadTool(tool) }.font(.caption).frame(maxWidth:.infinity,minHeight:44)
            .background(session.roadTool == tool ? .white.opacity(0.16) : .clear,in:RoundedRectangle(cornerRadius:8))
            .accessibilityIdentifier("roadMode-"+id)
    }
}
