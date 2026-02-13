import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var router: Router
    @State private var currentView: ViewType = .home
    @StateObject private var statsViewModel: StatsViewModel
    
    enum ViewType {
        case home
        case stats
    }
    
    init(viewModel: HomeViewModel, calculateStatsUseCase: CalculateStatsUseCase) {
        self.viewModel = viewModel
        self._statsViewModel = StateObject(wrappedValue: StatsViewModel(
            calculateStatsUseCase: calculateStatsUseCase
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Contenido principal
                if viewModel.showNightMode {
                    nightModeContent
                } else {
                    if currentView == .home {
                        dayContent
                    } else {
                        statsContent
                    }
                }
                
                // Barra de navegación inferior
                CustomTabBar(currentView: $currentView)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showNightMode)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: router.navigationPath) { _, newPath in
            if newPath.isEmpty {
                viewModel.reload()
            }
        }
    }

    // MARK: - Day Content (normal mode)

    private var dayContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                streak
                scheduleCard
                infoCardsSection
                actionsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Night Mode Content (inline)

    private var nightModeContent: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("😴")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                Text("Time to rest.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Come back tomorrow")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))

                if let lateMessage = viewModel.lateMessage {
                    Text(lateMessage)
                        .font(.subheadline)
                        .foregroundStyle(.orange.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }

            Spacer()
            
            Text("Keep the app open to track your streak")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 16) {
                // Break the block
                Button {
                    router.push(.breakBlock)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(viewModel.isStrictMode ? .caption2 : .caption)
                        Text("Break the block")
                            .font(viewModel.isStrictMode ? .caption : .subheadline)
                    }
                    .foregroundStyle(.red.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, viewModel.isStrictMode ? 10 : 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Stats Content
    
    private var statsContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                statsHeaderSection
                statsGrid
                motivationSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .onAppear {
            statsViewModel.onAppear()
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeaderSection: some View {
        VStack(spacing: 8) {
            Text("📊")
                .font(.system(size: 48))

            Text("Your Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Every night counts")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 20)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 12) {
            // El contenido está comentado en el original, lo mantengo así
        }
    }

    // MARK: - Motivation

    private var motivationSection: some View {
        VStack(spacing: 12) {
            if statsViewModel.stats.currentStreak > 0 {
                motivationCard(
                    message: streakMessage,
                    color: .orange
                )
            }

            if statsViewModel.stats.breaksThisWeek == 0 {
                motivationCard(
                    message: "Perfect week so far! Keep it up 💪",
                    color: .green
                )
            }
        }
        .padding(.bottom, 40)
    }

    private func motivationCard(message: String, color: Color) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
    }

    private var streakMessage: String {
        let streak = statsViewModel.stats.currentStreak
        switch streak {
        case 1: return "1 night down. The journey begins 🌱"
        case 2...4: return "\(streak) nights! Building momentum 🔥"
        case 5...9: return "\(streak) nights! You're on fire 🔥🔥"
        case 10...29: return "\(streak) nights! Incredible discipline 💪"
        default: return "\(streak) nights! You're unstoppable 🚀"
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hello, time to rest")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("Next rest: \(viewModel.formattedStartTime)")
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
    
    private var streak: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "trophy")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current streak")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("\(viewModel.stats.currentStreak) days in a row")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
            }
            
            HStack(spacing: 8) {
                let startDay = max(1, viewModel.stats.currentStreak - 6)
                
                ForEach(0..<7, id: \.self) { index in
                    let dayNumber = startDay + index
                    let isCompleted = dayNumber <= viewModel.stats.currentStreak && index < 5
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCompleted ? Color.orange : Color.gray.opacity(0.3))
                        .frame(height: 32)
                        .overlay(
                            Text("\(dayNumber)")
                                .font(.system(size: 12,).weight(.bold))
                                .foregroundStyle(isCompleted ? .white : Color.gray.opacity(0.6))
                        )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .glassEffect(in: .rect(cornerRadius: 24))
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
                        Text("Rest Schedule")
                            .font(.headline)
                            .foregroundStyle(.black)
                        
                        Text("Configuration")
                            .font(.subheadline)
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black.opacity(0.5))
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
            // Modo Estricto Card
            GlassCard(icon: "shield", title: "Streak mode", value: viewModel.isStrictMode ? "Activated" : "Deactivated", iconColor: .indigo)
            
            // Horario Card
            GlassCard(icon: "clock", title: "Schedule", value: "\(viewModel.formattedStartTime) - \(viewModel.formattedEndTime)", iconColor: .gray)
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Espacio vacío ya que la navegación ahora está en la barra inferior
        }
        .padding(.bottom, 20)
    }
}
