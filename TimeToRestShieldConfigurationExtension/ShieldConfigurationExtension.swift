import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        makeShieldConfiguration()
    }

    private func makeShieldConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.55),
            title: ShieldConfiguration.Label(
                text: "Rest mode is active",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Unlock ends your rest streak now.",
                color: .lightGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Unlock",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemRed,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Cancel",
                color: .white
            )
        )
    }
}
