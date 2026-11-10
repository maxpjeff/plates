import SwiftUI

struct WorkoutsScreenView: View {
    @Bindable var store: FuelStore
    @State private var editingWeekday: WeekdayEdit?
    @State private var showSettings = false

    private var weekStart: Date { store.selectedDate.startOfWeek }

    var body: some View {
        VStack(spacing: 12) {
            header
            Text("Tap a day to set your workout and how hard it is. Harder days get more carbs.")
                .font(V2Font.inter(13, .medium))
                .foregroundStyle(V2Color.sec)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 6) {
                ForEach(1...7, id: \.self) { weekday in
                    dayRow(weekday: weekday)
                }
            }

            proCard
            Spacer(minLength: 0)
        }
        .padding(.top, V2Layout.topPadding)
        .padding(.horizontal, V2Layout.screenHPadding)
        .padding(.bottom, 90)
        .background(V2Color.bg)
        .overlay {
            if editingWeekday != nil {
                Color.black.opacity(0.35).ignoresSafeArea()
            }
        }
        .sheet(item: $editingWeekday) { item in
            WorkoutEditSheet(store: store, weekday: item.id)
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
        }
        .sheet(isPresented: $showSettings) {
            V2DebugSettingsSheet()
        }
        .onLongPressGesture(minimumDuration: 0.8) {
            showSettings = true
        }
    }

    private var header: some View {
        HStack {
            V2RoundButton(systemName: "chevron.left") {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: store.selectedDate) ?? store.selectedDate
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Your week")
                    .font(V2Font.serif(30))
                    .foregroundStyle(V2Color.ink)
                Text(weekRangeLabel + " · repeats weekly")
                    .font(V2Font.inter(12, .semibold))
                    .foregroundStyle(V2Color.sec)
            }
            Spacer()
            V2RoundButton(systemName: "chevron.right") {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: store.selectedDate) ?? store.selectedDate
            }
        }
    }

    private var weekRangeLabel: String {
        let start = weekStart
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        return "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private func dayRow(weekday: Int) -> some View {
        let date = dateForWeekday(weekday)
        let split = store.split.first { $0.weekday == weekday } ?? SplitDay(weekday: weekday, workout: "Rest", effort: nil)
        let targets = TargetCalculator.targets(for: split, settings: store.settings)
        let isToday = Calendar.current.isDateInToday(date) || Calendar.current.isDate(date, inSameDayAs: V2MockData.startMonday)

        return Button {
            editingWeekday = WeekdayEdit(id: weekday)
        } label: {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(shortWeekday(weekday))
                        .font(V2Font.inter(11, .bold))
                        .tracking(1)
                        .foregroundStyle(V2Color.sec)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(V2Font.inter(17, .heavy))
                        .foregroundStyle(V2Color.ink)
                }
                .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(split.workout.isEmpty ? "+ Add workout" : split.workout)
                        .font(V2Font.inter(16, .bold))
                        .foregroundStyle(split.workout.isEmpty ? V2Color.ter : V2Color.ink)
                    if let effort = split.effort, split.workout != "Rest" {
                        Text(effort.rawValue)
                            .font(V2Font.inter(11.5, .bold))
                            .foregroundStyle(V2Color.ink)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 8)
                            .background(effortColor(effort))
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(targets.kcal.formatted(.number.grouping(.automatic))) kcal")
                        .font(V2Font.inter(14, .heavy))
                    Text("\(targets.carbs)g carbs")
                        .font(V2Font.inter(11, .semibold))
                        .foregroundStyle(V2Color.ter)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 62)
            .v2Card(radius: 20)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(V2Color.accent, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var proCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(V2Color.accentDeep)
            Text("**Free** estimates from your effort. **Pro** reads the actual workout (sets, distances, times) and sets exact targets.")
                .font(V2Font.inter(13, .medium))
                .foregroundStyle(V2Color.ink)
        }
        .padding(14)
        .background(V2Color.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(V2Color.accent, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        )
    }

    private func dateForWeekday(_ weekday: Int) -> Date {
        let start = weekStart
        let startWd = V2Calendar.specWeekday(start)
        let delta = weekday - startWd
        return Calendar.current.date(byAdding: .day, value: delta, to: start) ?? start
    }

    private func shortWeekday(_ weekday: Int) -> String {
        ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][weekday - 1]
    }

    private func effortColor(_ effort: Effort) -> Color {
        switch effort {
        case .hard: V2Color.effortHard
        case .medium: V2Color.effortMedium
        case .light: V2Color.effortLight
        }
    }
}

struct WeekdayEdit: Identifiable {
    let id: Int
}

extension Date {
    var startOfWeek: Date {
        let cal = Calendar.current
        let day = V2Calendar.specWeekday(self)
        return cal.date(byAdding: .day, value: -(day - 1), to: cal.startOfDay(for: self)) ?? self
    }
}

#Preview {
    WorkoutsScreenView(store: FuelStore())
}
