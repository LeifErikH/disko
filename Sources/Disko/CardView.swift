import SwiftUI

struct CardView: View {
    let footprint: Footprint
    let takenAt: Date
    let tailSide: Edge
    let tailOffset: CGFloat
    let reveal: (Footprint.Slice) -> Void

    private static let visibleSlices = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, Layout.headerToBlock)

            VStack(alignment: .leading, spacing: Layout.blockSpacing) {
                ForEach(footprint.slices.prefix(Self.visibleSlices)) { slice in
                    SliceRow(slice: slice, total: footprint.bytes)
                        .contentShape(Rectangle())
                        .onTapGesture { reveal(slice) }
                }
            }

            footer
                .padding(.top, Layout.headerToBlock)
        }
        .padding(Layout.cardPadding)
        .frame(width: Layout.cardWidth, alignment: .leading)
        .padding(Edge.Set(tailSide), Layout.tailLength)
        .background(CardShape(side: tailSide, tailOffset: tailOffset).fill(Color.black))
    }

    private var header: some View {
        HStack(spacing: Layout.headerGap) {
            GlyphView(agent: footprint.agent, size: Design.px(40))
                .foregroundStyle(Palette.ink)
            Text("\(footprint.agent.title) Disk")
                .font(Typography.cardTitle)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: 0)
            Text(Bytes.long(footprint.bytes))
                .font(Typography.cardBody)
                .foregroundStyle(Palette.secondaryInk)
        }
    }

    private var footer: some View {
        Text("Scanned \(takenAt.formatted(.relative(presentation: .named))) · click a row to reveal")
            .font(Typography.cardBody)
            .foregroundStyle(Palette.secondaryInk)
    }
}

private struct SliceRow: View {
    let slice: Footprint.Slice
    let total: Int64

    @State private var isHovered = false

    private var fraction: CGFloat {
        total > 0 ? CGFloat(slice.bytes) / CGFloat(total) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(slice.kind.title)
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 12)
                Text(caption)
                    .foregroundStyle(Palette.secondaryInk)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .font(Typography.cardBody)
            .padding(.bottom, Layout.labelToBar)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.barTrack)
                    Capsule()
                        .fill(Palette.band(for: slice.bytes, watch: 1, critical: 5))
                        .frame(width: max(Layout.barHeight, geometry.size.width * fraction))
                }
            }
            .frame(height: Layout.barHeight)
            .padding(.bottom, Layout.barToUsed)

            Text("\(Bytes.long(slice.bytes)) · \(Int((fraction * 100).rounded()))%")
                .font(Typography.cardBody)
                .foregroundStyle(Palette.ink)
        }
        .opacity(isHovered ? 0.75 : 1)
        .onHover { isHovered = $0 }
    }

    private var caption: String {
        guard let biggest = slice.biggest else { return "" }
        let others = slice.finds.count - 1
        return others > 0 ? "\(biggest.label) +\(others)" : biggest.label
    }
}
