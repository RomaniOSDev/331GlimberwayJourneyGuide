import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainShellView()
            } else {
                OnboardingView {
                    store.completeOnboarding()
                }
            }
        }
        .environmentObject(store)
    }
}
