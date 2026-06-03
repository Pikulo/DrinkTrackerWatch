import Foundation
import SwiftUI

// MARK: - Drink Types (Watch version)
enum WatchDrinkType: String, CaseIterable, Identifiable {
    case water = "白水"
    case tea = "茶水"
    case coffee = "咖啡"
    case milk = "牛奶"
    case juice = "果汁"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .water: return "💧"
        case .tea: return "🍵"
        case .coffee: return "☕️"
        case .milk: return "🥛"
        case .juice: return "🧃"
        case .other: return "🫗"
        }
    }
    
    var color: Color {
        switch self {
        case .water: return .blue
        case .tea: return .green
        case .coffee: return .brown
        case .milk: return Color(red: 1.0, green: 0.95, blue: 0.85)
        case .juice: return .orange
        case .other: return .gray
        }
    }
}

// MARK: - Watch Drink Record
struct WatchDrinkRecord: Identifiable, Codable {
    var id: UUID
    var amount: Double
    var drinkTypeRaw: String
    var timestamp: Date
    
    var drinkType: WatchDrinkType {
        WatchDrinkType(rawValue: drinkTypeRaw) ?? .water
    }
    
    init(amount: Double, drinkType: WatchDrinkType, timestamp: Date = Date()) {
        self.id = UUID()
        self.amount = amount
        self.drinkTypeRaw = drinkType.rawValue
        self.timestamp = timestamp
    }
}

// MARK: - Watch Data Manager
class WatchDataManager: ObservableObject {
    @Published var todayRecords: [WatchDrinkRecord] = []
    @Published var dailyGoal: Double = 2000
    
    private let recordsKey = "watch_drink_records"
    private let goalKey = "watch_daily_goal"
    
    init() {
        loadData()
        cleanOldRecords()
    }
    
    var todayTotal: Double {
        todayRecords.reduce(0) { $0 + $1.amount }
    }
    
    var progress: Double {
        min(todayTotal / dailyGoal, 1.0)
    }
    
    var percentage: Int {
        Int(progress * 100)
    }
    
    var remaining: Double {
        max(dailyGoal - todayTotal, 0)
    }
    
    func addRecord(type: WatchDrinkType, amount: Double) {
        let record = WatchDrinkRecord(amount: amount, drinkType: type)
        todayRecords.append(record)
        saveData()
    }
    
    func deleteRecord(_ record: WatchDrinkRecord) {
        todayRecords.removeAll { $0.id == record.id }
        saveData()
    }
    
    func updateRecord(_ record: WatchDrinkRecord, type: WatchDrinkType, amount: Double) {
        if let index = todayRecords.firstIndex(where: { $0.id == record.id }) {
            todayRecords[index].drinkTypeRaw = type.rawValue
            todayRecords[index].amount = amount
            saveData()
        }
    }
    
    func undoLastRecord() -> WatchDrinkRecord? {
        guard let lastRecord = todayRecords.popLast() else { return nil }
        saveData()
        return lastRecord
    }
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(todayRecords) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([WatchDrinkRecord].self, from: data) {
            todayRecords = records
        }
        dailyGoal = UserDefaults.standard.double(forKey: goalKey)
        if dailyGoal == 0 { dailyGoal = 2000 }
    }
    
    private func cleanOldRecords() {
        let calendar = Calendar.current
        todayRecords = todayRecords.filter { calendar.isDateInToday($0.timestamp) }
        saveData()
    }
}