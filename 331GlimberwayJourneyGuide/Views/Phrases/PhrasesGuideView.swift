import SwiftUI

struct TimelineBoardView: View {
    @EnvironmentObject private var store: AppDataStore

    private var departure: Destination? { store.timelineDeparture }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AssetHero(
                    imageName: "imgPhrases",
                    title: "Clock",
                    subtitle: "T−24h · T−3h · T−30m from door time."
                )

                if let departure {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(departure.displayTitle)
                            .font(.headline)
                            .foregroundStyle(Color("AppTextPrimary"))
                        if let date = departure.plannedDate {
                            Text(date.formatted(date: .complete, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Toggle("I'm at the gate", isOn: Binding(
                            get: { departure.airportMode },
                            set: { store.setAirportMode(destinationId: departure.id, enabled: $0) }
                        ))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .tint(Color("AppAccent"))
                    }
                    .travelCard()

                    ForEach(TimelinePhase.allCases) { phase in
                        let tasks = departure.visibleTimelineTasks.filter { $0.phase == phase }
                        if !tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(phase.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color("AppAccent"))
                                ForEach(tasks) { task in
                                    Button {
                                        store.toggleTimelineTask(destinationId: departure.id, taskId: task.id)
                                    } label: {
                                        HStack(alignment: .top, spacing: 10) {
                                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(task.isDone ? Color.green : Color("AppTextSecondary"))
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.title)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundStyle(Color("AppTextPrimary"))
                                                    .strikethrough(task.isDone)
                                                if !task.detail.isEmpty {
                                                    Text(task.detail)
                                                        .font(.caption)
                                                        .foregroundStyle(Color("AppTextSecondary"))
                                                }
                                                if let date = departure.plannedDate {
                                                    Text(task.fireDate(from: date).formatted(date: .omitted, time: .shortened))
                                                        .font(.caption2.weight(.semibold))
                                                        .foregroundStyle(Color("AppAccent"))
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .travelCard()
                        }
                    }
                } else {
                    EmptyStateCard(
                        symbol: "clock.badge.exclamationmark",
                        title: "No door time yet",
                        message: "Add a leave on the Leave tab and set the hour you walk out. The clock is empty until then."
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .clearScrollBackground()
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
    }
}

struct PhrasesGuideView: View {
    var body: some View {
        TimelineBoardView()
    }
}
