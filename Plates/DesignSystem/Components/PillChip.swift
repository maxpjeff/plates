import SwiftUI

struct PillChip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            Text(title)
                .font(PlatesFont.bodySemibold(14))
                .foregroundStyle(isSelected ? PlatesColor.primaryButtonText : PlatesColor.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 36)
                .background {
                    Capsule()
                        .fill(isSelected ? PlatesColor.ink : PlatesColor.surface)
                }
                .overlay {
                    if !isSelected {
                        Capsule()
                            .strokeBorder(PlatesColor.line, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        PillChip(title: "Chest", isSelected: true)
        PillChip(title: "Back")
    }
    .padding()
    .background(PlatesColor.bg)
}
