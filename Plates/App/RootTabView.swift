import SwiftUI

private struct StartWorkoutKey: EnvironmentKey {
    static let defaultValue: (Routine) -> Void = { _ in }
}

private struct StartHybridSessionKey: EnvironmentKey {
    static let defaultValue: (TrainingSession) -> Void = { _ in }
}

extension EnvironmentValues {
    var startWorkout: (Routine) -> Void {
        get { self[StartWorkoutKey.self] }
        set { self[StartWorkoutKey.self] = newValue }
    }

    var startHybridSession: (TrainingSession) -> Void {
        get { self[StartHybridSessionKey.self] }
        set { self[StartHybridSessionKey.self] = newValue }
    }
}

struct RootTabView: View {
    @State private var tab: PlatesTab = .today
    @State private var activeRoutine: Routine?
    @State private var activeHybridSession: TrainingSession?

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ConnectedTodayView()
                    .frame(width: geo.size.width, height: geo.size.height)
                ConnectedPlanView()
                    .frame(width: geo.size.width, height: geo.size.height)
                DesignTabRootView()
                    .frame(width: geo.size.width, height: geo.size.height)
                ConnectedProgressView()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .offset(x: -CGFloat(tab.index) * geo.size.width)
            .animation(PlatesTabMotion.slide, value: tab)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.startWorkout) { routine in
            activeRoutine = routine
        }
        .environment(\.startHybridSession) { session in
            activeHybridSession = session
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            TabBarBottomChrome(selection: $tab)
        }
        .background(DesignSystem.Color.bg.ignoresSafeArea())
        .preferredColorScheme(.light)
        .fullScreenCover(item: $activeRoutine) { routine in
            ActiveWorkoutView(routine: routine)
        }
        .fullScreenCover(item: $activeHybridSession) { session in
            LiveSessionView(
                model: V1DataAdapter.liveSession(from: session),
                onBack: { activeHybridSession = nil },
                onFinish: { activeHybridSession = nil }
            )
        }
    }
}

extension Routine: @retroactive Identifiable {}
extension TrainingSession: @retroactive Identifiable {}

#Preview {
    RootTabView()
        .modelContainer(SampleData.previewContainer())
}
