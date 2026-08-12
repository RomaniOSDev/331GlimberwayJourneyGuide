import Foundation

enum PackingCategory: String, Codable, CaseIterable, Identifiable {
    case clothing
    case toiletries
    case docs
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clothing: return "Clothing"
        case .toiletries: return "Toiletries"
        case .docs: return "Documents"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .clothing: return "tshirt.fill"
        case .toiletries: return "drop.fill"
        case .docs: return "doc.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}

struct PackingItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var category: PackingCategory
    var isPacked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        category: PackingCategory,
        isPacked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.isPacked = isPacked
    }
}

struct PackingTrip: Identifiable, Codable, Equatable {
    var id: UUID
    var tripName: String
    var destinationId: UUID?
    var items: [PackingItem]

    init(
        id: UUID = UUID(),
        tripName: String,
        destinationId: UUID? = nil,
        items: [PackingItem] = []
    ) {
        self.id = id
        self.tripName = tripName
        self.destinationId = destinationId
        self.items = items
    }

    var packedCount: Int { items.filter(\.isPacked).count }
    var totalCount: Int { items.count }
}
