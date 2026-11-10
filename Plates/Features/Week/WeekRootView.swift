import SwiftUI
import SwiftData

struct WeekRootView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.sortOrder) private var routines: [Routine]
    @State private var dayToPlan: PlanDaySheetItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("This week")
                        .font(PlatesFont.sectionTitle(28))
                    Text(weekRangeLabel)
                        .font(PlatesFont.secondary())
                        .foregroundStyle(PlatesColor.muted)
                    Text("Tap a day to assign routines, set lift times, and plan meals.")
                        .font(PlatesFont.secondary(13))
                        .foregroundStyle(PlatesColor.muted)
                    summaryCard
                    ForEach(weekDays, id: \.self) { day in
                        dayRow(day)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)
                .padding(.bottom, 20)
            }
            .background(PlatesColor.bg)
            .sheet(item: $dayToPlan) { item in
                WeekDayPlanSheet(date: item.date)
            }
        }
    }

    private var weekRangeLabel: String {
        let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date())!
        let f = interval.start.formatted(.dateTime.month().day())
        let t = interval.end.formatted(.dateTime.month().day())
        return "\(f) – \(t)"
    }

    private var summaryCard: some View {
        PlatesCard {
            HStack {
                stat("Routines", value: "\(routines.count)")
                stat("Avg kcal", value: "\(avgTrainingKcal)")
            }
        }
    }

    private var avgTrainingKcal: Int {
        let t = PlatesDataStore.targets(for: Date(), context: context)
        return t.kcal
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading) {
            Text(label)
                .platesLabelCaps()
            Text(value)
                .font(PlatesFont.bodySemibold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weekDays: [Date] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private func dayRow(_ date: Date) -> some View {
        let weekday = Calendar.current.component(.weekday, from: date)
        let schedule = WeekScheduleService.schedule(for: weekday, context: context)
        let routine = schedule?.isRest == false ? schedule?.routine : nil
        let sessionTitle = schedule?.sessionTitle ?? HybridDataStore.session(for: date, context: context)?.title
        let loadLabel = schedule?.dayLoadLabel ?? HybridDataStore.dayLoad(for: date, context: context)?.label
        let liftTime = schedule?.preferredWorkoutTime
        let targets = PlatesDataStore.targets(for: date, context: context)
        let isToday = Calendar.current.isDateInToday(date)
        let plan = PlatesDataStore.dayPlan(for: date, context: context)
        let mealCount = plan.plannedMeals.count
        let eaten = plan.plannedMeals.filter(\.isEaten).count

        return Button {
            dayToPlan = PlanDaySheetItem(date: date)
        } label: {
            PlatesCard(padding: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(date.formatted(.dateTime.weekday(.wide)))
                            .font(PlatesFont.bodySemibold())
                            .foregroundStyle(PlatesColor.ink)
                        Text(date.formatted(.dateTime.month().day()))
                            .font(PlatesFont.secondary())
                            .foregroundStyle(PlatesColor.muted)
                        if let liftTime, routine != nil {
                            Label(liftTime.formatted(date: .omitted, time: .shortened), systemImage: "figure.strengthtraining.traditional")
                                .font(PlatesFont.secondary(11))
                                .foregroundStyle(PlatesColor.muted)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        if let loadLabel {
                            DayLoadBadge(label: loadLabel)
                        }
                        if let sessionTitle {
                            Text(sessionTitle)
                                .font(PlatesFont.bodySemibold(13))
                                .foregroundStyle(PlatesColor.ink)
                                .lineLimit(2)
                        } else if let routine {
                            TextCardSticker(label: routine.shortLabel, color: routine.stickerColor, rotation: 2)
                        } else {
                            Text(schedule?.isRest == true ? "Rest" : "Plan day")
                                .font(PlatesFont.secondary())
                                .foregroundStyle(PlatesColor.muted)
                        }
                        if let subtitle = schedule?.cardioName {
                            Text(subtitle)
                                .font(PlatesFont.secondary(11))
                                .foregroundStyle(PlatesColor.muted)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(targets.kcal) kcal")
                            .font(PlatesFont.bodySemibold())
                            .foregroundStyle(PlatesColor.ink)
                        Text("\(eaten)/\(mealCount) meals")
                            .font(PlatesFont.secondary(11))
                            .foregroundStyle(PlatesColor.muted)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(PlatesColor.muted)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isToday {
                RoundedRectangle(cornerRadius: 2)
                    .fill(PlatesColor.accent)
                    .frame(width: 4)
                    .padding(.vertical, 4)
            }
        }
    }
}

private struct PlanDaySheetItem: Identifiable {
    let id = UUID()
    let date: Date
}

#Preview {
    WeekRootView()
        .modelContainer(SampleData.previewContainer())
}
