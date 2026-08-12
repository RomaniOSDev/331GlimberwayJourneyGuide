import SwiftUI

struct PhrasesGuideView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedLanguage: PhraseLanguage = .spanish
    @State private var selectedCategory: PhraseCategory = .greetings
    @State private var showFavoritesOnly = false
    @State private var selectedPhrase: PhraseEntry?
    @State private var showPractice = false

    private var phrases: [PhraseEntry] {
        var list = PhraseCatalog.phrases(language: selectedLanguage, category: selectedCategory)
        if showFavoritesOnly {
            list = list.filter { store.phraseUserData.isFavorite($0.id) }
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionBanner(imageName: "imgPhrases", height: 130)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Practice streak")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text("\(store.phraseUserData.practice.currentStreak) day streak")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    Spacer()
                    Button("Practice") { showPractice = true }
                        .buttonStyle(PrimaryGradientButtonStyle())
                }
                .travelCard()

                if !store.suggestedPhraseLanguages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggested for your trips")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(store.suggestedPhraseLanguages) { language in
                                    Button {
                                        selectedLanguage = language
                                    } label: {
                                        Text("\(language.flag) \(language.title)")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedLanguage == language ? Color("AppPrimary").opacity(0.45) : Color("AppSurface").opacity(0.7))
                                            )
                                            .foregroundStyle(Color("AppTextPrimary"))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .travelCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Language")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color("AppTextSecondary"))
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(PhraseLanguage.allCases) { language in
                            Text("\(language.flag) \(language.title)").tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color("AppAccent"))
                }
                .travelCard()

                Picker("Category", selection: $selectedCategory) {
                    ForEach(PhraseCategory.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .colorScheme(.dark)
                .padding(.horizontal, 4)

                Toggle("Favorites only", isOn: $showFavoritesOnly)
                    .foregroundStyle(Color("AppTextPrimary"))
                    .tint(Color("AppAccent"))
                    .travelCard()

                if phrases.isEmpty {
                    EmptyStateCard(
                        symbol: "heart.text.square",
                        title: showFavoritesOnly ? "No favorites here" : "No phrases",
                        message: showFavoritesOnly
                            ? "Heart phrases you want to keep close, then filter favorites for quick review."
                            : "Try another category or language to browse useful travel lines."
                    )
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(phrases) { phrase in
                            Button {
                                selectedPhrase = phrase
                            } label: {
                                PhraseRow(
                                    phrase: phrase,
                                    isFavorite: store.phraseUserData.isFavorite(phrase.id),
                                    note: store.phraseUserData.note(for: phrase.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .sheet(item: $selectedPhrase) { phrase in
            PhraseDetailSheet(phrase: phrase)
                .environmentObject(store)
        }
        .sheet(isPresented: $showPractice) {
            PhrasePracticeView(language: selectedLanguage)
                .environmentObject(store)
        }
        .onAppear {
            applyNavigationLanguage()
        }
        .onChange(of: store.navigationTarget) { _ in
            applyNavigationLanguage()
        }
    }

    private func applyNavigationLanguage() {
        guard case let .phrases(language) = store.navigationTarget else { return }
        if let language {
            selectedLanguage = language
        }
        store.clearNavigationTarget()
    }
}

private struct PhraseRow: View {
    let phrase: PhraseEntry
    let isFavorite: Bool
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(phrase.english)
                    .font(.headline)
                    .foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                if isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            Text(phrase.translation)
                .font(.subheadline)
                .foregroundStyle(Color("AppTextPrimary"))
            Text(phrase.pronunciation)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
            if !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .italic()
            }
        }
        .travelCard()
    }
}

struct PhraseDetailSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let phrase: PhraseEntry

    @State private var noteText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(phrase.english)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(phrase.translation)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(phrase.pronunciation)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                    .travelCard()

                    TravelTextField(
                        title: "Custom note",
                        text: $noteText,
                        axis: .vertical,
                        lineLimit: 2...5
                    )
                    .travelCard()

                    Button(store.phraseUserData.isFavorite(phrase.id) ? "Remove from favorites" : "Add to favorites") {
                        store.toggleFavorite(phraseId: phrase.id)
                    }
                    .buttonStyle(PrimaryGradientButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .dismissKeyboardOnTap()
            .appScreenBackground()
            .navigationTitle(phrase.category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        store.setPhraseNote(phraseId: phrase.id, note: noteText)
                        dismiss()
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            .onAppear {
                noteText = store.phraseUserData.note(for: phrase.id)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
