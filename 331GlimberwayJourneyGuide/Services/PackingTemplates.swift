import Foundation

enum PackingTemplate: String, CaseIterable, Identifiable {
    case beach
    case city
    case winter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beach: return "Beach"
        case .city: return "City"
        case .winter: return "Winter"
        }
    }

    var symbol: String {
        switch self {
        case .beach: return "sun.max.fill"
        case .city: return "building.2.fill"
        case .winter: return "snowflake"
        }
    }

    var items: [(title: String, category: PackingCategory)] {
        switch self {
        case .beach:
            return [
                ("Swimsuit", .clothing),
                ("Sandals", .clothing),
                ("Light shirt", .clothing),
                ("Sunscreen", .toiletries),
                ("After-sun lotion", .toiletries),
                ("Passport", .docs),
                ("Travel adapter", .other),
                ("Reusable water bottle", .other)
            ]
        case .city:
            return [
                ("Comfortable walking shoes", .clothing),
                ("Day outfit", .clothing),
                ("Light jacket", .clothing),
                ("Toothbrush", .toiletries),
                ("Face wash", .toiletries),
                ("ID / passport", .docs),
                ("Transit cards note", .docs),
                ("Power bank", .other),
                ("Umbrella", .other)
            ]
        case .winter:
            return [
                ("Warm coat", .clothing),
                ("Thermal layer", .clothing),
                ("Gloves and scarf", .clothing),
                ("Lip balm", .toiletries),
                ("Moisturizer", .toiletries),
                ("Passport", .docs),
                ("Insurance details", .docs),
                ("Hand warmers", .other)
            ]
        }
    }
}
