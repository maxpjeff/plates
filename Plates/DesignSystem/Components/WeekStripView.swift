import SwiftUI

struct WeekStripView: View {
    @Binding var selectedDate: Date
    var dayLabels: [Date: DayLoadLabel] = [:]

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(day)
        let label = dayLabels[Calendar.current.startOfDay(for: day)]

        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(PlatesFont.secondary(11))
                Text(day.formatted(.dateTime.day()))
                    .font(PlatesFont.bodySemibold(14))
                Circle()
                    .fill(dotColor(label))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? PlatesColor.primaryButton : PlatesColor.surface)
            .foregroundStyle(isSelected ? PlatesColor.primaryButtonText : PlatesColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(PlatesColor.accent, lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func dotColor(_ label: DayLoadLabel?) -> Color {
        guard let label else { return PlatesColor.line }
        switch label {
        case .high: return PlatesColor.accent
        case .moderate: return PlatesColor.gold
        case .low: return PlatesColor.good.opacity(0.7)
        case .rest: return PlatesColor.muted.opacity(0.5)
        }
    }
}

struct DayLoadBadge: View {
    let label: DayLoadLabel

    var body: some View {
        Text(label.title.uppercased())
            .font(PlatesFont.labelCaps(10))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(PlatesColor.soft)
            .clipShape(Capsule())
    }
}
