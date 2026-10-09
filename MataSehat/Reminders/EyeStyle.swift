import Foundation

nonisolated enum EyeStyle: String, CaseIterable, Sendable {
    case light, dark, system

    var title: String {
        switch self {
        case .light: "Светлый"
        case .dark: "Тёмный"
        case .system: "Системный"
        }
    }

    func resolved(isDarkAppearance: Bool) -> Self {
        self == .system ? (isDarkAppearance ? .light : .dark) : self
    }
}
