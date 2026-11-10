import SwiftUI
import SwiftData

struct RoutineActionsSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.startWorkout) private var startWorkout

    let routine: Routine
    var onEdit: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextCardSticker(label: routine.shortLabel, color: routine.stickerColor)
                    VStack(alignment: .leading) {
                        Text(routine.name)
                            .font(PlatesFont.bodySemibold(17))
                        Text("\(routine.items.count) exercises")
                            .font(PlatesFont.secondary())
                            .foregroundStyle(PlatesColor.muted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(spacing: 10) {
                    actionButton(title: "Start workout", icon: "play.fill", prominent: true) {
                        dismiss()
                        startWorkout(routine)
                    }
                    actionButton(title: "Edit routine", icon: "pencil") {
                        dismiss()
                        onEdit()
                    }
                    actionButton(title: "Delete routine", icon: "trash", destructive: true) {
                        confirmDelete = true
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(PlatesColor.bg)
            .navigationTitle("Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete “\(routine.name)”?",
                isPresented: $confirmDelete,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteRoutine()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the routine from your library. Week assignments for this routine will be cleared.")
            }
        }
        .presentationDetents([.medium])
    }

    private func actionButton(
        title: String,
        icon: String,
        prominent: Bool = false,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(PlatesFont.bodySemibold())
                Spacer()
            }
            .foregroundStyle(destructive ? PlatesColor.heart : (prominent ? PlatesColor.primaryButtonText : PlatesColor.ink))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(destructive ? PlatesColor.heart.opacity(0.12) : (prominent ? PlatesColor.primaryButton : PlatesColor.surface))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func deleteRoutine() {
        let schedules = (try? context.fetch(FetchDescriptor<WeekSchedule>())) ?? []
        for schedule in schedules where schedule.routine?.id == routine.id {
            schedule.routine = nil
            schedule.isRest = true
        }
        context.delete(routine)
        try? context.save()
        dismiss()
    }
}
