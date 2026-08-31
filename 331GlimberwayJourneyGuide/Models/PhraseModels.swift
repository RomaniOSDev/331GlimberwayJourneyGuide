import Foundation

enum LeaveMode: String, Codable, CaseIterable, Identifiable {
    case flight
    case road
    case rail
    case overnight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .flight: return "Flight morning"
        case .road: return "Road leave"
        case .rail: return "Rail / overnight"
        case .overnight: return "One-night bag"
        }
    }

    var symbol: String {
        switch self {
        case .flight: return "airplane.departure"
        case .road: return "car.fill"
        case .rail: return "tram.fill"
        case .overnight: return "moon.stars.fill"
        }
    }
}

enum ForecastCondition: String, Codable, CaseIterable, Identifiable {
    case unset
    case fair
    case rain
    case heat
    case freeze
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unset: return "Not set"
        case .fair: return "Fair / dry"
        case .rain: return "Rain"
        case .heat: return "Hot"
        case .freeze: return "Freeze"
        case .mixed: return "Mixed layers"
        }
    }

    var symbol: String {
        switch self {
        case .unset: return "questionmark.circle"
        case .fair: return "sun.max.fill"
        case .rain: return "cloud.rain.fill"
        case .heat: return "thermometer.sun.fill"
        case .freeze: return "snowflake"
        case .mixed: return "cloud.sun.fill"
        }
    }
}

enum TimelinePhase: String, Codable, CaseIterable, Identifiable {
    case t24h
    case t3h
    case t30m
    case airport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .t24h: return "T−24h"
        case .t3h: return "T−3h"
        case .t30m: return "T−30m"
        case .airport: return "At the gate"
        }
    }

    var minutesBefore: Int {
        switch self {
        case .t24h: return 24 * 60
        case .t3h: return 3 * 60
        case .t30m: return 30
        case .airport: return 0
        }
    }
}

enum DocumentKind: String, Codable, CaseIterable, Identifiable {
    case passport
    case ticket
    case insurance
    case visa
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .passport: return "Passport / ID"
        case .ticket: return "Ticket / boarding"
        case .insurance: return "Insurance"
        case .visa: return "Visa / entry"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .passport: return "person.text.rectangle"
        case .ticket: return "qrcode"
        case .insurance: return "cross.case.fill"
        case .visa: return "globe"
        case .other: return "doc.fill"
        }
    }
}

struct TimelineTask: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var minutesBeforeDeparture: Int
    var phase: TimelinePhase
    var isDone: Bool
    var notify: Bool
    var airportRelevant: Bool

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        minutesBeforeDeparture: Int,
        phase: TimelinePhase,
        isDone: Bool = false,
        notify: Bool = true,
        airportRelevant: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.minutesBeforeDeparture = minutesBeforeDeparture
        self.phase = phase
        self.isDone = isDone
        self.notify = notify
        self.airportRelevant = airportRelevant
    }

    func fireDate(from departure: Date) -> Date {
        departure.addingTimeInterval(-TimeInterval(minutesBeforeDeparture * 60))
    }
}

struct HomeLeaveItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct TravelDocument: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var kind: DocumentKind
    var title: String
    var expiresOn: Date?
    var photoFileName: String?

    init(
        id: UUID = UUID(),
        destinationId: UUID,
        kind: DocumentKind,
        title: String,
        expiresOn: Date? = nil,
        photoFileName: String? = nil
    ) {
        self.id = id
        self.destinationId = destinationId
        self.kind = kind
        self.title = title
        self.expiresOn = expiresOn
        self.photoFileName = photoFileName
    }

    var isExpired: Bool {
        guard let expiresOn else { return false }
        return Calendar.current.startOfDay(for: expiresOn) < Calendar.current.startOfDay(for: Date())
    }

    var expiresSoon: Bool {
        guard let expiresOn, !isExpired else { return false }
        let limit = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
        return expiresOn <= limit
    }
}
