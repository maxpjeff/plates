import SwiftUI

// MARK: - Before / Reflect

struct BeforeCardModel: Equatable {
    let goalChip: String
    let note: String
}

struct AfterCardModel: Equatable {
    let feel: Int
    let note: String
}

struct DashedAddButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(DesignSystem.Color.ink)
                    }
                Text(title)
                    .font(InterFont.inter(16, .bold))
                    .foregroundStyle(DesignSystem.Color.accentText)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Color.clear)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        DesignSystem.Color.accent,
                        style: StrokeStyle(lineWidth: 2, dash: [6, 5])
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

struct BeforeCard: View {
    let model: BeforeCardModel
    var onEdit: () -> Void = {}

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BEFORE")
                        .font(InterFont.inter(11, .bold))
                        .tracking(0.66)
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                    Spacer()
                    Text("Edit")
                        .font(InterFont.inter(12, .semibold))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                Text(model.goalChip)
                    .font(InterFont.inter(12, .bold))
                    .foregroundStyle(DesignSystem.Color.ptChipText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 9)
                    .background(DesignSystem.Color.accentTint)
                    .clipShape(Capsule())
                Text(model.note)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.chipText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct AfterCard: View {
    let model: AfterCardModel
    var onEdit: () -> Void = {}

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("AFTER")
                        .font(InterFont.inter(11, .bold))
                        .tracking(0.66)
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                    Spacer()
                    Text("Edit")
                        .font(InterFont.inter(12, .semibold))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                Text("Feel · \(model.feel)/5")
                    .font(InterFont.inter(12, .bold))
                    .foregroundStyle(DesignSystem.Color.ptChipText)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 9)
                    .background(DesignSystem.Color.accentTint)
                    .clipShape(Capsule())
                Text(model.note)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.chipText)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(DesignSystem.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calendar

struct CalendarSquare: View {
    let shadeOpacity: Double
    var accessibilityDateLabel: String = "Day"

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(DesignSystem.Color.bg)
            .frame(width: 22, height: 22)
            .overlay {
                if shadeOpacity > 0 {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(DesignSystem.Color.accent.opacity(shadeOpacity))
                }
            }
            .accessibilityLabel(accessibilityDateLabel)
    }
}

struct MiniMonthCalendar: View {
    @Binding var month: Date
    let dayCompletion: [Int: Int]

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 6) {
            header
            HStack(spacing: 5) {
                ForEach(weekdays, id: \.self) { letter in
                    Text(letter)
                        .font(InterFont.inter(10.5, .semibold))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                        .frame(width: 22)
                }
            }
            daysGrid
            legend
        }
        .frame(width: 184)
    }

    private var header: some View {
        HStack(spacing: 0) {
            monthButton(systemName: "chevron.left") { shiftMonth(-1) }
            Spacer()
            Text(monthTitle)
                .font(InterFont.inter(13, .heavy))
                .foregroundStyle(DesignSystem.Color.ink)
            Spacer()
            monthButton(systemName: "chevron.right") { shiftMonth(1) }
        }
    }

    private func monthButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(DesignSystem.Color.ink)
                .frame(width: 22, height: 22)
                .background(DesignSystem.Color.bg)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var daysGrid: some View {
        let layout = monthLayout
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(22), spacing: 5), count: 7), spacing: 5) {
            ForEach(0..<layout.leadingBlanks, id: \.self) { _ in
                Color.clear.frame(width: 22, height: 22)
            }
            ForEach(1...layout.daysInMonth, id: \.self) { day in
                let pct = dayCompletion[day] ?? 0
                CalendarSquare(
                    shadeOpacity: CalendarDayShade.opacity(forCompletionPercent: pct),
                    accessibilityDateLabel: accessibilityLabel(day: day, percent: pct)
                )
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 10) {
            legendItem(opacity: 1.0, label: "Done")
            legendItem(opacity: 0.38, label: "Partial")
        }
        .padding(.top, 2)
    }

    private func legendItem(opacity: Double, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(DesignSystem.Color.accent.opacity(opacity))
                .frame(width: 10, height: 10)
            Text(label)
                .font(InterFont.inter(11, .semibold))
                .foregroundStyle(DesignSystem.Color.chipText)
        }
    }

    private var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    private var monthLayout: (leadingBlanks: Int, daysInMonth: Int) {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: month) ?? 1..<31
        let firstWeekday = cal.component(.weekday, from: cal.date(from: cal.dateComponents([.year, .month], from: month))!) - 1
        return (firstWeekday, range.count)
    }

    private func shiftMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: month) {
            month = next
        }
    }

    private func accessibilityLabel(day: Int, percent: Int) -> String {
        let monthName = month.formatted(.dateTime.month(.wide))
        switch percent {
        case 100: return "\(monthName) \(day), done"
        case 0: return "\(monthName) \(day), not started"
        default: return "\(monthName) \(day), partly done"
        }
    }
}

// MARK: - Segmented pill

struct SegmentedPill<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                let selected = selection == option
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(InterFont.inter(13, selected ? .bold : .semibold))
                        .foregroundStyle(selected ? DesignSystem.Color.ink : DesignSystem.Color.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(selected ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: selected ? .black.opacity(0.08) : .clear, radius: 1, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(DesignSystem.Color.bg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Goal & PR rows

struct GoalRow: View {
    let title: String
    let remaining: String
    let progress: Double
    let nowLine: String
    let deadlineLine: String
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(InterFont.inter(15, .bold))
                    .foregroundStyle(DesignSystem.Color.ink)
                Spacer()
                Text(remaining)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            PlatesMacroBar(percent: progress, color: DesignSystem.Color.accent)
                .frame(height: 8)
            HStack {
                Text(nowLine)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                Spacer()
                Text(deadlineLine)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            if showDivider {
                Rectangle()
                    .fill(DesignSystem.Color.divider)
                    .frame(height: 1)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 14)
    }
}

struct PRRow: View {
    let row: PersonalRecordRow
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(row.name)
                            .font(InterFont.inter(15, .bold))
                            .foregroundStyle(DesignSystem.Color.ink)
                        if row.tagNew {
                            prTag("New", accent: true)
                        }
                        if row.tagWindAided {
                            prTag("Wind-aided", accent: false)
                        }
                    }
                    Text(row.context)
                        .font(InterFont.inter(12, .medium))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(row.value)
                        .font(InterFont.inter(20, .heavy))
                        .tracking(-0.4)
                        .monospacedDigit()
                        .foregroundStyle(row.valueIsMuted ? DesignSystem.Color.inkSecondary : DesignSystem.Color.ink)
                    Text(row.detail)
                        .font(InterFont.inter(11, .semibold))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
            }
            .padding(.vertical, 13)
            if showDivider {
                Rectangle()
                    .fill(DesignSystem.Color.divider)
                    .frame(height: 1)
            }
        }
    }

    private func prTag(_ text: String, accent: Bool) -> some View {
        Text(text)
            .font(InterFont.inter(10.5, .heavy))
            .foregroundStyle(accent ? DesignSystem.Color.ink : DesignSystem.Color.chipText)
            .padding(.vertical, 2)
            .padding(.horizontal, 7)
            .background(accent ? DesignSystem.Color.accent : DesignSystem.Color.bg)
            .clipShape(Capsule())
    }
}

// MARK: - Session timeline stack

struct SessionTimelineContent: View {
    let session: SessionTimelineModel
    var onAddBefore: () -> Void = {}
    var onEditBefore: () -> Void = {}
    var onLogSession: () -> Void = {}
    var onLogLive: () -> Void = {}
    var onReflect: () -> Void = {}
    var onEditReflect: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            if let before = session.before {
                BeforeCard(model: before, onEdit: onEditBefore)
            } else {
                DashedAddButton(title: "Add goals & notes", action: onAddBefore)
            }

            SessionCard(
                caps: session.caps,
                title: session.title,
                blocks: session.blocks,
                onLogSession: onLogSession,
                onLogLive: onLogLive
            )

            if let after = session.after {
                AfterCard(model: after, onEdit: onEditReflect)
            } else {
                DashedAddButton(title: "Reflect", action: onReflect)
            }
        }
    }
}
