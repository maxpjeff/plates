import SwiftUI

enum MockupFont {
    static func title(_ size: CGFloat = 34) -> Font { .system(size: size, weight: .bold, design: .default) }
    static func headline(_ size: CGFloat = 17) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat = 15) -> Font { .system(size: size, weight: .regular) }
    static func caption(_ size: CGFloat = 12) -> Font { .system(size: size, weight: .medium) }
    static func micro(_ size: CGFloat = 10) -> Font { .system(size: size, weight: .bold) }
    static func heroNumber(_ size: CGFloat = 48) -> Font { .system(size: size, weight: .bold, design: .rounded) }
}

struct MockupHighDayPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(MockupFont.caption(11))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(MockupColors.highDayBlue)
            .clipShape(Capsule())
    }
}

struct MockupProfileAvatar: View {
    let initials: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(initials)
                .font(MockupFont.headline(14))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(MockupColors.ink)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct MockupWeekStripExact: View {
    @Binding var selectedDate: Date

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                cell(day)
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let selected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        return Button {
            selectedDate = Calendar.current.startOfDay(for: day)
        } label: {
            VStack(spacing: 5) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(MockupFont.caption(11))
                Text(day.formatted(.dateTime.day()))
                    .font(MockupFont.headline(14))
                Circle()
                    .fill(MockupColors.highDayBlue)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? MockupColors.ink : MockupColors.card)
            .foregroundStyle(selected ? Color.white : MockupColors.ink)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: MockupColors.ink.opacity(selected ? 0 : 0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct MockupMacroProgressColumn: View {
    let title: String
    let eaten: Int
    let target: Int
    let fill: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(MockupFont.caption(11))
                .foregroundStyle(MockupColors.muted)
            Text("\(eaten)/\(target) g")
                .font(MockupFont.headline(14))
                .foregroundStyle(MockupColors.ink)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.black.opacity(0.06))
                    Capsule()
                        .fill(fill)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progress: CGFloat {
        guard target > 0 else { return 0 }
        return CGFloat(min(1, Double(eaten) / Double(target)))
    }
}

struct MockupMacroPills: View {
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    var body: some View {
        HStack(spacing: 6) {
            pill("\(kcal) kcal")
            pill("P \(protein)g")
            pill("C \(carbs)g")
            pill("F \(fat)g")
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(MockupFont.micro(10))
            .foregroundStyle(MockupColors.muted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.05))
            .clipShape(Capsule())
    }
}

struct MockupFloatingTabBar: View {
    @Binding var selection: PlatesTab

    var body: some View {
        HStack(spacing: 8) {
            tab(.today, icon: "house.fill", label: "Today")
            tab(.plan, icon: "calendar", label: "Plan")
            tab(.design, icon: "square.and.pencil", label: "Design")
            tab(.progress, icon: "chart.bar.fill", label: nil)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(MockupColors.tabBar)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func tab(_ tab: PlatesTab, icon: String, label: String?) -> some View {
        let selected = selection == tab
        return Button {
            if tab != .progress { selection = tab }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                if selected, let label {
                    Text(label)
                        .font(MockupFont.headline(13))
                }
            }
            .foregroundStyle(selected ? MockupColors.ink : Color.white.opacity(0.85))
            .padding(.horizontal, selected && label != nil ? 16 : 12)
            .padding(.vertical, 10)
            .background(selected ? Color.white : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

struct MockupDayLoadChart: View {
    var labels: [DayLoadLabel?]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Day Load")
                .font(MockupFont.headline(16))
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barColor(label))
                            .frame(width: 28, height: barHeight(label))
                        Text(["S", "M", "T", "W", "T", "F", "S"][index])
                            .font(MockupFont.caption(11))
                            .foregroundStyle(MockupColors.muted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100, alignment: .bottom)
            MockupLoadLegend()
        }
        .padding(18)
        .background(MockupColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func barHeight(_ label: DayLoadLabel?) -> CGFloat {
        switch label {
        case .high: 72
        case .moderate: 52
        case .low: 36
        case .rest: 20
        case .none: 16
        }
    }

    private func barColor(_ label: DayLoadLabel?) -> Color {
        switch label {
        case .high: MockupColors.loadHigh
        case .moderate: MockupColors.loadModerate
        case .low: MockupColors.loadLow
        case .rest: MockupColors.loadRest
        case .none: MockupColors.loadRest
        }
    }
}

struct MockupLoadLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legend("High", MockupColors.loadHigh)
            legend("Moderate", MockupColors.loadModerate)
            legend("Low", MockupColors.loadLow)
            legend("Rest", MockupColors.loadRest)
        }
        .font(MockupFont.caption(10))
        .foregroundStyle(MockupColors.muted)
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }
}

func mockupLoadColor(_ label: DayLoadLabel?) -> Color {
    switch label {
    case .high: MockupColors.loadHigh
    case .moderate: MockupColors.loadModerate
    case .low: MockupColors.loadLow
    case .rest: MockupColors.loadRest
    case .none: MockupColors.loadRest
    }
}
