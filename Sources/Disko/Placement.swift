import SwiftUI

enum NotchEdge: String, CaseIterable, Identifiable {
    case left, right, top, bottom

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var isVertical: Bool { self == .left || self == .right }

    var tailSide: Edge {
        switch self {
        case .right:  .trailing
        case .left:   .leading
        case .top:    .top
        case .bottom: .bottom
        }
    }

    var restingTrim: ClosedRange<CGFloat> {
        switch self {
        case .right:        0.75...1.0
        case .left, .top:   0.5...0.75
        case .bottom:       0.25...0.5
        }
    }
}

struct Placement {
    let edge: NotchEdge

    private static let horizontalPad = Design.px(60)
    private static let cardMaxHeight: CGFloat = 500
    static let orbReach = Layout.orbDiameter / 2 + Layout.orbStroke

    var depth: CGFloat {
        edge.isVertical ? Layout.depth : Layout.cell + 2 * Self.horizontalPad
    }

    var stackLength: CGFloat {
        let count = CGFloat(Agent.allCases.count)
        let cell = edge.isVertical ? Layout.cell : Layout.ring
        return count * cell + (count - 1) * Layout.cellSpacing
    }

    private var leadPad: CGFloat { edge.isVertical ? Layout.padTop : Self.horizontalPad }
    private var trailPad: CGFloat { edge.isVertical ? Layout.padBottom : Self.horizontalPad }

    var notchLength: CGFloat { 2 * Layout.curl + leadPad + stackLength + trailPad }

    var stackCenter: CGFloat { Layout.curl + leadPad + stackLength / 2 }

    func ringCenter(_ index: Int) -> CGFloat {
        let step = (edge.isVertical ? Layout.cell : Layout.ring) + Layout.cellSpacing
        return Layout.curl + leadPad + CGFloat(index) * step + Layout.ring / 2
    }

    var cardReach: CGFloat {
        Layout.tailGap + Layout.tailLength + (edge.isVertical ? Layout.cardWidth : Self.cardMaxHeight)
    }

    var along: CGFloat { notchLength + Self.orbReach }
    var across: CGFloat { depth + cardReach + 8 }

    var windowSize: CGSize {
        edge.isVertical ? CGSize(width: across, height: along) : CGSize(width: along, height: across)
    }

    func point(along a: CGFloat, across c: CGFloat) -> CGPoint {
        let size = windowSize
        switch edge {
        case .right:  return CGPoint(x: size.width - c, y: a)
        case .left:   return CGPoint(x: c, y: a)
        case .top:    return CGPoint(x: a, y: c)
        case .bottom: return CGPoint(x: a, y: size.height - c)
        }
    }

    func rect(along: ClosedRange<CGFloat>, across: ClosedRange<CGFloat>) -> CGRect {
        let first = point(along: along.lowerBound, across: across.lowerBound)
        let second = point(along: along.upperBound, across: across.upperBound)
        return CGRect(x: min(first.x, second.x), y: min(first.y, second.y),
                      width: abs(first.x - second.x), height: abs(first.y - second.y))
    }

    func frame(depth: CGFloat, length: CGFloat) -> CGSize {
        edge.isVertical ? CGSize(width: depth, height: length) : CGSize(width: length, height: depth)
    }

    var orbCenter: CGPoint { point(along: notchLength, across: Layout.curl) }

    func windowFrame(on screen: CGRect) -> CGRect {
        let size = windowSize
        let origin: CGPoint
        switch edge {
        case .right:  origin = CGPoint(x: screen.maxX - size.width, y: screen.midY + notchLength / 2 - size.height)
        case .left:   origin = CGPoint(x: screen.minX, y: screen.midY + notchLength / 2 - size.height)
        case .top:    origin = CGPoint(x: screen.midX - notchLength / 2, y: screen.maxY - size.height)
        case .bottom: origin = CGPoint(x: screen.midX - notchLength / 2, y: screen.minY)
        }
        return CGRect(origin: origin, size: size)
    }

    func cardCenter(ring index: Int, cardSize: CGSize) -> (center: CGPoint, tailOffset: CGFloat) {
        let ring = ringCenter(index)
        let length = edge.isVertical ? cardSize.height : cardSize.width
        let thickness = edge.isVertical ? cardSize.width : cardSize.height
        let limit = edge.isVertical ? windowSize.height : windowSize.width
        let mid = min(max(ring, length / 2), max(limit - length / 2, length / 2))
        let center = point(along: mid, across: depth + Layout.tailGap + thickness / 2)
        return (center, ring - (mid - length / 2))
    }
}
