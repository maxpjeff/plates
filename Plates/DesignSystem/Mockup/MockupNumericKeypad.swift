import SwiftUI

struct MockupNumericKeypad: View {
    @Binding var text: String
    var onAppend: ((String) -> Void)?

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tap(key)
                        } label: {
                            Text(key)
                                .font(PlatesFont.bodySemibold(22))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(PlatesColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(PlatesColor.line.opacity(0.6)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func tap(_ key: String) {
        if key == "⌫" {
            if !text.isEmpty { text.removeLast() }
            return
        }
        if key == "." && text.contains(".") { return }
        text += key
        onAppend?(key)
    }
}
