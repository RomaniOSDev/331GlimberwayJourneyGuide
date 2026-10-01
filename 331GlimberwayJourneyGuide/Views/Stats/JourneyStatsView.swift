import SwiftUI
import UIKit

struct RadarBoardView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var quickKind: GoBackKind = .secondTrip
    @State private var quickNote = ""

    private var insight: RadarInsight { store.radarInsight }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AssetHero(
                    imageName: "bannerRadar",
                    title: "Radar",
                    subtitle: "Go-back tags and sealed doors."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("\(insight.sealCount) door seals · \(insight.goBackCount) go-backs")
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                    if let top = insight.topMiss {
                        Text("Most common miss · \(top.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppAccent"))
                    }
                    if let peak = insight.peakHour {
                        Text("Peak leave hour · \(hourLabel(peak))")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    if let quiet = insight.quietHour {
                        Text("Suggested quiet window · \(hourLabel(quiet))")
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    if insight.sealCount == 0 {
                        Text("Seal a door or log a go-back to start the radar.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }
                .travelCard()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Log a go-back now")
                        .font(.headline)
                        .foregroundStyle(Color("AppTextPrimary"))
                    Picker("Kind", selection: $quickKind) {
                        ForEach(GoBackKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color("AppAccent"))
                    TravelTextField(title: "What sent you back upstairs?", text: $quickNote)
                    Button("Save miss") {
                        store.logStandaloneGoBack(quickKind, note: quickNote)
                        quickNote = ""
                    }
                    .buttonStyle(PrimaryGradientButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .travelCard()

                if !store.doorSeals.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent seals")
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        ForEach(Array(store.doorSeals.sorted { $0.sealedAt > $1.sealedAt }.prefix(8))) { seal in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(seal.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Text(seal.sealedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(Color("AppTextSecondary"))
                                if let kind = seal.goBackKind {
                                    Text(kind.title)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppAccent"))
                                }
                                if !seal.residue.isEmpty {
                                    Text(seal.residue.joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                            .padding(.bottom, 6)
                        }
                    }
                    .travelCard()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .clearScrollBackground()
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
    }

    private func hourLabel(_ hour: Int) -> String {
        var components = DateComponents()
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

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
        RadarBoardView()
    }
}
