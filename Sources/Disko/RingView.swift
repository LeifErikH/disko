import SwiftUI

struct RingView: View {
    let agent: Agent
    let share: Double
    let bytes: Int64?
    let isScanning: Bool

    @State private var spin: Double = 0

    private var color: Color {
        Palette.band(for: bytes ?? 0, watch: 5, critical: 15)
    }

    var body: some View {
        VStack(spacing: Layout.ringLabelGap) {
            ZStack {
                Circle()
                    .strokeBorder(Palette.ringTrack, lineWidth: Layout.trackStroke)

                Circle()
                    .inset(by: Layout.trackStroke / 2)
                    .trim(from: 0, to: bytes == nil ? 0.18 : max(share, 0.02))
                    .stroke(bytes == nil ? Palette.secondaryInk : color,
                            style: StrokeStyle(lineWidth: Layout.progressStroke, lineCap: .round))
                    .rotationEffect(.degrees(-90 + spin))
                    .animation(.spring(response: 0.7, dampingFraction: 0.85), value: share)

                GlyphView(agent: agent)
                    .foregroundStyle(Palette.ink)
            }
            .frame(width: Layout.ring, height: Layout.ring)

            Text(bytes.map(Bytes.short) ?? "···")
                .font(Typography.size)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .frame(height: Layout.labelHeight)
        }
        .onChange(of: isScanning, initial: true) { _, scanning in
            guard scanning else { return }
            spinOnce()
        }
    }

    private func spinOnce() {
        withAnimation(.timingCurve(0.32, 0, 0.14, 1, duration: 0.95)) {
            spin += 360
        } completion: {
            if isScanning { spinOnce() }
        }
    }
}
