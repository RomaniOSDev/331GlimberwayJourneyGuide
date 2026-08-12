import SwiftUI

extension View {
    func appScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color("AppBackground")
                    .overlay {
                        Image("bgRoadTrip")
                            .resizable()
                            .scaledToFill()
                            .opacity(0.30)
                    }
                    .clipped()
                    .ignoresSafeArea()
            }
    }
}
