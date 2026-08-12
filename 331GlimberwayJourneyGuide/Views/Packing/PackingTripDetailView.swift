import SwiftUI

struct PackingTripDetailView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let tripId: UUID

    @State private var showAddItem = false
    @State private var showTemplates = false
    @State private var showCopyFrom = false
    @State private var itemToDelete: PackingItem?

    private var trip: PackingTrip? {
        store.packingTrip(for: tripId)
    }

    private var otherTrips: [PackingTrip] {
        store.packingTrips.filter { $0.id != tripId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let trip {
                        HStack(spacing: 10) {
                            Button("Add template") { showTemplates = true }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                            Spacer()
                            Button("Copy from list") { showCopyFrom = true }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                                .disabled(otherTrips.isEmpty)
                        }
                        .travelCard()

                        ForEach(PackingCategory.allCases) { category in
                            let items = trip.items.filter { $0.category == category }
                            if !items.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label(category.title, systemImage: category.symbol)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))

                                    ForEach(items) { item in
                                        PackingItemRow(
                                            item: item,
                                            onToggle: {
                                                store.togglePackingItem(tripId: trip.id, itemId: item.id)
                                            },
                                            onDelete: {
                                                itemToDelete = item
                                            }
                                        )
                                    }
                                }
                                .travelCard()
                            }
                        }

                        if trip.items.isEmpty {
                            EmptyStateCard(
                                symbol: "checklist",
                                title: "List is empty",
                                message: "Add items manually, apply a Beach/City/Winter template, or copy from another trip.",
                                actionTitle: "Add Item",
                                action: { showAddItem = true }
                            )
                        }

                        Button("Add Item") {
                            showAddItem = true
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("This packing list is no longer available.")
                            .foregroundStyle(Color("AppTextSecondary"))
                            .travelCard()
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .appScreenBackground()
            .navigationTitle(trip?.tripName ?? "Packing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .sheet(isPresented: $showAddItem) {
                if let trip {
                    AddPackingItemSheet(trip: trip)
                        .environmentObject(store)
                }
            }
            .confirmationDialog("Add template items", isPresented: $showTemplates, titleVisibility: .visible) {
                ForEach(PackingTemplate.allCases) { template in
                    Button(template.title) {
                        store.applyTemplate(template, to: tripId)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Items already on the list are skipped.")
            }
            .confirmationDialog("Copy items from", isPresented: $showCopyFrom, titleVisibility: .visible) {
                ForEach(otherTrips) { source in
                    Button(source.tripName) {
                        _ = store.copyPackingItems(from: source.id, to: tripId)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Existing item titles are kept; duplicates are skipped.")
            }
            .confirmationDialog(
                "Remove this item?",
                isPresented: Binding(
                    get: { itemToDelete != nil },
                    set: { if !$0 { itemToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: itemToDelete
            ) { item in
                Button("Delete", role: .destructive) {
                    store.deletePackingItem(tripId: tripId, itemId: item.id)
                    itemToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            } message: { item in
                Text(item.title)
            }
        }
    }
}

private struct PackingItemRow: View {
    let item: PackingItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPacked ? Color.green : Color("AppTextSecondary"))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .foregroundStyle(Color("AppTextPrimary"))
                .strikethrough(item.isPacked)

            Spacer()

            Button("Remove", role: .destructive, action: onDelete)
                .font(.caption.weight(.semibold))
        }
        .font(.subheadline)
    }
}

struct AddPackingItemSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let trip: PackingTrip

    @State private var title = ""
    @State private var category: PackingCategory = .clothing
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TravelTextField(title: "Item title", text: $title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Picker("Category", selection: $category) {
                            ForEach(PackingCategory.allCases) { cat in
                                Text(cat.title).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                        .colorScheme(.dark)
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
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if store.addPackingItem(to: trip, title: title, category: category) {
                            dismiss()
                        } else {
                            errorMessage = "Enter an item title."
                        }
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .presentationDetents([.medium])
    }
}
