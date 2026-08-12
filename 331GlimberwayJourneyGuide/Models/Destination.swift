import Foundation

struct DepartureChecklistItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

enum DepartureChecklist {
    static let defaultTitles = [
        "Passport / ID ready",
        "Tickets confirmed",
        "Phone charged",
        "Keys and wallet",
        "Medications packed"
    ]

    static func makeDefaultItems() -> [DepartureChecklistItem] {
        defaultTitles.map { DepartureChecklistItem(title: $0) }
    }
}

struct Destination: Identifiable, Codable, Equatable {
    var id: UUID
    var country: String
    var city: String
    var notes: String
    var plannedDate: Date?
    var isVisited: Bool
    var checklistItems: [DepartureChecklistItem]
    var reminderEnabled: Bool
    var reminderDaysBefore: Int

    init(
        id: UUID = UUID(),
        country: String,
        city: String,
        notes: String = "",
        plannedDate: Date? = nil,
        isVisited: Bool = false,
        checklistItems: [DepartureChecklistItem] = DepartureChecklist.makeDefaultItems(),
        reminderEnabled: Bool = false,
        reminderDaysBefore: Int = 3
    ) {
        self.id = id
        self.country = country
        self.city = city
        self.notes = notes
        self.plannedDate = plannedDate
        self.isVisited = isVisited
        self.checklistItems = checklistItems
        self.reminderEnabled = reminderEnabled
        self.reminderDaysBefore = reminderDaysBefore
    }

    private enum CodingKeys: String, CodingKey {
        case id, country, city, notes, plannedDate, isVisited
        case checklistItems, reminderEnabled, reminderDaysBefore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        country = try container.decode(String.self, forKey: .country)
        city = try container.decode(String.self, forKey: .city)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        plannedDate = try container.decodeIfPresent(Date.self, forKey: .plannedDate)
        isVisited = try container.decodeIfPresent(Bool.self, forKey: .isVisited) ?? false
        checklistItems = try container.decodeIfPresent([DepartureChecklistItem].self, forKey: .checklistItems)
            ?? DepartureChecklist.makeDefaultItems()
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderDaysBefore = try container.decodeIfPresent(Int.self, forKey: .reminderDaysBefore) ?? 3
    }

    var displayTitle: String {
        let c = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines)
        if c.isEmpty { return co }
        if co.isEmpty { return c }
        return "\(c), \(co)"
    }

    var duplicateKey: String {
        let c = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(co)|\(c)"
    }

    var daysUntilTrip: Int? {
        guard let plannedDate, !isVisited else { return nil }
        let start = Calendar.current.startOfDay(for: Date())
        let trip = Calendar.current.startOfDay(for: plannedDate)
        return Calendar.current.dateComponents([.day], from: start, to: trip).day
    }

    var checklistDoneCount: Int {
        checklistItems.filter(\.isDone).count
    }
}

enum DestinationFilter: String, CaseIterable, Identifiable {
    case all
    case planned
    case visited
    case thisYear
    case noDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .planned: return "Planned"
        case .visited: return "Visited"
        case .thisYear: return "This year"
        case .noDate: return "No date"
        }
    }
}
