import Foundation

struct DiaryEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var day: Date
    var text: String
    var photoFileName: String?

    init(
        id: UUID = UUID(),
        destinationId: UUID,
        day: Date = Date(),
        text: String = "",
        photoFileName: String? = nil
    ) {
        self.id = id
        self.destinationId = destinationId
        self.day = Calendar.current.startOfDay(for: day)
        self.text = text
        self.photoFileName = photoFileName
    }

    var dayLabel: String {
        day.formatted(date: .abbreviated, time: .omitted)
    }
}

enum GoBackKind: String, Codable, CaseIterable, Identifiable {
    case forgotPouch
    case houseSkip
    case overweight
    case rideLate
    case docExpired
    case secondTrip
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forgotPouch: return "Forgot pouch"
        case .houseSkip: return "Skipped house loop"
        case .overweight: return "Bag over limit"
        case .rideLate: return "Ride ran late"
        case .docExpired: return "Document issue"
        case .secondTrip: return "Second trip upstairs"
        case .other: return "Other miss"
        }
    }

    var symbol: String {
        switch self {
        case .forgotPouch: return "envelope.fill"
        case .houseSkip: return "house.fill"
        case .overweight: return "scalemass.fill"
        case .rideLate: return "car.fill"
        case .docExpired: return "person.text.rectangle"
        case .secondTrip: return "arrow.uturn.up"
        case .other: return "questionmark.circle"
        }
    }
}

struct DoorSeal: Identifiable, Codable, Equatable {
    var id: UUID
    var destinationId: UUID
    var title: String
    var sealedAt: Date
    var residue: [String]
    var houseDone: Int
    var houseTotal: Int
    var bagKg: Double
    var bagLimitKg: Double
    var goBackKind: GoBackKind?
    var note: String

    init(
        id: UUID = UUID(),
        destinationId: UUID,
        title: String,
        sealedAt: Date = Date(),
        residue: [String] = [],
        houseDone: Int,
        houseTotal: Int,
        bagKg: Double,
        bagLimitKg: Double,
        goBackKind: GoBackKind? = nil,
        note: String = ""
    ) {
        self.id = id
        self.destinationId = destinationId
        self.title = title
        self.sealedAt = sealedAt
        self.residue = residue
        self.houseDone = houseDone
        self.houseTotal = houseTotal
        self.bagKg = bagKg
        self.bagLimitKg = bagLimitKg
        self.goBackKind = goBackKind
        self.note = note
    }

    var hourOfDay: Int {
        Calendar.current.component(.hour, from: sealedAt)
    }
}

struct RadarInsight: Equatable {
    var topMiss: GoBackKind?
    var quietHour: Int?
    var peakHour: Int?
    var sealCount: Int
    var goBackCount: Int
}
