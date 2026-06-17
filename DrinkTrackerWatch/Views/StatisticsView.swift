import SwiftUI
import WatchKit

struct StatisticsView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var selectedPeriod: StatPeriod = .week
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var exportFormat = "JSON"
    
    enum StatPeriod: String, CaseIterable {
        case week = "本周"
        case month = "本月"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 打卡连续天数
                    streakCard
                    
                    // 周期切换
                    periodPicker
                    
                    // 柱状图
                    chartSection
                    
                    // 按饮品类型统计
                    drinkTypeStats
                    
                    // 导出按钮
                    exportSection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("📊 统计")
        }
    }
    
    // MARK: - Streak Card
    private var streakCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🔥 连续达标")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(dataManager.currentStreak) 天")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            Spacer()
            VStack(alignment: .center, spacing: 2) {
                Text("30天均值")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(Int(dataManager.averageDailyIntake))ml")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("今日进度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(dataManager.percentage)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Period Picker
    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(StatPeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation { selectedPeriod = period }
                }) {
                    Text(period.rawValue)
                        .font(.caption2)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(selectedPeriod == period ? Color.blue.opacity(0.3) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(8)
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(selectedPeriod == .week ? "每日饮水量" : "每周平均饮水量")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if selectedPeriod == .week {
                weeklyChart
            } else {
                monthlyChart
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var weeklyChart: some View {
        let data = dataManager.weeklyData()
        let maxTotal = data.map { $0.total }.max() ?? 1
        let goal = dataManager.dailyGoal
        
        return VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let height = max(item.total / maxTotal, 0.05)
                    let reachedGoal = item.total >= goal
                    
                    VStack(spacing: 2) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(reachedGoal ? Color.green : Color.blue.opacity(0.6))
                            .frame(height: max(CGFloat(height) * 55, 3))
                        
                        Text(dayLabel(for: item.date))
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 75)
            
            HStack {
                Spacer()
                Text("目标: \(Int(goal))ml")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var monthlyChart: some View {
        let data = dataManager.monthlyGroupedData()
        let maxAvg = data.map { $0.avgTotal }.max() ?? 1
        let goal = dataManager.dailyGoal
        
        return VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data.indices, id: \.self) { index in
                    let item = data[index]
                    let height = max(item.avgTotal / maxAvg, 0.05)
                    let reachedGoal = item.avgTotal >= goal
                    
                    VStack(spacing: 2) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(reachedGoal ? Color.green : Color.cyan.opacity(0.6))
                            .frame(height: max(CGFloat(height) * 55, 3))
                        
                        Text(item.label)
                            .font(.system(size: 7))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 75)
            
            HStack {
                Text("日均目标: \(Int(goal))ml")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    // MARK: - Drink Type Stats
    private var drinkTypeStats: some View {
        let stats = dataManager.statsByDrinkType(for: nil)
        
        return VStack(alignment: .leading, spacing: 6) {
            Text("饮品分布")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if stats.isEmpty {
                Text("今日暂无记录")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(stats, id: \.type) { stat in
                    HStack(spacing: 8) {
                        Text(stat.type.icon)
                            .font(.caption)
                        
                        Text(stat.type.rawValue)
                            .font(.system(size: 10))
                            .frame(width: 32, alignment: .leading)
                        
                        // 进度条
                        GeometryReader { geo in
                            let ratio = stat.total / (stats.first?.total ?? 1)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stat.type.color.opacity(0.4))
                                .frame(width: geo.size.width * CGFloat(ratio), height: geo.size.height)
                        }
                        .frame(height: 8)
                        
                        Text("\(Int(stat.total))ml")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Export Section
    private var exportSection: some View {
        VStack(spacing: 6) {
            Text("导出数据")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Button(action: {
                    exportFormat = "JSON"
                    exportText = dataManager.exportToJSON()
                    WKInterfaceDevice.current().play(.click)
                    showExportSheet = true
                }) {
                    Label("JSON", systemImage: "doc.text")
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    exportFormat = "CSV"
                    exportText = dataManager.exportToCSV()
                    WKInterfaceDevice.current().play(.click)
                    showExportSheet = true
                }) {
                    Label("CSV", systemImage: "tablecells")
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .sheet(isPresented: $showExportSheet) {
            exportPreviewSheet
        }
    }
    
    // MARK: - Export Preview Sheet
    private var exportPreviewSheet: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("导出 - \(exportFormat)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(exportText)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                
                Text("已导出 \(dataManager.allRecords.count) 条记录")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Helpers
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "今"
        }
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    StatisticsView()
        .environmentObject(WatchDataManager())
}