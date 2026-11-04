import Testing
@testable import SpeedTalkCore

@Test func coreVersionIsExposed() {
    #expect(SpeedTalkCore.version == "1.0.0")
}
