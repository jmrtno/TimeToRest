import Foundation
import BackgroundTasks
import Combine

/// Manages background task scheduling and execution for TimeToRest app.
/// Handles periodic night window checks when app is in background.
@MainActor
final class BackgroundTaskManager: ObservableObject {
    
    // MARK: - Constants
    static let nightCheckTaskIdentifier = "com.timetorest.nightcheck"
    
    // MARK: - State
    @Published private(set) var isBackgroundTaskScheduled: Bool = false
    
    // MARK: - Initialization
    init() {
        // No dependencies to break circular reference
    }
    
    // MARK: - Registration
    
    /// Registers background tasks with the system.
    /// Should be called during app launch.
    func registerBackgroundTasks() {
        // Register processing task for more predictable execution
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.nightCheckTaskIdentifier,
            using: nil
        ) { [weak self] task in
            self?.handleNightCheckTask(task as! BGProcessingTask)
        }
    }
    
    // MARK: - Scheduling
    
    /// Schedules a background task to check night window status.
    /// Uses BGProcessingTask for more reliable execution.
    func scheduleNightCheckTask() {
        // Cancel any existing task first
        cancelNightCheckTask()
        
        let request = BGProcessingTaskRequest(identifier: Self.nightCheckTaskIdentifier)
        
        // Set requiresNetworkConnectivity to false for local checks
        request.requiresNetworkConnectivity = false
        
        // Set earliestBeginDate for minimum delay
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            isBackgroundTaskScheduled = true
            print("✅ Background night check task scheduled successfully")
        } catch {
            print("❌ Failed to schedule background night check task: \(error)")
            isBackgroundTaskScheduled = false
            
            // Fallback to timer if background scheduling fails
            scheduleFallbackTimer()
        }
    }
    
    /// Cancels any pending background night check task.
    func cancelNightCheckTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.nightCheckTaskIdentifier)
        isBackgroundTaskScheduled = false
    }
    
    // MARK: - Background Task Handling
    
    private func handleNightCheckTask(_ task: BGProcessingTask) {
        print("🌙 Background night check task started")
        
        // Schedule the next task before handling the current one
        scheduleNextBackgroundTask()
        
        // Create operation to handle the night check
        let operation = NightCheckOperation()
        
        // Handle task expiration
        task.expirationHandler = {
            print("⏰ Background night check task expired")
            operation.cancel()
        }
        
        // Handle completion
        operation.completionBlock = { [weak self] in
            Task { @MainActor [weak self] in
                task.setTaskCompleted(success: !operation.isCancelled)
                print("🏁 Background night check task completed")
                
                // Schedule next task if not cancelled
                if !operation.isCancelled {
                    self?.scheduleNextBackgroundTask()
                }
            }
        }
        
        // Execute the operation
        let queue = OperationQueue()
        queue.addOperation(operation)
    }
    
    private func scheduleNextBackgroundTask() {
        // Schedule next check in 30 seconds
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            self?.scheduleNightCheckTask()
        }
    }
    
    // MARK: - Fallback Timer
    
    private func scheduleFallbackTimer() {
        print("⚠️ Scheduling fallback timer for night checks")
        
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performNightCheck()
            }
        }
    }
    
    // MARK: - Night Check Logic
    
    private func performNightCheck() async {
        // This will be called by NightModeViewModel through notification
        NotificationCenter.default.post(name: .nightCheckBackgroundTask, object: nil)
    }
}

// MARK: - Night Check Operation

private final class NightCheckOperation: Operation, @unchecked Sendable {
    
    override func main() {
        guard !isCancelled else { return }
        
        // Perform night window check
        let semaphore = DispatchSemaphore(value: 0)
        
        Task { @MainActor in
            // Post notification to trigger night check
            NotificationCenter.default.post(name: .nightCheckBackgroundTask, object: nil)
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let nightCheckBackgroundTask = Notification.Name("nightCheckBackgroundTask")
}
