import SwiftUI
import SwiftData
import SpeedTalkCore

struct StageListView: View {
    let plan: Curriculum.Plan
    let stage: Curriculum.Plan.Stage

    @Query private var progressList: [PlanProgress]

    private var progress: PlanProgress? { progressList.first { $0.planID == plan.id } }

    var body: some View {
        List {
            ForEach(stage.units, id: \.index) { unit in
                Section("\(unit.index). \(unit.title)") {
                    ForEach(unit.days) { day in
                        NavigationLink {
                            DayDetailView(phraseIDs: day.phraseIDs, title: day.title)
                        } label: {
                            HStack {
                                Text("Day \(day.day)")
                                    .font(.captionLabel)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 58, alignment: .leading)
                                Text(day.title).font(.subheadline)
                                Spacer()
                                if isCompleted(day.day) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.positive)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("\(stage.id.uppercased()) 阶段")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isCompleted(_ day: Int) -> Bool {
        guard let progress, progress.currentStage == stage.id else { return false }
        return day < progress.currentDay
    }
}

struct DayDetailView: View {
    @Environment(AppContainer.self) private var container
    let phraseIDs: [String]
    let title: String

    var body: some View {
        List {
            ForEach(phraseIDs.compactMap { container.content.library.phrase(id: $0) }) { phrase in
                NavigationLink {
                    PhraseDetailScreen(phrase: phrase)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(phrase.en).font(.subheadline.weight(.medium))
                        Text(phrase.zh).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
