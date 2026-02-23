import SwiftUI
import BackgroundTasks

@main
struct TimeToRestApp: App {

    private let dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            AppCoordinator(dependencies: dependencies)
                .preferredColorScheme(.dark)
                .onAppear {
                    dependencies.backgroundTaskManager.registerBackgroundTasks()
                }
        }
    }
}
