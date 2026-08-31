import Foundation

enum PackingCategory: String, Codable, CaseIterable, Identifiable {
    case clothing
    case toiletries
    case docs
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clothing: return "Wear / cloth"
        case .toiletries: return "Toiletry bag"
        case .docs: return "Pouch"
        case .other: return "Carry"
        }
    }

    var symbol: String {
        switch self {
        case .clothing: return "tshirt.fill"
        case .toiletries: return "drop.fill"
        case .docs: return "envelope.fill"
        case .other: return "bag.fill"
        }
    }
}

enum BagPlacement: String, Codable, CaseIterable, Identifiable {
    case packed
    case wear
    case toiletry

    var id: String { rawValue }

    var title: String {
        switch self {
        case .packed: return "In bag"
        case .wear: return "On body"
        case .toiletry: return "Toiletry"
        }
    }
}

struct PackingItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var category: PackingCategory
    var isPacked: Bool
    var placement: BagPlacement
    var weightGrams: Int

    init(
        id: UUID = UUID(),
        title: String,
        category: PackingCategory,
        isPacked: Bool = false,
        placement: BagPlacement? = nil,
        weightGrams: Int = 0
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.isPacked = isPacked
        self.placement = placement ?? BagPlacement.default(for: category)
        self.weightGrams = weightGrams
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, category, isPacked, placement, weightGrams
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(PackingCategory.self, forKey: .category)
        isPacked = try container.decodeIfPresent(Bool.self, forKey: .isPacked) ?? false
        placement = try container.decodeIfPresent(BagPlacement.self, forKey: .placement)
            ?? BagPlacement.default(for: category)
        weightGrams = try container.decodeIfPresent(Int.self, forKey: .weightGrams) ?? 0
    }

    var countsTowardBag: Bool {
        placement != .wear
    }
}

private extension BagPlacement {
    static func `default`(for category: PackingCategory) -> BagPlacement {
        switch category {
        case .toiletries: return .toiletry
        case .clothing: return .packed
        case .docs, .other: return .packed
        }
    }
}

struct PackingTrip: Identifiable, Codable, Equatable {
    var id: UUID
    var tripName: String
    var destinationId: UUID?
    var items: [PackingItem]
    var weightLimitKg: Double

    init(
        id: UUID = UUID(),
        tripName: String,
        destinationId: UUID? = nil,
        items: [PackingItem] = [],
        weightLimitKg: Double = 7
    ) {
        self.id = id
        self.tripName = tripName
        self.destinationId = destinationId
        self.items = items
        self.weightLimitKg = weightLimitKg
    }

    private enum CodingKeys: String, CodingKey {
        case id, tripName, destinationId, items, weightLimitKg
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tripName = try container.decode(String.self, forKey: .tripName)
        destinationId = try container.decodeIfPresent(UUID.self, forKey: .destinationId)
        items = try container.decodeIfPresent([PackingItem].self, forKey: .items) ?? []
        weightLimitKg = try container.decodeIfPresent(Double.self, forKey: .weightLimitKg) ?? 7
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var totalCount: Int { items.count }

    var bagWeightKg: Double {
        let grams = items
            .filter { $0.isPacked && $0.countsTowardBag }
            .reduce(0) { $0 + $1.weightGrams }
        return Double(grams) / 1000
    }

    var wornWeightKg: Double {
        let grams = items
            .filter { $0.isPacked && $0.placement == .wear }
            .reduce(0) { $0 + $1.weightGrams }
        return Double(grams) / 1000
    }

    var isOverLimit: Bool {
        bagWeightKg > weightLimitKg + 0.01
    }
}
