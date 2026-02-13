import Foundation
import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct StatsView: View {

    @StateObject private var statsViewModel: StatsViewModel
    
    init(calculateStatsUseCase: CalculateStatsUseCase) {
        self._statsViewModel = StateObject(wrappedValue: StatsViewModel(
            calculateStatsUseCase: calculateStatsUseCase
        ))
    }
    
    // MARK: - Stats Content
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsHeaderSection
                statsGrid
                restBreaks
                averageStartTime
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
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.orange)
            
            Text("Your Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Every night counts")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            StatsGlassCard(
                icon: "trophy",
                title: "Current Streak",
                value: "\(statsViewModel.stats.currentStreak)",
                iconColor: .orange
            )
            
            StatsGlassCard(
                icon: "star",
                title: "Best Streak",
                value: "\(statsViewModel.stats.bestStreak)",
                iconColor: .blue
            )
        }
    }
    
    private var restBreaks: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "nosign")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Rest breaks")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("This week")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text("\(statsViewModel.stats.breaksThisWeek)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    private var averageStartTime: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "clock.badge")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Average start time")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("Last 30 days")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            Text(statsViewModel.formattedAverageStartTime)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}
