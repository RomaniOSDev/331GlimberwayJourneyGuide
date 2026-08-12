import SwiftUI

struct PhrasePracticeView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let language: PhraseLanguage

    @State private var deck: [PhraseEntry] = []
    @State private var index = 0
    @State private var showAnswer = false
    @State private var correctCount = 0
    @State private var finished = false

    private var current: PhraseEntry? {
        guard index < deck.count else { return nil }
        return deck[index]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Label("Streak \(store.phraseUserData.practice.currentStreak)", systemImage: "flame.fill")
                        .foregroundStyle(Color("AppAccent"))
                    Spacer()
                    Text("Best \(store.phraseUserData.practice.bestStreak)")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .font(.subheadline.weight(.semibold))
                .travelCard()

                if finished {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session complete")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text("You recalled \(correctCount) of \(deck.count) phrases.")
                            .foregroundStyle(Color("AppTextSecondary"))
                        Button("Practice again") {
                            store.recordPracticeSession(correctAnswers: correctCount)
                            restart()
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                        Button("Done") {
                            store.recordPracticeSession(correctAnswers: correctCount)
                            dismiss()
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                    }
                    .travelCard()
                    Spacer()
                } else if let phrase = current {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What is this in \(language.title)?")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                        Text(phrase.english)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))

                        if showAnswer {
                            Text(phrase.translation)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                            Text(phrase.pronunciation)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        } else {
                            Text("Think of the phrase, then reveal.")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .travelCard()

                    if showAnswer {
                        HStack(spacing: 12) {
                            Button("Missed") { advance(correct: false) }
                                .buttonStyle(PrimaryGradientButtonStyle())
                            Button("Got it") { advance(correct: true) }
                                .buttonStyle(PrimaryGradientButtonStyle())
                        }
                    } else {
                        Button("Reveal answer") { showAnswer = true }
                            .buttonStyle(PrimaryGradientButtonStyle())
                    }

                    Text("Card \(index + 1) of \(deck.count)")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    Spacer()
                } else {
                    EmptyStateCard(
                        symbol: "text.bubble",
                        title: "No phrases",
                        message: "This language has no practice cards yet."
                    )
                    Spacer()
                }
            }
            .padding(16)
            .appScreenBackground()
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if correctCount > 0 {
                            store.recordPracticeSession(correctAnswers: correctCount)
                        }
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            .onAppear(perform: restart)
        }
    }

    private func restart() {
        deck = PhraseCatalog.phrases(language: language, category: .greetings)
            + PhraseCatalog.phrases(language: language, category: .transport)
            + PhraseCatalog.phrases(language: language, category: .dining)
        deck.shuffle()
        if deck.count > 8 {
            deck = Array(deck.prefix(8))
        }
        index = 0
        showAnswer = false
        correctCount = 0
        finished = deck.isEmpty
    }

    private func advance(correct: Bool) {
        if correct { correctCount += 1 }
        if index + 1 >= deck.count {
            finished = true
        } else {
            index += 1
            showAnswer = false
        }
    }
}
