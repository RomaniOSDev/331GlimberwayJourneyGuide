import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        (
            "airplane.departure",
            "Plan your places",
            "Save destinations, set travel dates, and keep a clear list of where you want to go next."
        ),
        (
            "suitcase.fill",
            "Pack with templates",
            "Start from Beach, City, or Winter lists, copy items between trips, and track what’s ready."
        ),
        (
            "text.bubble.fill",
            "Practice phrases",
            "Browse useful phrases, favorite the ones you need, and build a daily practice streak offline."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 18) {
                        Spacer()
                        Image(systemName: pages[index].symbol)
                            .font(.system(size: 54, weight: .semibold))
                            .foregroundStyle(Color("AppAccent"))
                        Text("Glimberway")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(pages[index].title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Text(pages[index].body)
                            .font(.body)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == pages.count - 1 ? "Start exploring" : "Next") {
                if page == pages.count - 1 {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(PrimaryGradientButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .appScreenBackground()
    }
}
