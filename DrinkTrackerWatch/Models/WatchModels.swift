import Foundation
import SwiftUI
import UserNotifications

// MARK: - Drink Types
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

// MARK: - Quick Drink Config
struct QuickDrinkConfig: Identifiable, Codable, Equatable {
    var id: UUID
    var drinkTypeRaw: String
    var amount: Double
    
    var drinkType: WatchDrinkType {
        WatchDrinkType(rawValue: drinkTypeRaw) ?? .water
    }
    
    init(id: UUID = UUID(), drinkType: WatchDrinkType, amount: Double) {
        self.id = id
        self.drinkTypeRaw = drinkType.rawValue
        self.amount = amount
    }
    
    static func == (lhs: QuickDrinkConfig, rhs: QuickDrinkConfig) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable {
    case system = "跟随系统"
    case dark = "深色"
    case light = "浅色"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Watch Data Manager
class WatchDataManager: ObservableObject {
    @Published var allRecords: [WatchDrinkRecord] = []
    @Published var dailyGoal: Double = 2000
    @Published var reminderInterval: Int = 60 // 分钟，0 = 关闭
    @Published var appTheme: AppTheme = .system
    @Published var quickDrinks: [QuickDrinkConfig] = []
    
    // MARK: - Keys
    private let recordsKey = "watch_drink_records"
    private let goalKey = "watch_daily_goal"
    private let reminderKey = "watch_reminder_interval"
    private let themeKey = "watch_app_theme"
    private let quickDrinksKey = "watch_quick_drinks"
    
    // MARK: - App Group (与 Complication 共享数据)
    static let appGroupID = "group.com.drinking.app"
    
    var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupID)
    }
    
    init() {
        loadData()
        cleanupOldRecords()
        syncToSharedDefaults()
    }
    
    // MARK: - 今日数据
    
    var todayRecords: [WatchDrinkRecord] {
        allRecords.filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
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
    
    // MARK: - 连续打卡天数
    
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date()
        
        let todayTotal = self.todayTotal
        if todayTotal < dailyGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        
        while true {
            let dayTotal = totalForDate(date)
            if dayTotal >= dailyGoal {
                streak += 1
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: date) else { break }
                date = prevDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - 查询函数
    
    func recordsForDate(_ date: Date) -> [WatchDrinkRecord] {
        let calendar = Calendar.current
        return allRecords.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func totalForDate(_ date: Date) -> Double {
        recordsForDate(date).reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - 每周/每月数据
    
    func weeklyData() -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).reversed().compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            return (date: date, total: totalForDate(date))
        }
    }
    
    func monthlyData() -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).reversed().compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            return (date: date, total: totalForDate(date))
        }
    }
    
    // 按周分组的月度数据（用于月度图表更清晰展示）
    func monthlyGroupedData() -> [(label: String, avgTotal: Double, days: Int)] {
        let calendar = Calendar.current
        let today = Date()
        var weeks: [(label: String, avgTotal: Double, days: Int)] = []
        
        for weekIndex in (0..<4).reversed() {
            let startDay = weekIndex * 7
            let endDay = min(startDay + 7, 30)
            var weekTotal: Double = 0
            var weekDays = 0
            
            for dayOffset in startDay..<endDay {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let total = totalForDate(date)
                if total > 0 {
                    weekTotal += total
                    weekDays += 1
                }
            }
            
            let avg = weekDays > 0 ? weekTotal / Double(endDay - startDay) : 0
            let weekLabel = weekIndex == 0 ? "本周" : "\(weekIndex)周前"
            weeks.append((label: weekLabel, avgTotal: avg, days: weekDays))
        }
        return weeks
    }
    
    // MARK: - 平均每日摄入量
    
    var averageDailyIntake: Double {
        let calendar = Calendar.current
        let today = Date()
        var totalSum: Double = 0
        var activeDays = 0
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayTotal = totalForDate(date)
            if dayTotal > 0 {
                totalSum += dayTotal
                activeDays += 1
            }
        }
        
        return activeDays > 0 ? totalSum / Double(activeDays) : 0
    }
    
    // MARK: - 按饮品类型统计
    
    func statsByDrinkType(for date: Date? = nil) -> [(type: WatchDrinkType, total: Double, count: Int)] {
        let records: [WatchDrinkRecord]
        if let date = date {
            records = recordsForDate(date)
        } else {
            records = todayRecords
        }
        
        var stats: [String: (total: Double, count: Int)] = [:]
        for type in WatchDrinkType.allCases {
            stats[type.rawValue] = (total: 0, count: 0)
        }
        for record in records {
            if var stat = stats[record.drinkTypeRaw] {
                stat.total += record.amount
                stat.count += 1
                stats[record.drinkTypeRaw] = stat
            }
        }
        return WatchDrinkType.allCases.compactMap { type in
            guard let stat = stats[type.rawValue], stat.total > 0 else { return nil }
            return (type: type, total: stat.total, count: stat.count)
        }.sorted { $0.total > $1.total }
    }
    
    // MARK: - CRUD 操作
    
    func addRecord(type: WatchDrinkType, amount: Double) {
        let record = WatchDrinkRecord(amount: amount, drinkType: type)
        allRecords.append(record)
        saveData()
        syncToSharedDefaults()
    }
    
    func deleteRecord(_ record: WatchDrinkRecord) {
        allRecords.removeAll { $0.id == record.id }
        saveData()
        syncToSharedDefaults()
    }
    
    func updateRecord(_ record: WatchDrinkRecord, type: WatchDrinkType, amount: Double) {
        if let index = allRecords.firstIndex(where: { $0.id == record.id }) {
            allRecords[index].drinkTypeRaw = type.rawValue
            allRecords[index].amount = amount
            saveData()
            syncToSharedDefaults()
        }
    }
    
    func undoLastRecord() -> WatchDrinkRecord? {
        guard let lastIndex = allRecords.lastIndex(where: { Calendar.current.isDateInToday($0.timestamp) }) else { return nil }
        let record = allRecords.remove(at: lastIndex)
        saveData()
        syncToSharedDefaults()
        return record
    }
    
    // MARK: - 设置更新
    
    func updateGoal(_ goal: Double) {
        dailyGoal = goal
        UserDefaults.standard.set(goal, forKey: goalKey)
        syncToSharedDefaults()
    }
    
    func updateReminderInterval(_ interval: Int) {
        reminderInterval = interval
        UserDefaults.standard.set(interval, forKey: reminderKey)
        scheduleNotifications()
    }
    
    func updateTheme(_ theme: AppTheme) {
        appTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }
    
    func updateQuickDrinks(_ drinks: [QuickDrinkConfig]) {
        quickDrinks = drinks
        if let data = try? JSONEncoder().encode(drinks) {
            UserDefaults.standard.set(data, forKey: quickDrinksKey)
        }
    }
    
    // MARK: - 通知提醒
    
    func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        guard reminderInterval > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💧 该喝水了"
        content.body = "已经 \(reminderInterval) 分钟没有喝水，记得补充水分！"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(reminderInterval, 1) * 60),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "drink_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("通知调度失败: \(error.localizedDescription)")
            }
        }
    }
    
    func requestNotificationPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }
    
    // MARK: - 导出数据
    
    func exportToJSON() -> String {
        let formatter = ISO8601DateFormatter()
        let exportData: [String: Any] = [
            "app": "DrinkTrackerWatch",
            "dailyGoal": dailyGoal,
            "exportDate": formatter.string(from: Date()),
            "totalRecords": allRecords.count,
            "currentStreak": currentStreak,
            "records": allRecords.map { record -> [String: Any] in
                [
                    "id": record.id.uuidString,
                    "drinkType": record.drinkTypeRaw,
                    "amount": record.amount,
                    "timestamp": formatter.string(from: record.timestamp)
                ]
            }
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
    
    func exportToCSV() -> String {
        var csv = "日期,时间,饮品图标,饮品名称,数量(ml)\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        for record in allRecords.sorted(by: { $0.timestamp > $1.timestamp }) {
            let date = dateFormatter.string(from: record.timestamp)
            let time = timeFormatter.string(from: record.timestamp)
            let icon = record.drinkType.icon
            let name = record.drinkType.rawValue
            csv += "\(date),\(time),\(icon),\(name),\(Int(record.amount))\n"
        }
        return csv
    }
    
    // MARK: - 持久化
    
    private func saveData() {
        if let data = try? JSONEncoder().encode(allRecords) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
    
    private func loadData() {
        // 加载记录
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([WatchDrinkRecord].self, from: data) {
            allRecords = records
        }
        
        // 加载目标
        dailyGoal = UserDefaults.standard.double(forKey: goalKey)
        if dailyGoal == 0 { dailyGoal = 2000 }
        
        // 加载提醒间隔
        reminderInterval = UserDefaults.standard.integer(forKey: reminderKey)
        
        // 加载主题
        if let themeRaw = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeRaw) {
            appTheme = theme
        }
        
        // 加载快捷饮品
        if let data = UserDefaults.standard.data(forKey: quickDrinksKey),
           let drinks = try? JSONDecoder().decode([QuickDrinkConfig].self, from: data) {
            quickDrinks = drinks
        } else {
            quickDrinks = [
                QuickDrinkConfig(drinkType: .water, amount: 250),
                QuickDrinkConfig(drinkType: .water, amount: 500)
            ]
        }
    }
    
    // MARK: - 清理旧记录（保留 90 天）
    
    private func cleanupOldRecords() {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -90, to: Date()) else { return }
        let countBefore = allRecords.count
        allRecords.removeAll { $0.timestamp < cutoff }
        if allRecords.count != countBefore {
            saveData()
        }
    }
    
    // MARK: - 共享数据 (用于 Complication)
    
    private func syncToSharedDefaults() {
        guard let shared = sharedDefaults else { return }
        shared.set(todayTotal, forKey: "today_total")
        shared.set(dailyGoal, forKey: "daily_goal")
        shared.set(progress, forKey: "progress")
        shared.set(percentage, forKey: "percentage")
        shared.set(currentStreak, forKey: "current_streak")
        shared.set(Date().timeIntervalSince1970, forKey: "last_updated")
    }
}