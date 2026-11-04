import Foundation
import Observation
import SpeedTalkCore

@Observable
final class TodayViewModel {
    private let selector: DailySelector
    private(set) var cards: [Phrase] = []
    private(set) var index: Int = 0
    private(set) var dayTitle: String = ""

    init(selector: DailySelector) {
        self.selector = selector
    }

    func load(snapshot: PlanProgressSnapshot) {
        cards = selector.selection(for: snapshot)
        dayTitle = selector.dayTitle(plan: snapshot.planID, stage: snapshot.stage, day: snapshot.day)
        index = 0
    }

    var current: Phrase? { cards.indices.contains(index) ? cards[index] : nil }
    var isFinished: Bool { index >= cards.count }
    var total: Int { cards.count }

    func advance() {
        guard index < cards.count else { return }
        index += 1
    }

    func restart() { index = 0 }

    func back() {
        guard index > 0 else { return }
        index -= 1
    }
}
