import SwiftUI
import SwiftData

struct PlanMockupRootView: View {
    @Environment(\.modelContext) private var context
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var dayToPlan: PlanDaySheetItem?
    @Query private var schedules: [WeekSchedule]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MockupLayout.sectionSpacing) {
                weekHeader
                dayLoadSummary
                MockupLoadWeekStrip(selectedDate: $selectedDate, labels: [:])
                ForEach(weekDays, id: \.self) { day in
                    planRow(day)
                }
            }
            .padding(.horizontal, MockupLayout.screenPadding)
            .padding(.top, 52)
            .padding(.bottom, 24)
        }
        .background(PlatesColor.bg)
        .overlay(alignment: .topTrailing) {
            ThemeToggleButton()
                .padding(.top, 8)
                .padding(.trailing, MockupLayout.screenPadding)
        }
        .sheet(item: $dayToPlan) { item in
            WeekDayPlanSheet(date: item.date)
        }
    }

    private var weekHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(weekRangeLabel)
                .font(PlatesFont.secondary(14))
                .foregroundStyle(PlatesColor.muted)
            Text("This week")
                .font(PlatesFont.screenTitle(36))
        }
    }

    private var weekRangeLabel: String {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        let f = interval.start.formatted(.dateTime.month().day())
        let t = Calendar.current.date(byAdding: .day, value: -1, to: interval.end)!.formatted(.dateTime.month().day())
        return "\(f) – \(t)"
    }

    private var dayLoadSummary: some View {
        let counts = loadCounts
        return Text("Day Load \(counts.high) high · \(counts.moderateLow) moderate-low · \(counts.rest) rest")
            .font(PlatesFont.bodyMedium(15))
            .foregroundStyle(PlatesColor.muted)
    }

    private var loadCounts: (high: Int, moderateLow: Int, rest: Int) {
        var high = 0, mod = 0, rest = 0
        for day in weekDays {
            let weekday = Calendar.current.component(.weekday, from: day)
            let label = schedules.first(where: { $0.weekday == weekday })?.dayLoadLabel
                ?? HybridDataStore.dayLoad(for: day, context: context)?.label
            switch label {
            case .high: high += 1
            case .moderate, .low: mod += 1
            case .rest, .none: rest += 1
            }
        }
        return (high, mod, rest)
    }

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func planRow(_ date: Date) -> some View {
        let weekday = Calendar.current.component(.weekday, from: date)
        let schedule = WeekScheduleService.schedule(for: weekday, context: context)
        let sessionTitle = schedule?.sessionTitle ?? HybridDataStore.session(for: date, context: context)?.title
        let subtitle = schedule?.cardioName
        let loadLabel = schedule?.dayLoadLabel ?? HybridDataStore.dayLoad(for: date, context: context)?.label
        let targets = PlatesDataStore.targets(for: date, context: context)
        let isToday = Calendar.current.isDateInToday(date)
        let dayNum = Calendar.current.component(.day, from: date)
        let weekdayName = date.formatted(.dateTime.weekday(.wide))

        return Button {
            dayToPlan = PlanDaySheetItem(date: date)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(weekdayName)
                            .font(PlatesFont.bodySemibold(16))
                        if isToday {
                            Text("Today")
                                .font(PlatesFont.labelCaps(9))
                                .foregroundStyle(PlatesColor.accent)
                        }
                    }
                    Text("\(dayNum)")
                        .font(PlatesFont.secondary(13))
                        .foregroundStyle(PlatesColor.muted)
                }
                .frame(width: 88, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text(sessionTitle ?? "Rest day")
                        .font(PlatesFont.bodySemibold(15))
                    if let subtitle {
                        Text(subtitle)
                            .font(PlatesFont.secondary(13))
                            .foregroundStyle(PlatesColor.muted)
                    }
                    if let loadLabel {
                        Text(loadLabel.title)
                            .font(PlatesFont.labelCaps(10))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(PlatesColor.soft)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Text("\(targets.kcal) kcal")
                    .font(PlatesFont.bodySemibold(15))
            }
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) {
                Divider().overlay(PlatesColor.divider)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(PlatesColor.ink)
    }
}

private struct PlanDaySheetItem: Identifiable {
    let id = UUID()
    let date: Date
}

#Preview {
    PlanMockupRootView()
        .modelContainer(SampleData.previewContainer())
        .environmentObject(AppAppearance.shared)
}
