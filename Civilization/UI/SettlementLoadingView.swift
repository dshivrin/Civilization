import SwiftUI

struct SettlementLoadingView: View {
    let stage: String
    var body: some View {
        ZStack {
            panelColor.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("CIVILIZATION").font(.system(size: 28, weight: .semibold, design: .serif)).tracking(4)
                Text("Every civilization has a beginning.").font(.subheadline).foregroundStyle(parchment.opacity(0.75))
                ProgressView().tint(parchment)
                Text(stage).font(.caption).foregroundStyle(parchment.opacity(0.75))
            }.foregroundStyle(parchment).padding(24)
        }.accessibilityElement(children: .combine).accessibilityIdentifier("settlementLoading")
    }
}
