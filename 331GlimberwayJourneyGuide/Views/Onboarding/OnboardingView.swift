import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        (
            "door.left.hand.open",
            "One leave at a time",
            "Leave Desk is for the hours before you walk out — not a place to collect dream trips."
        ),
        (
            "clock.arrow.circlepath",
            "T−24h, T−3h, T−30m",
            "The clock nags at the marks that actually matter: pouch, ride, and the last house pass."
        ),
        (
            "scalemass.fill",
            "Lock, weigh, share",
            "Close the house, keep the coat on your body, and send a ready card when the bag is honest."
        )
    ]

    var body: some View {
        ZStack {
            LeaveAtmosphereBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        VStack(spacing: 18) {
                            Spacer()
                            Image(systemName: pages[index].symbol)
                                .font(.system(size: 54, weight: .semibold))
                                .foregroundStyle(Color("AppAccent"))
                            Text(AppResources.brandName)
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
                .clearScrollBackground()

                Button(page == pages.count - 1 ? "Open the desk" : "Next") {
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
        }
        .background(Color.clear)
    }
}
