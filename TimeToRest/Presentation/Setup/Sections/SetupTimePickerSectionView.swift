import SwiftUI

// MARK: - SetupTimePickerSectionView
/// Section that lets the user pick the start and end times for the rest window.
struct SetupTimePickerSectionView: View {

    let startTime: Binding<Date>
    let endTime: Binding<Date>

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Night Schedule")
                .textCase(.uppercase)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
            timeRow(label: "Start time", selection: startTime)
            timeRow(label: "End time", selection: endTime)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }

    // MARK: - Time Row

    private func timeRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(.orange)
            .colorScheme(.dark)
        }
    }
}
