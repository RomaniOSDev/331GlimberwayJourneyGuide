import SwiftUI

struct DestinationsListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var searchText = ""
    @State private var filter: DestinationFilter = .all
    @State private var showEditor = false
    @State private var editingDestination: Destination?
    @State private var destinationToDelete: Destination?
    @State private var selectedDestination: Destination?

    private var items: [Destination] {
        store.filteredDestinations(query: searchText, filter: filter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionBanner(imageName: "bannerPassport", height: 130)

                if store.hasFirstTripBadge {
                    FirstTripBadge()
                }

                TravelSearchField(placeholder: "Search destinations", text: $searchText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(DestinationFilter.allCases) { option in
                            Button {
                                filter = option
                            } label: {
                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(filter == option ? Color("AppPrimary").opacity(0.5) : Color("AppSurface").opacity(0.75))
                                    )
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if items.isEmpty {
                    EmptyStateCard(
                        symbol: searchText.isEmpty && filter == .all ? "mappin.and.ellipse" : "magnifyingglass",
                        title: searchText.isEmpty && filter == .all ? "No places yet" : "Nothing matches",
                        message: searchText.isEmpty && filter == .all
                            ? "Add your first destination, set a date, and open the trip hub for countdown, checklist, diary, and packing tips."
                            : "Try another filter or clear the search to see more places.",
                        actionTitle: searchText.isEmpty && filter == .all ? "Add Destination" : nil,
                        action: searchText.isEmpty && filter == .all ? {
                            editingDestination = nil
                            showEditor = true
                        } : nil
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { destination in
                            DestinationRow(
                                destination: destination,
                                onOpen: { selectedDestination = destination },
                                onEdit: {
                                    editingDestination = destination
                                    showEditor = true
                                },
                                onDelete: { destinationToDelete = destination },
                                onMarkVisited: {
                                    store.markDestinationVisited(destination, visited: !destination.isVisited)
                                },
                                onOpenPacking: {
                                    store.openPacking(for: destination)
                                },
                                onOpenPhrases: {
                                    store.openSuggestedPhrases(for: destination)
                                }
                            )
                        }
                    }
                }

                Button("Add Destination") {
                    editingDestination = nil
                    showEditor = true
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showEditor) {
            DestinationEditorSheet(destination: editingDestination)
                .environmentObject(store)
        }
        .sheet(item: $selectedDestination) { destination in
            DestinationHubView(destinationId: destination.id)
                .environmentObject(store)
        }
        .confirmationDialog(
            "Delete this destination?",
            isPresented: Binding(
                get: { destinationToDelete != nil },
                set: { if !$0 { destinationToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: destinationToDelete
        ) { destination in
            Button("Delete", role: .destructive) {
                store.deleteDestination(destination)
                destinationToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                destinationToDelete = nil
            }
        } message: { destination in
            Text(destination.displayTitle)
        }
    }
}

private struct DestinationRow: View {
    let destination: Destination
    var onOpen: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onMarkVisited: () -> Void
    var onOpenPacking: () -> Void
    var onOpenPhrases: () -> Void

    private var dateLabel: String {
        guard let date = destination.plannedDate else { return "Date not set" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var countdownLabel: String? {
        guard let days = destination.daysUntilTrip else { return nil }
        if days > 0 { return "\(days)d left" }
        if days == 0 { return "Today" }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.displayTitle)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(destination.isVisited ? "Visited" : "Planned")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(destination.isVisited ? Color.green.opacity(0.9) : Color("AppAccent"))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(dateLabel)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                        if let countdownLabel {
                            Text(countdownLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            if !destination.notes.isEmpty {
                Text(destination.notes)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Text("Checklist \(destination.checklistDoneCount)/\(destination.checklistItems.count)")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickChip(destination.isVisited ? "Mark planned" : "Mark visited", action: onMarkVisited)
                    quickChip("Packing", action: onOpenPacking)
                    quickChip("Phrases", action: onOpenPhrases)
                    quickChip("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .travelCard()
    }

    private func quickChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color("AppBackground").opacity(0.55)))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .buttonStyle(.plain)
    }
}
