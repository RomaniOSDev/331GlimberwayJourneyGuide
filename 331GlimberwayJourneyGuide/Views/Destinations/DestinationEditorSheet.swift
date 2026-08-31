import SwiftUI

struct DestinationEditorSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destination: Destination?

    @State private var country = ""
    @State private var city = ""
    @State private var notes = ""
    @State private var hasPlannedDate = true
    @State private var plannedDate = Date().addingTimeInterval(36 * 60 * 60)
    @State private var isVisited = false
    @State private var createPackingList = true
    @State private var leaveMode: LeaveMode = .flight
    @State private var forecast: ForecastCondition = .unset
    @State private var bagLimitKg: Double = 7
    @State private var errorMessage: String?

    private var isEditing: Bool { destination != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Heading to")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            TravelTextField(title: "City", text: $city, submitLabel: .next)
                            TravelTextField(title: "Country", text: $country, submitLabel: .next)
                        }
                        .travelCard()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("How you leave")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Picker("Mode", selection: $leaveMode) {
                                ForEach(LeaveMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppAccent"))

                            Picker("Forecast on leave day", selection: $forecast) {
                                ForEach(ForecastCondition.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppAccent"))

                            Toggle("Set leave time", isOn: $hasPlannedDate)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .tint(Color("AppAccent"))

                            if hasPlannedDate {
                                DatePicker(
                                    "Door time",
                                    selection: $plannedDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .foregroundStyle(Color("AppTextPrimary"))
                                .tint(Color("AppAccent"))
                                .colorScheme(.dark)
                            }

                            Toggle("Already left", isOn: $isVisited)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .tint(Color("AppAccent"))

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bag limit \(bagLimitKg, specifier: "%.0f") kg")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                Slider(value: $bagLimitKg, in: 5...32, step: 1)
                                    .tint(Color("AppAccent"))
                            }

                            TravelTextField(
                                title: "Door notes",
                                text: $notes,
                                axis: .vertical,
                                lineLimit: 3...6
                            )
                        }
                        .travelCard()

                        if !isEditing {
                            Toggle("Build a bag list from this mode", isOn: $createPackingList)
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
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(isEditing ? "Edit leave" : "New leave")
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
        .background(Color.clear)
        .presentationDetents([.large])
    }

    private func populate() {
        guard let destination else { return }
        country = destination.country
        city = destination.city
        notes = destination.notes
        isVisited = destination.isVisited
        leaveMode = destination.leaveMode
        forecast = destination.forecast
        bagLimitKg = destination.bagLimitKg
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
                isVisited: isVisited,
                leaveMode: leaveMode,
                forecast: forecast,
                bagLimitKg: bagLimitKg
            )
            if ok {
                dismiss()
            } else {
                errorMessage = "Enter city and country. Duplicate leaves are not allowed."
            }
        } else {
            if store.isDuplicateDestination(country: country, city: city) {
                errorMessage = "This city and country combination already exists."
                return
            }
            if store.addDestination(
                country: country,
                city: city,
                notes: notes,
                plannedDate: date,
                isVisited: isVisited,
                createPackingList: createPackingList,
                leaveMode: leaveMode,
                forecast: forecast,
                bagLimitKg: bagLimitKg
            ) != nil {
                dismiss()
            } else {
                errorMessage = "Could not save. Check city and country."
            }
        }
    }
}
