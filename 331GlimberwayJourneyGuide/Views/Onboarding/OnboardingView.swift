import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        (
            "checkmark.seal.fill",
            "Door seal",
            "You do not just tick ‘left’. Park up to three leftovers and tag a go-back if you already ran upstairs."
        ),
        (
            "sunrise.fill",
            "Return brief",
            "The next leave opens with yesterday’s residue already on the pouch list."
        ),
        (
            "dot.radiowaves.left.and.right",
            "Go-back radar",
            "Misses stack by kind and hour so the desk can suggest a quieter window."
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
