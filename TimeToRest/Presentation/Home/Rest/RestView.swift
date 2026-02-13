import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct RestView: View {
    
    @ObservedObject var viewModel: RestViewModel
    @EnvironmentObject private var router: Router
    
    init(viewModel: RestViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Day Content (normal mode)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                streak
                scheduleCard
                infoCardsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
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
            GlassCard(icon: "shield", title: "Strict mode", value: viewModel.isStrictMode ? "Activated" : "Deactivated", iconColor: .indigo)
            
            // Horario Card
            GlassCard(icon: "clock", title: "Schedule", value: "\(viewModel.formattedStartTime) - \(viewModel.formattedEndTime)", iconColor: .gray)
        }
    }
}
