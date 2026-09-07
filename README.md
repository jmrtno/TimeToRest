# Time To Rest

An iOS digital wellness app that helps you build healthier nighttime habits. Define your rest window, choose which apps to block, and let Time To Rest shield those apps during your rest period — so you can actually sleep instead of scrolling.

## 🎯 Purpose

"Time To Rest" addresses the modern problem of late-night phone overuse. By leveraging Apple's Screen Time API (Family Controls, Device Activity, and Managed Settings), the app creates a protective shield over the apps you choose during a configurable nighttime window. It tracks your rest streaks, rewards consistency, and helps you understand your habits through statistics.

## ✨ Features

- **Night Rest Window**: Configure a custom start and end time for your nightly rest period
- **App Shielding**: Select which apps to block during rest using Apple's Family Controls picker
- **Automatic Monitoring**: Device Activity monitoring starts automatically when you enter your rest window
- **Shield UI**: Blocked apps display a custom shield with "Unlock" and "Cancel" actions
- **Break Detection**: Detects when you unlock blocked apps and records the break reason
- **Streak Tracking**: Tracks current and best rest streaks to motivate consistency
- **Weekly Stats**: Shows breaks this week and a 15-day break history
- **AI Coach**: Provides sleep tips to help you improve your rest habits
- **Grace Period**: Configurable grace period in minutes before the rest window starts
- **Notifications**: Local notifications for rest events (blocked attempts, broken rest, completed rest)
- **Background Tasks**: Scheduled background checks to keep your rest session alive
- **Mandatory Setup**: First-launch setup flow ensures you configure rest times before using the app
- **Dark Mode**: Designed with a dark color scheme optimized for nighttime use

## 🏗️ Architecture

The app follows **Clean Architecture** principles with clear separation of concerns, using a composition root for dependency injection and a coordinator-based navigation system.

### 📁 Project Structure

```
TimeToRest/
├── TimeToRest.xcodeproj
├── TimeToRest/                                # Main app target
│   ├── TimeToRestApp.swift                    # App entry point
│   ├── TimeToRest.entitlements                # Family Controls + App Group
│   ├── TimeToRest.simulator.entitlements      # Simulator entitlements
│   ├── Info.plist                             # Background task identifiers
│   ├── Assets.xcassets
│   ├── App/
│   │   └── AppDependencies.swift              # Composition root (DI container)
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── TimeToRestEntity.swift         # Rest window configuration
│   │   │   ├── RestSessionEntity.swift        # Single rest session record
│   │   │   ├── RestStatsEntity.swift          # Aggregated statistics
│   │   │   ├── AppSettingsEntity.swift        # User settings (grace period, etc.)
│   │   │   └── BreakReason.swift              # Enum of break reasons
│   │   ├── Contracts/
│   │   │   ├── TimeToRestRepositoryContract.swift
│   │   │   ├── RestSessionRepositoryContract.swift
│   │   │   └── AppSettingsRepositoryContract.swift
│   │   └── UseCases/
│   │       ├── StartRestTime/                 # Fetch/save rest time, start session
│   │       ├── BreakRestTime/                 # Break a rest session
│   │       ├── CalculateStats/                # Compute streaks and stats
│   │       ├── RestSession/                   # Complete, fetch, delete sessions
│   │       ├── AppSettings/                   # Fetch/save app settings
│   │       └── AICoach/                       # Get sleep tips
│   ├── Data/
│   │   ├── DTO/
│   │   │   ├── TimeToRestDTO.swift
│   │   │   ├── RestSessionDTO.swift
│   │   │   └── AppSettingsDTO.swift
│   │   ├── Repositories/
│   │   │   ├── TimeToRestRepository.swift
│   │   │   ├── RestSessionRepository.swift
│   │   │   └── AppSettingsRepository.swift
│   │   └── Infraestructure/
│   │       ├── RestSessionManager.swift       # DeviceActivity + ManagedSettings orchestration
│   │       ├── BackgroundTaskManager.swift     # BGTaskScheduler registration
│   │       ├── NotificationManager.swift       # Local notifications
│   │       ├── RestSessionDeviceActivityMonitor.swift
│   │       └── RestSessionDeviceActivityIdentifiers.swift
│   ├── Navigation/
│   │   ├── AppCoordinator.swift               # Root coordinator (NavigationStack)
│   │   ├── Router.swift                        # @Observable navigation state
│   │   ├── Route.swift                         # Type-safe navigation routes
│   │   ├── RouteViewFactory.swift              # Route → SwiftUI view resolver
│   │   ├── RestConfigurationMode.swift         # .mandatory / .editable
│   │   └── BreakBlockMode.swift                # .countdown / .celebration
│   └── Presentation/
│       ├── Home/
│       │   ├── HomeScreen.swift                # Tab container
│       │   └── Sections/
│       │       ├── NightMode/                  # Rest session UI + ViewModel
│       │       ├── RestInfo/                   # Rest info card + ViewModel
│       │       ├── Stats/                      # Statistics charts + ViewModel
│       │       └── Settings/                   # App settings + ViewModel
│       ├── Setup/
│       │   ├── SetupScreen.swift               # First-launch configuration
│       │   ├── SetupViewModel.swift
│       │   └── Sections/
│       │       ├── SetupTimePickerSectionView.swift
│       │       ├── SetupNotAllowedAppsSectionView.swift
│       │       └── SetupAICoachSectionView.swift
│       ├── BreakBlock/
│       │   ├── BreakBlockTimerScreen.swift     # Countdown modal
│       │   ├── BreakBlockCelebrationScreen.swift
│       │   ├── BreakBlockViewModel.swift
│       │   └── Sections/
│       │       └── CountdownSectionView.swift
│       └── Common/
│           ├── GlassCard.swift                 # Reusable glassmorphism card
│           ├── BigGlassCard.swift
│           └── CustomTabBar.swift
├── TimeToRestMonitorExtension/                 # DeviceActivityMonitor extension
│   ├── DeviceActivityMonitorExtension.swift
│   ├── Info.plist
│   └── TimeToRestMonitorExtension.entitlements
├── TimeToRestShieldActionExtension/            # ShieldActionDelegate extension
│   ├── ShieldActionExtension.swift
│   ├── Info.plist
│   └── TimeToRestShieldActionExtension.entitlements
└── TimeToRestShieldConfigurationExtension/     # ShieldConfigurationDataSource extension
    ├── ShieldConfigurationExtension.swift
    ├── Info.plist
    └── TimeToRestShieldConfigurationExtension.entitlements
```

### 🔄 Data Flow

1. **User Interaction** → SwiftUI Screens (Presentation Layer)
2. **Screens** → ViewModels (via `@State` and section view models)
3. **ViewModels** → Use Cases (Domain Layer)
4. **Use Cases** → Repository Contracts (Domain Layer)
5. **Repositories** → DTOs → UserDefaults (Data Layer, shared via App Group)
6. **RestSessionManager** → DeviceActivityCenter + ManagedSettingsStore (Infrastructure)
7. **Extensions** → Receive Darwin notifications and update shared UserDefaults

### 🎯 Core Components

#### TimeToRestEntity
Represents the user's rest window configuration: a start time and end time (as `DateComponents`), plus a unique identifier. This is the core configuration that drives the rest schedule.

#### RestSessionEntity
Represents a single rest session: the day it occurred, when it started, whether it was broken, the break reason, and how many minutes of phone use were avoided. This entity is persisted and used to compute statistics.

#### RestStatsEntity
Aggregated statistics derived from rest sessions: current streak, best streak, breaks this week, average start time over the last 15 days, and a 15-day break status history for chart rendering.

#### RestSessionManager
The infrastructure orchestrator that ties together Apple's Screen Time APIs:
- Requests `FamilyControls` authorization
- Applies `ManagedSettings` shields to selected apps
- Starts `DeviceActivity` monitoring during the rest window
- Listens for Darwin notifications from the Shield Action extension
- Breaks the current session when the user unlocks blocked apps

#### AppDependencies
The composition root. Creates all repositories, use cases, and managers with lazy initialization and proper dependency wiring. Passed to `AppCoordinator` at launch.

#### Router
An `@Observable` navigation state manager for SwiftUI's `NavigationStack`. Handles push/pop operations and modal presentation for rest configuration and break block flows.

### 🧩 App Extensions

Time To Rest uses three app extensions required by Apple's Screen Time API:

| Extension | Protocol | Responsibility |
|-----------|----------|----------------|
| `TimeToRestMonitorExtension` | `DeviceActivityMonitor` | Receives threshold events when blocked apps are used during rest |
| `TimeToRestShieldActionExtension` | `ShieldActionDelegate` | Handles shield button taps (Unlock / Cancel) and breaks the rest session |
| `TimeToRestShieldConfigurationExtension` | `ShieldConfigurationDataSource` | Provides the visual configuration for the shield shown over blocked apps |

All extensions share data with the main app via an App Group (`group.com.javidev.TimeToRest`) and communicate via Darwin notifications.

## 🚀 Getting Started

### Prerequisites

- iOS 26.0+
- Xcode 16.0+
- Swift 5.0+ (with Swift 6 concurrency features enabled)
- A physical device is recommended for testing Screen Time features (simulators have limited support)
- An Apple Developer account (Family Controls entitlement requires a paid account)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/jmrtno/TimeToRest.git
cd TimeToRest
```

2. Open the project in Xcode:
```bash
open TimeToRest.xcodeproj
```

3. Configure signing:
   - Select the `TimeToRest` target
   - Set your development team
   - Ensure the Family Controls capability is enabled
   - The App Group `group.com.javidev.TimeToRest` must be configured

4. Build and run on a physical device for full functionality.

### Permissions Required

The app requires the following permissions and capabilities:

1. **Family Controls**: To access Screen Time APIs and select apps to block
2. **Notifications**: To send local notifications about rest events
3. **Background Processing**: To run background tasks for rest session management
4. **App Group**: To share data between the main app and extensions

## 📱 Usage

### First Launch

1. The app detects no rest configuration exists
2. A mandatory setup screen appears
3. Set your rest start and end times (e.g., 23:30 → 07:00)
4. Select which apps to block during rest using the Family Controls picker
5. Optionally configure the AI Coach and grace period
6. Save to complete setup

### Night Mode

1. When you enter your rest window, the app automatically starts monitoring
2. Selected apps are shielded with a custom screen
3. If you try to open a blocked app, you see a shield with "Unlock" and "Cancel"
4. Tapping "Unlock" breaks your rest streak and removes the shield
5. Tapping "Cancel" keeps the shield active

### Stats

1. View your current rest streak and best streak
2. See how many breaks you had this week
3. Check your average rest start time over the last 15 days
4. Review a 15-day break history chart

### Settings

1. Adjust your rest window times
2. Change which apps are blocked
3. Configure the grace period (minutes before rest starts)
4. Enable or disable notifications

## 🛠️ Technical Details

### Screen Time API Integration

The app uses three Apple frameworks for digital wellness:

- **FamilyControls**: Provides `FamilyActivityPicker` for app selection and authorization via `AuthorizationCenter`
- **DeviceActivity**: Monitors device activity during scheduled intervals via `DeviceActivityCenter` and `DeviceActivityMonitor`
- **ManagedSettings**: Applies shields to selected apps via `ManagedSettingsStore`

### Data Persistence

- All data is stored in `UserDefaults` within the shared App Group
- DTOs handle `Codable` serialization between the main app and extensions
- The `RestSessionDTO` mirrors `RestSessionEntity` for use in extensions that cannot access the main app's types

### Background Execution

- Registered background task identifier: `com.timetorest.nightcheck`
- Background modes: `fetch` and `processing`
- `BackgroundTaskManager` registers and schedules background tasks on app launch

### Swift Concurrency

- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `RestSessionManager` and `Router` are `@MainActor` and `@Observable`
- Use cases and entities are designed to be `Sendable` where appropriate

### Inter-Process Communication

The main app and extensions communicate via:
- **Darwin Notifications**: `CFNotificationCenter` for real-time events (e.g., shield unlock requested)
- **Shared UserDefaults**: App Group storage for session data persistence

### Glassmorphism UI

The app uses a custom glassmorphism design system:
- `GlassCard` and `BigGlassCard`: Reusable translucent card components
- `CustomTabBar`: Custom tab bar with glass effect
- Optimized for dark mode with `preferredColorScheme(.dark)`

### Device Support

- **iPhone & iPad** (`TARGETED_DEVICE_FAMILY = 1,2`)
- **iOS Deployment Target**: 26.0
- **App Category**: Healthcare & Fitness
- **Bundle Identifier**: `com.javidev.TimeToRest`
- **App Group**: `group.com.javidev.TimeToRest`

## 🔧 Configuration

### Build Settings

- **iOS Deployment Target**: 26.0
- **Swift Language Version**: 5.0
- **Swift Concurrency**: Approachable concurrency with MainActor default isolation
- **Architecture**: Clean Architecture with MVVM and section-based UI
- **Code Signing**: Automatic with Apple Development identity

### Targets

| Target | Type | Bundle ID |
|--------|------|-----------|
| `TimeToRest` | App | `com.javidev.TimeToRest` |
| `TimeToRestMonitorExtension` | App Extension | `com.javidev.TimeToRest.TimeToRestMonitorExtension` |
| `TimeToRestShieldActionExtension` | App Extension | `com.javidev.TimeToRest.TimeToRestShieldActionExtension` |
| `TimeToRestShieldConfigurationExtension` | App Extension | `com.javidev.TimeToRest.TimeToRestShieldConfigurationExtension` |

### Environment Configurations

- **Debug**: Includes preview support and debug mocks for stats
- **Release**: Optimized build with production settings

## 📋 Requirements

### Functional Requirements

- ✅ Configure a nightly rest window with start and end times
- ✅ Select apps to block during rest using Family Controls
- ✅ Automatically shield selected apps during the rest window
- ✅ Detect when the user unlocks blocked apps and record the break
- ✅ Track rest streaks (current and best)
- ✅ Display weekly break count and 15-day history
- ✅ Provide sleep tips via AI Coach
- ✅ Send local notifications for rest events
- ✅ Run background tasks to maintain rest sessions
- ✅ Require mandatory setup on first launch

### Non-Functional Requirements

- ✅ SwiftUI interface optimized for dark mode
- ✅ Clean, maintainable, testable architecture
- ✅ Swift concurrency-safe with MainActor isolation
- ✅ App Group data sharing between app and extensions
- ✅ iPad and iPhone support

## 🧪 Testing

### Manual Testing

1. **Setup Flow**: Test first-launch mandatory configuration
2. **Rest Window**: Verify monitoring starts at the configured time
3. **App Shielding**: Open a blocked app and verify the shield appears
4. **Break Detection**: Tap "Unlock" on the shield and verify the streak breaks
5. **Stats**: Verify streak calculation and 15-day history rendering
6. **Notifications**: Test blocked attempt and rest broken notifications
7. **Background**: Verify background tasks keep sessions alive

### Debug Features

Debug builds include:
- `RestStatsEntity.debugConsistentMock`: A consistent mock for stats preview
- `NightModeViewModel+Preview`: Preview support for SwiftUI canvases

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

When adding a new feature, follow the existing patterns:
- **Domain layer**: Add entities, repository contracts, and use cases organized by feature
- **Data layer**: Add DTOs, repository implementations, and infrastructure services
- **Presentation layer**: Add screens with section-based architecture (Screen, ViewModel, Sections)
- **Navigation**: Add new routes to `Route` and handle them in `RouteViewFactory`
- **Dependencies**: Register new use cases and repositories in `AppDependencies`

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Apple Screen Time API (FamilyControls, DeviceActivity, ManagedSettings) for digital wellness capabilities
- SwiftUI for modern declarative UI development
- Clean Architecture principles for maintainable, testable code
- The Swift Observation framework for reactive state management

## 📞 Support

If you have any questions or issues, please open an issue on the GitHub repository.

---

**Made with ❤️ using SwiftUI, Screen Time API, and Clean Architecture**
