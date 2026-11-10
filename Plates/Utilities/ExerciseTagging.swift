import Foundation

extension Exercise {
    var muscleDisplayTags: [String] {
        var tags: [String] = [primaryMuscle.friendlyName]
        for muscle in secondaryMuscles {
            tags.append(muscle.friendlyName)
        }
        tags.append(contentsOf: fineMuscleTags(from: name))
        return Array(Set(tags)).sorted { $0.localizedCompare($1) == .orderedAscending }
    }

    var patternTags: [String] {
        movementPatterns.map(\.label)
    }

    var isRunning: Bool {
        movementPatterns.contains { MovementPattern.runFilters.contains($0) }
    }

    private func fineMuscleTags(from name: String) -> [String] {
        let n = name.lowercased()
        var fine: [String] = []
        if n.contains("curl") || n.contains("bicep") { fine.append("Biceps") }
        if n.contains("tricep") || n.contains("pushdown") || n.contains("skull") { fine.append("Triceps") }
        if n.contains("squat") || n.contains("leg press") || n.contains("leg extension") { fine.append("Quads") }
        if n.contains("rdl") || n.contains("romanian") || n.contains("hamstring") || n.contains("leg curl") {
            fine.append("Hamstrings")
        }
        if n.contains("glute") || n.contains("hip thrust") { fine.append("Glutes") }
        if n.contains("calf") { fine.append("Calves") }
        if n.contains("lateral raise") || n.contains("delt") { fine.append("Shoulders") }
        if isRunning { fine.append("Cardio") }
        return fine
    }
}
