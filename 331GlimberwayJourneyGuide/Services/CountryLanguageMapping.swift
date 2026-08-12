import Foundation

enum CountryLanguageMapping {
    private static let spanishCountries: Set<String> = [
        "spain", "mexico", "argentina", "colombia", "chile", "peru", "ecuador", "cuba"
    ]
    private static let frenchCountries: Set<String> = [
        "france", "belgium", "switzerland", "canada", "monaco", "senegal", "morocco"
    ]
    private static let japaneseCountries: Set<String> = ["japan"]
    private static let italianCountries: Set<String> = ["italy", "vatican", "san marino"]

    static func suggestedLanguages(for destinations: [Destination]) -> [PhraseLanguage] {
        var ordered: [PhraseLanguage] = []
        var seen = Set<PhraseLanguage>()
        for destination in destinations {
            guard let lang = language(forCountry: destination.country), !seen.contains(lang) else { continue }
            seen.insert(lang)
            ordered.append(lang)
        }
        return ordered
    }

    static func language(forCountry country: String) -> PhraseLanguage? {
        let key = country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        if spanishCountries.contains(key) { return .spanish }
        if frenchCountries.contains(key) { return .french }
        if japaneseCountries.contains(key) { return .japanese }
        if italianCountries.contains(key) { return .italian }
        return nil
    }
}
