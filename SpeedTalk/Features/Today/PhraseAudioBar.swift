import SwiftUI
import SpeedTalkCore

struct PhraseAudioBar: View {
    let phrase: Phrase
    @State private var player = SpeechPlayer()

    var body: some View {
        HStack(spacing: 10) {
            ForEach(SpeechPlayer.Speed.allCases, id: \.self) { speed in
                Button {
                    player.speak(phrase.en, speed: speed)
                } label: {
                    Label(speed.title, systemImage: "speaker.wave.2")
                        .font(.captionLabel)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.accent.opacity(0.12), in: Capsule())
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            if player.isSpeaking {
                Button("停") { player.stop() }
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
