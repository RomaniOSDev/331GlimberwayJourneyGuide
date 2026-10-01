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
        "Passport / ID in the leave pouch",
        "Tickets saved offline",
        "Phone at 100% + cable",
        "Keys and wallet on the hook",
        "Medications in the carry pouch"
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
    var leaveMode: LeaveMode
    var forecast: ForecastCondition
    var bagLimitKg: Double
    var airportMode: Bool
    var timelineTasks: [TimelineTask]
    var homeItems: [HomeLeaveItem]
    var documents: [TravelDocument]
    var appliedSealId: UUID?

    init(
        id: UUID = UUID(),
        country: String,
        city: String,
        notes: String = "",
        plannedDate: Date? = nil,
        isVisited: Bool = false,
        checklistItems: [DepartureChecklistItem] = DepartureChecklist.makeDefaultItems(),
        reminderEnabled: Bool = false,
        reminderDaysBefore: Int = 3,
        leaveMode: LeaveMode = .flight,
        forecast: ForecastCondition = .unset,
        bagLimitKg: Double = 7,
        airportMode: Bool = false,
        timelineTasks: [TimelineTask] = [],
        homeItems: [HomeLeaveItem] = [],
        documents: [TravelDocument] = [],
        appliedSealId: UUID? = nil
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
        self.leaveMode = leaveMode
        self.forecast = forecast
        self.bagLimitKg = bagLimitKg
        self.airportMode = airportMode
        self.timelineTasks = timelineTasks.isEmpty ? TimelineCatalog.makeTasks(for: leaveMode) : timelineTasks
        self.homeItems = homeItems.isEmpty ? HomeLeaveCatalog.makeItems() : homeItems
        self.documents = documents
        self.appliedSealId = appliedSealId
    }

    private enum CodingKeys: String, CodingKey {
        case id, country, city, notes, plannedDate, isVisited
        case checklistItems, reminderEnabled, reminderDaysBefore
        case leaveMode, forecast, bagLimitKg, airportMode
        case timelineTasks, homeItems, documents, appliedSealId
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
        leaveMode = try container.decodeIfPresent(LeaveMode.self, forKey: .leaveMode) ?? .flight
        forecast = try container.decodeIfPresent(ForecastCondition.self, forKey: .forecast) ?? .unset
        bagLimitKg = try container.decodeIfPresent(Double.self, forKey: .bagLimitKg) ?? 7
        airportMode = try container.decodeIfPresent(Bool.self, forKey: .airportMode) ?? false
        let decodedTasks = try container.decodeIfPresent([TimelineTask].self, forKey: .timelineTasks) ?? []
        timelineTasks = decodedTasks.isEmpty ? TimelineCatalog.makeTasks(for: leaveMode) : decodedTasks
        let decodedHome = try container.decodeIfPresent([HomeLeaveItem].self, forKey: .homeItems) ?? []
        homeItems = decodedHome.isEmpty ? HomeLeaveCatalog.makeItems() : decodedHome
        documents = try container.decodeIfPresent([TravelDocument].self, forKey: .documents) ?? []
        appliedSealId = try container.decodeIfPresent(UUID.self, forKey: .appliedSealId)
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

    var minutesUntilDeparture: Int? {
        guard let plannedDate, !isVisited else { return nil }
        return Int(plannedDate.timeIntervalSinceNow / 60)
    }

    var checklistDoneCount: Int {
        checklistItems.filter(\.isDone).count
    }

    var timelineDoneCount: Int {
        timelineTasks.filter(\.isDone).count
    }

    var homeDoneCount: Int {
        homeItems.filter(\.isDone).count
    }

    var visibleTimelineTasks: [TimelineTask] {
        let list = airportMode
            ? timelineTasks.filter(\.airportRelevant)
            : timelineTasks
        return list.sorted { $0.minutesBeforeDeparture > $1.minutesBeforeDeparture }
    }

    var expiredDocumentCount: Int {
        documents.filter(\.isExpired).count
    }

    var readinessPercent: Int {
        let buckets: [Double] = [
            checklistItems.isEmpty ? 1 : Double(checklistDoneCount) / Double(checklistItems.count),
            timelineTasks.isEmpty ? 1 : Double(timelineDoneCount) / Double(timelineTasks.count),
            homeItems.isEmpty ? 1 : Double(homeDoneCount) / Double(homeItems.count),
            documents.isEmpty ? 0.35 : (expiredDocumentCount == 0 ? 1 : 0.4)
        ]
        return Int((buckets.reduce(0, +) / Double(buckets.count) * 100).rounded())
    }
}

enum DestinationFilter: String, CaseIterable, Identifiable {
    case all
    case leaving
    case today
    case later
    case departed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .leaving: return "Leaving soon"
        case .today: return "Leave today"
        case .later: return "Later"
        case .departed: return "Already left"
        }
    }
}
