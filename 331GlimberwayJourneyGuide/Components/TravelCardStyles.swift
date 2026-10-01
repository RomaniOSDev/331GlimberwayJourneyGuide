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
            .padding(.leading, 6)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color("AppSurface").opacity(0.94))
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color("AppAccent").opacity(0.16), lineWidth: 1)
                    Rectangle()
                        .fill(Color("AppAccent"))
                        .frame(width: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                        .padding(.vertical, 10)
                        .padding(.leading, 6)
                }
            )
            .shadow(color: Color.black.opacity(0.28), radius: 10, y: 5)
    }
}

extension View {
    func travelCard() -> some View {
        modifier(TravelCardModifier())
    }
}

struct AssetHero: View {
    let imageName: String
    let title: String
    let subtitle: String
    var height: CGFloat = 128

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
            LinearGradient(
                colors: [Color("AppBackground").opacity(0.88), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
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

struct SymbolHero: View {
    let symbol: String
    let title: String
    let subtitle: String
    var height: CGFloat = 128

    var body: some View {
        AssetHero(imageName: imageName(for: symbol), title: title, subtitle: subtitle, height: height)
    }

    private func imageName(for symbol: String) -> String {
        switch symbol {
        case "clock.arrow.circlepath", "clock.fill": return "imgPhrases"
        case "scalemass.fill", "bag.fill": return "imgSuitcase"
        case "dot.radiowaves.left.and.right": return "bannerPassport"
        default: return "bannerPassport"
        }
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
        AssetHero(
            imageName: imageName,
            title: title(for: imageName),
            subtitle: subtitle(for: imageName),
            height: height
        )
    }

    private func title(for name: String) -> String {
        switch name {
        case "imgSuitcase": return "Weigh the bag"
        case "imgPhrases": return "Leave clock"
        default: return "Desk"
        }
    }

    private func subtitle(for name: String) -> String {
        switch name {
        case "imgSuitcase": return "On body does not count toward the limit"
        case "imgPhrases": return "T−24h · T−3h · T−30m"
        default: return "Seal the door. Brief the next leave."
        }
    }
}

struct FirstTripBadge: View {
    var body: some View {
        ReadyScoreBadge(percent: 0)
    }
}
