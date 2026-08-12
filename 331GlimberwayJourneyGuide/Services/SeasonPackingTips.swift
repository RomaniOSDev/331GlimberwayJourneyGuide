import Foundation

enum SeasonPackingTips {
    enum Season: String {
        case spring, summer, autumn, winter

        var title: String {
            switch self {
            case .spring: return "Spring"
            case .summer: return "Summer"
            case .autumn: return "Autumn"
            case .winter: return "Winter"
            }
        }
    }

    static func season(for date: Date) -> Season {
        let month = Calendar.current.component(.month, from: date)
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    static func tips(for destination: Destination) -> (season: Season, tips: [String]) {
        let date = destination.plannedDate ?? Date()
        let season = season(for: date)
        let country = destination.country.lowercased()
        var tips = baseTips(for: season)

        if ["japan", "italy", "france", "spain"].contains(where: { country.contains($0) }) {
            tips.append("City walking days: pack a light layer and comfy shoes.")
        }
        if ["mexico", "cuba", "senegal", "morocco"].contains(where: { country.contains($0) }) {
            tips.append("Warmer climate: prioritize sun protection and breathable clothes.")
        }
        if country.contains("switzerland") || country.contains("canada") {
            tips.append("Cooler evenings are common — bring a warmer mid-layer.")
        }

        return (season, Array(tips.prefix(4)))
    }

    private static func baseTips(for season: Season) -> [String] {
        switch season {
        case .spring:
            return [
                "Expect mild days and cooler evenings — pack a light jacket.",
                "A compact umbrella helps with spring showers.",
                "Layers beat bulky coats for changing temperatures."
            ]
        case .summer:
            return [
                "Prioritize breathable clothes and sun protection.",
                "Carry a refillable bottle for warm walking days.",
                "A light cover-up helps in air-conditioned spaces."
            ]
        case .autumn:
            return [
                "Pack a waterproof shell for wind and rain.",
                "Warm mid-layers are useful as evenings cool down.",
                "Closed shoes handle wet sidewalks better than sandals."
            ]
        case .winter:
            return [
                "Focus on insulating layers, gloves, and a warm coat.",
                "Lip balm and moisturizer help in dry cold air.",
                "Keep documents in an inner pocket for quick access indoors."
            ]
        }
    }
}
