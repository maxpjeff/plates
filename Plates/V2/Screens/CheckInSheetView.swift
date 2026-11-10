import SwiftUI

struct CheckInSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: FuelStore
    @AppStorage("isPro") private var isPro = false

    @State private var feel = 2
    @State private var tags: Set<String> = []
    @State private var ateYesterday = "all"
    @State private var missedIDs: Set<UUID> = []

    private let tagOptions = ["Sore legs", "Sluggish", "Poor sleep", "Always hungry", "Stomach off", "All good"]
    private let feelLabels = ["Drained", "Low", "Okay", "Good", "Great"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Good morning, \(store.userName)")
                .font(V2Font.serif(32))
                .foregroundStyle(V2Color.ink)
            Text("\(store.selectedDate.formatted(.dateTime.weekday(.wide))), \(store.selectedDate.formatted(.dateTime.month(.abbreviated).day())) · \(todayChip)")
                .font(V2Font.inter(13.5, .medium))
                .foregroundStyle(V2Color.sec)

            sectionTitle("How do you feel?")
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    Button {
                        feel = index
                    } label: {
                        Text(feelLabels[index])
                            .font(V2Font.inter(12, .semibold))
                            .foregroundStyle(V2Color.ink)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(feel == index ? V2Color.accent : V2Color.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(V2Color.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("Anything off?")
            FlowLayoutV2(spacing: 8) {
                ForEach(tagOptions, id: \.self) { tag in
                    Button {
                        toggleTag(tag)
                    } label: {
                        Text(tag)
                            .font(V2Font.inter(12, .semibold))
                            .foregroundStyle(tags.contains(tag) ? Color.white : V2Color.ink)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(tags.contains(tag) ? V2Color.ink : V2Color.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(V2Color.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            sectionTitle("Did you eat yesterday's plan?")
            HStack(spacing: 6) {
                ateButton("all", "All of it")
                ateButton("most", "Most")
                ateButton("no", "Not really")
            }

            if ateYesterday != "all" {
                VStack(spacing: 6) {
                    ForEach(yesterdayMeals) { meal in
                        Button {
                            toggleMissed(meal.id)
                        } label: {
                            HStack {
                                Text(meal.name)
                                    .font(V2Font.inter(14, .medium))
                                    .strikethrough(missedIDs.contains(meal.id))
                                    .foregroundStyle(missedIDs.contains(meal.id) ? V2Color.ter : V2Color.ink)
                                Spacer()
                                if missedIDs.contains(meal.id) {
                                    Circle().stroke(V2Color.line, lineWidth: 1.5).frame(width: 20, height: 20)
                                } else {
                                    Circle()
                                        .fill(V2Color.met)
                                        .frame(width: 20, height: 20)
                                        .overlay {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .v2Card(radius: 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            proInsightCard
                .blur(radius: isPro ? 0 : 6)
                .overlay {
                    if !isPro {
                        Text("Unlock with Pro")
                            .font(V2Font.inter(13, .bold))
                            .foregroundStyle(V2Color.ink)
                    }
                }

            Button(action: startDay) {
                Text("Start my day")
                    .font(V2Font.inter(16, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(V2Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("Skip today", action: skip)
                .font(V2Font.inter(14, .semibold))
                .foregroundStyle(V2Color.sec)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(height: 772)
        .frame(maxWidth: .infinity)
        .background(V2Color.bg)
    }

    private var todayChip: String {
        let split = store.split(for: store.selectedDate)
        if split.workout == "Rest" { return "\(split.workout) today" }
        return "\(split.workout) · \(split.effort?.rawValue ?? "Medium") today"
    }

    private var yesterdayMeals: [FuelMeal] {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: store.selectedDate) ?? store.selectedDate
        let plan = store.plan(for: yesterday)
        return MealSlot.allCases.compactMap { slot -> FuelMeal? in
            guard let id = plan.picks[slot] else { return nil }
            return store.meals.first { $0.id == id }
        }
    }

    private var proInsightCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundStyle(V2Color.accentDeep)
                Text("Pro · Pattern spotted")
                    .font(V2Font.inter(13, .bold))
            }
            Text(insightText)
                .font(V2Font.inter(13, .medium))
                .foregroundStyle(V2Color.ink)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(V2Color.sageTint)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(V2Color.sageLine, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        )
    }

    private var insightText: String {
        if tags.contains("Poor sleep") {
            return "Sleep looks rough — keep breakfast easy and front-load carbs before hard sessions."
        }
        if tags.contains("Sore legs") {
            return "Leg soreness plus a hard day ahead — extra carbs at lunch may help you hit targets without forcing dinner."
        }
        if feel <= 1 {
            return "Energy is low today. Favor familiar meals and hit protein early."
        }
        return "You're trending steady. Matching yesterday's meal timing could keep energy smooth through practice."
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(V2Font.inter(14, .bold))
            .foregroundStyle(V2Color.ink)
    }

    private func ateButton(_ value: String, _ title: String) -> some View {
        Button {
            ateYesterday = value
        } label: {
            Text(title)
                .font(V2Font.inter(12, .semibold))
                .foregroundStyle(ateYesterday == value ? Color.white : V2Color.ink)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(ateYesterday == value ? V2Color.ink : V2Color.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(V2Color.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func toggleTag(_ tag: String) {
        if tag == "All good" {
            tags = ["All good"]
            return
        }
        tags.remove("All good")
        if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
    }

    private func toggleMissed(_ id: UUID) {
        if missedIDs.contains(id) { missedIDs.remove(id) } else { missedIDs.insert(id) }
    }

    private func startDay() {
        saveCheckIn()
        dismiss()
    }

    private func skip() {
        saveCheckIn(empty: true)
        dismiss()
    }

    private func saveCheckIn(empty: Bool = false) {
        let checkIn = CheckIn(
            date: store.selectedDate,
            feel: empty ? 2 : feel,
            tags: empty ? [] : Array(tags),
            ateYesterday: empty ? "all" : ateYesterday,
            missedMealIDs: empty ? [] : Array(missedIDs)
        )
        _ = checkIn
    }
}

#Preview {
    CheckInSheetView(store: FuelStore())
}
