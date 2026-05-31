import SwiftUI

struct BreakBlockCelebrationScreen: View {
    @EnvironmentObject private var router: Router
    @State private var didScheduleDismiss = false
    @StateObject var viewModel: BreakBlockViewModel

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.indigo.opacity(0.1))
                    .frame(width: 78, height: 78)
                
                Image(systemName: "shield")
                    .font(.system(size: 45, weight: .medium))
                    .foregroundStyle(.indigo)
            }
            Text("Rest completed!")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text(viewModel.congratulationMessage)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            viewModel.pickCongratulationRandomMessage()
            try? await Task.sleep(for: .seconds(4))
            await MainActor.run {
                router.dismissBreakBlock()
                router.popToRoot()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BreakBlockCelebrationScreen(viewModel: .preview)
    }
}
