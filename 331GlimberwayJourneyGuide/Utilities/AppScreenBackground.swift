import SwiftUI

struct LeaveAtmosphereBackground: View {
    var body: some View {
        ZStack {
            Color("AppBackground")
            Image("bgRoadTrip")
                .resizable()
                .scaledToFill()
                .opacity(0.42)
            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0.55),
                    Color("AppBackground").opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
