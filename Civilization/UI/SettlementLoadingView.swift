import SwiftUI

struct SettlementLoadingView: View {
    let stage: String
    var body: some View {
        ZStack {
            panelColor.ignoresSafeArea()
            if let image = EraArt.image("loading-valley.png", maximumPixels: 1600) {
                GeometryReader { geometry in
                    Image(uiImage: image).resizable().scaledToFill().frame(width: geometry.size.width, height: geometry.size.height).clipped()
                }.ignoresSafeArea().accessibilityHidden(true)
                LinearGradient(colors: [.black.opacity(0.20), panelColor.opacity(0.90)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            }
            VStack(spacing: 18) {
                Text("CIVILIZATION").font(.system(size: 28, weight: .semibold, design: .serif)).tracking(4)
                Text("Every civilization has a beginning.").font(.subheadline).foregroundStyle(parchment.opacity(0.75))
                ProgressView().tint(parchment)
                Text(stage).font(.caption).foregroundStyle(parchment.opacity(0.75))
            }.foregroundStyle(parchment).padding(32).background(panelColor.opacity(0.72), in: RoundedRectangle(cornerRadius: 24)).padding(24)
        }.accessibilityElement(children: .combine).accessibilityIdentifier("settlementLoading")
    }
}
