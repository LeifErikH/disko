import SwiftUI

struct NotchShape: Shape {
    var edge: NotchEdge = .right
    var curl: CGFloat = Layout.curl
    var corner: CGFloat = Layout.corner

    func path(in rect: CGRect) -> Path {
        let depth = edge.isVertical ? rect.width : rect.height
        let length = edge.isVertical ? rect.height : rect.width
        return canonicalPath(in: CGRect(x: 0, y: 0, width: depth, height: length))
            .applying(transform(depth: depth))
            .applying(CGAffineTransform(translationX: rect.minX, y: rect.minY))
    }

    private func transform(depth: CGFloat) -> CGAffineTransform {
        switch edge {
        case .right:  .identity
        case .left:   CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: depth, ty: 0)
        case .top:    CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: depth)
        case .bottom: CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: 0, ty: 0)
        }
    }

    private func canonicalPath(in rect: CGRect) -> Path {
        let wanted = max(0, min(corner, rect.width / 2))
        let curl = max(0, min(curl, rect.height / 2, rect.width - wanted))
        let corner = max(0, min(wanted, (rect.height - 2 * curl) / 2))
        let bodyTop = rect.minY + curl
        let bodyBottom = rect.maxY - curl

        var path = Path()
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - curl, y: rect.minY), radius: curl,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + corner, y: bodyTop))
        path.addArc(center: CGPoint(x: rect.minX + corner, y: bodyTop + corner), radius: corner,
                    startAngle: .degrees(270), endAngle: .degrees(180), clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX, y: bodyBottom - corner))
        path.addArc(center: CGPoint(x: rect.minX + corner, y: bodyBottom - corner), radius: corner,
                    startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX - curl, y: bodyBottom))
        path.addArc(center: CGPoint(x: rect.maxX - curl, y: rect.maxY), radius: curl,
                    startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct CardShape: Shape {
    var side: Edge
    var tailOffset: CGFloat
    var corner: CGFloat = Layout.cardCorner

    func path(in rect: CGRect) -> Path {
        let vertical = side == .leading || side == .trailing
        let length = vertical ? rect.height : rect.width
        let body = rect.inset(side: side, by: Layout.tailLength)
        let halfTail = Layout.tailHeight / 2
        let margin = corner + halfTail * 0.4
        let offset = min(max(tailOffset, margin), length - margin)

        return Path(roundedRect: body, cornerRadius: corner, style: .continuous)
            .union(tail(at: offset, half: halfTail).applying(placement(in: rect)))
    }

    private func tail(at offset: CGFloat, half: CGFloat) -> Path {
        let reach = Layout.tailLength
        var tail = Path()
        tail.move(to: CGPoint(x: offset - half, y: 1))
        tail.addQuadCurve(to: CGPoint(x: offset, y: -reach), control: CGPoint(x: offset - half * 0.15, y: -reach * 0.25))
        tail.addQuadCurve(to: CGPoint(x: offset + half, y: 1), control: CGPoint(x: offset + half * 0.15, y: -reach * 0.25))
        tail.closeSubpath()
        return tail
    }

    private func placement(in rect: CGRect) -> CGAffineTransform {
        let reach = Layout.tailLength
        switch side {
        case .top:      return CGAffineTransform(translationX: rect.minX, y: rect.minY + reach)
        case .bottom:   return CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: rect.minX, ty: rect.maxY - reach)
        case .leading:  return CGAffineTransform(a: 0, b: 1, c: 1, d: 0, tx: rect.minX + reach, ty: rect.minY)
        case .trailing: return CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: rect.maxX - reach, ty: rect.minY)
        }
    }
}

extension CGRect {
    func inset(side: Edge, by amount: CGFloat) -> CGRect {
        switch side {
        case .top:      CGRect(x: minX, y: minY + amount, width: width, height: height - amount)
        case .bottom:   CGRect(x: minX, y: minY, width: width, height: height - amount)
        case .leading:  CGRect(x: minX + amount, y: minY, width: width - amount, height: height)
        case .trailing: CGRect(x: minX, y: minY, width: width - amount, height: height)
        }
    }
}

struct GlyphShape: Shape {
    let outline: [[CGPoint]]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for loop in outline {
            guard let first = loop.first else { continue }
            path.move(to: point(first, in: rect))
            for next in loop.dropFirst() { path.addLine(to: point(next, in: rect)) }
            path.closeSubpath()
        }
        return path
    }

    private func point(_ p: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
    }
}

struct GlyphView: View {
    let agent: Agent
    var size: CGFloat = Layout.glyph

    var body: some View {
        GlyphShape(outline: agent.outline)
            .fill(style: FillStyle(eoFill: true))
            .scaleEffect(agent.opticalScale)
            .frame(width: size, height: size)
    }
}
