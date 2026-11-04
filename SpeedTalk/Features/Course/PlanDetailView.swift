import SwiftUI
import SwiftData
import SpeedTalkCore

struct PlanDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]
    @Query private var phraseProgress: [PhraseProgress]
    @State private var showCertificate = false

    let plan: Curriculum.Plan

    var body: some View {
        List {
            if plan.stages.isEmpty {
                Section {
                    Text("这个方案的 1800 句还在制作中，先把 01 练顺。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("三个阶段") {
                    ForEach(plan.stages) { stage in
                        NavigationLink {
                            StageListView(plan: plan, stage: stage)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(stage.id.uppercased()) · \(stage.title)").font(.headline)
                                Text("\(stage.days.count) 天 · \(stage.days.count * 5) 句")
                                    .font(.captionLabel)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if progress?.isCompleted == true {
                    Section {
                        Button {
                            showCertificate = true
                        } label: {
                            Label("查看通关证书", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(Theme.positive)
                        }
                    }
                }
                Section {
                    Button(action: setActive) {
                        Text(isActive ? "当前在学" : "设为当前方案")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isActive)
                }
            }
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCertificate) {
            PlanCertificateView(
                planID: plan.id,
                title: plan.title,
                subtitle: plan.subtitle,
                totalDays: plan.totalDayCount,
                totalPhrases: plan.totalPhraseCount,
                masteredCount: masteredCount,
                streak: profiles.first?.streak ?? 0,
                finishedAt: progress?.finishedAt
            )
        }
    }

    private var progress: PlanProgress? { progressList.first { $0.planID == plan.id } }

    private var masteredCount: Int {
        phraseProgress.filter { $0.phraseID.hasPrefix("\(plan.id)-") && $0.masteryLevel >= 4 }.count
    }

    private var isActive: Bool { (profiles.first?.activePlan ?? "01") == plan.id }

    private func setActive() {
        let profile = profiles.first ?? {
            let created = UserProfile()
            modelContext.insert(created)
            return created
        }()
        profile.activePlan = plan.id
        if progressList.first(where: { $0.planID == plan.id }) == nil {
            modelContext.insert(PlanProgress(planID: plan.id))
        }
        try? modelContext.save()
    }
}
