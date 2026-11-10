import SwiftUI

// MARK: - Flow layout

struct FlowChipLayout: Layout {
    var spacing: CGFloat
    var rowSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + rowSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

// MARK: - Screen header

struct ScreenHeader<Accessory: View>: View {
    let overline: String
    let title: String
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(overline)
                    .font(InterFont.inter(14, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                Text(title)
                    .font(InterFont.inter(34, .heavy))
                    .tracking(-0.68)
                    .foregroundStyle(DesignSystem.Color.ink)
            }
            Spacer(minLength: 8)
            accessory()
        }
    }
}

// MARK: - Day strip

struct DayPill: View {
    let weekday: String
    let dateNumber: Int
    let load: DayLoadLabel
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Text(weekday)
                .font(InterFont.inter(12, isSelected ? .medium : .medium))
                .foregroundStyle(isSelected ? DesignSystem.Color.onDarkSecondary : DesignSystem.Color.inkSecondary)
            Text("\(dateNumber)")
                .font(InterFont.inter(17, .bold))
                .foregroundStyle(isSelected ? .white : DesignSystem.Color.ink)
            dot
        }
        .frame(width: 44)
        .padding(.top, 10)
        .padding(.bottom, 9)
        .background(isSelected ? DesignSystem.Color.ink : DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.dayPill, style: .continuous))
    }

    @ViewBuilder
    private var dot: some View {
        if isSelected {
            Circle()
                .fill(Color(hex: "60A5FA"))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "1D4ED8"), lineWidth: 2)
                        .frame(width: 10, height: 10)
                )
        } else {
            Circle()
                .fill(load.stripDotColor)
                .frame(width: 6, height: 6)
        }
    }
}

struct DayStrip: View {
    let days: [DayStripModel]

    var body: some View {
        HStack {
            ForEach(days) { day in
                DayPill(
                    weekday: day.weekday,
                    dateNumber: day.dateNumber,
                    load: day.load,
                    isSelected: day.isSelected
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Load badge

enum LoadBadgeSize { case large, small }

struct LoadBadge: View {
    let label: DayLoadLabel
    var style: LoadBadgeSize = .small
    var headerStyle: Bool = false

    private var text: String {
        headerStyle ? label.headerBadgeTitle : label.badgeTitle
    }

    var body: some View {
        Text(text)
            .font(InterFont.inter(style == .large ? 13 : 11, .bold))
            .foregroundStyle(label.textColor)
            .padding(.vertical, style == .large ? (headerStyle ? 6 : 5) : 3)
            .padding(.horizontal, style == .large ? (headerStyle ? 12 : 11) : 9)
            .background(label.fillColor)
            .clipShape(Capsule())
    }
}

// MARK: - Chip

struct PlatesChip: View {
    let text: String
    var style: PlanChipStyle?

    init(_ text: String, style: PlanChipStyle? = nil) {
        self.text = text
        self.style = style
    }

    init(_ style: PlanChipStyle) {
        switch style {
        case .standard(let t): self.text = t; self.style = nil
        case .ptGuided(let t): self.text = t; self.style = style
        }
    }

    var body: some View {
        Text(text)
            .font(InterFont.inter(12, .semibold))
            .foregroundStyle(foreground)
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(background)
            .clipShape(Capsule())
    }

    private var foreground: Color {
        if case .ptGuided = style { return DesignSystem.Color.ptChipText }
        return DesignSystem.Color.chipText
    }

    private var background: Color {
        if case .ptGuided = style { return DesignSystem.Color.accentTint }
        return DesignSystem.Color.bg
    }

    private var verticalPadding: CGFloat {
        if style != nil { return 3 }
        return 4
    }

    private var horizontalPadding: CGFloat {
        if style != nil { return 8 }
        return 9
    }
}

struct ChipFlow: View {
    let chips: [String]
    var spacing: CGFloat = 6
    var ptStyles: Set<String> = []

    var body: some View {
        FlowChipLayout(spacing: spacing, rowSpacing: spacing) {
            ForEach(chips, id: \.self) { chip in
                if ptStyles.contains(chip) {
                    PlatesChip(.ptGuided(chip))
                } else {
                    PlatesChip(chip)
                }
            }
        }
    }
}

// MARK: - Macro bar

struct PlatesMacroBar: View {
    let percent: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(DesignSystem.Color.bg)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, geo.size.width * min(1, percent)))
                }
        }
        .frame(height: 6)
    }
}

// MARK: - Calorie ring

struct CalorieRing<Center: View>: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignSystem.Color.bg, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, progress))
                .stroke(DesignSystem.Color.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            center()
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tab bar

private struct TabBarItem: Identifiable {
    let tab: PlatesTab
    let icon: String
    let label: String?
    var id: PlatesTab { tab }
}

struct TabBarBottomChrome: View {
    @Binding var selection: PlatesTab

    var body: some View {
        VStack(spacing: 0) {
            MainTabBar(selection: $selection)
                .padding(.top, DesignSystem.Layout.tabBarChromeExtra)
        }
        .padding(.bottom, DesignSystem.Layout.tabBarBottomInset)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.Color.bg.ignoresSafeArea(edges: .bottom))
    }
}

struct MainTabBar: View {
    @Binding var selection: PlatesTab
    @Namespace private var pillNamespace

    private let items: [TabBarItem] = [
        TabBarItem(tab: .today, icon: "house", label: "Today"),
        TabBarItem(tab: .plan, icon: "calendar", label: "Plan"),
        TabBarItem(tab: .design, icon: "square.and.pencil", label: "Design"),
        TabBarItem(tab: .progress, icon: "chart.bar", label: "Progress"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                tabButton(item, index: index)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 6)
        .frame(height: DesignSystem.Layout.tabBarHeight)
        .background(DesignSystem.Color.ink)
        .clipShape(Capsule())
        .padding(.horizontal, DesignSystem.Layout.tabBarSideInset)
    }

    private func tabButton(_ item: TabBarItem, index: Int) -> some View {
        let active = selection == item.tab
        let selectedIndex = selection.index

        return Button {
            withAnimation(PlatesTabMotion.slide) {
                selection = item.tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.system(size: active ? 20 : 22, weight: active ? .semibold : .regular))
                if active, let label = item.label {
                    Text(label)
                        .font(InterFont.inter(14, .bold))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .foregroundStyle(active ? DesignSystem.Color.ink : DesignSystem.Color.nodeEmpty)
            .padding(.horizontal, active ? 14 : 10)
            .frame(height: 52)
            .background {
                if active {
                    Capsule()
                        .fill(Color.white)
                        .matchedGeometryEffect(id: "tabPill", in: pillNamespace)
                }
            }
            .offset(x: nudge(for: index, selectedIndex: selectedIndex))
            .animation(PlatesTabMotion.slide, value: selection)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label ?? item.tab.rawValue.capitalized)
    }

    /// Inactive tabs shift slightly away from the selected pill.
    private func nudge(for index: Int, selectedIndex: Int) -> CGFloat {
        guard index != selectedIndex else { return 0 }
        return index < selectedIndex ? -4 : 4
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(InterFont.inter(16, .bold))
                .foregroundStyle(DesignSystem.Color.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(DesignSystem.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline

enum TimelineNodeStyle {
    case eaten, upcoming, session
}

struct TimelineRow<Content: View>: View {
    let time: String
    let node: TimelineNodeStyle
    let showLine: Bool
    var sessionTime: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(time)
                .font(InterFont.inter(12, .semibold))
                .foregroundStyle(sessionTime ? DesignSystem.Color.ink : DesignSystem.Color.inkSecondary)
                .frame(width: 58, alignment: .trailing)
                .padding(.top, 17)

            VStack(spacing: 0) {
                nodeView
                    .padding(.top, 19)
                if showLine {
                    Rectangle()
                        .fill(DesignSystem.Color.timelineLine)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 4)
                }
            }
            .frame(width: 16)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var nodeView: some View {
        switch node {
        case .eaten:
            Circle().fill(DesignSystem.Color.accent).frame(width: 12, height: 12)
        case .upcoming:
            Circle()
                .fill(DesignSystem.Color.bg)
                .overlay(Circle().stroke(DesignSystem.Color.nodeEmpty, lineWidth: 2))
                .frame(width: 12, height: 12)
        case .session:
            Circle().fill(DesignSystem.Color.ink).frame(width: 14, height: 14)
        }
    }
}

struct MealCard: View {
    let role: String
    let name: String
    let kcal: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let eaten: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text(role.uppercased())
                    .font(InterFont.inter(11, .bold))
                    .tracking(0.66)
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                Text(name)
                    .font(InterFont.inter(16, .semibold))
                    .foregroundStyle(DesignSystem.Color.ink)
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                ChipFlow(chips: ["\(kcal) kcal", "P \(protein)g", "C \(carbs)g", "F \(fat)g"], spacing: 6)
            }
            Spacer(minLength: 0)
            checkmark
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous))
    }

    @ViewBuilder
    private var checkmark: some View {
        if eaten {
            Circle()
                .fill(DesignSystem.Color.accent)
                .frame(width: 26, height: 26)
                .overlay {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DesignSystem.Color.ink)
                }
        } else {
            Circle()
                .strokeBorder(DesignSystem.Color.checkEmpty, lineWidth: 2)
                .frame(width: 26, height: 26)
        }
    }
}

struct SessionCard: View {
    let caps: String
    let title: String
    let blocks: [SessionBlockRow]
    var onLogSession: () -> Void = {}
    var onLogLive: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(caps)
                    .font(InterFont.inter(11, .bold))
                    .tracking(0.66)
                    .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                Text(title)
                    .font(InterFont.inter(22, .heavy))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                ForEach(blocks) { block in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.sessionIconTile, style: .continuous)
                            .fill(DesignSystem.Color.darkTile)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Image(systemName: block.icon)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.name)
                                .font(InterFont.inter(14, .bold))
                                .foregroundStyle(.white)
                            Text(block.detail)
                                .font(InterFont.inter(13, .regular))
                                .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                        }
                    }
                }
            }

            VStack(spacing: 10) {
                Button(action: onLogSession) {
                    Text("Log session")
                        .font(InterFont.inter(16, .bold))
                        .foregroundStyle(DesignSystem.Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(DesignSystem.Color.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.button, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onLogLive) {
                    Text("or log live during it")
                        .font(InterFont.inter(13, .semibold))
                        .foregroundStyle(DesignSystem.Color.onDarkSecondary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(DesignSystem.Color.ink)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.summary, style: .continuous))
    }
}

// MARK: - Fuel components

struct MacroCard: View {
    let label: String
    let eaten: Int
    let target: Int
    let left: String
    let percent: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.uppercased())
                .font(InterFont.inter(12, .bold))
                .tracking(0.6)
                .foregroundStyle(DesignSystem.Color.inkSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(eaten)")
                    .font(InterFont.inter(24, .heavy))
                    .tracking(-0.48)
                    .monospacedDigit()
                Text("/\(target)g")
                    .font(InterFont.inter(13, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            .padding(.top, 6)
            .padding(.bottom, 10)
            PlatesMacroBar(percent: percent, color: color)
            Text(left)
                .font(InterFont.inter(12, .medium))
                .foregroundStyle(DesignSystem.Color.inkSecondary)
                .padding(.top, 8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous))
    }
}

struct FoodRow: View {
    let model: FoodRowModel
    var showDivider: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.foodIcon, style: .continuous)
                    .fill(DesignSystem.Color.bg)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: model.icon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(DesignSystem.Color.ink)
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(displayName)
                        .font(InterFont.inter(15, .semibold))
                        .foregroundStyle(DesignSystem.Color.ink)
                        .padding(.bottom, 6)
                    ChipFlow(
                        chips: ["P \(model.protein)g", "C \(model.carbs)g", "F \(model.fat)g"],
                        spacing: 5
                    )
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(model.kcal)")
                        .font(InterFont.inter(17, .heavy))
                        .monospacedDigit()
                    Text(model.time)
                        .font(InterFont.inter(11, .medium))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
            }
            .padding(.vertical, 12)
            .opacity(model.planned ? 0.55 : 1)

            if showDivider {
                Rectangle()
                    .fill(DesignSystem.Color.divider)
                    .frame(height: 1)
            }
        }
    }

    private var displayName: String {
        model.planned ? "\(model.name) · planned" : model.name
    }
}

// MARK: - Plan components

struct DayCard: View {
    let model: PlanDayModel

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(model.weekdayLabel)
                    .font(InterFont.inter(12, .semibold))
                    .foregroundStyle(model.isToday ? DesignSystem.Color.ink : DesignSystem.Color.inkSecondary)
                Text("\(model.day)")
                    .font(InterFont.inter(22, .heavy))
                    .foregroundStyle(DesignSystem.Color.ink)
                    .lineSpacing(0)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text(model.title)
                    .font(InterFont.inter(16, .bold))
                    .padding(.bottom, 6)
                planChips
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 0) {
                LoadBadge(label: model.load, style: .small)
                Text("\(PlatesFormat.grouped(model.kcal)) kcal")
                    .font(InterFont.inter(12, .semibold))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(DesignSystem.Color.card)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous))
        .overlay {
            if model.isToday {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous)
                    .strokeBorder(DesignSystem.Color.accent, lineWidth: 2)
            }
        }
    }

    @ViewBuilder
    private var planChips: some View {
        FlowChipLayout(spacing: 5, rowSpacing: 5) {
            ForEach(Array(model.chips.enumerated()), id: \.offset) { _, chip in
                PlatesChip(chip)
            }
        }
    }
}

struct LoadBarChart: View {
    let days: [LoadChartDay]

    var body: some View {
        HStack(alignment: .bottom) {
            ForEach(days) { day in
                VStack(spacing: 8) {
                    bar(for: day)
                    Text(day.letter)
                        .font(InterFont.inter(12, day.isToday ? .heavy : .semibold))
                        .foregroundStyle(day.isToday ? DesignSystem.Color.ink : DesignSystem.Color.inkSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 150, alignment: .bottom)
    }

    @ViewBuilder
    private func bar(for day: LoadChartDay) -> some View {
        if day.isToday {
            Capsule()
                .fill(day.load.fillColor)
                .frame(width: 34, height: day.barHeight)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .padding(-3)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(DesignSystem.Color.accent, lineWidth: 2)
                        .padding(-5)
                }
        } else {
            Capsule()
                .fill(day.load.fillColor)
                .frame(width: 34, height: day.barHeight)
        }
    }
}

struct LoadChartLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legend("High", DayLoadLabel.high.fillColor)
            legend("Moderate", DayLoadLabel.moderate.fillColor)
            legend("Low", DayLoadLabel.low.fillColor)
            legend("Rest", DayLoadLabel.rest.fillColor)
        }
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title)
                .font(InterFont.inter(12, .semibold))
                .foregroundStyle(DesignSystem.Color.chipText)
        }
    }
}

// MARK: - Profile avatar

struct ProfileAvatarButton: View {
    let initials: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(initials)
                .font(InterFont.inter(15, .bold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(DesignSystem.Color.ink)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Profile")
    }
}

struct PlanAddButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(DesignSystem.Color.ink)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Color.accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add session")
    }
}

struct FuelAddFAB: View {
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(DesignSystem.Color.ink)
                .frame(width: 60, height: 60)
                .background(DesignSystem.Color.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 10, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add food")
    }
}
