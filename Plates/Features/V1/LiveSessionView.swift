import SwiftUI

struct LiveSessionView: View {
    let model: LiveSessionModel
    var onBack: () -> Void = {}
    var onFinish: () -> Void = {}
    var onSaveRep: () -> Void = {}

    @State private var timingSelection: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapSession) {
            topBar
            titleBlock
            blockCard
            timingPills
            numberPad
            saveButton
        }
        .padding(.horizontal, DesignSystem.Layout.screenPadding)
        .padding(.top, 4)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(DesignSystem.Color.sessionBg)
        .preferredColorScheme(.dark)
        .onAppear { timingSelection = model.selectedTiming }
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(DesignSystem.Color.sessionRow)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Spacer()
            Text(model.elapsed)
                .font(InterFont.inter(17, .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
            Spacer()
            Button(action: onFinish) {
                Text("Finish")
                    .font(InterFont.inter(14, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background(DesignSystem.Color.sessionRow)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.title)
                .font(InterFont.inter(26, .heavy))
                .tracking(-0.52)
                .foregroundStyle(.white)
            Text(model.blockProgress)
                .font(InterFont.inter(13, .semibold))
                .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                .padding(.top, 4)
            HStack(spacing: 6) {
                ForEach(Array(model.segmentFill.enumerated()), id: \.offset) { _, fill in
                    GeometryReader { geo in
                        Capsule()
                            .fill(DesignSystem.Color.sessionRaised)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(DesignSystem.Color.accent)
                                    .frame(width: geo.size.width * fill)
                            }
                    }
                    .frame(height: 5)
                }
            }
            .padding(.top, 10)
        }
    }

    private var blockCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.exerciseTitle)
                        .font(InterFont.inter(18, .heavy))
                        .foregroundStyle(.white)
                    Text(model.exerciseSubtitle)
                        .font(InterFont.inter(13, .medium))
                        .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                }
                Spacer()
                Text(model.restLabel)
                    .font(InterFont.inter(12, .bold))
                    .monospacedDigit()
                    .foregroundStyle(DesignSystem.Color.sessionPillText)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 11)
                    .background(DesignSystem.Color.sessionRaised)
                    .clipShape(Capsule())
            }
            .padding(.bottom, 4)

            ForEach(model.reps) { rep in
                repRow(rep)
            }
        }
        .padding(16)
        .background(DesignSystem.Color.sessionSurface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sessionBlock, style: .continuous))
    }

    @ViewBuilder
    private func repRow(_ rep: LiveRepRowModel) -> some View {
        switch rep {
        case .done(let label, let value, let trailing):
            HStack(spacing: 12) {
                Text(label)
                    .font(InterFont.inter(13, .semibold))
                    .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                    .frame(width: 52, alignment: .leading)
                Text(value)
                    .font(InterFont.inter(20, .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailingView(trailing)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.sessionRow)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))

        case .active(let label, let partial):
            HStack(spacing: 12) {
                Text(label)
                    .font(InterFont.inter(13, .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, alignment: .leading)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(partial)
                        .font(InterFont.inter(30, .heavy))
                        .foregroundStyle(.white)
                    Text("_")
                        .font(InterFont.inter(30, .heavy))
                        .foregroundStyle(DesignSystem.Color.sessionMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("s")
                    .font(InterFont.inter(12, .semibold))
                    .foregroundStyle(DesignSystem.Color.onDarkSecondary)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.sessionActiveRow)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous)
                    .strokeBorder(DesignSystem.Color.accent, lineWidth: 2)
            }

        case .pending(let label):
            HStack(spacing: 12) {
                Text(label)
                    .font(InterFont.inter(13, .semibold))
                    .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                    .frame(width: 52, alignment: .leading)
                Text("—")
                    .font(InterFont.inter(20, .heavy))
                    .foregroundStyle(DesignSystem.Color.sessionDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.sessionRow)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
            .opacity(0.45)
        }
    }

    @ViewBuilder
    private func trailingView(_ trailing: LiveRepTrailing) -> some View {
        switch trailing {
        case .meta(let text):
            Text(text)
                .font(InterFont.inter(12, .semibold))
                .foregroundStyle(DesignSystem.Color.onDarkSecondary)
        case .onTarget:
            Text("On target")
                .font(InterFont.inter(11, .heavy))
                .foregroundStyle(DesignSystem.Color.ink)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(DesignSystem.Color.accent)
                .clipShape(Capsule())
        }
    }

    private var timingPills: some View {
        HStack(spacing: 8) {
            ForEach(model.timingPills, id: \.self) { pill in
                Button {
                    timingSelection = pill
                } label: {
                    Text(pill)
                        .font(InterFont.inter(13, .semibold))
                        .foregroundStyle(timingSelection == pill ? DesignSystem.Color.ink : DesignSystem.Color.sessionPillText)
                        .padding(.horizontal, 14)
                        .frame(height: 36)
                        .background(timingSelection == pill ? Color.white : DesignSystem.Color.sessionRow)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
            Text(model.wind)
                .font(InterFont.inter(13, .semibold))
                .foregroundStyle(DesignSystem.Color.sessionPillText)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(DesignSystem.Color.sessionRow)
                .clipShape(Capsule())
        }
    }

    private var numberPad: some View {
        let keys: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "delete"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Button {} label: {
                    Group {
                        if key == "delete" {
                            Image(systemName: "delete.left")
                                .font(.system(size: 24, weight: .regular))
                        } else {
                            Text(key)
                                .font(InterFont.inter(24, .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(DesignSystem.Color.sessionRow)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var saveButton: some View {
        Button(action: onSaveRep) {
            Text("Save rep · start rest")
                .font(InterFont.inter(17, .heavy))
                .foregroundStyle(DesignSystem.Color.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(DesignSystem.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.saveRep, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LiveSessionView(model: MockData.liveSessionModel)
}
