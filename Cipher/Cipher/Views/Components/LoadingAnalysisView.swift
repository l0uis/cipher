import SwiftUI

struct LoadingAnalysisView: View {
    @State private var currentStep = 0
    @State private var timer: Timer?

    private let steps = [
        "Analyzing pattern...",
        "Identifying cultural origins...",
        "Examining motifs and symbols...",
        "Researching historical context...",
        "Analyzing color palette...",
        "Investigating material techniques...",
        "Exploring cultural references...",
        "Compiling analysis..."
    ]

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)

            Text(steps[currentStep])
                .font(CipherStyle.Fonts.subheadline)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: currentStep)

            Text("This may take up to a minute")
                .font(CipherStyle.Fonts.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                withAnimation {
                    currentStep = (currentStep + 1) % steps.count
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}
