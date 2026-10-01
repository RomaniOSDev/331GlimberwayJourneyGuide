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
                AssetHero(
                    imageName: "bannerPassport",
                    title: "Desk",
                    subtitle: "Seal the door. Brief the next leave."
                )

                if let brief = store.pendingBrief {
                    ReturnBriefCard(
                        seal: brief,
                        canApply: store.nextDeparture != nil,
                        onApply: {
                            if let id = store.nextDeparture?.id {
                                store.applyReturnBrief(to: id)
                            }
                        },
                        onDismiss: { store.dismissReturnBrief() }
                    )
                }

                if let next = store.nextDeparture {
                    ReadyScoreBadge(percent: next.readinessPercent)
                }

                TravelSearchField(placeholder: "Search a leave", text: $searchText)

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
                        symbol: searchText.isEmpty && filter == .all ? "door.left.hand.open" : "magnifyingglass",
                        title: searchText.isEmpty && filter == .all ? "No leave on the desk" : "Nothing matches",
                        message: searchText.isEmpty && filter == .all
                            ? "Add the next exit — time, mode, and a house loop. Dream lists stay out of this app."
                            : "Try another filter or clear the search.",
                        actionTitle: searchText.isEmpty && filter == .all ? "New leave" : nil,
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
                                onMarkLeft: {
                                    store.markDestinationVisited(destination, visited: !destination.isVisited)
                                },
                                onOpenPacking: {
                                    store.openPacking(for: destination)
                                },
                                onOpenClock: {
                                    store.openTimeline(for: destination)
                                }
                            )
                        }
                    }
                }

                Button("New leave") {
                    editingDestination = nil
                    showEditor = true
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .clearScrollBackground()
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
            "Delete this leave?",
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
    var onMarkLeft: () -> Void
    var onOpenPacking: () -> Void
    var onOpenClock: () -> Void

    private var dateLabel: String {
        guard let date = destination.plannedDate else { return "Time not set" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    private var countdownLabel: String? {
        guard let minutes = destination.minutesUntilDeparture else { return nil }
        if minutes <= 0 { return "Leave now" }
        if minutes < 60 { return "\(minutes)m" }
        if minutes < 24 * 60 { return "\(minutes / 60)h" }
        if let days = destination.daysUntilTrip, days > 0 { return "\(days)d" }
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
                        Text(destination.isVisited ? "Already left" : destination.leaveMode.title)
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

            Text("Ready \(destination.readinessPercent)% · House \(destination.homeDoneCount)/\(destination.homeItems.count) · Clock \(destination.timelineDoneCount)/\(destination.timelineTasks.count)")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickChip(destination.isVisited ? "Still home" : "Seal door", action: destination.isVisited ? onMarkLeft : onOpen)
                    quickChip("Clock", action: onOpenClock)
                    quickChip("Bags", action: onOpenPacking)
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

struct ReturnBriefCard: View {
    let seal: DoorSeal
    var canApply: Bool
    var onApply: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Return brief")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Text("Last door seal · \(seal.title)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))
            if seal.residue.isEmpty {
                Text("No residue was parked. House \(seal.houseDone)/\(seal.houseTotal).")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(seal.residue, id: \.self) { item in
                    Text("Carry · \(item)")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
            HStack {
                if canApply {
                    Button("Carry into next leave", action: onApply)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }
                Spacer()
                Button("Dismiss", action: onDismiss)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .travelCard()
    }
}
