import SwiftUI

struct ProgressScreenModel {
    let overline: String
    let score: Int
    let streakDays: Int
    let vsLastWeek: Int
    let calendarMonth: Date
    let dayCompletionByDay: [Int: Int]
    let bestWeekScore: Int
    let messageTitle: String
    let messageSubtitle: String
    let goals: [ProgressGoalRowModel]
    let prsByCategory: [PRCategory: [PersonalRecordRow]]
}

struct ProgressGoalRowModel: Identifiable, Equatable {
    let id: UUID
    let title: String
    let remaining: String
    let progress: Double
    let nowLine: String
    let deadlineLine: String
}

struct PlatesProgressView: View {
    let model: ProgressScreenModel
    @State private var calendarMonth: Date
    @State private var prCategory: PRCategory = .competition

    init(model: ProgressScreenModel) {
        self.model = model
        _calendarMonth = State(initialValue: model.calendarMonth)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapProgress) {
                ScreenHeader(overline: model.overline, title: "Progress") {
                    EmptyView()
                }
                scoreCard
                goalsCard
                prCard
            }
            .padding(.horizontal, DesignSystem.Layout.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, DesignSystem.Layout.scrollBottomPadding)
        }
        .background(DesignSystem.Color.bg)
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PLATES SCORE")
                    .font(InterFont.inter(11, .bold))
                    .tracking(0.66)
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Color.accent)
                    Text("\(model.streakDays)-day streak")
                        .font(InterFont.inter(13, .bold))
                        .foregroundStyle(DesignSystem.Color.ink)
                }
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(model.score)")
                            .font(InterFont.inter(60, .heavy))
                            .tracking(-2.4)
                            .monospacedDigit()
                        Text("/100")
                            .font(InterFont.inter(15, .semibold))
                            .foregroundStyle(DesignSystem.Color.inkSecondary)
                    }
                    .padding(.top, 4)
                    Text(model.vsLastWeek >= 0 ? "+\(model.vsLastWeek) vs last week" : "\(model.vsLastWeek) vs last week")
                        .font(InterFont.inter(12, .bold))
                        .foregroundStyle(DesignSystem.Color.chipText)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 9)
                        .background(DesignSystem.Color.bg)
                        .clipShape(Capsule())
                }
                Spacer(minLength: 0)
                MiniMonthCalendar(month: $calendarMonth, dayCompletion: model.dayCompletionByDay)
            }

            Rectangle()
                .fill(DesignSystem.Color.divider)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 12) {
                Text(model.messageTitle)
                    .font(InterFont.inter(17, .heavy))
                    .tracking(-0.17)
                Text(model.messageSubtitle)
                    .font(InterFont.inter(14, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                    .padding(.top, 3)
                bestWeekBar
            }
            .padding(.top, 14)
        }
        .padding(20)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }

    private var bestWeekBar: some View {
        let current = Double(model.score) / 100
        let best = Double(model.bestWeekScore) / 100
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DesignSystem.Color.bg)
                    .frame(height: 8)
                Capsule()
                    .fill(DesignSystem.Color.accent)
                    .frame(width: geo.size.width * current, height: 8)
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(DesignSystem.Color.ink)
                    .frame(width: 2, height: 16)
                    .offset(x: geo.size.width * best - 1)
                Text("Best \(model.bestWeekScore)")
                    .font(InterFont.inter(11, .bold))
                    .foregroundStyle(DesignSystem.Color.ink)
                    .offset(x: geo.size.width * best - 24, y: -18)
            }
        }
        .frame(height: 28)
    }

    private var goalsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Goals")
                    .font(InterFont.inter(20, .heavy))
                Spacer()
                Button {} label: {
                    Text("+ Add")
                        .font(InterFont.inter(13, .bold))
                        .foregroundStyle(DesignSystem.Color.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(DesignSystem.Color.bg)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 12)
            .padding(.bottom, 2)

            ForEach(Array(model.goals.enumerated()), id: \.element.id) { index, goal in
                GoalRow(
                    title: goal.title,
                    remaining: goal.remaining,
                    progress: goal.progress,
                    nowLine: goal.nowLine,
                    deadlineLine: goal.deadlineLine,
                    showDivider: index < model.goals.count - 1
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }

    private var prCard: some View {
        let rows = model.prsByCategory[prCategory] ?? []
        let countLabel: String = {
            switch prCategory {
            case .competition: "4 events"
            case .training: "4 tests"
            case .lift: "4 lifts"
            }
        }()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Personal records")
                    .font(InterFont.inter(20, .heavy))
                Spacer()
                Text(countLabel)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            SegmentedPill(options: PRCategory.allCases, selection: $prCategory) { tab in
                switch tab {
                case .competition: "Competition"
                case .training: "Training"
                case .lift: "Lifts"
                }
            }
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                PRRow(row: row, showDivider: index < rows.count - 1)
            }
        }
        .padding(18)
        .padding(.bottom, 4)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }
}

#Preview {
    PlatesProgressView(model: MockData.progressModel)
}
