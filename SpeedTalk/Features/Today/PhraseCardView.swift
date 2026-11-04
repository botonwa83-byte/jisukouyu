import SwiftUI
import SpeedTalkCore

struct PhraseCardView: View {
    let phrase: Phrase
    let position: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 8) {
                TagChip(text: phrase.scene.title)
                TagChip(text: phrase.register.title, tint: .secondary)
                Spacer()
                Text("\(position)/\(total)")
                    .font(.captionLabel)
                    .foregroundStyle(.secondary)
            }

            Text(phrase.en)
                .font(.phrase)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(phrase.zh)
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Label(phrase.focus, systemImage: "sparkle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
                Text(phrase.pronunciation.ipa)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.paper, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Theme.ink.opacity(0.06), lineWidth: 1)
        )
    }
}
