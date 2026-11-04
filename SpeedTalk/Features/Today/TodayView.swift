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
    /// 速览模式：翻页即推进，不强制跟读；偏好持久化，方便有基础或赶时间的用户。
    @AppStorage("browseModeEnabled") private var browseMode = false

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
                        if browseMode {
                            browseHint
                        }
                        PhraseCardView(phrase: phrase, position: vm.index + 1, total: vm.total)
                            .frame(maxHeight: 480)
                            .id(phrase.id)
                            .gesture(browseSwipe(vm))
                        PhraseAudioBar(phrase: phrase)
                        actions(vm)
                    }
                    .padding(24)
                    .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
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
            VStack(alignment: .trailing, spacing: 6) {
                Text("Day \(progress?.currentDay ?? 1)")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
                modeToggle
            }
        }
    }

    private var modeToggle: some View {
        let tint = browseMode ? Theme.warning : Theme.accent
        return Button {
            withAnimation(.snappy) { browseMode.toggle() }
        } label: {
            Label(browseMode ? "速览" : "跟读", systemImage: browseMode ? "book.pages" : "mic")
                .font(.captionLabel)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(tint.opacity(0.12), in: Capsule())
                .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("modeToggle")
    }

    /// 速览模式下左右滑卡片等于翻页，和「下一句」按钮等价。
    private func browseSwipe(_ vm: TodayViewModel) -> some Gesture {
        DragGesture(minimumDistance: 40)
            .onEnded { value in
                guard browseMode,
                      abs(value.translation.width) > 60,
                      abs(value.translation.width) > abs(value.translation.height)
                else { return }
                if value.translation.width < 0 {
                    advanceBrowsing(vm)
                } else {
                    vm.back()
                }
            }
    }

    private var browseHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "book.pages")
            Text("速览中：点「下一句」一直往前，想练哪句再点麦克风")
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(Theme.warning)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func actions(_ vm: TodayViewModel) -> some View {
        HStack(spacing: 12) {
            if browseMode {
                Button {
                    advanceBrowsing(vm)
                } label: {
                    Label("下一句", systemImage: "chevron.right.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("browseNext")

                practiceEntry(vm, compact: true)
                detailEntry(vm, compact: true)
            } else {
                practiceEntry(vm, compact: false)
                detailEntry(vm, compact: false)
            }
        }
    }

    private func practiceEntry(_ vm: TodayViewModel, compact: Bool) -> some View {
        NavigationLink {
            if let phrase = vm.current {
                PracticeView(phrase: phrase) { score in
                    handlePracticeScore(score, vm: vm)
                }
            }
        } label: {
            if compact {
                iconLabel("练这句", systemImage: "mic.fill", tint: Theme.accent)
            } else {
                Label("按住说", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
    }

    private func detailEntry(_ vm: TodayViewModel, compact: Bool) -> some View {
        NavigationLink {
            if let phrase = vm.current { PhraseDetailView(phrase: phrase) }
        } label: {
            if compact {
                iconLabel("详解", systemImage: "text.book.closed", tint: Theme.ink)
            } else {
                Label("详解", systemImage: "text.book.closed")
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Theme.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(Theme.ink)
            }
        }
        .buttonStyle(.plain)
    }

    private func iconLabel(_ title: String, systemImage: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .frame(minWidth: 56)
        .padding(.vertical, 11)
        .padding(.horizontal, 10)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .foregroundStyle(tint)
    }

    private func handlePracticeScore(_ score: Int, vm: TodayViewModel) {
        completedScores.append(score)
        if completedScores.count >= goal, didCheckIn == false {
            _ = checkIn(completedCount: completedScores.count)
        }
        vm.advance()
    }

    /// 速览模式翻完一组：照常打卡与推进，然后直接载入下一组，保持连续翻页。
    private func advanceBrowsing(_ vm: TodayViewModel) {
        vm.advance()
        guard vm.isFinished else { return }
        let outcome = didCheckIn ? nil : checkIn(completedCount: vm.total)
        guard outcome?.finished != true, celebration == nil else { return }
        didCheckIn = false
        if let target = outcome?.snapshot ?? progress?.snapshot {
            vm.load(snapshot: target)
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

    /// 记录当天打卡并推进进度，返回推进结果；同一组重复调用只生效一次。
    @discardableResult
    private func checkIn(completedCount: Int) -> CheckInOutcome? {
        guard let profile = profiles.first, didCheckIn == false else { return nil }
        let store = ProgressStore(context: modelContext)
        let plan = activePlan
        let stage = progress?.currentStage ?? "a"
        let day = progress?.currentDay ?? 1
        let average = completedScores.reduce(0, +) / max(completedScores.count, 1)
        store.logDayCompletion(
            plan: plan,
            stage: stage,
            day: day,
            completedCount: completedCount,
            totalScore: average,
            profile: profile
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
        return CheckInOutcome(snapshot: snapshot, finished: finished)
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
            didCheckIn = false
            viewModel?.load(snapshot: item.nextSnapshot)
        } else {
            showCertificate = true
        }
    }
}

/// 打卡结果：推进后的进度快照，以及本次是否刚好走完整个方案。
private struct CheckInOutcome {
    let snapshot: PlanProgressSnapshot
    let finished: Bool
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
