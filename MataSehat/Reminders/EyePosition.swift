import Foundation
import CoreGraphics

nonisolated enum EyePosition: String, CaseIterable, Sendable {
    case topLeading, top, topTrailing, leading, center, trailing, bottomLeading, bottom, bottomTrailing

    var title: LocalizedStringResource {
        switch self {
        case .topLeading: "Top left"
        case .top: "Top"
        case .topTrailing: "Top right"
        case .leading: "Left"
        case .center: "Centre"
        case .trailing: "Right"
        case .bottomLeading: "Bottom left"
        case .bottom: "Bottom"
        case .bottomTrailing: "Bottom right"
        }
    }
    var column: Int {
        switch self {
        case .topLeading, .leading, .bottomLeading: 0
        case .top, .center, .bottom: 1
        case .topTrailing, .trailing, .bottomTrailing: 2
        }
    }
    var row: Int {
        switch self {
        case .topLeading, .top, .topTrailing: 0
        case .leading, .center, .trailing: 1
        case .bottomLeading, .bottom, .bottomTrailing: 2
        }
    }
}

nonisolated enum EyeLayout {
    // The former center eye was 64×38 points at scale 1.8.
    static let referenceSize = CGSize(width: 115.2, height: 68.4)

    static func frame(in container: CGSize, position: EyePosition, scale: Double,
                      topInset: CGFloat = 0, referenceSize: CGSize = referenceSize,
                      margin: CGFloat = 28) -> CGRect {
        let scale = scale.isFinite ? min(2, max(0.5, scale)) : 1
        let width = max(0, container.width)
        let height = max(0, container.height)
        let left = min(margin, width / 4)
        let top = min(max(0, topInset) + margin, height / 4)
        let area = CGRect(x: left, y: top, width: max(0, width - 2 * left),
                          height: max(0, height - top - min(margin, height / 4)))
        let factor = max(0, min(scale, min(width * 0.25 / referenceSize.width,
                                          height * 0.25 / referenceSize.height)))
        let size = CGSize(width: referenceSize.width * factor, height: referenceSize.height * factor)
        let x = position.column == 1 ? (width - size.width) / 2
            : area.minX + (area.width - size.width) * CGFloat(position.column) / 2
        let y = position.row == 1 ? (height - size.height) / 2
            : area.minY + (area.height - size.height) * CGFloat(position.row) / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
