import SwiftUI
import Charts

struct JourneyStatsView: View {
    @EnvironmentObject private var store: AppDataStore

    private var visitedCount: Int {
        store.destinations.filter(\.isVisited).count
    }

    private var plannedCount: Int {
        store.destinations.filter { !$0.isVisited }.count
    }

    private var statusSlices: [StatusSlice] {
        [
            StatusSlice(title: "Visited", count: visitedCount, color: Color.green.opacity(0.85)),
            StatusSlice(title: "Planned", count: plannedCount, color: Color("AppAccent"))
        ].filter { $0.count > 0 }
    }

    private var packingBars: [PackingBar] {
        store.packingTrips
            .sorted { $0.tripName.localizedCaseInsensitiveCompare($1.tripName) == .orderedAscending }
            .prefix(8)
            .map { trip in
                let total = max(trip.totalCount, 1)
                let percent = Int((Double(trip.packedCount) / Double(total) * 100).rounded())
                return PackingBar(name: trip.tripName, percent: percent)
            }
    }

    private var favoriteBars: [FavoriteBar] {
        PhraseLanguage.allCases.compactMap { language in
            let count = store.phraseUserData.favoriteIds.reduce(into: 0) { result, id in
                if let phrase = PhraseCatalog.phrase(id: id), phrase.language == language {
                    result += 1
                }
            }
            guard count > 0 else { return nil }
            return FavoriteBar(language: language.title, count: count)
        }
    }

    private var upcomingByMonth: [MonthBar] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var buckets: [String: (date: Date, count: Int)] = [:]
        for destination in store.destinations {
            guard let date = destination.plannedDate, !destination.isVisited else { continue }
            let comps = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: comps) else { continue }
            let key = formatter.string(from: monthStart)
            let current = buckets[key]?.count ?? 0
            buckets[key] = (monthStart, current + 1)
        }
        return buckets
            .map { MonthBar(label: $0.key, count: $0.value.count, sortDate: $0.value.date) }
            .sorted { $0.sortDate < $1.sortDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionBanner(imageName: "bannerPassport", height: 120)

                HStack(spacing: 10) {
                    StatTile(title: "Places", value: "\(store.destinations.count)")
                    StatTile(title: "Lists", value: "\(store.packingTrips.count)")
                    StatTile(title: "Favorites", value: "\(store.phraseUserData.favoriteIds.count)")
                }

                chartCard(title: "Trip status") {
                    if statusSlices.isEmpty {
                        emptyLabel("Add destinations to see status.")
                    } else {
                        Chart(statusSlices) { slice in
                            BarMark(
                                x: .value("Status", slice.title),
                                y: .value("Count", slice.count)
                            )
                            .foregroundStyle(slice.color)
                            .cornerRadius(6)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.15))
                                AxisValueLabel {
                                    if let intVal = value.as(Int.self) {
                                        Text("\(intVal)")
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                    }
                                }
                            }
                        }
                        .frame(height: 180)

                        HStack(spacing: 16) {
                            ForEach(statusSlices) { slice in
                                HStack(spacing: 6) {
                                    Circle().fill(slice.color).frame(width: 8, height: 8)
                                    Text("\(slice.title): \(slice.count)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                }
                            }
                        }
                    }
                }

                chartCard(title: "Packing readiness") {
                    if packingBars.isEmpty {
                        emptyLabel("Create a packing list to track progress.")
                    } else {
                        Chart(packingBars) { bar in
                            BarMark(
                                x: .value("Ready %", bar.percent),
                                y: .value("Trip", bar.name)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color("AppPrimary"), Color("AppAccent")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(4)
                        }
                        .chartXScale(domain: 0...100)
                        .chartXAxis {
                            AxisMarks(values: [0, 50, 100]) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.15))
                                AxisValueLabel {
                                    if let intVal = value.as(Int.self) {
                                        Text("\(intVal)%")
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let name = value.as(String.self) {
                                        Text(name)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .frame(height: CGFloat(max(160, packingBars.count * 36)))
                    }
                }

                chartCard(title: "Upcoming by month") {
                    if upcomingByMonth.isEmpty {
                        emptyLabel("Set planned dates to see the timeline.")
                    } else {
                        Chart(upcomingByMonth) { bar in
                            BarMark(
                                x: .value("Month", bar.label),
                                y: .value("Trips", bar.count)
                            )
                            .foregroundStyle(Color("AppPrimary"))
                            .cornerRadius(5)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.15))
                                AxisValueLabel {
                                    if let intVal = value.as(Int.self) {
                                        Text("\(intVal)")
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                }

                chartCard(title: "Favorite phrases") {
                    if favoriteBars.isEmpty {
                        emptyLabel("Heart a few phrases to fill this chart.")
                    } else {
                        Chart(favoriteBars) { bar in
                            BarMark(
                                x: .value("Language", bar.language),
                                y: .value("Favorites", bar.count)
                            )
                            .foregroundStyle(Color("AppAccent"))
                            .cornerRadius(5)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.white.opacity(0.15))
                                AxisValueLabel {
                                    if let intVal = value.as(Int.self) {
                                        Text("\(intVal)")
                                            .foregroundStyle(Color("AppTextSecondary"))
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(label)
                                            .foregroundStyle(Color("AppTextPrimary"))
                                    }
                                }
                            }
                        }
                        .frame(height: 180)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color("AppTextPrimary"))
            content()
        }
        .travelCard()
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Color("AppTextSecondary"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

private struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color("AppTextPrimary"))
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .travelCard()
    }
}

private struct StatusSlice: Identifiable {
    var id: String { title }
    let title: String
    let count: Int
    let color: Color
}

private struct PackingBar: Identifiable {
    var id: String { name }
    let name: String
    let percent: Int
}

private struct FavoriteBar: Identifiable {
    var id: String { language }
    let language: String
    let count: Int
}

private struct MonthBar: Identifiable {
    var id: String { label }
    let label: String
    let count: Int
    let sortDate: Date
}
