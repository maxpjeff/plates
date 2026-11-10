import SwiftUI

struct FoodIllustrationView: View {
    let art: FoodArt
    let colors: [String]

    var body: some View {
        ZStack {
            switch art {
            case .bowl:
                Ellipse()
                    .fill(V2Color.dish)
                    .frame(width: 52, height: 22)
                    .offset(y: 14)
                ForEach(Array(colors.prefix(3).enumerated()), id: \.offset) { index, hex in
                    Circle()
                        .fill(Color(v2Hex: hex))
                        .frame(width: index == 0 ? 16 : 12, height: index == 0 ? 16 : 12)
                        .offset(x: CGFloat(index - 1) * 14, y: -4)
                }
                Ellipse()
                    .stroke(V2Color.dishLine, lineWidth: 1.5)
                    .frame(width: 56, height: 26)
                    .offset(y: 14)
            case .plate:
                Circle()
                    .fill(V2Color.dish)
                    .frame(width: 48, height: 48)
                if let main = colors.first {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(v2Hex: main))
                        .frame(width: 28, height: 18)
                }
                ForEach(Array(colors.dropFirst().prefix(2).enumerated()), id: \.offset) { index, hex in
                    Circle()
                        .fill(Color(v2Hex: hex))
                        .frame(width: 8, height: 8)
                        .offset(x: index == 0 ? -14 : 14, y: 12)
                }
                Circle()
                    .stroke(V2Color.dishLine, lineWidth: 1.5)
                    .frame(width: 48, height: 48)
            case .glass:
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(V2Color.dish)
                    .frame(width: 28, height: 44)
                    .overlay(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(v2Hex: colors.first ?? "E8B49A"))
                            .frame(width: 24, height: 26)
                            .padding(.bottom, 4)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(V2Color.dishLine, lineWidth: 1.5)
                    }
            case .bar:
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(v2Hex: colors.first ?? "E8B49A"))
                    .frame(width: 46, height: 18)
                    .rotationEffect(.degrees(-18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(V2Color.dishLine, lineWidth: 1.5)
                            .frame(width: 46, height: 18)
                            .rotationEffect(.degrees(-18))
                    }
            }
        }
        .frame(width: 64, height: 64)
    }
}

struct V2RoundButton: View {
    let systemName: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(V2Color.ink)
                .frame(width: V2Layout.roundButton, height: V2Layout.roundButton)
                .background(V2Color.card)
                .clipShape(Circle())
                .overlay(Circle().stroke(V2Color.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct V2BottomBar: View {
    @Binding var tab: V2Tab

    var body: some View {
        HStack(spacing: 6) {
            barButton(.fuel, icon: "fork.knife", title: "Fuel")
            barButton(.workouts, icon: "dumbbell", title: "Workouts")
        }
        .padding(6)
        .background(V2Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(V2Color.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .padding(.horizontal, V2Layout.screenHPadding)
        .padding(.bottom, V2Layout.bottomBarInset)
    }

    private func barButton(_ value: V2Tab, icon: String, title: String) -> some View {
        let active = tab == value
        return Button {
            tab = value
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(V2Font.inter(16, .bold))
            }
            .foregroundStyle(active ? Color.white : V2Color.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(active ? V2Color.ink : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum V2Tab { case fuel, workouts }

struct V2CardBorder: ViewModifier {
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(V2Color.card)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(V2Color.line, lineWidth: 1))
    }
}

extension View {
    func v2Card(radius: CGFloat) -> some View {
        modifier(V2CardBorder(radius: radius))
    }
}
