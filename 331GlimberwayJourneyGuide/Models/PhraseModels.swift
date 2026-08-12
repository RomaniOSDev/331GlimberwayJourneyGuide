import Foundation

enum PhraseLanguage: String, CaseIterable, Identifiable, Codable {
    case spanish
    case french
    case japanese
    case italian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spanish: return "Spanish"
        case .french: return "French"
        case .japanese: return "Japanese"
        case .italian: return "Italian"
        }
    }

    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .japanese: return "🇯🇵"
        case .italian: return "🇮🇹"
        }
    }
}

enum PhraseCategory: String, CaseIterable, Identifiable, Codable {
    case greetings
    case transport
    case dining

    var id: String { rawValue }

    var title: String {
        switch self {
        case .greetings: return "Greetings"
        case .transport: return "Transport"
        case .dining: return "Dining"
        }
    }
}

struct PhraseEntry: Identifiable, Hashable {
    let id: String
    let language: PhraseLanguage
    let category: PhraseCategory
    let english: String
    let translation: String
    let pronunciation: String

    static func makeId(language: PhraseLanguage, category: PhraseCategory, english: String) -> String {
        "\(language.rawValue)|\(category.rawValue)|\(english.lowercased())"
    }
}

struct PracticeProgress: Codable, Equatable {
    var currentStreak: Int
    var bestStreak: Int
    var lastPracticeDayKey: String?
    var totalCorrect: Int

    init(
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        lastPracticeDayKey: String? = nil,
        totalCorrect: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.lastPracticeDayKey = lastPracticeDayKey
        self.totalCorrect = totalCorrect
    }
}

struct PhraseUserData: Codable, Equatable {
    var favoriteIds: [String]
    var notesByPhraseId: [String: String]
    var practice: PracticeProgress

    init(
        favoriteIds: [String] = [],
        notesByPhraseId: [String: String] = [:],
        practice: PracticeProgress = PracticeProgress()
    ) {
        self.favoriteIds = favoriteIds
        self.notesByPhraseId = notesByPhraseId
        self.practice = practice
    }

    private enum CodingKeys: String, CodingKey {
        case favoriteIds, notesByPhraseId, practice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favoriteIds = try container.decodeIfPresent([String].self, forKey: .favoriteIds) ?? []
        notesByPhraseId = try container.decodeIfPresent([String: String].self, forKey: .notesByPhraseId) ?? [:]
        practice = try container.decodeIfPresent(PracticeProgress.self, forKey: .practice) ?? PracticeProgress()
    }

    func isFavorite(_ phraseId: String) -> Bool {
        favoriteIds.contains(phraseId)
    }

    func note(for phraseId: String) -> String {
        notesByPhraseId[phraseId] ?? ""
    }
}
