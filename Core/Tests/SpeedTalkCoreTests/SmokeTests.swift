import Testing
@testable import SpeedTalkCore

@Test func coreVersionIsExposed() {
    #expect(SpeedTalkVersion.current == "1.0.0")
}
