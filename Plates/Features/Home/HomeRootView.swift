import SwiftUI
import SwiftData

struct HomeRootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    @State private var showSettings = false
    @State private var summary: MonthlyAccountabilitySummary?

    private var profile: UserProfile? { profiles.first }
    private var firstName: String {
        let name = profile?.name ?? "You"
        return name.split(separator: " ").first.map(String.init) ?? name
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                if let summary {
                    monthlyRecapCard(summary)
                }
                HybridTodaySection()
            }
            .padding(.horizontal, 20)
            .padding(.top, 52)
            .padding(.bottom, 32)
        }
        .background(PlatesColor.bg)
        .refreshable { refreshSummary() }
        .onAppear { refreshSummary() }
        .sheet(isPresented: $showSettings) {
            if let profile {
                SettingsView(profile: profile)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(firstName)'s dashboard")
                .font(PlatesFont.secondary())
                .foregroundStyle(PlatesColor.muted)
            HStack(alignment: .firstTextBaseline) {
                Text(Date.now.formatted(.dateTime.month(.wide).year()))
                    .font(PlatesFont.screenTitle(34))
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Text(initials)
                        .font(PlatesFont.bodySemibold(13))
                        .foregroundStyle(PlatesColor.ink)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().strokeBorder(PlatesColor.line.opacity(0.5), lineWidth: 1))
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    private func monthlyRecapCard(_ summary: MonthlyAccountabilitySummary) -> some View {
        PlatesCard(padding: 20, style: .elevated) {
            VStack(alignment: .leading, spacing: 18) {
                Text("PLATES SCORE")
                    .platesLabelCaps()

                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recapHeadline(summary))
                            .font(PlatesFont.body())
                            .foregroundStyle(PlatesColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(summary.daysMetPlan)")
                                .font(PlatesFont.statHero())
                            Text("days on plan")
                                .font(PlatesFont.bodyMedium())
                                .foregroundStyle(PlatesColor.muted)
                        }
                        Text(previousMonthLabel(summary))
                            .font(PlatesFont.secondary())
                            .foregroundStyle(PlatesColor.muted)
                    }
                    Spacer(minLength: 0)
                    scoreRing(summary.averageScore)
                }

                MonthAccountabilityChart(results: summary.dailyResults)

                HStack {
                    miniStat(title: "Avg score", value: "\(summary.averageScore)")
                    miniStat(title: "Workouts", value: "\(workoutsThisMonth())")
                }
            }
        }
    }

    private func recapHeadline(_ summary: MonthlyAccountabilitySummary) -> String {
        if summary.daysMetPlan >= summary.daysInMonth / 2 {
            return "You're stacking consistent days where fuel and training line up."
        }
        return "Small wins add up — each day you hit protein and your session counts."
    }

    private func previousMonthLabel(_ summary: MonthlyAccountabilitySummary) -> String {
        let prev = summary.previousMonthDaysMet
        let month = Calendar.current.date(byAdding: .month, value: -1, to: Date())?
            .formatted(.dateTime.month(.wide)) ?? "Last month"
        return "\(month): \(prev) days"
    }

    private func scoreRing(_ score: Int) -> some View {
        ZStack {
            Circle()
                .stroke(PlatesColor.soft, lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(PlatesColor.good, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(PlatesFont.statHero(28))
        }
        .frame(width: 72, height: 72)
        .accessibilityLabel("Average score \(score) out of 100")
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(PlatesFont.labelCaps(10))
                .foregroundStyle(PlatesColor.muted)
            Text(value)
                .font(PlatesFont.bodySemibold(17))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PlatesColor.soft.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func workoutsThisMonth() -> Int {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: Date()) else { return 0 }
        let sessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        return sessions.filter { session in
            guard let ended = session.endedAt else { return false }
            return interval.contains(ended)
        }.count
    }

    private var initials: String {
        let name = profile?.name ?? "You"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(1)).uppercased()
    }

    private func refreshSummary() {
        summary = AccountabilityDataStore.monthlySummary(context: context)
    }
}

#Preview {
    HomeRootView()
        .modelContainer(SampleData.previewContainer())
        .environmentObject(AppAppearance.shared)
}
