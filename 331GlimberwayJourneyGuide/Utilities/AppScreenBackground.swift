import SwiftUI

struct LeaveAtmosphereBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("AppBackground"),
                    Color("AppPrimary").opacity(0.55),
                    Color("AppBackground")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
                Canvas { context, size in
                    let step: CGFloat = 28
                    var x: CGFloat = 16
                    while x < size.width {
                        var y: CGFloat = 20
                        while y < size.height {
                            let tick = Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6))
                            context.fill(tick, with: .color(Color.white.opacity(0.07)))
                            y += step
                        }
                        x += step
                    }

                    let ring = Path(ellipseIn: CGRect(
                        x: size.width * 0.55,
                        y: -size.height * 0.12,
                        width: size.width * 0.7,
                        height: size.width * 0.7
                    ))
                    context.stroke(ring, with: .color(Color("AppAccent").opacity(0.12)), lineWidth: 18)
                }
                .allowsHitTesting(false)
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func clearScrollBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.clear)
    }

    func appScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                LeaveAtmosphereBackground()
            }
    }

    func leaveScreen<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            LeaveAtmosphereBackground()
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}
