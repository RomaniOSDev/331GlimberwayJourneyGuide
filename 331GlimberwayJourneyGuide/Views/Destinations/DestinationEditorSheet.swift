import SwiftUI

struct DestinationEditorSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destination: Destination?

    @State private var country = ""
    @State private var city = ""
    @State private var notes = ""
    @State private var hasPlannedDate = false
    @State private var plannedDate = Date()
    @State private var isVisited = false
    @State private var createPackingList = true
    @State private var errorMessage: String?

    private var isEditing: Bool { destination != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Place")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        TravelTextField(title: "Country", text: $country, submitLabel: .next)
                        TravelTextField(title: "City", text: $city, submitLabel: .next)
                    }
                    .travelCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        Toggle("Set planned date", isOn: $hasPlannedDate)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppAccent"))

                        if hasPlannedDate {
                            DatePicker(
                                "Planned date",
                                selection: $plannedDate,
                                displayedComponents: .date
                            )
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppAccent"))
                            .colorScheme(.dark)
                        }

                        Toggle("Already visited", isOn: $isVisited)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppAccent"))

                        TravelTextField(
                            title: "Notes",
                            text: $notes,
                            axis: .vertical,
                            lineLimit: 3...6
                        )
                    }
                    .travelCard()

                    if !isEditing {
                        Toggle("Create packing list for this trip", isOn: $createPackingList)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .tint(Color("AppAccent"))
                            .travelCard()
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(Color.red.opacity(0.95))
                            .font(.footnote)
                            .travelCard()
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .appScreenBackground()
            .navigationTitle(isEditing ? "Edit Destination" : "New Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: populate)
        }
        .presentationDetents([.large])
    }

    private func populate() {
        guard let destination else {
            createPackingList = true
            return
        }
        country = destination.country
        city = destination.city
        notes = destination.notes
        isVisited = destination.isVisited
        if let date = destination.plannedDate {
            hasPlannedDate = true
            plannedDate = date
        }
    }

    private func save() {
        errorMessage = nil
        let date = hasPlannedDate ? plannedDate : nil

        if let destination {
            let ok = store.updateDestination(
                destination,
                country: country,
                city: city,
                notes: notes,
                plannedDate: date,
                isVisited: isVisited
            )
            if ok {
                dismiss()
            } else {
                errorMessage = "Enter country and city. Duplicate places are not allowed."
            }
        } else {
            if store.isDuplicateDestination(country: country, city: city) {
                errorMessage = "This country and city combination already exists."
                return
            }
            if store.addDestination(
                country: country,
                city: city,
                notes: notes,
                plannedDate: date,
                isVisited: isVisited,
                createPackingList: createPackingList
            ) != nil {
                dismiss()
            } else {
                errorMessage = "Could not save. Check country and city."
            }
        }
    }
}
