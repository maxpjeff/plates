import SwiftUI

struct AvatarView: View {
    let state: AvatarState
    var useTintAsset = false
    var allowsMotion = true

    @State private var bobUp = false

    var body: some View {
        let name = useTintAsset ? state.tintImageName : state.imageName
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 300, maxHeight: 236)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .offset(y: state == .lockedIn && !useTintAsset ? (bobUp ? -4 : 0) : 0)
            .id(state)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
            .onAppear {
                guard allowsMotion, state == .lockedIn, !useTintAsset else { return }
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    bobUp.toggle()
                }
            }
            .onChange(of: state) { _, new in
                if new != .lockedIn { bobUp = false }
            }
            .accessibilityLabel(state.label)
    }
}

#Preview("Avatar states") {
    HStack(alignment: .bottom, spacing: 8) {
        ForEach(AvatarState.allCases, id: \.self) { s in
            VStack(spacing: 6) {
                AvatarView(state: s)
                    .frame(width: 160, height: 140)
                    .background(s.sceneColor)
                Text(s.label)
                    .font(CapyFont.nunito(11, .heavy))
            }
        }
    }
    .padding()
    .background(PaperBackground())
}
