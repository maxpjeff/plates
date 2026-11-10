import SwiftUI

struct PaperBackground: View {
    var body: some View {
        ZStack {
            Theme.Color.paper
            Canvas { context, size in
                let spacing: CGFloat = 18
                let dot: CGFloat = 1.3
                var y: CGFloat = spacing / 2
                while y < size.height + spacing {
                    var x: CGFloat = spacing / 2
                    while x < size.width + spacing {
                        let rect = CGRect(x: x - dot / 2, y: y - dot / 2, width: dot, height: dot)
                        context.fill(Path(ellipseIn: rect), with: .color(Theme.Color.paperDot))
                        x += spacing
                    }
                    y += spacing
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PaperBackground()
}
