import SwiftUI

struct PlanView: View {
    let model: PlanScreenModel
    var onAddSession: () -> Void = {}
    var onSelectDay: (Date) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapPlan) {
                ScreenHeader(overline: model.overline, title: "This week") {
                    PlanAddButton(action: onAddSession)
                }

                Text("Tap a day to place workouts and meals from Design.")
                    .font(InterFont.inter(14, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)

                dayLoadCard

                ForEach(model.days) { day in
                    Button { onSelectDay(day.date) } label: {
                        DayCard(model: day)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, DesignSystem.Layout.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, DesignSystem.Layout.scrollBottomPadding)
        }
        .background(DesignSystem.Color.bg)
    }

    private var dayLoadCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("Day Load")
                    .font(InterFont.inter(17, .heavy))
                    .tracking(-0.2)
                Spacer()
                Text(model.loadSummary)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            LoadBarChart(days: model.chartDays)
            LoadChartLegend()
        }
        .padding(20)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }
}

#Preview {
    PlanView(model: MockData.planModel)
}
