import SwiftUI

struct TodayView: View {
    let model: TodayScreenModel
    var onProfile: () -> Void = {}
    var onAddBefore: () -> Void = {}
    var onEditBefore: () -> Void = {}
    var onLogSession: () -> Void = {}
    var onLogLive: () -> Void = {}
    var onReflect: () -> Void = {}
    var onEditReflect: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapToday) {
                ScreenHeader(overline: model.overline, title: "Today") {
                    ProfileAvatarButton(initials: model.profileInitials, action: onProfile)
                }

                DayStrip(days: model.dayStrip)

                summaryCard

                HStack(alignment: .firstTextBaseline) {
                    Text("Your day")
                        .font(InterFont.inter(22, .heavy))
                        .tracking(-0.2)
                    Spacer()
                    Text("\(model.mealsCount) meals · \(model.sessionsCount) session")
                        .font(InterFont.inter(13, .medium))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                .padding(.top, 6)

                timeline
            }
            .padding(.horizontal, DesignSystem.Layout.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, DesignSystem.Layout.todayScrollBottomPadding)
        }
        .background(DesignSystem.Color.bg)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                LoadBadge(label: model.load, style: .large, headerStyle: true)
                Text(model.sessionSubtitle)
                    .font(InterFont.inter(14, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(PlatesFormat.grouped(model.kcalLeft))
                        .font(InterFont.inter(46, .heavy))
                        .tracking(-1.38)
                        .monospacedDigit()
                    Text("kcal to go · \(PlatesFormat.grouped(model.kcalEaten)) of \(PlatesFormat.grouped(model.kcalTarget)) eaten")
                        .font(InterFont.inter(14, .medium))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                Spacer()
                CalorieRing(progress: model.calorieProgress, size: 84, lineWidth: 10) {
                    Text("\(Int(model.calorieProgress * 100))%")
                        .font(InterFont.inter(15, .heavy))
                        .foregroundStyle(DesignSystem.Color.ink)
                }
            }

            HStack(spacing: 14) {
                macroColumn("Protein", eaten: model.proteinEaten, target: model.proteinTarget, percent: model.proteinPercent, color: DesignSystem.Color.accent)
                macroColumn("Carbs", eaten: model.carbsEaten, target: model.carbsTarget, percent: model.carbsPercent, color: DesignSystem.Color.macroCarbs)
                macroColumn("Fat", eaten: model.fatEaten, target: model.fatTarget, percent: model.fatPercent, color: DesignSystem.Color.macroFat)
            }
        }
        .padding(20)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }

    private func macroColumn(_ title: String, eaten: Int, target: Int, percent: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(InterFont.inter(12, .semibold))
                .foregroundStyle(DesignSystem.Color.inkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(eaten)")
                    .font(InterFont.inter(17, .bold))
                    .monospacedDigit()
                Text("/\(target) g")
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            .padding(.top, 3)
            .padding(.bottom, 7)
            PlatesMacroBar(percent: percent, color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeline: some View {
        VStack(spacing: 0) {
            ForEach(Array(model.timeline.enumerated()), id: \.element.id) { index, item in
                let isLast = index == model.timeline.count - 1
                switch item {
                case .meal(let meal):
                    TimelineRow(
                        time: meal.time,
                        node: meal.eaten ? .eaten : .upcoming,
                        showLine: !isLast
                    ) {
                        MealCard(
                            role: meal.role,
                            name: meal.name,
                            kcal: meal.kcal,
                            protein: meal.protein,
                            carbs: meal.carbs,
                            fat: meal.fat,
                            eaten: meal.eaten
                        )
                    }
                case .session(let session):
                    TimelineRow(
                        time: session.time,
                        node: .session,
                        showLine: !isLast,
                        sessionTime: true
                    ) {
                        SessionTimelineContent(
                            session: session,
                            onAddBefore: onAddBefore,
                            onEditBefore: onEditBefore,
                            onLogSession: onLogSession,
                            onLogLive: onLogLive,
                            onReflect: onReflect,
                            onEditReflect: onEditReflect
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    TodayView(model: MockData.todayModel)
}
