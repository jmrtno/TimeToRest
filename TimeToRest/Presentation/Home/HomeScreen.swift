import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.showNightMode {
                nightModeContent
            } else {
                dayContent
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
                    Text("Racha actual")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text("\(viewModel.stats.currentStreak) días seguidos")
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
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
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
            Button {
                router.push(.stats)
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Statistics")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
        .padding(.bottom, 40)
    }
}
