import SwiftUI

enum JourneyTab: String, CaseIterable, Identifiable {
    case leave
    case clock
    case bags
    case radar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leave: return "Desk"
        case .clock: return "Clock"
        case .bags: return "Bags"
        case .radar: return "Radar"
        }
    }

    var symbol: String {
        switch self {
        case .leave: return "door.left.hand.open"
        case .clock: return "clock.arrow.circlepath"
        case .bags: return "scalemass.fill"
        case .radar: return "dot.radiowaves.left.and.right"
        }
    }
}

struct TicketTabBar: View {
    @Binding var selection: JourneyTab
    var onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                ForEach(JourneyTab.allCases) { tab in
                    Button {
                        selection = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.symbol)
                                .font(.caption.weight(.semibold))
                            Text(tab.title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selection == tab ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selection == tab ? Color("AppAccent").opacity(0.28) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(8)
                        .background(Circle().fill(Color("AppBackground").opacity(0.55)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color("AppSurface").opacity(0.96))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color("AppAccent").opacity(0.35))
                    .frame(height: 2)
            }
        }
    }
}
