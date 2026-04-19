import SwiftUI

/// Skeleton/shimmer placeholder shown while a panel loads its first data.
/// Matches the approximate height and layout of the target panel so there is no layout shift.
struct LoadingStateView: View {
    var rows: Int = 3
    var showsLargeBlock: Bool = false

    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsLargeBlock {
                shimmerBlock(height: 60, widthFraction: 0.5)
            }
            ForEach(0 ..< rows, id: \.self) { index in
                shimmerBlock(height: 16, widthFraction: index == 0 ? 0.8 : 0.6)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
        .accessibilityLoading("Panel")
    }

    private func shimmerBlock(height: CGFloat, widthFraction: CGFloat) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 6)
                .fill(shimmerGradient(width: proxy.size.width))
                .frame(width: proxy.size.width * widthFraction, height: height)
        }
        .frame(height: height)
    }

    private func shimmerGradient(width _: CGFloat) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color.secondaryLabel.opacity(0.2), location: 0),
                .init(color: Color.secondaryLabel.opacity(0.4), location: max(0, phase - 0.2)),
                .init(color: Color.secondaryLabel.opacity(0.2), location: phase)
            ],
            startPoint: .leading,
            endPoint: .trailing,
        )
    }
}
