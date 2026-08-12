import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    settingsButton(title: "Rate Us", systemImage: "star.fill") {
                        requestReview()
                    }
                    settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                        if let url = URL(string: AppLinks.privacy) {
                            UIApplication.shared.open(url)
                        }
                    }
                    settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                        if let url = URL(string: AppLinks.terms) {
                            UIApplication.shared.open(url)
                        }
                    }
                    settingsButton(title: "Replay Onboarding", systemImage: "sparkles") {
                        store.resetOnboardingFlag()
                        dismiss()
                    }
                    settingsButton(title: "Reset All Data", systemImage: "trash.fill", destructive: true) {
                        showResetConfirm = true
                    }
                }
                .padding(16)
            }
            .appScreenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .confirmationDialog(
                "Reset destinations, packing lists, and phrase notes?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) {
                    store.resetAllData()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func settingsButton(
        title: String,
        systemImage: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(destructive ? Color.red.opacity(0.9) : Color("AppAccent"))
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(destructive ? Color.red.opacity(0.95) : Color("AppTextPrimary"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(14)
            .travelCard()
        }
        .buttonStyle(.plain)
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
