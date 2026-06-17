import SwiftUI
import WatchKit
import UserNotifications

@main
struct DrinkTrackerWatchApp: App {
    @StateObject private var dataManager = WatchDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .preferredColorScheme(dataManager.appTheme.colorScheme)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // 请求通知权限
        dataManager.requestNotificationPermission { granted in
            if granted && dataManager.reminderInterval > 0 {
                dataManager.scheduleNotifications()
            }
        }
    }
}