import SwiftUI

struct PrescriptionStepper: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...99
    var step: Int = 1
    var suffix: String = ""

    var body: some View {
        HStack {
            Text(title)
                .font(PlatesFont.secondary(13))
                .foregroundStyle(PlatesColor.muted)
            Spacer()
            HStack(spacing: 0) {
                stepButton(systemName: "minus") {
                    value = max(range.lowerBound, value - step)
                }
                Text("\(value)\(suffix)")
                    .font(PlatesFont.bodySemibold())
                    .frame(minWidth: 44)
                    .multilineTextAlignment(.center)
                stepButton(systemName: "plus") {
                    value = min(range.upperBound, value + step)
                }
            }
            .padding(4)
            .background(PlatesColor.soft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 36, height: 32)
                .background(PlatesColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct ExerciseTagsRow: View {
    let muscleTags: [String]
    let patternTags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(muscleTags, id: \.self) { tag in
                tagCapsule(tag, filled: true)
            }
            ForEach(patternTags, id: \.self) { tag in
                tagCapsule(tag, filled: false)
            }
        }
    }

    private func tagCapsule(_ text: String, filled: Bool) -> some View {
        Text(text)
            .font(PlatesFont.secondary(11))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(filled ? PlatesColor.ink.opacity(0.08) : PlatesColor.surface)
            .foregroundStyle(PlatesColor.ink)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(PlatesColor.line, lineWidth: filled ? 0 : 1))
    }
}

/// Simple horizontal flow for tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
