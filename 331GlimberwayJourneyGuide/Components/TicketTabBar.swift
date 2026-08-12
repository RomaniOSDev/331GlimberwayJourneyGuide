import SwiftUI

enum JourneyTab: String, CaseIterable, Identifiable {
    case destinations
    case packing
    case phrases
    case stats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .destinations: return "Places"
        case .packing: return "Packing"
        case .phrases: return "Phrases"
        case .stats: return "Stats"
        }
    }

    var symbol: String {
        switch self {
        case .destinations: return "airplane.departure"
        case .packing: return "suitcase.fill"
        case .phrases: return "text.bubble.fill"
        case .stats: return "chart.bar.fill"
        }
    }
}

struct PerforatedEdgeShape: Shape {
    var notchRadius: CGFloat = 5
    var notchSpacing: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - notchRadius))

        var x = rect.maxX
        while x > rect.minX {
            path.addArc(
                center: CGPoint(x: x - notchRadius, y: rect.maxY),
                radius: notchRadius,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: true
            )
            x -= notchSpacing
        }

        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - notchRadius))
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
                                .fill(selection == tab ? Color("AppPrimary").opacity(0.35) : Color.clear)
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
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color("AppSurface").opacity(0.98),
                        Color("AppPrimary").opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(PerforatedEdgeShape())
            .shadow(color: Color.black.opacity(0.22), radius: 12, y: 6)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }
}
