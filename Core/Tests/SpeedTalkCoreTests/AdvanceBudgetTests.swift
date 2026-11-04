import Testing
import Foundation
@testable import SpeedTalkCore

@Test func freshBudgetAllowsTwoDays() {
    let now = Date()
    let budget = AdvanceBudget()
    #expect(budget.remaining(on: now, calendar: .current) == 2)
}

@Test func consumedBudgetStopsAtZero() {
    let now = Date()
    let budget = AdvanceBudget(date: now, used: 2)
    #expect(budget.remaining(on: now, calendar: .current) == 0)
    let next = budget.consuming(1, on: now, calendar: .current)
    #expect(next.used == 2)
    #expect(next.remaining(on: now, calendar: .current) == 0)
}

@Test func budgetResetsOnNextCalendarDay() {
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let budget = AdvanceBudget(date: yesterday, used: 2)
    #expect(budget.remaining(on: now, calendar: .current) == 2)
    let next = budget.consuming(1, on: now, calendar: .current)
    #expect(next.used == 1)
    #expect(next.remaining(on: now, calendar: .current) == 1)
}
