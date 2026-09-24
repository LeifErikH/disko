import SwiftUI

struct SettingsOrb: View {
    let edge: NotchEdge
    let isHovered: Bool

    var body: some View {
        ZStack {
            Circle()
                .trim(from: edge.restingTrim.lowerBound, to: edge.restingTrim.upperBound)
                .stroke(Color.black, style: StrokeStyle(lineWidth: Layout.orbStroke, lineCap: .round))
                .frame(width: Layout.orbArcRadius * 2, height: Layout.orbArcRadius * 2)
                .opacity(isHovered ? 0 : 1)
                .scaleEffect(isHovered ? 0.86 : 1)

            Circle()
                .fill(Color.black)
                .frame(width: Layout.orbDiameter, height: Layout.orbDiameter)
                .opacity(isHovered ? 1 : 0)
                .scaleEffect(isHovered ? 1 : 1.1)

            Image(systemName: "gearshape")
                .font(.system(size: Layout.orbGlyph, weight: .regular))
                .foregroundStyle(Palette.ink)
                .opacity(isHovered ? 1 : 0)
                .scaleEffect(isHovered ? 1 : 0.5)
                .rotationEffect(.degrees(isHovered ? 0 : -60))
        }
        .frame(width: Layout.orbDiameter + Layout.orbStroke, height: Layout.orbDiameter + Layout.orbStroke)
        .animation(.spring(response: 0.36, dampingFraction: 0.7), value: isHovered)
    }
}
