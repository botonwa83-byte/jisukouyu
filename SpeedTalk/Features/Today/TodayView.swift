import SwiftUI
import SwiftData
import SpeedTalkCore

struct TodayView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var modelContext
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]
    @Query private var phraseProgress: [PhraseProgress]
    @State private var viewModel: TodayViewModel?
    @State private var completedScores: [Int] = []
    @State private var showCertificate = false
    @State private var celebration: StageCelebration?
    @State private var didCheckIn = false

    private var activePlan: String { profiles.first?.activePlan ?? "01" }
    private var progress: PlanProgress? { progressList.first { $0.planID == activePlan } }
    private var goal: Int { profiles.first?.dailyGoal ?? 5 }
    private var masteredForPlan: Int {
        phraseProgress.filter { $0.phraseID.hasPrefix("\(activePlan)-") && $0.masteryLevel >= 4 }.count
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel, let phrase = vm.current {
                    VStack(spacing: 16) {
                        header(vm)
                        PhraseCardView(phrase: phrase, position: vm.index + 1, total: vm.total)
                            .id(phrase.id)
                        PhraseAudioBar(phrase: phrase)
                        actions(vm)
                    }
                    .padding(24)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                } else if let vm = viewModel, vm.isFinished {
                    finishedState(vm)
                } else {
                    ProgressView()
                        .task { load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper.ignoresSafeArea())
            .navigationTitle("今日")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showCertificate) {
            certificateView
        }
        .sheet(item: $celebration) { item in
            StageCompletionView(
                planTitle: container.content.curriculum.plan(id: activePlan)?.title ?? "方案 \(activePlan)",
                stageID: item.stageID,
                stageTitle: item.stageTitle,
                dayCount: item.dayCount,
                phraseCount: item.phraseCount,
                averageScore: item.averageScore,
                nextStageTitle: item.nextStageTitle,
                onContinue: { continueAfterStage(item) }
            )
        }
    }

    private var certificateView: some View {
        let plan = container.content.curriculum.plan(id: activePlan)
        return PlanCertificateView(
            planID: activePlan,
            title: plan?.title ?? "方案 \(activePlan)",
            subtitle: plan?.subtitle ?? "",
            totalDays: plan?.totalDayCount ?? 0,
            totalPhrases: plan?.totalPhraseCount ?? 0,
            masteredCount: masteredForPlan,
            streak: profiles.first?.streak ?? 0,
            finishedAt: progress?.finishedAt
        )
    }

    private func header(_ vm: TodayViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(container.content.curriculum.plan(id: activePlan)?.title ?? "") · \(progress?.currentStage ?? "a") 阶段")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
                Text(vm.dayTitle).font(.headline)
            }
            Spacer()
            Text("Day \(progress?.currentDay ?? 1)")
                .font(.captionLabel)
                .foregroundStyle(.secondary)
        }
    }

    private func actions(_ vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                if let phrase = vm.current {
                    PracticeView(phrase: phrase) { score in
                        completedScores.append(score)
                        if completedScores.count >= goal { checkIn() }
                        vm.advance()
                    }
                }
            } label: {
                Label("按住说", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)

            NavigationLink {
                if let phrase = vm.current { PhraseDetailView(phrase: phrase) }
            } label: {
                Label("详解", systemImage: "text.book.closed")
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
        }
    }

    private func finishedState(_ vm: TodayViewModel) -> some View {
        let planFinished = progress?.isCompleted == true
        let checkedIn = didCheckIn || completedScores.count >= goal
        return VStack(spacing: 14) {
            EmptyStateView(
                title: planFinished ? "方案通关" : (checkedIn ? "今天学完了" : "第 1 组完成"),
                message: planFinished
                    ? "1800 句全部走完，来领你的通关证书"
                    : (checkedIn
                        ? "打卡完成，明天再来一组"
                        : "还差 \(goal - completedScores.count) 句，再来一组就打卡")
            )
            if planFinished {
                PrimaryButton(title: "查看通关证书") {
                    showCertificate = true
                }
                .padding(.horizontal, 20)
            } else {
                PrimaryButton(title: "再学一组") {
                    let base = progress?.snapshot ?? .initial(planID: activePlan)
                    // 已打卡时进度已经推进，直接加载下一天，避免跳过一句。
                    let next = checkedIn ? base : container.engine.advance(base).snapshot
                    vm.load(snapshot: next)
                    didCheckIn = false
                }
                .padding(.horizontal, 20)
            }
            Spacer(minLength: 0)
        }
        .onAppear { autoPresentCertificateIfNeeded() }
    }

    /// 通关后第一次回到今日页自动亮出证书，只亮一次。
    private func autoPresentCertificateIfNeeded() {
        guard progress?.isCompleted == true else { return }
        let key = "certificateShown.\(activePlan)"
        guard UserDefaults.standard.bool(forKey: key) == false else { return }
        UserDefaults.standard.set(true, forKey: key)
        showCertificate = true
    }

    private func load() {
        guard viewModel == nil else { return }
        let vm = TodayViewModel(selector: container.selector)
        let snapshot = progress?.snapshot ?? .initial(planID: activePlan)
        vm.load(snapshot: snapshot)
        viewModel = vm
    }

    private func checkIn() {
        guard let profile = profiles.first else { return }
        let store = ProgressStore(context: modelContext)
        let plan = activePlan
        let stage = progress?.currentStage ?? "a"
        let day = progress?.currentDay ?? 1
        let average = completedScores.reduce(0, +) / max(completedScores.count, 1)
        store.logDayCompletion(
            plan: plan,
            stage: stage,
            day: day,
            completedCount: completedScores.count,
            totalScore: average
        )

        let target = progress ?? {
            let created = PlanProgress(planID: plan)
            modelContext.insert(created)
            return created
        }()

        let advanceTimes = max(1, profile.dailyGoal / 5)
        var snapshot = target.snapshot
        var finished = false
        var finishedStage: String?
        for _ in 0..<advanceTimes where !finished {
            let result = container.engine.advance(snapshot)
            snapshot = result.snapshot
            finished = result.didFinishPlan
            if let stage = result.completedStage { finishedStage = stage }
        }
        target.apply(snapshot)
        if finished {
            target.isCompleted = true
            target.finishedAt = .now
        }
        try? modelContext.save()
        completedScores = []
        didCheckIn = true
        if let stage = finishedStage, finished == false {
            celebration = makeCelebration(
                stage: stage,
                nextSnapshot: snapshot,
                averageScore: average
            )
        }
    }

    /// 阶段收尾时组装庆祝数据；下一阶段快照随庆祝层一起带出，点继续即可切过去。
    private func makeCelebration(
        stage: String,
        nextSnapshot: PlanProgressSnapshot,
        averageScore: Int
    ) -> StageCelebration {
        let plan = container.content.curriculum.plan(id: activePlan)
        let stageModel = plan?.stages.first { $0.id == stage }
        let nextStage = container.service.nextStage(after: stage, plan: activePlan)
        let nextStageTitle = plan?.stages.first { $0.id == nextStage }?.title
        return StageCelebration(
            stageID: stage,
            stageTitle: stageModel?.title ?? "阶段 \(stage)",
            dayCount: stageModel?.dayCount ?? 0,
            phraseCount: stageModel?.phraseCount ?? 0,
            averageScore: averageScore,
            nextStageTitle: nextStageTitle,
            nextSnapshot: nextSnapshot
        )
    }

    private func continueAfterStage(_ item: StageCelebration) {
        if item.nextStageTitle != nil {
            viewModel?.load(snapshot: item.nextSnapshot)
        } else {
            showCertificate = true
        }
    }
}

/// 阶段通关庆祝的临时数据，持有下一阶段快照以便一键切换。
private struct StageCelebration: Identifiable {
    let stageID: String
    let stageTitle: String
    let dayCount: Int
    let phraseCount: Int
    let averageScore: Int
    let nextStageTitle: String?
    let nextSnapshot: PlanProgressSnapshot

    var id: String { stageID }
}
