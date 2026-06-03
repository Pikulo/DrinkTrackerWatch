import SwiftUI

@main
struct DrinkTrackerWatchApp: App {
    @StateObject private var dataManager = WatchDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
