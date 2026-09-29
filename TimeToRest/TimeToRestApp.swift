import SwiftUI

@main
struct TimeToRestApp: App {

    private let dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            AppCoordinator(dependencies: dependencies)
                .preferredColorScheme(.dark)
        }
    }
}
