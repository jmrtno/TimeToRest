import SwiftUI

// MARK: - SetupNotAllowedAppsSectionView
/// Section for choosing the apps and categories to block while resting.
struct SetupNotAllowedAppsSectionView: View {

    let viewModel: SetupViewModel

    // MARK: - Body
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Blocks during your rest")
                    .textCase(.uppercase)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 16)

                Text("Selected apps will be blocked automatically while you rest.")
                    .font(.headline)
                    .foregroundStyle(.white)

                Button {
                    viewModel.isFamilyActivityPickerPresented = true
                } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.orange.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: "lock.app.dashed")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                        Text("Select apps")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("Apps blocked: \(viewModel.blockedSocialAppsDescription).")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            
            Spacer()
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}
