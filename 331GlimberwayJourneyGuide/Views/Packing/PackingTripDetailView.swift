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
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if let trip {
                            weightCard(trip)

                            HStack(spacing: 10) {
                                Button("Add kit") { showTemplates = true }
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
                                                onCycle: {
                                                    store.cyclePlacement(tripId: trip.id, itemId: item.id)
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
                                    symbol: "scalemass",
                                    title: "Bag is empty",
                                    message: "Apply a leave kit, copy another list, or add items with grams.",
                                    actionTitle: "Add item",
                                    action: { showAddItem = true }
                                )
                            }

                            Button("Add item") {
                                showAddItem = true
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                            .frame(maxWidth: .infinity)
                        } else {
                            Text("This bag list is gone.")
                                .foregroundStyle(Color("AppTextSecondary"))
                                .travelCard()
                        }
                    }
                    .padding(16)
                }
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(trip?.tripName ?? "Bag")
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
            .confirmationDialog("Add kit items", isPresented: $showTemplates, titleVisibility: .visible) {
                ForEach(PackingTemplate.allCases) { template in
                    Button(template.title) {
                        store.applyTemplate(template, to: tripId)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Titles already on the list are skipped.")
            }
            .confirmationDialog("Copy items from", isPresented: $showCopyFrom, titleVisibility: .visible) {
                ForEach(otherTrips) { source in
                    Button(source.tripName) {
                        _ = store.copyPackingItems(from: source.id, to: tripId)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Existing titles stay; duplicates are skipped.")
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
        .background(Color.clear)
    }

    private func weightCard(_ trip: PackingTrip) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(format: "Bag %.1f kg", trip.bagWeightKg))
                    .font(.headline)
                    .foregroundStyle(trip.isOverLimit ? Color.red.opacity(0.9) : Color("AppTextPrimary"))
                Spacer()
                Text(String(format: "Limit %.0f kg", trip.weightLimitKg))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            ProgressView(value: min(trip.bagWeightKg, trip.weightLimitKg), total: max(trip.weightLimitKg, 1))
                .tint(trip.isOverLimit ? .red : Color("AppAccent"))
            Text(String(format: "On body %.1f kg (not in the limit)", trip.wornWeightKg))
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
            Slider(
                value: Binding(
                    get: { trip.weightLimitKg },
                    set: { store.setWeightLimit(tripId: trip.id, kilograms: $0) }
                ),
                in: 5...32,
                step: 1
            )
            .tint(Color("AppAccent"))
        }
        .travelCard()
    }
}

private struct PackingItemRow: View {
    let item: PackingItem
    var onToggle: () -> Void
    var onCycle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPacked ? Color.green : Color("AppTextSecondary"))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .strikethrough(item.isPacked)
                Text(item.weightGrams > 0 ? "\(item.weightGrams) g" : "No weight")
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }

            Spacer()

            Button(item.placement.title, action: onCycle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))

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
    @State private var placement: BagPlacement = .packed
    @State private var gramsText = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        TravelTextField(title: "Item", text: $title)
                        TravelTextField(title: "Grams (optional)", text: $gramsText)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Picker("Category", selection: $category) {
                                ForEach(PackingCategory.allCases) { cat in
                                    Text(cat.title).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppAccent"))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Picker("Placement", selection: $placement) {
                                ForEach(BagPlacement.allCases) { item in
                                    Text(item.title).tag(item)
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
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("Add item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let grams = Int(gramsText) ?? 0
                        if store.addPackingItem(to: trip, title: title, category: category, placement: placement, weightGrams: grams) {
                            dismiss()
                        } else {
                            errorMessage = "Enter an item name."
                        }
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .background(Color.clear)
        .presentationDetents([.medium, .large])
    }
}
