import Foundation
import CoreGraphics

nonisolated enum EyePosition: String, CaseIterable, Sendable {
    case topLeading, top, topTrailing, leading, center, trailing, bottomLeading, bottom, bottomTrailing
    case random

    static var fixedPositions: [Self] { allCases.filter { $0 != .random } }

    func resolved(choosing choose: () -> Self = { Self.fixedPositions.randomElement() ?? .center }) -> Self {
        self == .random ? choose() : self
    }

    var title: String {
        switch self {
        case .topLeading: "Сверху слева"
        case .top: "Сверху"
        case .topTrailing: "Сверху справа"
        case .leading: "Слева"
        case .center: "В центре"
        case .trailing: "Справа"
        case .bottomLeading: "Снизу слева"
        case .bottom: "Снизу"
        case .bottomTrailing: "Снизу справа"
        case .random: "Случайное"
        }
    }
    var column: Int {
        switch self {
        case .topLeading, .leading, .bottomLeading: 0
        case .top, .center, .bottom, .random: 1
        case .topTrailing, .trailing, .bottomTrailing: 2
        }
    }
    var row: Int {
        switch self {
        case .topLeading, .top, .topTrailing: 0
        case .leading, .center, .trailing, .random: 1
        case .bottomLeading, .bottom, .bottomTrailing: 2
        }
    }
}

nonisolated enum EyeLayout {
    // 100% matches the former 200% eye, retaining the 64:38 vector aspect ratio.
    static let referenceSize = CGSize(width: 230.4, height: 136.8)

    static func frame(in container: CGSize, position: EyePosition, scale: Double,
                      topInset: CGFloat = 0, referenceSize: CGSize = referenceSize,
                      margin: CGFloat = 28, maximumFraction: CGFloat = 0.25) -> CGRect {
        let scale = scale.isFinite ? min(2, max(0.5, scale)) : 1
        let width = max(0, container.width)
        let height = max(0, container.height)
        let left = min(margin, width / 4)
        let top = min(max(0, topInset) + margin, height / 4)
        let area = CGRect(x: left, y: top, width: max(0, width - 2 * left),
                          height: max(0, height - top - min(margin, height / 4)))
        let factor = max(0, min(scale, min(width * maximumFraction / referenceSize.width,
                                          height * maximumFraction / referenceSize.height)))
        let size = CGSize(width: referenceSize.width * factor, height: referenceSize.height * factor)
        let x = position.column == 1 ? (width - size.width) / 2
            : area.minX + (area.width - size.width) * CGFloat(position.column) / 2
        let y = position.row == 1 ? (height - size.height) / 2
            : area.minY + (area.height - size.height) * CGFloat(position.row) / 2
        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }
}
