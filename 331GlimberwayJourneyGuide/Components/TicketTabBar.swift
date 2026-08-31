import SwiftUI

enum JourneyTab: String, CaseIterable, Identifiable {
    case leave
    case clock
    case bags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leave: return "Leave"
        case .clock: return "Clock"
        case .bags: return "Bags"
        }
    }

    var symbol: String {
        switch self {
        case .leave: return "door.left.hand.open"
        case .clock: return "clock.arrow.circlepath"
        case .bags: return "scalemass.fill"
        }
    }
}

struct ClockNotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let notch: CGFloat = 7
        path.move(to: CGPoint(x: rect.minX + 16, y: rect.minY))
        var x = rect.minX + 28
        while x < rect.maxX - 28 {
            path.addLine(to: CGPoint(x: x - 4, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.minY + notch))
            path.addLine(to: CGPoint(x: x + 4, y: rect.minY))
            x += 22
        }
        path.addLine(to: CGPoint(x: rect.maxX - 16, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + 16),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 16))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 16, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + 16, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - 16),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + 16))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 16, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

struct TicketTabBar: View {
    @Binding var selection: JourneyTab
    var onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
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
                        .padding(.vertical, 9)
                        .foregroundStyle(selection == tab ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selection == tab ? Color("AppAccent").opacity(0.32) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(9)
                        .background(
                            Circle()
                                .fill(Color("AppSurface").opacity(0.85))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 10)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppSurface").opacity(0.98),
                        Color("AppPrimary").opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(ClockNotchShape())
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}
