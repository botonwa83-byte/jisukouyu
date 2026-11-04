import SwiftUI
import SpeedTalkCore

struct PhraseDetailView: View {
    let phrase: Phrase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("怎么用") {
                    Text(phrase.context)
                }
                section("发音要点") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(phrase.pronunciation.ipa)
                            .font(.system(.subheadline, design: .monospaced))
                        ForEach(phrase.pronunciation.notes, id: \.self) { note in
                            Label(note, systemImage: "waveform")
                                .font(.subheadline)
                        }
                    }
                }
                section("换个说法") {
                    ForEach(phrase.variants, id: \.self) { variant in
                        Text(variant).font(.body)
                    }
                }
                if let avoid = phrase.avoid {
                    section("别说成") {
                        Text(avoid)
                            .font(.body)
                            .foregroundStyle(Theme.danger)
                    }
                }
                if let transfer = phrase.transfer {
                    section("换个词也能用") {
                        Text(transfer)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.paper)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.captionLabel).foregroundStyle(.secondary)
            content()
        }
    }
}
