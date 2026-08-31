import SwiftUI
import PhotosUI
import UIKit

struct DocumentWalletView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destinationId: UUID

    @State private var title = ""
    @State private var kind: DocumentKind = .passport
    @State private var hasExpiry = false
    @State private var expiresOn = Date().addingTimeInterval(365 * 24 * 60 * 60)
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var errorMessage: String?

    private var destination: Destination? {
        store.destination(for: destinationId)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Photos stay in the app folder on this phone. No account, no upload.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .travelCard()

                        if let destination {
                            if destination.documents.isEmpty {
                                EmptyStateCard(
                                    symbol: "person.text.rectangle",
                                    title: "Pouch is empty",
                                    message: "Add a passport page or ticket screenshot so expiry is visible on leave day."
                                )
                            } else {
                                ForEach(destination.documents) { doc in
                                    documentRow(doc)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Add to pouch")
                                .font(.headline)
                                .foregroundStyle(Color("AppTextPrimary"))
                            TravelTextField(title: "Label", text: $title)
                            Picker("Kind", selection: $kind) {
                                ForEach(DocumentKind.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppAccent"))
                            Toggle("Has expiry", isOn: $hasExpiry)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .tint(Color("AppAccent"))
                            if hasExpiry {
                                DatePicker("Expires", selection: $expiresOn, displayedComponents: .date)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .tint(Color("AppAccent"))
                                    .colorScheme(.dark)
                            }
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Attach photo", systemImage: "photo")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppAccent"))
                            }
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Color.red.opacity(0.95))
                            }
                            Button("Save in pouch") {
                                Task { await saveDocument() }
                            }
                            .buttonStyle(PrimaryGradientButtonStyle())
                            .frame(maxWidth: .infinity)
                        }
                        .travelCard()
                    }
                    .padding(16)
                }
                .clearScrollBackground()
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .navigationTitle("Document pouch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
        }
        .background(Color.clear)
    }

    private func documentRow(_ doc: TravelDocument) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: doc.kind.symbol)
                    .foregroundStyle(Color("AppAccent"))
                Text(doc.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Button("Remove", role: .destructive) {
                    store.deleteDocument(doc)
                }
                .font(.caption.weight(.semibold))
            }
            if let expires = doc.expiresOn {
                Text(doc.isExpired ? "Expired \(expires.formatted(date: .abbreviated, time: .omitted))" : "Expires \(expires.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(doc.isExpired || doc.expiresSoon ? Color.red.opacity(0.9) : Color("AppTextSecondary"))
            }
            if let image = DiaryPhotoStore.loadImage(fileName: doc.photoFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .travelCard()
    }

    private func saveDocument() async {
        let label = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else {
            errorMessage = "Give the document a label."
            return
        }
        var fileName: String?
        if let selectedPhoto, let data = try? await selectedPhoto.loadTransferable(type: Data.self) {
            let image = UIImage(data: data)
            let jpeg = image?.jpegData(compressionQuality: 0.72) ?? data
            fileName = DiaryPhotoStore.saveJPEG(jpeg)
        }
        let document = TravelDocument(
            destinationId: destinationId,
            kind: kind,
            title: label,
            expiresOn: hasExpiry ? expiresOn : nil,
            photoFileName: fileName
        )
        await MainActor.run {
            store.addDocument(document)
            title = ""
            selectedPhoto = nil
            errorMessage = nil
        }
    }
}

struct PhrasePracticeView: View {
    var body: some View {
        EmptyView()
    }
}
