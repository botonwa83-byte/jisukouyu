import Testing
import Foundation
@testable import SpeedTalkCore

@Test func coreVersionIsExposed() {
    let parts = SpeedTalkVersion.current.split(separator: ".")
    #expect(parts.count == 3)
    #expect(parts.allSatisfy { Int($0) != nil })
}
