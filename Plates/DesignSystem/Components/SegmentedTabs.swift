import SwiftUI

struct SegmentedTabs<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let title: (T) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection == option
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(isSelected ? PlatesFont.bodySemibold() : PlatesFont.body())
                        .foregroundStyle(PlatesColor.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(PlatesColor.surface)
                                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(PlatesColor.soft)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    struct Demo: View {
        @State private var tab = 0
        var body: some View {
            SegmentedTabs(options: [0, 1, 2], selection: $tab, title: { ["Routines", "Exercises", "History"][$0] })
                .padding()
        }
    }
    return Demo()
        .background(PlatesColor.bg)
}
