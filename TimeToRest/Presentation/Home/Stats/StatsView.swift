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
                breakRateChart
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

    private var breakRateChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Break Rate 15d")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("Daily break / no break")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                Text("\(statsViewModel.breakRatePercentage)%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            BreakRateDailyChart(values: statsViewModel.breakRateDailySeries)
            .frame(height: 120)

            HStack {
                Text("15 days ago")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
                Text("Break-free: \(statsViewModel.breakFreeDaysCount)/15")
                    .font(.caption2)
                    .foregroundStyle(.green.opacity(0.85))
                Text("Breaks: \(statsViewModel.breakDaysCount)/15")
                    .font(.caption2)
                    .foregroundStyle(.red.opacity(0.85))
                Spacer()
                Text("Today")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }

}

private struct BreakRateDailyChart: View {
    let values: [Bool]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let safeValues = values.isEmpty ? [Bool](repeating: false, count: 15) : values
            let denominator = max(CGFloat(safeValues.count - 1), 1)
            let breakY = height * 0.22
            let noBreakY = height * 0.78

            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        Rectangle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                Path { path in
                    path.move(to: CGPoint(x: 0, y: breakY))
                    path.addLine(to: CGPoint(x: width, y: breakY))
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 1)

                Path { path in
                    path.move(to: CGPoint(x: 0, y: noBreakY))
                    path.addLine(to: CGPoint(x: width, y: noBreakY))
                }
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                Path { path in
                    for (index, didBreak) in safeValues.enumerated() {
                        let x = (CGFloat(index) / denominator) * width
                        let y = didBreak ? breakY : noBreakY
                        let point = CGPoint(x: x, y: y)

                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                ForEach(Array(safeValues.enumerated()), id: \.offset) { index, didBreak in
                    let x = (CGFloat(index) / denominator) * width
                    let y = didBreak ? breakY : noBreakY

                    Circle()
                        .fill(didBreak ? Color.red : Color.green)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }

                VStack {
                    HStack {
                        Text("Break")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.85))
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("No break")
                            .font(.caption2)
                            .foregroundStyle(.green.opacity(0.85))
                        Spacer()
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }
}
