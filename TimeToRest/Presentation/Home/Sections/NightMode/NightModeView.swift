import SwiftUI

// MARK: - NightModeView

struct NightModeView: View {

    @ObservedObject var viewModel: NightModeViewModel
    @EnvironmentObject private var router: Router
    @State private var stars: [StarSpec] = StarSpec.generate(count: 20)
    
    @Environment(\.verticalSizeClass) private var vSizeClass

    var isLandscapeCompact: Bool {
        vSizeClass == .compact
    }
    
    var body: some View {
        if isLandscapeCompact {
            ScrollView {
                nightModeContent
            }
        } else {
            nightModeContent
        }
        
    }
    
    // MARK: - Night Content

    private var nightModeContent: some View {
        ZStack {
            animatedBackground

            VStack {
                header
                cardsAndMessage
                winningHours
                breakRestButton
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.10))
                    .frame(width: 250, height: 250)
                    .blur(radius: 36)
                Image("night-mode-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75, height: 75)
            }
            .offset(y: -110)
            
            Text("Time to rest")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .padding(.bottom, 14)
                .offset(y: -160)
        }
    }
    
    // MARK: - Cards and Messages
    
    private var cardsAndMessage: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatsGlassCard(icon: "shield",
                               title: "Strict mode",
                               value: viewModel.isStrictModeEnabled,
                               iconColor: .indigo)
                StatsGlassCard(icon: "alarm",
                               title: "Alarm",
                               value: viewModel.formattedEndTime,
                               iconColor: .gray)
            }
            
            Text("Keep the app open to track your streak")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.3))
        }
        .offset(y: -160)
    }
    
    // MARK: - Winning Hours
    
    private var winningHours: some View {
        VStack {
            Text(viewModel.formattedSessionRestHours)
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("Horas de descanso previstas")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.gray.opacity(0.9))
        }
        .offset(y: -75)
    }
    
    // MARK: - Break Rest Button
    
    private var breakRestButton: some View {
        VStack(spacing: 16) {
            Button {
                router.presentBreakBlock()
            } label: {
                Image(systemName: "power")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .padding(viewModel.isStrictMode ? 20 : 30)
                    .background(
                        Circle()
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                    
            }
            
            Text("Break rest")
                .font(viewModel.isStrictMode ? .caption : .subheadline)
        }
        .foregroundStyle(.red.opacity(0.6))
    }

    // MARK: - Animated Background
    
    private var animatedBackground: some View {
        GeometryReader { proxy in
            ForEach(stars) { star in
                TwinklingStarView(spec: star, size: proxy.size)
            }
            .ignoresSafeArea()
        }
    }
}

private struct StarSpec: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    let delay: Double

    static func generate(count: Int) -> [StarSpec] {
        (0..<count).map { _ in
            StarSpec(
                x: .random(in: 0...1),
                y: .random(in: 0...1),
                size: .random(in: 1...2.2),
                minOpacity: .random(in: 0.15...0.35),
                maxOpacity: .random(in: 0.55...0.95),
                duration: .random(in: 2.0...5.0),
                delay: .random(in: 0...2.0)
            )
        }
    }
}

private struct TwinklingStarView: View {
    let spec: StarSpec
    let size: CGSize

    @State private var isTwinkling = false

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: spec.size, height: spec.size)
            .opacity(isTwinkling ? spec.maxOpacity : spec.minOpacity)
            .position(x: spec.x * size.width, y: spec.y * size.height)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: spec.duration)
                    .repeatForever(autoreverses: true)
                    .delay(spec.delay)
                ) {
                    isTwinkling = true
                }
            }
    }
}
