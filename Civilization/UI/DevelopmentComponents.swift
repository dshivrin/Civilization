import SwiftUI

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
            VStack(alignment: .leading, spacing: 5) {
                HStack { if let pillarID { EraIcon(domain: .pillar, id: pillarID, size: 26) }; Text(title).font(.subheadline.bold()) }
                Text(detail).font(.caption)
                ProgressView(value: Double(completed), total: Double(max(1, total)))
            }.padding(12).frame(minWidth: 125, maxWidth: .infinity, minHeight: 66, alignment: .leading)
                .background(Color.white.opacity(selected ? 0.16 : 0.05), in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
struct DevelopmentCardStyle: ViewModifier {
    let color: Color
    func body(content: Content) -> some View {
        content.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [Color(red: 0.19, green: 0.235, blue: 0.18), Color(red: 0.135, green: 0.185, blue: 0.145)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1))
    }
}
