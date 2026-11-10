import SwiftUI
import SwiftData

struct ActiveHybridSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let session: TrainingSession

    @State private var blockIndex = 0
    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?
    @State private var restRemaining = 0
    @State private var restTimer: Timer?
    @State private var timingMethod: TimingMethod = .hand
    @State private var repTimeText = ""
    @State private var windText = "+1.2"

    private var sortedBlocks: [TrainingBlock] {
        session.blocks.sorted { $0.order < $1.order }
    }

    private var currentBlock: TrainingBlock? {
        guard blockIndex < sortedBlocks.count else { return nil }
        return sortedBlocks[blockIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            mockupTopBar
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(session.title)
                        .font(PlatesFont.screenTitle(32))
                        .padding(.horizontal, MockupLayout.screenPadding)

                    if let block = currentBlock {
                        if block.blockType == .sprint {
                            sprintMockup(block)
                        } else {
                            blockHeader(block)
                            fallbackBlock(block)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(PlatesColor.bg)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                elapsed += 1
            }
        }
        .onDisappear {
            timer?.invalidate()
            restTimer?.invalidate()
        }
        .safeAreaInset(edge: .bottom) {
            if restRemaining > 0 {
                Text("Rest \(formatRest(restRemaining))")
                    .font(PlatesFont.bodySemibold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(PlatesColor.ink)
                    .foregroundStyle(PlatesColor.primaryButtonText)
            }
        }
    }

    private var mockupTopBar: some View {
        HStack {
            Text(formatElapsed(elapsed))
                .font(PlatesFont.bodySemibold())
                .monospacedDigit()
            Spacer()
            Button("Finish") { dismiss() }
                .font(PlatesFont.bodySemibold())
        }
        .padding(.horizontal, MockupLayout.screenPadding)
        .padding(.vertical, 14)
    }

    private func blockHeader(_ block: TrainingBlock) -> some View {
        Text("Block \(blockIndex + 1) of \(sortedBlocks.count) · \(block.blockType.label)")
            .font(PlatesFont.labelCaps(11))
            .foregroundStyle(PlatesColor.muted)
            .padding(.horizontal, MockupLayout.screenPadding)
    }

    private func sprintMockup(_ block: TrainingBlock) -> some View {
        guard let item = block.items.first, let spec = item.plannedSpec else { return AnyView(EmptyView()) }
        let target = HybridDataStore.targetSprintTime(
            distanceM: spec.distanceM ?? 30,
            intensityPct: spec.intensityPct ?? 95,
            context: context
        )
        let reps = spec.sprintReps ?? 4

        return AnyView(
            VStack(alignment: .leading, spacing: 18) {
                Text("Block \(blockIndex + 1) of \(sortedBlocks.count) · Sprint")
                    .font(PlatesFont.labelCaps(11))
                    .foregroundStyle(PlatesColor.muted)

                Text("\(Int(spec.distanceM ?? 30)) m fly @ \(spec.intensityPct ?? 95)%")
                    .font(PlatesFont.bodySemibold(18))

                if let target {
                    Text(String(format: "Target %.2f s · PR 2.90 s (FAT)", target))
                        .font(PlatesFont.secondary(14))
                        .foregroundStyle(PlatesColor.muted)
                }

                if restRemaining > 0 {
                    Text("Rest \(formatRest(restRemaining))")
                        .font(PlatesFont.bodySemibold(16))
                }

                VStack(spacing: 0) {
                    ForEach(0..<reps, id: \.self) { index in
                        repStatusRow(index: index, item: item, target: target)
                        if index < reps - 1 {
                            Divider().padding(.leading, 8)
                        }
                    }
                }
                .padding(14)
                .background(PlatesColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: MockupLayout.cardRadius))

                timingMethodPicker

                HStack {
                    Text("Wind")
                        .font(PlatesFont.secondary())
                    TextField("m/s", text: $windText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.horizontal, 4)

                MockupNumericKeypad(text: $repTimeText)

                Button {
                    saveSprintRep(item: item, restSec: spec.restSec ?? 240, target: target)
                } label: {
                    Text("Save rep · start rest")
                        .font(PlatesFont.bodySemibold())
                        .foregroundStyle(PlatesColor.primaryButtonText)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(PlatesColor.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, MockupLayout.screenPadding)
        )
    }

    private var timingMethodPicker: some View {
        HStack(spacing: 8) {
            ForEach(TimingMethod.allCases, id: \.self) { method in
                Button {
                    timingMethod = method
                } label: {
                    Text(method.rawValue.capitalized)
                        .font(PlatesFont.bodySemibold(12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(timingMethod == method ? PlatesColor.ink : PlatesColor.surface)
                        .foregroundStyle(timingMethod == method ? PlatesColor.primaryButtonText : PlatesColor.ink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private func repStatusRow(index: Int, item: TrainingBlockItem, target: Double?) -> some View {
        HStack {
            Text("Rep \(index + 1)")
                .font(PlatesFont.bodyMedium())
            Spacer()
            Text(repStatusLabel(index: index, item: item, target: target))
                .font(PlatesFont.secondary(14))
                .foregroundStyle(PlatesColor.muted)
        }
        .padding(.vertical, 8)
    }

    private func repStatusLabel(index: Int, item: TrainingBlockItem, target: Double?) -> String {
        guard let reps = item.actualResult?.sprintReps, index < reps.count else {
            return index == sprintRepIndex && !repTimeText.isEmpty ? "\(repTimeText) s" : "—"
        }
        let rep = reps[index]
        let timing = rep.timing.rawValue.capitalized
        if let target, abs(rep.seconds - target) <= 0.05 {
            return String(format: "%.2f s On target", rep.seconds)
        }
        if let wind = rep.windMS {
            return String(format: "%.2f s %@ · %+.1f", rep.seconds, timing, wind)
        }
        return String(format: "%.2f s %@", rep.seconds, timing)
    }

    private var sprintRepIndex: Int {
        itemRepCount()
    }

    private func itemRepCount() -> Int {
        guard let block = currentBlock, let item = block.items.first else { return 0 }
        return item.actualResult?.sprintReps?.count ?? 0
    }

    private func saveSprintRep(item: TrainingBlockItem, restSec: Int, target: Double?) {
        guard let seconds = Double(repTimeText) else { return }
        var result = item.actualResult ?? HybridItemResult()
        var reps = result.sprintReps ?? []
        reps.append(
            HybridTimedRep(
                seconds: seconds,
                timing: timingMethod,
                windMS: Double(windText.replacingOccurrences(of: "+", with: "")),
                quality: nil
            )
        )
        result.sprintReps = reps
        item.updateActual(result)
        try? context.save()
        repTimeText = ""
        startRest(restSec)
    }

    private func fallbackBlock(_ block: TrainingBlock) -> some View {
        PlatesCard {
            Text("\(block.title) — switch block from session plan on Today.")
                .font(PlatesFont.body())
        }
        .padding(.horizontal, MockupLayout.screenPadding)
    }

    private func startRest(_ seconds: Int) {
        restRemaining = seconds
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restRemaining > 0 { restRemaining -= 1 }
            else { restTimer?.invalidate() }
        }
    }

    private func formatElapsed(_ interval: TimeInterval) -> String {
        let m = Int(interval) / 60
        let s = Int(interval) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatRest(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
