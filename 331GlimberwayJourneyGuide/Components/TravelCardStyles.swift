import SwiftUI

struct PrimaryGradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color("AppPrimary"), Color("AppAccent")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.12 : 0.28), radius: 10, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct TravelCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color("AppSurface").opacity(0.92),
                                Color("AppPrimary").opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 5)
    }
}

extension View {
    func travelCard() -> some View {
        modifier(TravelCardModifier())
    }
}

struct SymbolHero: View {
    let symbol: String
    let title: String
    let subtitle: String
    var height: CGFloat = 128

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color("AppAccent").opacity(0.55),
                    Color("AppPrimary").opacity(0.25),
                    Color("AppSurface").opacity(0.4)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            HStack {
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.18))
                    .padding(.trailing, 18)
                    .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ReadyScoreBadge: View {
    let percent: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: percent >= 80 ? "checkmark.seal.fill" : "clock.badge.checkmark")
                .foregroundStyle(Color("AppAccent"))
            Text("Leave ready \(percent)%")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .travelCard()
    }
}

struct SectionBanner: View {
    let imageName: String
    var height: CGFloat = 120

    var body: some View {
        SymbolHero(
            symbol: symbol(for: imageName),
            title: title(for: imageName),
            subtitle: subtitle(for: imageName),
            height: height
        )
    }

    private func symbol(for name: String) -> String {
        switch name {
        case "imgSuitcase": return "bag.fill"
        case "imgPhrases": return "clock.fill"
        default: return "door.left.hand.open"
        }
    }

    private func title(for name: String) -> String {
        switch name {
        case "imgSuitcase": return "Weigh the bag"
        case "imgPhrases": return "Leave clock"
        default: return "Leave desk"
        }
    }

    private func subtitle(for name: String) -> String {
        switch name {
        case "imgSuitcase": return "On body does not count toward the limit"
        case "imgPhrases": return "T−24h · T−3h · T−30m"
        default: return "Get out the door without a second trip upstairs"
        }
    }
}

struct FirstTripBadge: View {
    var body: some View {
        ReadyScoreBadge(percent: 0)
    }
}
