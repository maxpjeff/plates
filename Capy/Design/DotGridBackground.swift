import SwiftUI

struct DotGridBackground: View {
    var base: Color
    var dot: Color
    var spacing: CGFloat = 18
    var dotSize: CGFloat = 1.3

    var body: some View {
        ZStack {
            base
            Canvas { context, size in
                var y: CGFloat = spacing / 2
                while y < size.height + spacing {
                    var x: CGFloat = spacing / 2
                    while x < size.width + spacing {
                        let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(dot))
                        x += spacing
                    }
                    y += spacing
                }
            }
        }
    }
}
