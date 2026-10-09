import Foundation

nonisolated enum EyeVariant: String, CaseIterable, Sendable {
    case standard, sauron, cipher, sharingan, hal, mike, sheikah, horus, dragon
    case hypnotoad, cacodemon, rinnegan, cheshire

    static let easterEggs: [Self] = [.sauron, .cipher, .sharingan, .hal, .mike, .sheikah, .horus,
                                   .dragon, .hypnotoad, .cacodemon, .rinnegan, .cheshire]
    static let cadence = 10

    var title: String {
        switch self {
        case .standard: "Глаз"
        case .sauron: "Око Саурона"
        case .cipher: "Билл Шифр"
        case .sharingan: "Шаринган"
        case .hal: "HAL 9000"
        case .mike: "Майк Вазовски"
        case .sheikah: "Глаз Шиика"
        case .horus: "Око Гора"
        case .dragon: "Дракон"
        case .hypnotoad: "Гипножаба"
        case .cacodemon: "Какодемон"
        case .rinnegan: "Риннеган"
        case .cheshire: "Глаз Чеширского Кота"
        }
    }
}
