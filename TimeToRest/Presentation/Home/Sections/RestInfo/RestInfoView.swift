import SwiftUI

// MARK: - RestInfoView

struct RestInfoView: View {
    
    @ObservedObject var viewModel: RestInfoViewModel
    @EnvironmentObject private var router: Router
    
    @Environment(\.verticalSizeClass) private var vSizeClass

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
            headerSection
            streak
            scheduleCard
            infoCardsSection
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            viewModel.onAppear()
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
        BigGlassCard(icon: "trophy",
                       title: "Current streak",
                       subtitle: "\(viewModel.stats.currentStreak) days in a row",
                       value: "",
                       color: .orange,
                       content: {
            return HStack(spacing: 8) {
                let startDay = max(1, viewModel.stats.currentStreak - 6)
                
                ForEach(0..<7, id: \.self) { index in
                    let dayNumber = startDay + index
                    let isCompleted = dayNumber <= viewModel.stats.currentStreak && index < 5
                    let isBestStreakDay = dayNumber == viewModel.stats.bestStreak
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isCompleted ? Color.orange : Color.gray.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isBestStreakDay ? .blue : .clear, lineWidth: 3)
                        )
                        .frame(height: 32)
                        .overlay(
                            Text("\(dayNumber)")
                                .font(.system(size: 12).weight(.bold))
                                .foregroundStyle(isCompleted || isBestStreakDay ? .white : Color.gray.opacity(0.6))
                        )
                }
            }
        })
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
            GlassCard(icon: "shield",
                      title: "Strict mode",
                      value: viewModel.isStrictMode ? "Activated" : "Deactivated",
                      iconColor: .indigo)
            
            // Horario Card
            GlassCard(icon: "clock",
                      title: "Schedule",
                      value: "\(viewModel.formattedStartTime) - \(viewModel.formattedEndTime)",
                      iconColor: .gray)
        }
    }
}

