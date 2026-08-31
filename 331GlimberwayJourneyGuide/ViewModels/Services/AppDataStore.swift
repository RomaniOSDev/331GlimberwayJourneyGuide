import Foundation
import Combine

enum AppNavigationTarget: Equatable {
    case packing
    case timeline
}

final class AppDataStore: ObservableObject {
    @Published private(set) var destinations: [Destination] = []
    @Published private(set) var packingTrips: [PackingTrip] = []
    @Published var hasCompletedOnboarding: Bool
    @Published var navigationTarget: AppNavigationTarget?
    @Published var focusPackingTripId: UUID?
    @Published var focusedDepartureId: UUID?

    private let destinationsKey = "glimberway.destinations.v2"
    private let packingKey = "glimberway.packing.v2"
    private let onboardingKey = "glimberway.onboarding.v2"
    private let legacyDestinationsKey = "glimberway.destinations.v1"
    private let legacyPackingKey = "glimberway.packing.v1"
    private let legacyOnboardingKey = "glimberway.onboarding.v1"

    init() {
        let fresh = UserDefaults.standard.bool(forKey: onboardingKey)
        let legacy = UserDefaults.standard.bool(forKey: legacyOnboardingKey)
        hasCompletedOnboarding = fresh || legacy
        load()
        TripReminderService.rescheduleAll(for: destinations)
    }

    var nextDeparture: Destination? {
        destinations
            .filter { !$0.isVisited && $0.plannedDate != nil }
            .sorted { ($0.plannedDate ?? .distantFuture) < ($1.plannedDate ?? .distantFuture) }
            .first
    }

    var timelineDeparture: Destination? {
        if let focusedDepartureId, let match = destination(for: focusedDepartureId) {
            return match
        }
        return nextDeparture
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
        let sorted = destinations.sorted { lhs, rhs in
            let lDate = lhs.plannedDate ?? .distantFuture
            let rDate = rhs.plannedDate ?? .distantFuture
            if lDate != rDate { return lDate < rDate }
            return lhs.displayTitle.localizedCaseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
        }
        return sorted.filter { destination in
            switch filter {
            case .all:
                break
            case .leaving:
                guard !destination.isVisited, let days = destination.daysUntilTrip, days > 0, days <= 3 else { return false }
            case .today:
                guard !destination.isVisited, destination.daysUntilTrip == 0 else { return false }
            case .later:
                guard !destination.isVisited, let days = destination.daysUntilTrip, days > 3 else { return false }
            case .departed:
                guard destination.isVisited else { return false }
            }
            guard !q.isEmpty else { return true }
            return destination.country.lowercased().contains(q)
                || destination.city.lowercased().contains(q)
                || destination.notes.lowercased().contains(q)
                || destination.leaveMode.title.lowercased().contains(q)
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
        createPackingList: Bool,
        leaveMode: LeaveMode,
        forecast: ForecastCondition,
        bagLimitKg: Double
    ) -> Destination? {
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let ci = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !co.isEmpty, !ci.isEmpty else { return nil }
        guard !isDuplicateDestination(country: co, city: ci) else { return nil }

        var destination = Destination(
            country: co,
            city: ci,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            plannedDate: plannedDate,
            isVisited: isVisited,
            leaveMode: leaveMode,
            forecast: forecast,
            bagLimitKg: bagLimitKg
        )
        destination.timelineTasks = TimelineCatalog.makeTasks(for: leaveMode)
        destination.homeItems = HomeLeaveCatalog.makeItems()
        destinations.append(destination)
        if createPackingList {
            _ = addPackingTrip(
                tripName: destination.displayTitle,
                destinationId: destination.id,
                template: template(for: leaveMode),
                weightLimitKg: bagLimitKg
            )
            applyForecastExtras(toDestinationId: destination.id)
        }
        persist()
        TripReminderService.syncAll(for: destination)
        focusedDepartureId = destination.id
        return destination
    }

    @discardableResult
    func updateDestination(
        _ destination: Destination,
        country: String,
        city: String,
        notes: String,
        plannedDate: Date?,
        isVisited: Bool,
        leaveMode: LeaveMode,
        forecast: ForecastCondition,
        bagLimitKg: Double
    ) -> Bool {
        let co = country.trimmingCharacters(in: .whitespacesAndNewlines)
        let ci = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !co.isEmpty, !ci.isEmpty else { return false }
        guard !isDuplicateDestination(country: co, city: ci, excludingId: destination.id) else { return false }
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else { return false }

        let modeChanged = destinations[index].leaveMode != leaveMode
        var updated = destinations[index]
        updated.country = co
        updated.city = ci
        updated.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.plannedDate = plannedDate
        updated.isVisited = isVisited
        updated.leaveMode = leaveMode
        updated.forecast = forecast
        updated.bagLimitKg = bagLimitKg
        if modeChanged {
            updated.timelineTasks = TimelineCatalog.makeTasks(for: leaveMode)
        }
        destinations[index] = updated
        if let packingIndex = packingTrips.firstIndex(where: { $0.destinationId == destination.id }) {
            packingTrips[packingIndex].weightLimitKg = bagLimitKg
        }
        persist()
        TripReminderService.syncAll(for: updated)
        return true
    }

    func markDestinationVisited(_ destination: Destination, visited: Bool = true) {
        guard let index = destinations.firstIndex(where: { $0.id == destination.id }) else { return }
        destinations[index].isVisited = visited
        if visited {
            destinations[index].airportMode = false
        }
        persist()
        TripReminderService.syncAll(for: destinations[index])
    }

    func toggleChecklistItem(destinationId: UUID, itemId: UUID) {
        guard let destIndex = destinations.firstIndex(where: { $0.id == destinationId }),
              let itemIndex = destinations[destIndex].checklistItems.firstIndex(where: { $0.id == itemId }) else { return }
        destinations[destIndex].checklistItems[itemIndex].isDone.toggle()
        persist()
    }

    func toggleTimelineTask(destinationId: UUID, taskId: UUID) {
        guard let destIndex = destinations.firstIndex(where: { $0.id == destinationId }),
              let taskIndex = destinations[destIndex].timelineTasks.firstIndex(where: { $0.id == taskId }) else { return }
        destinations[destIndex].timelineTasks[taskIndex].isDone.toggle()
        persist()
        TripReminderService.syncAll(for: destinations[destIndex])
    }

    func toggleHomeItem(destinationId: UUID, itemId: UUID) {
        guard let destIndex = destinations.firstIndex(where: { $0.id == destinationId }),
              let itemIndex = destinations[destIndex].homeItems.firstIndex(where: { $0.id == itemId }) else { return }
        destinations[destIndex].homeItems[itemIndex].isDone.toggle()
        persist()
    }

    func setAirportMode(destinationId: UUID, enabled: Bool) {
        guard let index = destinations.firstIndex(where: { $0.id == destinationId }) else { return }
        destinations[index].airportMode = enabled
        persist()
    }

    func setForecast(destinationId: UUID, forecast: ForecastCondition) {
        guard let index = destinations.firstIndex(where: { $0.id == destinationId }) else { return }
        destinations[index].forecast = forecast
        persist()
    }

    func applyForecastExtras(toDestinationId destinationId: UUID) {
        guard let destination = destination(for: destinationId) else { return }
        let extras = ForecastPackingAdvisor.extras(for: destination.forecast, mode: destination.leaveMode)
        guard !extras.isEmpty else { return }
        let trip = ensurePackingTrip(for: destination)
        guard let index = packingTrips.firstIndex(where: { $0.id == trip.id }) else { return }
        let existing = Set(packingTrips[index].items.map { $0.title.lowercased() })
        for extra in extras where !existing.contains(extra.title.lowercased()) {
            packingTrips[index].items.append(
                PackingItem(
                    title: extra.title,
                    category: extra.category,
                    placement: extra.placement,
                    weightGrams: extra.grams
                )
            )
        }
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
        TripReminderService.syncAll(for: destinations[index])
    }

    func addDocument(_ document: TravelDocument) {
        guard let index = destinations.firstIndex(where: { $0.id == document.destinationId }) else { return }
        destinations[index].documents.append(document)
        persist()
    }

    func deleteDocument(_ document: TravelDocument) {
        DiaryPhotoStore.delete(fileName: document.photoFileName)
        guard let index = destinations.firstIndex(where: { $0.id == document.destinationId }) else { return }
        destinations[index].documents.removeAll { $0.id == document.id }
        persist()
    }

    func deleteDestination(_ destination: Destination) {
        destinations.first(where: { $0.id == destination.id })?.documents.forEach {
            DiaryPhotoStore.delete(fileName: $0.photoFileName)
        }
        destinations.removeAll { $0.id == destination.id }
        packingTrips.removeAll { $0.destinationId == destination.id }
        TripReminderService.removeAll(for: destination.id)
        if focusedDepartureId == destination.id {
            focusedDepartureId = nil
        }
        persist()
    }

    @discardableResult
    func addPackingTrip(
        tripName: String,
        destinationId: UUID? = nil,
        template: PackingTemplate? = nil,
        weightLimitKg: Double = 7
    ) -> PackingTrip? {
        let name = tripName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        var trip = PackingTrip(tripName: name, destinationId: destinationId, weightLimitKg: weightLimitKg)
        if let template {
            trip.items = template.items.map {
                PackingItem(title: $0.title, category: $0.category, placement: $0.placement, weightGrams: $0.grams)
            }
        }
        packingTrips.append(trip)
        persist()
        return trip
    }

    func deletePackingTrip(_ trip: PackingTrip) {
        packingTrips.removeAll { $0.id == trip.id }
        persist()
    }

    @discardableResult
    func addPackingItem(
        to trip: PackingTrip,
        title: String,
        category: PackingCategory,
        placement: BagPlacement,
        weightGrams: Int
    ) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard let index = packingTrips.firstIndex(where: { $0.id == trip.id }) else { return false }
        packingTrips[index].items.append(
            PackingItem(title: trimmed, category: category, placement: placement, weightGrams: max(0, weightGrams))
        )
        persist()
        return true
    }

    func applyTemplate(_ template: PackingTemplate, to tripId: UUID) {
        guard let index = packingTrips.firstIndex(where: { $0.id == tripId }) else { return }
        let existingTitles = Set(packingTrips[index].items.map { $0.title.lowercased() })
        for item in template.items where !existingTitles.contains(item.title.lowercased()) {
            packingTrips[index].items.append(
                PackingItem(title: item.title, category: item.category, placement: item.placement, weightGrams: item.grams)
            )
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
                PackingItem(
                    title: item.title,
                    category: item.category,
                    isPacked: false,
                    placement: item.placement,
                    weightGrams: item.weightGrams
                )
            )
        }
        persist()
        return true
    }

    func ensurePackingTrip(for destination: Destination) -> PackingTrip {
        if let existing = packingTrip(forDestinationId: destination.id) {
            return existing
        }
        return addPackingTrip(
            tripName: destination.displayTitle,
            destinationId: destination.id,
            template: template(for: destination.leaveMode),
            weightLimitKg: destination.bagLimitKg
        ) ?? PackingTrip(tripName: destination.displayTitle, destinationId: destination.id)
    }

    func togglePackingItem(tripId: UUID, itemId: UUID) {
        guard let tripIndex = packingTrips.firstIndex(where: { $0.id == tripId }),
              let itemIndex = packingTrips[tripIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        packingTrips[tripIndex].items[itemIndex].isPacked.toggle()
        persist()
    }

    func cyclePlacement(tripId: UUID, itemId: UUID) {
        guard let tripIndex = packingTrips.firstIndex(where: { $0.id == tripId }),
              let itemIndex = packingTrips[tripIndex].items.firstIndex(where: { $0.id == itemId }) else { return }
        let order = BagPlacement.allCases
        let current = packingTrips[tripIndex].items[itemIndex].placement
        let next = order[((order.firstIndex(of: current) ?? 0) + 1) % order.count]
        packingTrips[tripIndex].items[itemIndex].placement = next
        persist()
    }

    func setWeightLimit(tripId: UUID, kilograms: Double) {
        guard let index = packingTrips.firstIndex(where: { $0.id == tripId }) else { return }
        packingTrips[index].weightLimitKg = max(1, min(kilograms, 32))
        persist()
    }

    func deletePackingItem(tripId: UUID, itemId: UUID) {
        guard let tripIndex = packingTrips.firstIndex(where: { $0.id == tripId }) else { return }
        packingTrips[tripIndex].items.removeAll { $0.id == itemId }
        persist()
    }

    func openPacking(for destination: Destination) {
        let trip = ensurePackingTrip(for: destination)
        focusPackingTripId = trip.id
        focusedDepartureId = destination.id
        navigationTarget = .packing
    }

    func openTimeline(for destination: Destination) {
        focusedDepartureId = destination.id
        navigationTarget = .timeline
    }

    func clearNavigationTarget() {
        navigationTarget = nil
    }

    func resetAllData() {
        for destination in destinations {
            destination.documents.forEach { DiaryPhotoStore.delete(fileName: $0.photoFileName) }
            TripReminderService.removeAll(for: destination.id)
        }
        destinations = []
        packingTrips = []
        focusedDepartureId = nil
        persist()
    }

    private func template(for mode: LeaveMode) -> PackingTemplate {
        switch mode {
        case .flight: return .flightMorning
        case .road: return .roadLeave
        case .rail: return .overnightRail
        case .overnight: return .weekendCarry
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: destinationsKey),
           let decoded = try? decoder.decode([Destination].self, from: data) {
            destinations = decoded
        } else if let data = UserDefaults.standard.data(forKey: legacyDestinationsKey),
                  let decoded = try? decoder.decode([Destination].self, from: data) {
            destinations = decoded
        }
        if let data = UserDefaults.standard.data(forKey: packingKey),
           let decoded = try? decoder.decode([PackingTrip].self, from: data) {
            packingTrips = decoded
        } else if let data = UserDefaults.standard.data(forKey: legacyPackingKey),
                  let decoded = try? decoder.decode([PackingTrip].self, from: data) {
            packingTrips = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(destinations) {
            UserDefaults.standard.set(data, forKey: destinationsKey)
        }
        if let data = try? encoder.encode(packingTrips) {
            UserDefaults.standard.set(data, forKey: packingKey)
        }
    }
}
