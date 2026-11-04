import SwiftUI
import SwiftData
import SpeedTalkCore

struct TodayView: View {
    @Environment(AppContainer.self) private var container
    @Query private var progressList: [PlanProgress]
    @Query private var profiles: [UserProfile]
    @State private var viewModel: TodayViewModel?

    private var activePlan: String { profiles.first?.activePlan ?? "01" }
    private var progress: PlanProgress? { progressList.first { $0.planID == activePlan } }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel, let phrase = vm.current {
                    VStack(spacing: 16) {
                        header(vm)
                        PhraseCardView(phrase: phrase, position: vm.index + 1, total: vm.total)
                            .id(phrase.id)
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        actions(vm)
                    }
                    .padding(20)
                } else if let vm = viewModel, vm.isFinished {
                    EmptyStateView(title: "今天 5 句学完了", message: "点下面的按钮打卡，明天再来 5 句")
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
            Button {
                withAnimation(.snappy) { vm.advance() }
            } label: {
                Label("下一句", systemImage: "arrow.right")
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

    private func load() {
        guard viewModel == nil else { return }
        let vm = TodayViewModel(selector: container.selector)
        let snapshot = progress?.snapshot ?? .initial(planID: activePlan)
        vm.load(snapshot: snapshot)
        viewModel = vm
    }
}
