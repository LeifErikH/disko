import SwiftUI

enum Design {
    static let scale: CGFloat = 44.0 / 117.0

    static func px(_ pixels: CGFloat) -> CGFloat { pixels * scale }

    static func fontSize(capPixels pixels: CGFloat) -> CGFloat { px(pixels) / 0.714 }
}

enum Layout {
    static let depth = Design.px(186)
    static let curl = Design.px(103)
    static let corner = Design.px(78.8)
    static let padTop = Design.px(69.5)
    static let padBottom = Design.px(50.1)
    static let cellSpacing = Design.px(83.5)

    static let ring = Design.px(117)
    static let trackStroke = Design.px(15.5)
    static let progressStroke = Design.px(8)
    static let glyph = Design.px(46)
    static let ringLabelGap = Design.px(26.9)
    static let labelHeight: CGFloat = 18

    static let pillDepth = Design.px(26)
    static let pillLength = Design.px(210)
    static let pillHotZone = Design.px(90)
    static let edgeHotZone: CGFloat = 4

    static let cardWidth = Design.px(640)
    static let cardCorner = Design.px(49.5)
    static let cardPadding = Design.px(32)
    static let tailLength = Design.px(75)
    static let tailHeight = Design.px(87)
    static let tailGap = Design.px(28)
    static let barHeight = Design.px(10.5)
    static let headerGap = Design.px(17)
    static let headerToBlock = Design.px(21)
    static let labelToBar = Design.px(16.8)
    static let barToUsed = Design.px(12)
    static let blockSpacing = Design.px(20)

    static let orbDiameter = Design.px(124)
    static let orbStroke = Design.px(18)
    static let orbGap = Design.px(27)
    static let orbGlyph = Design.px(56)
    static var orbArcRadius: CGFloat { curl - orbGap }
    static var orbMergeScale: CGFloat { (curl + orbStroke) / orbArcRadius }

    static var cell: CGFloat { ring + ringLabelGap + labelHeight }
}

enum Palette {
    static let ink = Color.white
    static let secondaryInk = Color(hex: 0x808080)
    static let ringTrack = Color.white.opacity(0.188)
    static let barTrack = Color.white.opacity(0.176)
    static let ample = Color(hex: 0x00FF88)
    static let watch = Color(hex: 0xF2FF00)
    static let critical = Color(hex: 0xFF3F00)

    static func band(for bytes: Int64, watch watchAt: Double, critical criticalAt: Double) -> Color {
        let gigabytes = Double(bytes) / 1_073_741_824
        if gigabytes >= criticalAt { return critical }
        if gigabytes >= watchAt { return watch }
        return ample
    }
}

enum Typography {
    static let size = Font.system(size: Design.fontSize(capPixels: 27), weight: .semibold)
    static let cardTitle = Font.system(size: Design.fontSize(capPixels: 26), weight: .semibold)
    static let cardBody = Font.system(size: Design.fontSize(capPixels: 18), weight: .regular)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
