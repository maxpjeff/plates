import SwiftUI
import SwiftData

struct ConnectedTodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.startHybridSession) private var startHybridSession
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var showSettings = false
    @State private var showBefore = false
    @State private var showLog = false
    @State private var showReflect = false

    var body: some View {
        TodayView(
            model: V1DataAdapter.today(context: context, date: selectedDate),
            onProfile: { showSettings = true },
            onAddBefore: { showBefore = true },
            onEditBefore: { showBefore = true },
            onLogSession: { showLog = true },
            onLogLive: {
                if let session = HybridDataStore.session(for: selectedDate, context: context) {
                    startHybridSession(session)
                }
            },
            onReflect: { showReflect = true },
            onEditReflect: { showReflect = true }
        )
        .sheet(isPresented: $showSettings) {
            SettingsView(profile: PlatesDataStore.profile(context: context))
        }
        .sheet(isPresented: $showBefore) {
            BeforeJournalPlaceholderSheet()
        }
        .sheet(isPresented: $showLog) {
            LogSessionPlaceholderSheet()
        }
        .sheet(isPresented: $showReflect) {
            ReflectJournalPlaceholderSheet()
        }
        .onReceive(NotificationCenter.default.publisher(for: .platesOpenTodayJournal)) { _ in
            showReflect = true
        }
    }
}

struct ConnectedPlanView: View {
    @Environment(\.modelContext) private var context
    @State private var planSheetDate: Date?

    var body: some View {
        PlanView(
            model: V1DataAdapter.plan(context: context),
            onAddSession: { planSheetDate = Date() },
            onSelectDay: { planSheetDate = $0 }
        )
        .sheet(isPresented: Binding(
            get: { planSheetDate != nil },
            set: { if !$0 { planSheetDate = nil } }
        )) {
            WeekDayPlanSheet(date: planSheetDate ?? Date())
        }
    }
}

struct ConnectedProgressView: View {
    var body: some View {
        PlatesProgressView(model: MockData.progressModel)
    }
}

#Preview {
    ConnectedProgressView()
}
