import Foundation
import Combine

enum AppNavigationTarget: Equatable {
    case packing
    case phrases(PhraseLanguage?)
}

final class AppDataStore: ObservableObject {
    @Published private(set) var destinations: [Destination] = []
    @Published private(set) var packingTrips: [PackingTrip] = []
    @Published private(set) var phraseUserData = PhraseUserData()
    @Published private(set) var diaryEntries: [DiaryEntry] = []
    @Published var hasCompletedOnboarding: Bool
    @Published var navigationTarget: AppNavigationTarget?
    @Published var focusPackingTripId: UUID?

    private let destinationsKey = "glimberway.destinations.v1"
    private let packingKey = "glimberway.packing.v1"
    private let phrasesKey = "glimberway.phrases.v1"
    private let diaryKey = "glimberway.diary.v1"
    private let onboardingKey = "glimberway.onboarding.v1"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        load()
        TripReminderService.rescheduleAll(for: destinations)
    }

    var hasFirstTripBadge: Bool {
        !destinations.isEmpty
    }

    var suggestedPhraseLanguages: [PhraseLanguage] {
        CountryLanguageMapping.suggestedLanguages(for: destinations)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func resetOnboardingFlag() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: onboardingKey)
    }

    func filteredDestinations(query: String, filter: DestinationFilter = .all) -> [Destination] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let year = Calendar.current.component(.year, from: Date())
        let sorted = destinations.sorted { lhs, rhs in
            let lDate = lhs.plannedDate ?? .distantFuture
            let rDate = rhs.plannedDate ?? .distantFuture
            if lDate != rDate { return lDate < rDate }
            return lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
        }
        return sorted.filter { destination in
            switch filter {
            case .all: break
            case .planned:
                guard !destination.isVisited else { return false }
            case .visited:
                guard destination.isVisited else { return false }
            case .thisYear:
                guard let date = destination.plannedDate,
                      Calendar.current.component(.year, from: date) == year else { return false }
            case .noDate:
                guard destination.plannedDate == nil else { return false }
            }
            guard !q.isEmpty else { return true }
            return destination.country.lowercased().contains(q)
                || destination.city.lowercased().contains(q)
                || destination.notes.lowercased().contains(q)
        }
    }

    func destination(for id: UUID) -> Destination? {
        destinations.first { $0.id == id }
    }

    func packingTrip(for id: UUID) -> PackingTrip? {
        packingTrips.first { $0.id == id }
    }

    func packingTrip(forDestinationId id: UUID) -> PackingTrip? {
        packingTrips.first { $0.destinationId == id }
    }

    func isDuplicateDestination(country: String, city: String, excludingId: UUID? = nil) -> Bool {
        let key = Destination(country: country, city: city).duplicateKey
        return destinations.contains { dest in
            if let excludingId, dest.id == excludingId { return false }
            return dest.duplicateKey == key
        }
    }

    @discardableResult
    func addDestination(
        country: String,
        city: String,
        notes: String,
        plannedDate: Date?,
        isVisited: Bool,
        createPackingList: Bool
    ) -> Destination? {
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let ci = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !co.isEmpty, !ci.isEmpty else { return nil }
        guard !isDuplicateDestination(country: co, city: ci) else { return nil }

        let destination = Destination(
            country: co,
            city: ci,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            plannedDate: plannedDate,
            isVisited: isVisited
        )
        destinations.append(destination)
        if createPackingList {
            _ = addPackingTrip(tripName: destination.displayTitle, destinationId: destination.id)
        }
        persist()
        TripReminderService.syncReminder(for: destination)
        return destination
    }

    @discardableResult
    func updateDestination(
        _ destination: Destination,
        country: String,
        city: String,
        notes: String,
        plannedDate: Date?,
        isVisited: Bool
    ) -> Bool {
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let ci = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !co.isEmpty, !ci.isEmpty else { return false }
        guard !isDuplicateDestination(country: co, city: ci, excludingId: destination.id) else { return false }
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else { return false }

        var updated = destination
        updated.country = co
        updated.city = ci
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.plannedDate = plannedDate
        updated.isVisited = isVisited
        destinations[index] = updated
        persist()
        TripReminderService.syncReminder(for: updated)
        return true
    }

    func markDestinationVisited(_ destination: Destination, visited: Bool = true) {
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else { return }
        destinations[index].isVisited = visited
        persist()
        TripReminderService.syncReminder(for: destinations[index])
    }

    func toggleChecklistItem(destinationId: UUID, itemId: UUID) {
        guard let destIndex = destinations.firstIndex(where: { $0.id == destinationId }),
              let itemIndex = destinations[destIndex].checklistItems.firstIndex(where: { $0.id == itemId }) else { return }
        destinations[destIndex].checklistItems[itemIndex].isDone.toggle()
        persist()
    }

    func setReminder(destinationId: UUID, enabled: Bool, daysBefore: Int) {
        guard let index = destinations.firstIndex(where: { $0.id == destinationId }) else { return }
        destinations[index].reminderEnabled = enabled
        destinations[index].reminderDaysBefore = max(1, min(daysBefore, 30))
        persist()
        if enabled {
            TripReminderService.requestAuthorizationIfNeeded()
        }
        TripReminderService.syncReminder(for: destinations[index])
    }

    func deleteDestination(_ destination: Destination) {
        destinations.removeAll { $0.id == destination.id }
        packingTrips.removeAll { $0.destinationId == destination.id }
        let orphanPhotos = diaryEntries.filter { $0.destinationId == destination.id }.compactMap(\.photoFileName)
        diaryEntries.removeAll { $0.destinationId == destination.id }
        orphanPhotos.forEach { DiaryPhotoStore.delete(fileName: $0) }
        TripReminderService.removeReminder(for: destination.id)
        persist()
    }

    @discardableResult
    func addPackingTrip(
        tripName: String,
        destinationId: UUID? = nil,
        template: PackingTemplate? = nil
    ) -> PackingTrip? {
        let name = tripName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        var trip = PackingTrip(tripName: name, destinationId: destinationId)
        if let template {
            trip.items = template.items.map { PackingItem(title: $0.title, category: $0.category) }
        }
        packingTrips.append(trip)
        persist()
        return trip
    }

    @discardableResult
    func updatePackingTripName(_ trip: PackingTrip, tripName: String) -> Bool {
        let name = tripName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        guard let index = packingTrips.firstIndex(where: { $0.id == trip.id }) else { return false }
        packingTrips[index].tripName = name
        persist()
        return true
    }

    func deletePackingTrip(_ trip: PackingTrip) {
        packingTrips.removeAll { $0.id == trip.id }
        persist()
    }

    @discardableResult
    func addPackingItem(to trip: PackingTrip, title: String, category: PackingCategory) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let index = packingTrips.firstIndex(where: { $0.id == trip.id }) else { return false }
        packingTrips[index].items.append(PackingItem(title: trimmed, category: category))
        persist()
        return true
    }

    func applyTemplate(_ template: PackingTemplate, to tripId: UUID) {
        guard let index = packingTrips.firstIndex(where: { $0.id == tripId }) else { return }
        let existingTitles = Set(packingTrips[index].items.map { $0.title.lowercased() })
        for item in template.items where !existingTitles.contains(item.title.lowercased()) {
            packingTrips[index].items.append(PackingItem(title: item.title, category: item.category))
        }
        persist()
    }

    @discardableResult
    func copyPackingItems(from sourceId: UUID, to targetId: UUID) -> Bool {
        guard sourceId != targetId,
              let source = packingTrips.first(where: { $0.id == sourceId }),
              let targetIndex = packingTrips.firstIndex(where: { $0.id == targetId }) else { return false }
        let existingTitles = Set(packingTrips[targetIndex].items.map { $0.title.lowercased() })
        for item in source.items where !existingTitles.contains(item.title.lowercased()) {
            packingTrips[targetIndex].items.append(
                PackingItem(title: item.title, category: item.category, isPacked: false)
            )
        }
        persist()
        return true
    }

    func ensurePackingTrip(for destination: Destination) -> PackingTrip {
        if let existing = packingTrip(forDestinationId: destination.id) {
            return existing
        }
        return addPackingTrip(tripName: destination.displayTitle, destinationId: destination.id)
            ?? PackingTrip(tripName: destination.displayTitle, destinationId: destination.id)
    }

    func togglePackingItem(tripId: UUID, itemId: UUID) {
        guard let tripIndex = packingTrips.firstIndex(where: { $0.id == tripId }),
              let itemIndex = packingTrips[tripIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        packingTrips[tripIndex].items[itemIndex].isPacked.toggle()
        persist()
    }

    func deletePackingItem(tripId: UUID, itemId: UUID) {
        guard let tripIndex = packingTrips.firstIndex(where: { $0.id == tripId }) else { return }
        packingTrips[tripIndex].items.removeAll { $0.id == itemId }
        persist()
    }

    func toggleFavorite(phraseId: String) {
        if phraseUserData.favoriteIds.contains(phraseId) {
            phraseUserData.favoriteIds.removeAll { $0 == phraseId }
        } else {
            phraseUserData.favoriteIds.append(phraseId)
        }
        persistPhrases()
    }

    func setPhraseNote(phraseId: String, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            phraseUserData.notesByPhraseId.removeValue(forKey: phraseId)
        } else {
            phraseUserData.notesByPhraseId[phraseId] = trimmed
        }
        persistPhrases()
    }

    func recordPracticeSession(correctAnswers: Int) {
        guard correctAnswers > 0 else { return }
        let today = Self.dayKey(for: Date())
        var practice = phraseUserData.practice
        if practice.lastPracticeDayKey == today {
            // already practiced today — keep streak, add score
        } else if let last = practice.lastPracticeDayKey,
                  let lastDate = Self.date(fromDayKey: last),
                  let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())),
                  Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
            practice.currentStreak += 1
        } else {
            practice.currentStreak = 1
        }
        practice.bestStreak = max(practice.bestStreak, practice.currentStreak)
        practice.lastPracticeDayKey = today
        practice.totalCorrect += correctAnswers
        phraseUserData.practice = practice
        persistPhrases()
    }

    func diaryEntries(for destinationId: UUID) -> [DiaryEntry] {
        diaryEntries
            .filter { $0.destinationId == destinationId }
            .sorted { $0.day > $1.day }
    }

    @discardableResult
    func addDiaryEntry(destinationId: UUID, text: String, day: Date, photoFileName: String?) -> DiaryEntry? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || photoFileName != nil else { return nil }
        let entry = DiaryEntry(
            destinationId: destinationId,
            day: day,
            text: trimmed,
            photoFileName: photoFileName
        )
        diaryEntries.append(entry)
        persistDiary()
        return entry
    }

    func deleteDiaryEntry(_ entry: DiaryEntry) {
        DiaryPhotoStore.delete(fileName: entry.photoFileName)
        diaryEntries.removeAll { $0.id == entry.id }
        persistDiary()
    }

    func openPacking(for destination: Destination) {
        let trip = ensurePackingTrip(for: destination)
        focusPackingTripId = trip.id
        navigationTarget = .packing
    }

    func openSuggestedPhrases(for destination: Destination) {
        let language = CountryLanguageMapping.language(forCountry: destination.country)
        navigationTarget = .phrases(language)
    }

    func clearNavigationTarget() {
        navigationTarget = nil
    }

    func resetAllData() {
        for destination in destinations {
            TripReminderService.removeReminder(for: destination.id)
        }
        for entry in diaryEntries {
            DiaryPhotoStore.delete(fileName: entry.photoFileName)
        }
        destinations = []
        packingTrips = []
        phraseUserData = PhraseUserData()
        diaryEntries = []
        persist()
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: destinationsKey),
           let decoded = try? decoder.decode([Destination].self, from: data) {
            destinations = decoded
        }
        if let data = UserDefaults.standard.data(forKey: packingKey),
           let decoded = try? decoder.decode([PackingTrip].self, from: data) {
            packingTrips = decoded
        }
        if let data = UserDefaults.standard.data(forKey: phrasesKey),
           let decoded = try? decoder.decode(PhraseUserData.self, from: data) {
            phraseUserData = decoded
        }
        if let data = UserDefaults.standard.data(forKey: diaryKey),
           let decoded = try? decoder.decode([DiaryEntry].self, from: data) {
            diaryEntries = decoded
        }
    }

    private func persistPhrases() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(phraseUserData) {
            UserDefaults.standard.set(data, forKey: phrasesKey)
        }
        objectWillChange.send()
    }

    private func persistDiary() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(diaryEntries) {
            UserDefaults.standard.set(data, forKey: diaryKey)
        }
        objectWillChange.send()
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(destinations) {
            UserDefaults.standard.set(data, forKey: destinationsKey)
        }
        if let data = try? encoder.encode(packingTrips) {
            UserDefaults.standard.set(data, forKey: packingKey)
        }
        if let data = try? encoder.encode(phraseUserData) {
            UserDefaults.standard.set(data, forKey: phrasesKey)
        }
        if let data = try? encoder.encode(diaryEntries) {
            UserDefaults.standard.set(data, forKey: diaryKey)
        }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func date(fromDayKey key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }
}
