import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Form {
            Picker("提醒时间", selection: hourBinding) {
                ForEach(7...23, id: \.self) { hour in
                    Text("\(hour):00").tag(hour)
                }
            }
            Button("开启提醒") {
                Task {
                    let granted = await ReminderScheduler.requestAuthorization()
                    if granted {
                        await ReminderScheduler.schedule(hour: profiles.first?.reminderHour ?? 20)
                    }
                }
            }
            Button("关闭提醒", role: .destructive) {
                ReminderScheduler.cancel()
            }
        }
        .navigationTitle("每日提醒")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hourBinding: Binding<Int> {
        Binding(
            get: { profiles.first?.reminderHour ?? 20 },
            set: { newValue in
                profiles.first?.reminderHour = newValue
                try? modelContext.save()
                Task { await ReminderScheduler.schedule(hour: newValue) }
            }
        )
    }
}
