import SwiftUI

struct DestinationHubView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destinationId: UUID

    @State private var showEditor = false
    @State private var showWallet = false
    @State private var showShare = false
    @State private var showSeal = false
    @State private var reminderDays: Int = 3

    private var destination: Destination? {
        store.destination(for: destinationId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    if let destination {
                        VStack(alignment: .leading, spacing: 14) {
                            countdownCard(destination)
                            readinessCard(destination)
                            airportCard(destination)
                            clockPreview(destination)
                            homeCard(destination)
                            forecastCard(destination)
                            reminderCard(destination)
                            documentsPreview(destination)
                            actions(destination)
                        }
                        .padding(16)
                    } else {
                        Text("This leave is no longer on the desk.")
                            .foregroundStyle(Color("AppTextSecondary"))
                            .travelCard()
                            .padding(16)
                    }
                }
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle(destination?.displayTitle ?? "Leave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit") { showEditor = true }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .sheet(isPresented: $showEditor) {
                if let destination {
                    DestinationEditorSheet(destination: destination)
                        .environmentObject(store)
                }
            }
            .sheet(isPresented: $showWallet) {
                DocumentWalletView(destinationId: destinationId)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showShare) {
                if let destination {
                    LeaveShareSheet(destination: destination)
                        .environmentObject(store)
                }
            }
            .sheet(isPresented: $showSeal) {
                if let destination {
                    DoorSealSheet(destination: destination)
                        .environmentObject(store)
                }
            }
            .onAppear {
                reminderDays = destination?.reminderDaysBefore ?? 3
                store.focusedDepartureId = destinationId
            }
        }
        .background(Color.clear)
    }

    private func countdownCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Door countdown")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            if destination.isVisited {
                Text("Already left — desk is closed for this one.")
                    .foregroundStyle(Color("AppTextSecondary"))
            } else if let minutes = destination.minutesUntilDeparture, let date = destination.plannedDate {
                if minutes > 24 * 60, let days = destination.daysUntilTrip {
                    Text("\(days) day\(days == 1 ? "" : "s") to the door")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                } else if minutes > 60 {
                    Text("\(minutes / 60)h \(minutes % 60)m")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                } else if minutes > 0 {
                    Text("\(minutes) minutes")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                } else {
                    Text("Leave now")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                }
                Text(date.formatted(date: .complete, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                Text(destination.leaveMode.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
            } else {
                Text("Set a door time so the clock can fire T−24h, T−3h, and T−30m.")
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .travelCard()
    }

    private func readinessCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Leave ready")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(destination.readinessPercent)%")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
            }
            ProgressView(value: Double(destination.readinessPercent), total: 100)
                .tint(Color("AppAccent"))
            Text("House, clock, pouch, and documents each move the score.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .travelCard()
    }

    private func airportCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("I'm at the gate", isOn: Binding(
                get: { destination.airportMode },
                set: { store.setAirportMode(destinationId: destination.id, enabled: $0) }
            ))
            .foregroundStyle(Color("AppTextPrimary"))
            .tint(Color("AppAccent"))
            Text(destination.airportMode
                 ? "Clock now shows only belt, liquids, and boarding marks."
                 : "Turn this on after security. House tasks drop away.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .travelCard()
    }

    private func clockPreview(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Leave clock")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(destination.timelineDoneCount)/\(destination.timelineTasks.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            ForEach(destination.visibleTimelineTasks.prefix(4)) { task in
                Button {
                    store.toggleTimelineTask(destinationId: destination.id, taskId: task.id)
                } label: {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(task.isDone ? Color.green : Color("AppTextSecondary"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(task.phase.title) · \(task.title)")
                                .foregroundStyle(Color("AppTextPrimary"))
                                .strikethrough(task.isDone)
                            if !task.detail.isEmpty {
                                Text(task.detail)
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            Button("Open full clock") {
                store.openTimeline(for: destination)
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppAccent"))
        }
        .travelCard()
    }

    private func homeCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("House loop")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(destination.homeDoneCount)/\(destination.homeItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Text("This is not the suitcase. This is what you shut before the deadbolt.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
            ForEach(destination.homeItems) { item in
                Button {
                    store.toggleHomeItem(destinationId: destination.id, itemId: item.id)
                } label: {
                    HStack {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isDone ? Color.green : Color("AppTextSecondary"))
                        Text(item.title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .strikethrough(item.isDone)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .travelCard()
    }

    private func forecastCard(_ destination: Destination) -> some View {
        let lines = ForecastPackingAdvisor.tipLines(for: destination.forecast, mode: destination.leaveMode)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Leave-day weather")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Picker("Forecast", selection: Binding(
                get: { destination.forecast },
                set: { store.setForecast(destinationId: destination.id, forecast: $0) }
            )) {
                ForEach(ForecastCondition.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.menu)
            .tint(Color("AppAccent"))
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Button("Add weather extras to the bag") {
                store.applyForecastExtras(toDestinationId: destination.id)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color("AppAccent"))
        }
        .travelCard()
    }

    private func reminderCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clock pings")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Toggle("Ping T−24h, T−3h, T−30m", isOn: Binding(
                get: { destination.reminderEnabled },
                set: { store.setReminder(destinationId: destination.id, enabled: $0, daysBefore: reminderDays) }
            ))
            .foregroundStyle(Color("AppTextPrimary"))
            .tint(Color("AppAccent"))

            Stepper("Also a morning ping \(reminderDays) day(s) before", value: $reminderDays, in: 1...14)
                .foregroundStyle(Color("AppTextPrimary"))
                .onChange(of: reminderDays) { value in
                    store.setReminder(
                        destinationId: destination.id,
                        enabled: destination.reminderEnabled,
                        daysBefore: value
                    )
                }

            Text("Local notifications only. Needs a door time.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .travelCard()
    }

    private func documentsPreview(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Document pouch")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(destination.documents.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            if destination.documents.isEmpty {
                Text("Keep passport and ticket photos on this phone. Nothing is uploaded.")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(destination.documents.prefix(3)) { doc in
                    HStack {
                        Image(systemName: doc.kind.symbol)
                            .foregroundStyle(Color("AppAccent"))
                        Text(doc.title)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        if doc.isExpired {
                            Text("Expired")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.red.opacity(0.9))
                        }
                    }
                }
            }
            Button("Open pouch") { showWallet = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))
        }
        .travelCard()
    }

    private func actions(_ destination: Destination) -> some View {
        VStack(spacing: 10) {
            if destination.isVisited {
                Button("Still home") {
                    store.markDestinationVisited(destination, visited: false)
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity)
            } else {
                Button("Seal the door") {
                    showSeal = true
                }
                .buttonStyle(PrimaryGradientButtonStyle())
                .frame(maxWidth: .infinity)
            }

            Button("Weigh the bag") {
                store.openPacking(for: destination)
                dismiss()
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: .infinity)

            Button("Share ready card") {
                showShare = true
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: .infinity)
        }
    }
}

struct DoorSealSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destination: Destination

    @State private var residue1 = ""
    @State private var residue2 = ""
    @State private var residue3 = ""
    @State private var goBack: GoBackKind?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Door seal")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text("Park up to three leftovers for the next Return Brief. Tag a go-back if you already ran upstairs once.")
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text("House \(destination.homeDoneCount)/\(destination.homeItems.count) · Ready \(destination.readinessPercent)%")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                        .travelCard()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Residue for tomorrow")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            TravelTextField(title: "Carry 1", text: $residue1)
                            TravelTextField(title: "Carry 2", text: $residue2)
                            TravelTextField(title: "Carry 3", text: $residue3)
                        }
                        .travelCard()

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Go-back tag")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Picker("Miss", selection: $goBack) {
                                Text("None").tag(Optional<GoBackKind>.none)
                                ForEach(GoBackKind.allCases) { kind in
                                    Text(kind.title).tag(Optional(kind))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppAccent"))
                            TravelTextField(title: "Note (optional)", text: $note)
                        }
                        .travelCard()

                        Button("Seal and leave") {
                            _ = store.sealDoor(
                                for: destination,
                                residue: [residue1, residue2, residue3],
                                goBackKind: goBack,
                                note: note
                            )
                            dismiss()
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .padding(16)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Seal the door")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .background(Color.clear)
    }
}
