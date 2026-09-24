import SwiftUI

struct NotchView: View {
    @ObservedObject var store: Store
    @State private var cardSize: CGSize = .zero
    @State private var orbHovered = false

    private var placement: Placement { Placement(edge: store.edge) }

    var body: some View {
        let size = placement.windowSize

        ZStack(alignment: .topLeading) {
            card
            notch
            orb
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: store.isExpanded)
        .animation(.easeOut(duration: 0.18), value: store.focus)
    }

    private var notch: some View {
        let depth = store.isExpanded ? placement.depth : Layout.pillDepth
        let length = store.isExpanded ? placement.notchLength : Layout.pillLength
        let frame = placement.frame(depth: depth, length: length)

        return ZStack {
            NotchShape(edge: store.edge)
                .fill(Color.black)
                .frame(width: frame.width, height: frame.height)
                .position(placement.point(along: placement.notchLength / 2, across: depth / 2))

            if store.isExpanded {
                rings
                    .position(placement.point(along: placement.stackCenter, across: placement.depth / 2))
                    .transition(.opacity.combined(with: .scale(scale: 0.6)))
            }
        }
        .contextMenu {
            Button("Rescan") { store.rescan() }
            Button("Settings…") { store.openSettings() }
            Divider()
            Button("Quit Disko") { NSApp.terminate(nil) }
        }
    }

    private var rings: some View {
        let layout = store.edge.isVertical
            ? AnyLayout(VStackLayout(spacing: Layout.cellSpacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Layout.cellSpacing))

        return layout {
            ForEach(Agent.allCases) { agent in
                RingView(agent: agent,
                         share: store.share(of: agent),
                         bytes: store.footprint(of: agent)?.bytes,
                         isScanning: store.isScanning)
                    .frame(width: Layout.ring)
                    .contentShape(Rectangle())
                    .onHover { if $0 { store.focus = agent } }
                    .onTapGesture { store.rescan() }
            }
        }
    }

    private var orb: some View {
        SettingsOrb(edge: store.edge, isHovered: orbHovered)
            .contentShape(Circle().scale(0.7))
            .onHover { orbHovered = $0 }
            .onTapGesture { store.openSettings() }
            .scaleEffect(store.isExpanded ? 1 : Layout.orbMergeScale)
            .opacity(store.isExpanded ? 1 : 0)
            .position(placement.orbCenter)
    }

    @ViewBuilder
    private var card: some View {
        if store.isExpanded, let agent = store.focus, let census = store.census {
            let index = Agent.allCases.firstIndex(of: agent) ?? 0
            let spot = placement.cardCenter(ring: index, cardSize: cardSize)

            CardView(footprint: census.footprint(of: agent),
                     takenAt: census.takenAt,
                     tailSide: store.edge.tailSide,
                     tailOffset: spot.tailOffset,
                     reveal: store.reveal)
                .fixedSize()
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                    cardSize = frame.size
                    store.cardFrame = frame
                }
                .position(spot.center)
                .opacity(cardSize == .zero ? 0 : 1)
                .transition(.opacity)
                .onDisappear { store.cardFrame = .zero }
        }
    }
}
