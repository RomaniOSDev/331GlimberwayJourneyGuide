import SwiftUI
import PhotosUI
import UIKit

struct DestinationHubView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destinationId: UUID

    @State private var showEditor = false
    @State private var diaryText = ""
    @State private var diaryDay = Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var reminderDays: Int = 3

    private var destination: Destination? {
        store.destination(for: destinationId)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let destination {
                    VStack(alignment: .leading, spacing: 14) {
                        countdownCard(destination)
                        checklistCard(destination)
                        seasonTipsCard(destination)
                        reminderCard(destination)
                        diaryCard(destination)
                        quickLinks(destination)
                    }
                    .padding(16)
                } else {
                    Text("This place is no longer available.")
                        .foregroundStyle(Color("AppTextSecondary"))
                        .travelCard()
                        .padding(16)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .appScreenBackground()
            .navigationTitle(destination?.displayTitle ?? "Trip")
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
            .onAppear {
                reminderDays = destination?.reminderDaysBefore ?? 3
            }
            .onChange(of: selectedPhoto) { item in
                Task { await handlePhoto(item) }
            }
        }
    }

    private func countdownCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Departure countdown")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            if destination.isVisited {
                Text("Marked as visited — nice work.")
                    .foregroundStyle(Color("AppTextSecondary"))
            } else if let days = destination.daysUntilTrip {
                if days > 0 {
                    Text("\(days) day\(days == 1 ? "" : "s") to go")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                } else if days == 0 {
                    Text("Trip day is today")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color("AppAccent"))
                } else {
                    Text("Planned date has passed")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                if let date = destination.plannedDate {
                    Text(date.formatted(date: .complete, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            } else {
                Text("Set a planned date to start the countdown.")
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .travelCard()
    }

    private func checklistCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pre-departure checklist")
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text("\(destination.checklistDoneCount)/\(destination.checklistItems.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            ForEach(destination.checklistItems) { item in
                Button {
                    store.toggleChecklistItem(destinationId: destination.id, itemId: item.id)
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

    private func seasonTipsCard(_ destination: Destination) -> some View {
        let tipSet = SeasonPackingTips.tips(for: destination)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Season packing tips")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Text("Based on \(tipSet.season.title.lowercased()) travel dates")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))
            ForEach(tipSet.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AppPrimary"))
                        .padding(.top, 2)
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .travelCard()
    }

    private func reminderCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trip reminder")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Toggle("Remind me before the trip", isOn: Binding(
                get: { destination.reminderEnabled },
                set: { store.setReminder(destinationId: destination.id, enabled: $0, daysBefore: reminderDays) }
            ))
            .foregroundStyle(Color("AppTextPrimary"))
            .tint(Color("AppAccent"))

            Stepper("Days before: \(reminderDays)", value: $reminderDays, in: 1...30)
                .foregroundStyle(Color("AppTextPrimary"))
                .onChange(of: reminderDays) { value in
                    store.setReminder(
                        destinationId: destination.id,
                        enabled: destination.reminderEnabled,
                        daysBefore: value
                    )
                }

            Text("Needs a planned date. Uses a local notification only.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .travelCard()
    }

    private func diaryCard(_ destination: Destination) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trip diary")
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            Text("Short notes and optional photos for each day.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))

            DatePicker("Day", selection: $diaryDay, displayedComponents: .date)
                .foregroundStyle(Color("AppTextPrimary"))
                .tint(Color("AppAccent"))
                .colorScheme(.dark)

            TravelTextField(title: "Diary note", text: $diaryText, axis: .vertical, lineLimit: 2...5)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Attach photo", systemImage: "photo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
            }

            Button("Save diary entry") {
                _ = store.addDiaryEntry(
                    destinationId: destination.id,
                    text: diaryText,
                    day: diaryDay,
                    photoFileName: nil
                )
                diaryText = ""
            }
            .buttonStyle(PrimaryGradientButtonStyle())

            let entries = store.diaryEntries(for: destination.id)
            if entries.isEmpty {
                Text("No diary entries yet.")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(entry.dayLabel)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppAccent"))
                            Spacer()
                            Button("Delete", role: .destructive) {
                                store.deleteDiaryEntry(entry)
                            }
                            .font(.caption.weight(.semibold))
                        }
                        if !entry.text.isEmpty {
                            Text(entry.text)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextPrimary"))
                        }
                        if let image = DiaryPhotoStore.loadImage(fileName: entry.photoFileName) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 140)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .travelCard()
    }

    private func quickLinks(_ destination: Destination) -> some View {
        VStack(spacing: 10) {
            Button(destination.isVisited ? "Mark as planned" : "Mark as visited") {
                store.markDestinationVisited(destination, visited: !destination.isVisited)
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: .infinity)

            Button("Open packing list") {
                store.openPacking(for: destination)
                dismiss()
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: .infinity)

            Button("Suggested phrases") {
                store.openSuggestedPhrases(for: destination)
                dismiss()
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .frame(maxWidth: .infinity)
        }
    }

    private func handlePhoto(_ item: PhotosPickerItem?) async {
        guard let item, let destination else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        // Compress lightly for local storage
        let image = UIImage(data: data)
        let jpeg = image?.jpegData(compressionQuality: 0.72) ?? data
        guard let fileName = DiaryPhotoStore.saveJPEG(jpeg) else { return }
        await MainActor.run {
            _ = store.addDiaryEntry(
                destinationId: destination.id,
                text: diaryText,
                day: diaryDay,
                photoFileName: fileName
            )
            diaryText = ""
            selectedPhoto = nil
        }
    }
}
