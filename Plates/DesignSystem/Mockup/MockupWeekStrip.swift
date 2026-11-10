import SwiftUI

/// Week strip matching mockup: letter + day number, minimal chrome.
struct MockupWeekStrip: View {
    @Binding var selectedDate: Date

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                cell(day)
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let selected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        let today = Calendar.current.isDateInToday(day)

        return Button {
            selectedDate = Calendar.current.startOfDay(for: day)
        } label: {
            VStack(spacing: 6) {
                Text(day.formatted(.dateTime.weekday(.narrow)))
                    .font(PlatesFont.secondary(12))
                Text(day.formatted(.dateTime.day()))
                    .font(PlatesFont.bodySemibold(15))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? PlatesColor.ink : Color.clear)
            .foregroundStyle(selected ? PlatesColor.primaryButtonText : PlatesColor.ink)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if today && !selected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(PlatesColor.ink.opacity(0.25), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct MockupLoadWeekStrip: View {
    @Binding var selectedDate: Date
    var labels: [Date: DayLoadLabel]

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let selected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    Button {
                        selectedDate = Calendar.current.startOfDay(for: day)
                    } label: {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(PlatesFont.bodySemibold(13))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selected ? PlatesColor.soft : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            MockupLoadLegend()
        }
    }

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }
}
