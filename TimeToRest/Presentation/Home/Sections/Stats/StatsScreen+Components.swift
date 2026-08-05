import SwiftUI

extension StatsScreen {
    
    struct BreakRateDailyChart: View {
        let values: [Bool]
        let isVisible: Bool
        
        init(values: [Bool], isVisible: Bool = false) {
            self.values = values
            self.isVisible = isVisible
        }

        var body: some View {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let safeValues = values
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
                    .trim(from: 0, to: isVisible ? 1 : 0)
                    .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .animation(.easeInOut(duration: 0.8).delay(0.2), value: isVisible)

                    ForEach(Array(safeValues.enumerated()), id: \.offset) { index, didBreak in
                        let x = (CGFloat(index) / denominator) * width
                        let y = didBreak ? breakY : noBreakY

                        Circle()
                            .fill(didBreak ? Color.red : Color.green)
                            .frame(width: 6, height: 6)
                            .position(x: x, y: y)
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1 : 0.4)
                            .animation(
                                .smooth(duration: 0.35, extraBounce: 0.1)
                                    .delay(0.45 + Double(index) * 0.02),
                                value: isVisible
                            )
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
}

