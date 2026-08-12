import SwiftUI

struct PackingTripsListView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showNewTrip = false
    @State private var tripToDelete: PackingTrip?
    @State private var selectedTrip: PackingTrip?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionBanner(imageName: "imgSuitcase", height: 130)

                if store.packingTrips.isEmpty {
                    EmptyStateCard(
                        symbol: "suitcase.fill",
                        title: "No packing lists yet",
                        message: "Create a list from a Beach, City, or Winter template — or start blank and build your own checklist.",
                        actionTitle: "New Packing List",
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

                Button("New Packing List") {
                    showNewTrip = true
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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
            "Delete this packing list?",
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
                Text("\(trip.packedCount)/\(trip.totalCount) packed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            ProgressView(value: Double(trip.packedCount), total: max(Double(trip.totalCount), 1))
                .tint(Color("AppAccent"))

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
    @State private var selectedTemplate: PackingTemplate?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TravelTextField(title: "Trip name", text: $tripName)
                    Text("Name your trip (e.g. city and country).")
                        .font(.footnote)
                        .foregroundStyle(Color("AppTextSecondary"))

                    Text("Template")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))

                    VStack(spacing: 8) {
                        templateButton(title: "Blank list", symbol: "square.dashed", template: nil)
                        ForEach(PackingTemplate.allCases) { template in
                            templateButton(title: template.title, symbol: template.symbol, template: template)
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
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .appScreenBackground()
            .navigationTitle("New packing list")
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
                            errorMessage = "Enter a trip name."
                        }
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func templateButton(title: String, symbol: String, template: PackingTemplate?) -> some View {
        Button {
            selectedTemplate = template
        } label: {
            HStack {
                Image(systemName: symbol)
                    .foregroundStyle(Color("AppAccent"))
                Text(title)
                    .foregroundStyle(Color("AppTextPrimary"))
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
