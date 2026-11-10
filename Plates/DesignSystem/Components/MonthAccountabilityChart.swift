import SwiftUI

struct MonthAccountabilityChart: View {
    let results: [DayAccountabilityResult]
    var zoneLower: Int = 68
    var zoneUpper: Int = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let points = chartPoints(width: width, height: height)

                ZStack {
                    zoneBand(height: height, width: width)
                    if points.count > 1 {
                        Path { path in
                            path.move(to: points[0])
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .stroke(PlatesColor.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 4]))

                        ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                            Circle()
                                .fill(PlatesColor.ink)
                                .frame(width: 6, height: 6)
                                .position(point)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .frame(height: 120)
            monthAxis
        }
    }

    private func zoneBand(height: CGFloat, width: CGFloat) -> some View {
        let lowerY = yPosition(for: zoneLower, height: height)
        let upperY = yPosition(for: zoneUpper, height: height)
        return RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(PlatesColor.good.opacity(0.22))
            .frame(width: width, height: max(8, lowerY - upperY))
            .position(x: width / 2, y: (lowerY + upperY) / 2)
    }

    private func chartPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !results.isEmpty else { return [] }
        let step = width / CGFloat(max(results.count - 1, 1))
        return results.enumerated().map { index, result in
            CGPoint(x: CGFloat(index) * step, y: yPosition(for: result.score, height: height))
        }
    }

    private func yPosition(for score: Int, height: CGFloat) -> CGFloat {
        let clamped = CGFloat(min(100, max(0, score))) / 100
        return height - clamped * (height - 12) - 6
    }

    private var monthAxis: some View {
        HStack {
            if let first = results.first?.date {
                Text(first.formatted(.dateTime.month(.abbreviated).day()))
            }
            Spacer()
            if let last = results.last?.date {
                Text(last.formatted(.dateTime.month(.abbreviated).day()))
            }
        }
        .font(PlatesFont.secondary(11))
        .foregroundStyle(PlatesColor.muted)
    }
}

#Preview {
    let sample = (1...20).map { day in
        DayAccountabilityResult(
            date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: day)) ?? Date(),
            score: 55 + (day % 7) * 6,
            metPlan: day % 3 != 0
        )
    }
    MonthAccountabilityChart(results: sample)
        .padding()
        .background(PlatesColor.bg)
}
