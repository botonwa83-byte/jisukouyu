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
        return VStack(spacing: 14) {
            EmptyStateView(
                title: planFinished ? "方案通关" : (completedScores.count >= goal ? "今天学完了" : "第 1 组完成"),
                message: planFinished
                    ? "1800 句全部走完，来领你的通关证书"
                    : (completedScores.count >= goal
                        ? "打卡完成，明天再来一组"
                        : "还差 \(goal - completedScores.count) 句，再来一组就打卡")
            )
            if planFinished {
                PrimaryButton(title: "查看通关证书") {
                    showCertificate = true
                }
                .padding(.horizontal, 20)
            } else if completedScores.count < goal {
                PrimaryButton(title: "再学一组") {
                    let next = container.engine
                        .advance(progress?.snapshot ?? .initial(planID: activePlan))
                        .snapshot
                    vm.load(snapshot: next)
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
        for _ in 0..<advanceTimes where !finished {
            let result = container.engine.advance(snapshot)
            snapshot = result.snapshot
            finished = result.didFinishPlan
        }
        target.apply(snapshot)
        if finished {
            target.isCompleted = true
            target.finishedAt = .now
        }
        try? modelContext.save()
        completedScores = []
    }
}
