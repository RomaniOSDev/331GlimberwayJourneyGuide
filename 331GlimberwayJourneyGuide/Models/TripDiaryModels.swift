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
