import SwiftUI
import SwiftData

struct LogWeightView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    @State private var weightText = ""

    private var units: WeightUnit { profiles.first?.units ?? .lb }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log today's weight")
                    .font(PlatesFont.sectionTitle(26))
                TextField(units == .lb ? "Weight (lb)" : "Weight (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
                    .font(PlatesFont.bigNumber(36))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(PlatesColor.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Button("Save") { save() }
                    .font(PlatesFont.bodySemibold())
                    .foregroundStyle(PlatesColor.primaryButtonText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(PlatesColor.primaryButton)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Spacer()
            }
            .padding(24)
            .background(PlatesColor.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        guard let kg = UnitFormat.parseWeightInput(weightText, units: units) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let entries = (try? context.fetch(FetchDescriptor<BodyWeightEntry>())) ?? []
        if let existing = entries.first(where: { Calendar.current.isDate($0.date, inSameDayAs: start) }) {
            existing.weightKg = kg
        } else {
            context.insert(BodyWeightEntry(date: start, weightKg: kg, source: .manual))
        }
        profiles.first?.bodyWeightKg = kg
        try? context.save()
        dismiss()
    }
}

#Preview {
    LogWeightView()
        .modelContainer(SampleData.previewContainer())
}
