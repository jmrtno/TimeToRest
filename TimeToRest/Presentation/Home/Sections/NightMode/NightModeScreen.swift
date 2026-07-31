import SwiftUI

// MARK: - NightModeScreen

struct NightModeScreen: View {

    var viewModel: NightModeViewModel
    @Environment(Router.self) private var router
    @State private var stars: [StarSpec] = StarSpec.generate(count: 20)
    @State private var showLateMessage = false
    @State private var isAnimating: Bool = false

    @Environment(\.verticalSizeClass) private var vSizeClass

    var isLandscapeCompact: Bool {
        vSizeClass == .compact
    }

    private var successBreak: Bool {
        viewModel.showCompletedButtonStyle
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

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 16)
                cardsAndMessage
                    .padding(.top, 16)
                Spacer()
                winningHours
                Spacer()
                breakRestButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 42)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .topTrailing) {
            reconfigureOverlay
        }
    }

    @ViewBuilder
    private var reconfigureOverlay: some View {
        if viewModel.isWithinGracePeriod, let secondsLeft = viewModel.gracePeriodSecondsRemaining {
            reconfigureButton(secondsLeft: secondsLeft)
                .padding(.trailing, 24)
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack {
            Image("night-mode-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .background(
                    Circle()
                        .fill(Color.indigo.opacity(0.10))
                        .frame(width: 250, height: 250)
                        .blur(radius: 36)
                )
            Text("Time to rest")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .padding(.bottom, 8)
        }

    }
    
    // MARK: - Cards and Messages
    
    private var cardsAndMessage: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatsGlassCardSectionView(icon: "alarm",
                                          title: "Alarm",
                                          value: viewModel.formattedEndTime,
                                          iconColor: .gray)
            }
            
            Text("Keep the app open to track your streak")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.3))
        }
    }
    
    // MARK: - Winning Hours

    private var winningHours: some View {
        VStack(spacing: 8) {
            Text(viewModel.formattedSessionRestHours)
                .font(.system(size: 50, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("Expected rest hours")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.gray.opacity(0.9))

            if let minutesLate = viewModel.minutesLate {
                Text("You started \(minutesLate) minutes late")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .opacity(showLateMessage ? 1 : 0)
            }
        }
        .onAppear {
            triggerLateMessageAnimation()
        }
        .onChange(of: viewModel.minutesLate) {
            triggerLateMessageAnimation()
        }
    }
    
    // MARK: - Break Rest Button
    
    private var breakRestButton: some View {
        let buttonBgColor = !successBreak ? Color.red : Color.green
        let buttonColor = !successBreak ? Color.red : Color.green
        let buttonText = !successBreak ? "Break rest" : "Rest finished"
    return VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(buttonBgColor)
                        .frame(width: 65, height: 65)
                        .opacity(isAnimating ? 0.3 : 0)
                        .blur(radius: 30)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 3.0)
                                .repeatForever(autoreverses: true)
                            ) {
                                isAnimating = true
                            }
                        }
                    Button {
                        handleBreakAction()
                    } label: {
                        Image(systemName: "power")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .padding(30)
                            .background(
                                Circle()
                                    .stroke(buttonBgColor.opacity(0.2), lineWidth: 1))
                    }
                }
                Text(buttonText)
                    .font(.subheadline)
            }
            .foregroundStyle(buttonColor.opacity(0.6))
            .animation(.easeInOut(duration: 1.0), value: successBreak)
    }

    // MARK: - Reconfigure Button

    private func reconfigureButton(secondsLeft: Int) -> some View {
        let minutesLeft = max(1, (secondsLeft + 59) / 60)
        return Button {
            handleReconfigureAction()
        } label: {
            VStack {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .tint(Color.orange.opacity(0.7))
                Text("Reconfig.\n\(minutesLeft) min. left")
                    .font(.footnote)
                    .foregroundStyle(.orange.opacity(0.7))
            }
        }
        .padding(.top, 12)
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

private extension NightModeScreen {

    private func triggerLateMessageAnimation() {
        guard viewModel.minutesLate != nil else {
            showLateMessage = false
            return
        }

        showLateMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeOut(duration: 3)) {
                showLateMessage = false
            }
        }
    }

    struct StarSpec: Identifiable {
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

    struct TwinklingStarView: View {
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

    private func handleBreakAction() {
        Task {
            let result = await viewModel.handleBreakRequest()
            switch result {
            case .completed:
                router.presentBreakBlock(mode: .celebration)
            case .needsManualBreak:
                router.presentBreakBlock(mode: .countdown)
            case .noSession:
                break
            }
        }
    }

    private func handleReconfigureAction() {
        Task {
            await viewModel.requestGracePeriodReconfiguration()
            router.presentRestConfiguration(mode: .editable)
        }
    }
}

#if DEBUG
#Preview("Grace Period") {
    ZStack {
        Color.black.ignoresSafeArea()
        NightModeScreen(viewModel: .previewWithGracePeriod)
    }
    .environment(Router())
}

#Preview("Default") {
    ZStack {
        Color.black.ignoresSafeArea()
        NightModeScreen(viewModel: .preview)
    }
    .environment(Router())
}
#endif
