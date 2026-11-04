import SwiftUI
import SwiftData
import SpeedTalkCore

struct AchievementWall: View {
    @Query private var records: [AchievementRecord]

    private var unlockedIDs: Set<String> { Set(records.map(\.achievementID)) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AchievementCatalog.all) { definition in
                    let unlocked = unlockedIDs.contains(definition.id)
                    VStack(spacing: 6) {
                        Image(systemName: definition.symbol)
                            .font(.title3)
                            .foregroundStyle(unlocked ? Theme.accent : Color.secondary.opacity(0.4))
                        Text(definition.title)
                            .font(.captionLabel)
                            .foregroundStyle(unlocked ? Theme.ink : .secondary)
                        Text(definition.detail)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 86, height: 96)
                    .background(
                        unlocked ? Theme.accent.opacity(0.08) : Theme.ink.opacity(0.03),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }
}
