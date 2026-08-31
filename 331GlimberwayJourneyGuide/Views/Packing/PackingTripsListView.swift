import SwiftUI

struct PackingTripsListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showNewTrip = false
    @State private var tripToDelete: PackingTrip?
    @State private var selectedTrip: PackingTrip?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SymbolHero(
                    symbol: "scalemass.fill",
                    title: "Weigh the bag",
                    subtitle: "On body does not count toward the limit."
                )

                if store.packingTrips.isEmpty {
                    EmptyStateCard(
                        symbol: "bag.fill",
                        title: "No bag lists",
                        message: "Build from Flight morning, Road leave, Rail, Weekend, or Family handoff — not a generic beach list.",
                        actionTitle: "New bag list",
                        action: { showNewTrip = true }
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(store.packingTrips.sorted(by: { $0.tripName.localizedCaseInsensitiveCompare($1.tripName) == .orderedAscending })) { trip in
                            Button {
                                selectedTrip = trip
                            } label: {
                                PackingTripRow(trip: trip) {
                                    tripToDelete = trip
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button("New bag list") {
                    showNewTrip = true
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .clearScrollBackground()
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .sheet(item: $selectedTrip) { trip in
            PackingTripDetailView(tripId: trip.id)
                .environmentObject(store)
        }
        .sheet(isPresented: $showNewTrip) {
            NewPackingTripSheet()
                .environmentObject(store)
        }
        .onAppear { openFocusedTripIfNeeded() }
        .onChange(of: store.focusPackingTripId) { _ in
            openFocusedTripIfNeeded()
        }
        .confirmationDialog(
            "Delete this bag list?",
            isPresented: Binding(
                get: { tripToDelete != nil },
                set: { if !$0 { tripToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: tripToDelete
        ) { trip in
            Button("Delete", role: .destructive) {
                store.deletePackingTrip(trip)
                tripToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                tripToDelete = nil
            }
        } message: { trip in
            Text(trip.tripName)
        }
    }

    private func openFocusedTripIfNeeded() {
        guard let tripId = store.focusPackingTripId,
              let trip = store.packingTrip(for: tripId) else { return }
        selectedTrip = trip
        store.focusPackingTripId = nil
    }
}

private struct PackingTripRow: View {
    let trip: PackingTrip
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.tripName)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(trip.packedCount)/\(trip.totalCount)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            ProgressView(value: Double(trip.packedCount), total: max(Double(trip.totalCount), 1))
                .tint(Color("AppAccent"))

            Text(String(format: "Bag %.1f / %.0f kg%@", trip.bagWeightKg, trip.weightLimitKg, trip.isOverLimit ? " — over" : ""))
                .font(.caption.weight(.semibold))
                .foregroundStyle(trip.isOverLimit ? Color.red.opacity(0.9) : Color("AppTextSecondary"))

            HStack {
                Spacer()
                Button("Delete", role: .destructive, action: onDelete)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .travelCard()
    }
}

private struct NewPackingTripSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var tripName = ""
    @State private var selectedTemplate: PackingTemplate? = .flightMorning
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        TravelTextField(title: "Bag list name", text: $tripName)
                        Text("Name the leave (city is enough).")
                            .font(.footnote)
                            .foregroundStyle(Color("AppTextSecondary"))

                        Text("Kit")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        VStack(spacing: 8) {
                            templateButton(title: "Blank list", symbol: "square.dashed", subtitle: "Start empty", template: nil)
                            ForEach(PackingTemplate.allCases) { template in
                                templateButton(
                                    title: template.title,
                                    symbol: template.symbol,
                                    subtitle: template.subtitle,
                                    template: template
                                )
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.95))
                        }
                    }
                    .padding(16)
                    .travelCard()
                    .padding(16)
                }
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("New bag list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if store.addPackingTrip(tripName: tripName, template: selectedTemplate) != nil {
                            dismiss()
                        } else {
                            errorMessage = "Enter a name."
                        }
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .background(Color.clear)
        .presentationDetents([.medium, .large])
    }

    private func templateButton(title: String, symbol: String, subtitle: String, template: PackingTemplate?) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(Color("AppAccent"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                Spacer()
                if selectedTemplate == template {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color("AppBackground").opacity(0.45))
            )
        }
        .buttonStyle(.plain)
    }
}
