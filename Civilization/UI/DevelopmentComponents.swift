import SwiftUI
import GameCore

/// Shared category navigation for the building and research menus.
struct DevelopmentCategoryButton: View {
    let title: String
    let detail: String
    let completed: Int
    let total: Int
    let selected: Bool
    var pillarID: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                HStack { if let pillarID { EraIcon(domain: .pillar, id: pillarID, size: 20) }; Text(title).font(.caption.bold()).lineLimit(1) }
                Text(detail).font(.caption)
                ProgressView(value: Double(completed), total: Double(max(1, total)))
            }.padding(10).frame(minWidth: 125, maxWidth: .infinity, minHeight: 54, alignment: .leading)
                .background(Color.white.opacity(selected ? 0.16 : 0.05), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct DevelopmentCardStyle: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(red: 0.19, green: 0.235, blue: 0.18), Color(red: 0.135, green: 0.185, blue: 0.145)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}

/// The same compact hierarchy for both catalogs; details never hide the primary action.
struct DevelopmentSummary<Picture: View>: View {
    let title: String
    let status: String
    let symbol: String
    let color: Color
    @ViewBuilder let picture: Picture
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        HStack(spacing: 10) {
            picture.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold()).lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
                Label(status, systemImage: symbol).font(.caption2).foregroundStyle(color)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
    }
}

struct DevelopmentDetailsButton: View {
    let title: String
    let id: String
    @Binding var expanded: Bool
    var body: some View {
        Button { expanded.toggle() } label: {
            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.bordered).accessibilityLabel((expanded ? "Less about " : "Details about ") + title)
            .accessibilityValue(expanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("details-" + id)
    }
}

/// Cost identity is conveyed by an object icon; shortages also expose exact counts in text/VoiceOver.
struct DevelopmentCosts: View {
    let cost: ResourceAmounts
    let stored: ResourceAmounts
    let id: String
    var paid = false
    var detailed = false
    private let shortfallColor = Color(red: 1, green: 0.43, blue: 0.40)
    private func amount(_ value: Double) -> String { String(format: "%g", value) }
    private var resources: [Resource] { Resource.allCases.filter { cost[$0] > 0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if resources.isEmpty { Text("No cost").font(.caption).foregroundStyle(.secondary) }
            else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { chips }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), alignment: .leading)], alignment: .leading, spacing: 5) { chips }
                }
            }
            if detailed {
                ForEach(resources, id: \.self) { resource in
                    let missing = max(0, cost[resource] - stored[resource])
                    Text(resource.title + ": " + amount(cost[resource]) + " required · " + amount(floor(stored[resource])) + " stored" + (paid ? " · already paid" : missing > 0 ? " · " + amount(ceil(missing)) + " missing" : ""))
                        .font(.caption).foregroundStyle(!paid && missing > 0 ? shortfallColor : parchment.opacity(0.8))
                }
            }
        }.frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
    }
    @ViewBuilder private var chips: some View {
        ForEach(resources, id: \.self) { resource in
            let missing = max(0, cost[resource] - stored[resource])
            let short = !paid && missing > 0
            HStack(spacing: 3) {
                EraIcon(domain: .resource, id: resource.rawValue, size: 20).accessibilityHidden(true)
                Text(amount(cost[resource])).monospacedDigit()
                if short { Image(systemName: "exclamationmark.circle.fill").font(.system(size: 10)) }
            }.font(.caption.bold()).foregroundStyle(short ? shortfallColor : parchment)
                .padding(.horizontal, 5).padding(.vertical, 4)
                .background((short ? shortfallColor : Color.white).opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(resource.title + ", " + amount(cost[resource]) + " required, " + amount(floor(stored[resource])) + " stored" + (paid ? ", already paid" : short ? ", " + amount(ceil(missing)) + " missing" : ", available"))
                .accessibilityIdentifier("cost-" + id + "-" + resource.rawValue)
        }
    }
}
