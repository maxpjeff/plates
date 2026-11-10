import SwiftUI

struct FuelView: View {
    let model: FuelScreenModel
    var onSearch: () -> Void = {}
    var onScan: () -> Void = {}
    var onAddGap: () -> Void = {}
    var onAddFood: () -> Void = {}

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapFuel) {
                    ScreenHeader(overline: model.overline, title: "Fuel") {
                        LoadBadge(label: model.load, style: .large, headerStyle: true)
                    }

                    DayStrip(days: model.dayStrip)

                    calorieCard

                    HStack(spacing: 10) {
                        MacroCard(label: "Protein", eaten: model.proteinEaten, target: model.proteinTarget, left: "\(model.proteinLeft)g left", percent: model.proteinPercent, color: DesignSystem.Color.accent)
                        MacroCard(label: "Carbs", eaten: model.carbsEaten, target: model.carbsTarget, left: "\(model.carbsLeft)g left", percent: model.carbsPercent, color: DesignSystem.Color.macroCarbs)
                        MacroCard(label: "Fat", eaten: model.fatEaten, target: model.fatTarget, left: "\(model.fatLeft)g left", percent: model.fatPercent, color: DesignSystem.Color.macroFat)
                    }

                    gapCard

                    HStack(spacing: 10) {
                        quickButton(icon: "magnifyingglass", title: "Search foods", action: onSearch)
                        quickButton(icon: "barcode.viewfinder", title: "Scan barcode", action: onScan)
                    }

                    foodListCard
                }
                .padding(.horizontal, DesignSystem.Layout.screenPadding)
                .padding(.top, 4)
                .padding(.bottom, DesignSystem.Layout.scrollBottomPadding)
            }

            FuelAddFAB(action: onAddFood)
                .padding(.trailing, 24)
                .padding(.bottom, 112)
        }
        .background(DesignSystem.Color.bg)
    }

    private var calorieCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("CALORIES")
                    .font(InterFont.inter(12, .bold))
                    .tracking(0.6)
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                Text("\(model.kcalEaten)")
                    .font(InterFont.inter(52, .heavy))
                    .tracking(-1.56)
                    .monospacedDigit()
                    .padding(.top, 6)
                Text("of \(PlatesFormat.grouped(model.kcalTarget)) eaten")
                    .font(InterFont.inter(15, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                    .padding(.top, 4)
                Text(model.fuelBreakdown)
                    .font(InterFont.inter(12, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                    .padding(.top, 10)
            }
            Spacer()
            CalorieRing(progress: model.calorieProgress, size: 112, lineWidth: 12) {
                VStack(spacing: 2) {
                    Text(PlatesFormat.grouped(model.kcalLeft))
                        .font(InterFont.inter(21, .heavy))
                        .monospacedDigit()
                    Text("LEFT")
                        .font(InterFont.inter(11, .semibold))
                        .tracking(0.66)
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
            }
        }
        .padding(22)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }

    private var gapCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.gapTitle)
                    .font(InterFont.inter(14, .bold))
                    .foregroundStyle(DesignSystem.Color.ink)
                Text(model.gapBody)
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.accentTintText)
            }
            Spacer(minLength: 8)
            Button(action: onAddGap) {
                Text("Add")
                    .font(InterFont.inter(14, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(DesignSystem.Color.ink)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.accentTint)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous))
    }

    private func quickButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(InterFont.inter(15, .semibold))
            }
            .foregroundStyle(DesignSystem.Color.ink)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(DesignSystem.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foodListCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today's food")
                    .font(InterFont.inter(20, .heavy))
                Spacer()
                Text("\(model.eatenCount) eaten · \(model.plannedCount) planned")
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            .padding(.vertical, 12)
            .padding(.bottom, 4)

            ForEach(Array(model.foods.enumerated()), id: \.element.id) { index, food in
                FoodRow(model: food, showDivider: index < model.foods.count - 1)
            }
        }
        .padding(.top, 6)
        .padding(.horizontal, 18)
        .padding(.bottom, 4)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }
}

#Preview {
    FuelView(model: MockData.fuelModel)
}
