import SwiftUI

/// Library for workout templates and meal plans — assign them to days on **Plan**.
struct DesignTabRootView: View {
    @State private var showWorkouts = false
    @State private var showMeals = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.sectionGapPlan) {
                ScreenHeader(overline: "Templates", title: "Design") {
                    EmptyView()
                }

                Text("Build workouts and meals here, then schedule them on Plan.")
                    .font(InterFont.inter(14, .medium))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)

                designEntry(
                    title: "Workouts",
                    subtitle: "Routines, exercises, hybrid sessions",
                    icon: "dumbbell",
                    action: { showWorkouts = true }
                )

                designEntry(
                    title: "Meals",
                    subtitle: "Saved meals and presets",
                    icon: "fork.knife",
                    action: { showMeals = true }
                )
            }
            .padding(.horizontal, DesignSystem.Layout.screenPadding)
            .padding(.top, 4)
            .padding(.bottom, DesignSystem.Layout.scrollBottomPadding)
        }
        .background(DesignSystem.Color.bg)
        .fullScreenCover(isPresented: $showWorkouts) {
            NavigationStack {
                LiftRootView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showWorkouts = false }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showMeals) {
            NavigationStack {
                FuelRootView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { showMeals = false }
                        }
                    }
            }
        }
    }

    private func designEntry(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.foodIcon, style: .continuous)
                    .fill(DesignSystem.Color.bg)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(DesignSystem.Color.ink)
                    }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(InterFont.inter(16, .bold))
                        .foregroundStyle(DesignSystem.Color.ink)
                    Text(subtitle)
                        .font(InterFont.inter(13, .medium))
                        .foregroundStyle(DesignSystem.Color.inkSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DesignSystem.Color.inkSecondary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(DesignSystem.Color.card)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.meal, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DesignTabRootView()
}
