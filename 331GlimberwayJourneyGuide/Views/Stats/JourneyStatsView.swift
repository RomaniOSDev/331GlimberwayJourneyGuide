import SwiftUI
import UIKit

struct LeaveReadyCardView: View {
    let destination: Destination
    let bagWeightKg: Double
    let bagLimitKg: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("LEAVE DESK")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppAccent"))
            Text(destination.displayTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            if let date = destination.plannedDate {
                Text(date.formatted(date: .complete, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            Text(destination.leaveMode.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppAccent"))

            HStack {
                metric("Ready", "\(destination.readinessPercent)%")
                metric("House", "\(destination.homeDoneCount)/\(destination.homeItems.count)")
                metric("Clock", "\(destination.timelineDoneCount)/\(destination.timelineTasks.count)")
            }

            Text(String(format: "Bag %.1f / %.0f kg", bagWeightKg, bagLimitKg))
                .font(.headline)
                .foregroundStyle(bagWeightKg > bagLimitKg ? Color.red.opacity(0.9) : Color("AppTextPrimary"))

            Text("Coat stays on the body. House is looped. Pouch is in the jacket.")
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(22)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [Color("AppSurface"), Color("AppPrimary").opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
            Text(value)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct LeaveShareSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let destination: Destination

    @State private var shareImage: UIImage?
    @State private var showShare = false

    private var packing: PackingTrip? {
        store.packingTrip(forDestinationId: destination.id)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LeaveAtmosphereBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        LeaveReadyCardView(
                            destination: destination,
                            bagWeightKg: packing?.bagWeightKg ?? 0,
                            bagLimitKg: packing?.weightLimitKg ?? destination.bagLimitKg
                        )
                        .padding(.top, 8)

                        Text("Share a still image. No account, no live location.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .multilineTextAlignment(.center)

                        Button("Share ready card") {
                            renderAndShare()
                        }
                        .buttonStyle(PrimaryGradientButtonStyle())
                    }
                    .padding(16)
                }
                .clearScrollBackground()
            }
            .navigationTitle("Ready card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("AppAccent"))
                }
            }
            .sheet(isPresented: $showShare) {
                if let shareImage {
                    ActivityView(items: [shareImage])
                }
            }
        }
        .background(Color.clear)
    }

    private func renderAndShare() {
        let card = LeaveReadyCardView(
            destination: destination,
            bagWeightKg: packing?.bagWeightKg ?? 0,
            bagLimitKg: packing?.weightLimitKg ?? destination.bagLimitKg
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        shareImage = renderer.uiImage
        showShare = shareImage != nil
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct JourneyStatsView: View {
    var body: some View {
        EmptyView()
    }
}
