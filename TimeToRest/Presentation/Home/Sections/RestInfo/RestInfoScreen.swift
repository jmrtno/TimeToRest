import SwiftUI

// MARK: - RestInfoScreen

struct RestInfoScreen: View {

    var viewModel: RestInfoViewModel
    @Environment(Router.self) private var router
    @Environment(\.verticalSizeClass) private var vSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isContentVisible = false
    @State private var isStreakVisible = false
    @State private var displayedCurrentStreak = 0
    @State private var displayedBestStreak = 0

    var isLandscapeCompact: Bool {
        vSizeClass == .compact
    }
    
    init(viewModel: RestInfoViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if isLandscapeCompact {
            ScrollView {
                restContent
            }
        } else {
            restContent
        }
        
    }

    // MARK: - Day Content
    
    private var restContent: some View {
        VStack(spacing: 24) {
            stage(headerSection, delay: 0.0)
            stage(streak, delay: 0.12)
            stage(scheduleCard, delay: 0.24)
            stage(infoCardsSection, delay: 0.36)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            viewModel.onAppear()
        }
        .task {
            await runEntranceAnimations()
        }
        .onChange(of: viewModel.stats) { _, newStats in
            syncDisplayedStats(with: newStats)
        }
    }
    
    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hello, Time To Rest")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Next rest starts at: \(viewModel.formattedStartTime)")
                    .foregroundStyle(.white.opacity(0.6))
                
            }
            .padding(.top, 15)
            
            Spacer()
            
            Image("home-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
        }
        
    }
    
    // MARK: - Streak section
    
    private var streak: some View {
        BigGlassCard(icon: "trophy",
                     title: "Current streak",
                     subtitle: "\(displayedCurrentStreak) days in a row",
                     value: "",
                     color: .orange,
                     animateNumbers: true) {
            HStack(spacing: 8) {
                let startDay = max(1, viewModel.stats.currentStreak - 4)
                
                ForEach(0..<7, id: \.self) { index in
                    let dayNumber = startDay + index
                    let isCompleted = dayNumber <= viewModel.stats.currentStreak
                    let isBestStreakDay = dayNumber == viewModel.stats.bestStreak
                    
                    streakBar(
                        dayNumber: dayNumber,
                        isCompleted: isCompleted,
                        isBestStreakDay: isBestStreakDay,
                        index: index
                    )
                }
            }
        }
    }


    // MARK: - Schedule Card

    private var scheduleCard: some View {
        Button {
            router.presentRestConfiguration(mode: .editable)
        } label: {
            HStack {
                // Icono circular
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.1))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "moon")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.black)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Schedule")
                            .font(.headline)
                            .foregroundStyle(.black)
                        
                        Text("Rest Configuration")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black.opacity(0.5))
                    .offset(x: viewModel.isPressed ? 5 : 0)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.isPressed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
            )
            .foregroundStyle(.black)
            .scaleEffect(viewModel.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            viewModel.isPressed = pressing
        }, perform: {})
    }

    // MARK: - Info Cards

    private var infoCardsSection: some View {
        HStack(spacing: 16) {
            GlassCard(icon: "shield",
                      title: "Best Streak",
                      value: "\(displayedBestStreak)",
                      iconColor: .indigo,
                      animateNumbers: true)
            // Horario Card
            GlassCard(icon: "clock",
                      title: "Schedule",
                      value: "\(viewModel.formattedStartTime) - \(viewModel.formattedEndTime)",
                      iconColor: .gray)
        }
    }
}

// MARK: - Animations

/// Border that keeps a constant stroke while its glow breathes in and out.
private struct PulsingBorder: View {
    let color: Color
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(color, lineWidth: 3)
            .shadow(
                color: color.opacity(isPulsing ? 0.9 : 0.5),
                radius: isPulsing ? 10 : 5
            )
            .animation(.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                       value: isPulsing)
            .onAppear {
                isPulsing = !reduceMotion
            }
    }
}

private extension RestInfoScreen {

    func runEntranceAnimations() async {
        withAnimation(.smooth(duration: 0.55, extraBounce: 0.05)) {
            isContentVisible = true
        }
        try? await Task.sleep(for: .seconds(0.45))
        withAnimation(.smooth(duration: 0.5, extraBounce: 0.08)) {
            isStreakVisible = true
        }
        try? await Task.sleep(for: .seconds(0.4))
        syncDisplayedStats(with: viewModel.stats)
    }

    /// Keeps the animated counters aligned with the source of truth, so a reload
    /// after a schedule change cannot leave them showing stale values.
    func syncDisplayedStats(with stats: RestStatsEntity) {
        withAnimation(.default) {
            displayedCurrentStreak = stats.currentStreak
            displayedBestStreak = stats.bestStreak
        }
    }

    @ViewBuilder
    func stage<Content: View>(_ view: Content, delay: TimeInterval) -> some View {
        if reduceMotion {
            view
                .opacity(isContentVisible ? 1 : 0)
                .animation(.smooth(duration: 0.4).delay(delay), value: isContentVisible)
        } else {
            view
                .offset(y: isContentVisible ? 0 : 20)
                .opacity(isContentVisible ? 1 : 0)
                .animation(.smooth(duration: 0.65, extraBounce: 0.05).delay(delay), value: isContentVisible)
        }
    }

    func streakBar(dayNumber: Int, isCompleted: Bool, isBestStreakDay: Bool, index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(isCompleted ? Color.orange : Color.gray.opacity(0.3))
                .overlay {
                    if isBestStreakDay {
                        PulsingBorder(color: .indigo)
                    }
                }
                .frame(height: 32)
                .scaleEffect(y: isStreakVisible ? 1.0 : 0.0, anchor: .bottom)

            Text("\(dayNumber)")
                .font(.system(size: 12).weight(.bold))
                .foregroundStyle(isCompleted || isBestStreakDay ? .white : Color.gray.opacity(0.6))
                .opacity(isStreakVisible ? 1 : 0)
        }
        .animation(
            .smooth(duration: 0.5, extraBounce: 0.08)
                .delay(Double(index) * 0.04),
            value: isStreakVisible
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        RestInfoScreen(viewModel: .preview)
    }
    .environment(Router())
}
#endif
