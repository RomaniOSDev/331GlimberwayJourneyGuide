import SwiftUI

struct MainShellView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: JourneyTab = .destinations
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            TicketTabBar(selection: $selectedTab) {
                showSettings = true
            }

            Group {
                switch selectedTab {
                case .destinations:
                    DestinationsListView()
                case .packing:
                    PackingTripsListView()
                case .phrases:
                    PhrasesGuideView()
                case .stats:
                    JourneyStatsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .appScreenBackground()
        .dismissKeyboardOnTap()
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
        }
        .onChange(of: store.navigationTarget) { target in
            guard let target else { return }
            switch target {
            case .packing:
                selectedTab = .packing
                store.clearNavigationTarget()
            case .phrases:
                selectedTab = .phrases
            }
        }
    }
}
