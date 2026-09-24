import SwiftUI

enum Report {
    static func print(_ census: Census) {
        for agent in Agent.allCases {
            let footprint = census.footprint(of: agent)
            Swift.print("\n\(agent.title.uppercased())  \(Bytes.long(footprint.bytes))")
            for slice in footprint.slices {
                Swift.print("  \(slice.kind.title.padding(toLength: 22, withPad: " ", startingAt: 0))\(Bytes.long(slice.bytes))")
                for find in slice.finds.sorted(by: { $0.bytes > $1.bytes }).prefix(6) {
                    Swift.print("      \(Bytes.short(find.bytes).padding(toLength: 7, withPad: " ", startingAt: 0))\(find.label)")
                }
            }
        }
        Swift.print("\nTOTAL  \(Bytes.long(census.total))")
    }

    @MainActor
    static func snapshot(_ census: Census, focus: Agent, edge: NotchEdge, to path: String) {
        let store = Store(census: census)
        store.isExpanded = true
        store.focus = focus
        store.edge = edge
        let renderer = ImageRenderer(content: NotchView(store: store).background(Color(hex: 0x3A6F86)))
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: URL(filePath: path))
    }
}
