import SwiftUI

struct MockupCalorieHero: View {
    let kcalLeft: Int
    let eaten: Int
    let target: Int
    let progress: Double

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(kcalLeft.formatted())
                .font(PlatesFont.statHero(MockupLayout.heroKcalSize))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 8) {
                Text("kcal to go · \(eaten) of \(target) eaten")
                    .font(PlatesFont.bodyMedium(14))
                    .foregroundStyle(PlatesColor.muted)
                ZStack {
                    Circle()
                        .stroke(PlatesColor.soft, lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: min(1, progress))
                        .stroke(PlatesColor.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(PlatesFont.bodySemibold(13))
                }
                .frame(width: 56, height: 56)
            }
            Spacer(minLength: 0)
        }
    }
}

struct MockupMacroStrip: View {
    let protein: String
    let carbs: String
    let fat: String

    var body: some View {
        HStack(spacing: 0) {
            macroCol("Protein", value: protein)
            macroCol("Carbs", value: carbs)
            macroCol("Fat", value: fat)
        }
    }

    private func macroCol(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(PlatesFont.secondary(13))
                .foregroundStyle(PlatesColor.muted)
            Text(value)
                .font(PlatesFont.bodySemibold(15))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MockupFuelCalorieBlock: View {
    let eaten: Int
    let target: Int
    let base: Int
    let sessionBonus: Int
    let left: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CALORIES")
                .platesLabelCaps()

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(eaten)")
                    .font(PlatesFont.statHero(44))
                Text("of \(target) eaten")
                    .font(PlatesFont.bodyMedium())
                    .foregroundStyle(PlatesColor.muted)
                Spacer()
                Text("\(left)")
                    .font(PlatesFont.statHero(36))
                Text("LEFT")
                    .font(PlatesFont.labelCaps(11))
                    .foregroundStyle(PlatesColor.muted)
            }

            Text("Base \(base.formatted()) + \(sessionBonus) for today's session")
                .font(PlatesFont.secondary(13))
                .foregroundStyle(PlatesColor.muted)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatesColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: MockupLayout.cardRadius, style: .continuous))
    }
}

struct MockupMacroFuelRows: View {
    let proteinEaten: Int
    let proteinTarget: Int
    let carbsEaten: Int
    let carbsTarget: Int
    let fatEaten: Int
    let fatTarget: Int

    var body: some View {
        VStack(spacing: 14) {
            row("PROTEIN", value: "\(proteinEaten)/\(proteinTarget)g", left: "\(max(0, proteinTarget - proteinEaten))g left")
            row("CARBS", value: "\(carbsEaten)/\(carbsTarget)g", left: "\(max(0, carbsTarget - carbsEaten))g left")
            row("FAT", value: "\(fatEaten)/\(fatTarget)g", left: "\(max(0, fatTarget - fatEaten))g left")
        }
    }

    private func row(_ title: String, value: String, left: String) -> some View {
        HStack {
            Text(title)
                .font(PlatesFont.labelCaps(11))
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(PlatesFont.bodySemibold(16))
            Spacer()
            Text(left)
                .font(PlatesFont.secondary(13))
                .foregroundStyle(PlatesColor.muted)
        }
    }
}
