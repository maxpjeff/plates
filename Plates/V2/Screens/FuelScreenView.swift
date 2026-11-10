import SwiftUI

struct FuelScreenView: View {
    @Bindable var store: FuelStore
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false
    var referenceToday: Date = V2MockData.startMonday

    var body: some View {
        let date = store.selectedDate
        let split = store.split(for: date)
        let targets = store.targets(for: date)
        let totals = store.totals(for: date)
        let lockedCount = store.plan(for: date).locked.count

        VStack(spacing: 10) {
            dateRow(date: date)
            dayTypeLine(split: split)
            totalsCard(targets: targets, totals: totals, lockedCount: lockedCount)
            VStack(spacing: 2) {
                ForEach(MealSlot.allCases) { slot in
                    mealRow(slot: slot, date: date)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.top, V2Layout.topPadding)
        .padding(.bottom, 90)
        .background(V2Color.bg)
        .sheet(isPresented: $showPaywall) {
            V2PaywallSheet()
        }
    }

    private func dateRow(date: Date) -> some View {
        HStack {
            V2RoundButton(systemName: "chevron.left") {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
                store.syncRailIndices()
            }
            Spacer()
            VStack(spacing: 2) {
                Text("\(date.formatted(.dateTime.weekday(.wide))), \(date.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(V2Font.serif(30))
                    .foregroundStyle(V2Color.ink)
                Text(V2Calendar.relativeDayLabel(for: date, today: referenceToday))
                    .font(V2Font.inter(12, .semibold))
                    .foregroundStyle(V2Color.sec)
            }
            Spacer()
            V2RoundButton(systemName: "chevron.right") {
                store.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                store.syncRailIndices()
            }
        }
        .padding(.horizontal, V2Layout.screenHPadding)
    }

    private func dayTypeLine(split: SplitDay) -> some View {
        HStack(spacing: 8) {
            Text(split.workout)
                .font(V2Font.inter(12, .bold))
                .foregroundStyle(V2Color.ink)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(V2Color.chip)
                .clipShape(Capsule())
            Text(effortNote(split: split))
                .font(V2Font.inter(12, .medium))
                .foregroundStyle(V2Color.sec)
            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private func effortNote(split: SplitDay) -> String {
        if split.workout == "Rest" { return "Recovery day" }
        switch split.effort {
        case .hard: return "Hard effort · extra carbs"
        case .medium: return "Medium effort"
        case .light: return "Light effort · lighter carbs"
        case .none: return "Medium effort"
        }
    }

    private func totalsCard(targets: MacroTargets, totals: (kcal: Int, protein: Int, carbs: Int, fat: Int), lockedCount: Int) -> some View {
        VStack(spacing: 11) {
            HStack(spacing: 0) {
                totalColumn(value: formattedKcal(totals.kcal), label: "Calories", target: "of \(formattedKcal(targets.kcal))")
                totalColumn(value: "\(totals.protein)g", label: "Protein", target: "of \(targets.protein)g")
                totalColumn(value: "\(totals.carbs)g", label: "Carbs", target: "of \(targets.carbs)g")
                totalColumn(value: "\(totals.fat)g", label: "Fat", target: "of \(targets.fat)g")
            }
            proteinBar(protein: totals.protein, target: targets.protein)
            HStack(spacing: 6) {
                Button {
                    if isPro {
                        store.fitMyDay(date: store.selectedDate)
                    } else {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(V2Color.accentDeep)
                        Text("Fit my day · Pro")
                            .font(V2Font.inter(12.5, .bold))
                            .foregroundStyle(V2Color.ink)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(V2Color.accentTint)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    store.shuffle(date: store.selectedDate)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shuffle")
                        Text("Shuffle")
                    }
                    .font(V2Font.inter(12.5, .bold))
                    .foregroundStyle(V2Color.ink)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(V2Color.bg)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(V2Color.line, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()
                Text(lockedCount == 0 ? "Tap a meal to lock" : "\(lockedCount) locked")
                    .font(V2Font.inter(11.5, .semibold))
                    .foregroundStyle(V2Color.ter)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .v2Card(radius: 26)
        .padding(.horizontal, V2Layout.screenHPadding)
    }

    private func totalColumn(value: String, label: String, target: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(V2Font.serif(30))
                .foregroundStyle(V2Color.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(V2Font.inter(11.5, .medium))
                .foregroundStyle(V2Color.sec)
            Text(target)
                .font(V2Font.inter(10.5, .semibold))
                .foregroundStyle(V2Color.ter)
        }
        .frame(maxWidth: .infinity)
    }

    private func proteinBar(protein: Int, target: Int) -> some View {
        let progress = target > 0 ? min(1, Double(protein) / Double(target)) : 0
        let met = abs(protein - target) <= 5
        return HStack(spacing: 10) {
            GeometryReader { geo in
                Capsule()
                    .fill(V2Color.track)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(met ? V2Color.met : V2Color.accent)
                            .frame(width: geo.size.width * progress)
                    }
            }
            .frame(height: 7)
            Text("\(protein) / \(target)g protein")
                .font(V2Font.inter(12.5, .semibold))
                .foregroundStyle(V2Color.ink)
                .fixedSize()
        }
    }

    private func mealRow(slot: MealSlot, date: Date) -> some View {
        let meals = store.meals(for: slot)
        let selected = store.selectedMeal(slot: slot, date: date)
        let locked = store.isLocked(slot: slot, date: date)
        let index = store.railIndex[slot] ?? 0

        return VStack(spacing: 0) {
            HStack {
                Text(slot.title.uppercased())
                    .font(V2Font.inter(11, .bold))
                    .tracking(1.3)
                    .foregroundStyle(V2Color.sec)
                Text(selected?.name ?? "—")
                    .font(V2Font.inter(14.5, .bold))
                    .foregroundStyle(V2Color.ink)
                    .lineLimit(1)
                Spacer()
                Text("\(selected?.kcal ?? 0) kcal")
                    .font(V2Font.inter(13, .semibold))
                    .foregroundStyle(V2Color.sec)
            }
            .padding(.horizontal, 22)

            MealRailView(
                meals: meals,
                selectedIndex: index,
                rowLocked: locked,
                onSelect: { idx in
                    guard idx < meals.count else { return }
                    let meal = meals[idx]
                    if idx == index {
                        store.toggleLock(slot: slot, date: date)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else {
                        store.setSelectedMeal(slot: slot, mealID: meal.id, date: date)
                        store.railIndex[slot] = idx
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                },
                onSwipe: { delta in
                    store.moveRail(slot: slot, delta: delta, date: date)
                }
            )
        }
    }

    private func formattedKcal(_ value: Int) -> String {
        value.formatted(.number.grouping(.automatic))
    }
}

struct MealRailView: View {
    let meals: [FuelMeal]
    let selectedIndex: Int
    let rowLocked: Bool
    var onSelect: (Int) -> Void
    var onSwipe: (Int) -> Void

    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let step = V2Layout.mealTileSize + V2Layout.mealTileSpacing
            let center = geo.size.width / 2
            let baseOffset = center - (CGFloat(selectedIndex) * step + V2Layout.mealTileSize / 2)

            HStack(spacing: V2Layout.mealTileSpacing) {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    MealTileView(
                        meal: meal,
                        isSelected: index == selectedIndex,
                        showLockBadge: rowLocked && index == selectedIndex,
                        dimmed: rowLocked && index != selectedIndex
                    )
                    .onTapGesture { onSelect(index) }
                }
            }
            .offset(x: baseOffset + dragTranslation)
            .animation(.easeInOut(duration: 0.35), value: selectedIndex)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { dragTranslation = $0.translation.width }
                    .onEnded { value in
                        defer { dragTranslation = 0 }
                        guard !rowLocked else { return }
                        if value.translation.width > 30 { onSwipe(-1) }
                        else if value.translation.width < -30 { onSwipe(1) }
                    }
            )
        }
        .frame(height: V2Layout.mealRailHeight)
        .clipped()
    }
}

struct MealTileView: View {
    let meal: FuelMeal
    let isSelected: Bool
    let showLockBadge: Bool
    let dimmed: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomTrailing) {
                FoodIllustrationView(art: meal.art, colors: meal.colors)
                if showLockBadge {
                    Circle()
                        .fill(V2Color.ink)
                        .frame(width: 26, height: 26)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: -4, y: -4)
                }
            }
            if meal.isFavorite {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(V2Color.accentDeep)
                    }
                    .offset(x: -4, y: 4)
            }
        }
        .frame(width: V2Layout.mealTileSize, height: V2Layout.mealTileSize)
        .background(V2Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(isSelected ? V2Color.accent : V2Color.line, lineWidth: isSelected ? 3 : 1)
        }
        .scaleEffect(isSelected ? 1.1 : 1)
        .opacity(dimmed ? 0.35 : (isSelected ? 1 : 0.8))
        .shadow(color: isSelected ? .black.opacity(0.08) : .clear, radius: 6, y: 3)
    }
}

#Preview {
    FuelScreenView(store: FuelStore())
}
