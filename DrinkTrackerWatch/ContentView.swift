import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var selectedTab = 0
    @State private var showingRecordSheet = false
    @State private var showCelebration = false
    @State private var editingRecord: WatchDrinkRecord?
    @State private var selectedRecord: WatchDrinkRecord?
    @State private var showRecordActions = false
    @State private var lastDeletedRecord: WatchDrinkRecord?
    @State private var showUndoToast = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 首页
            homeTab
                .tag(0)
            
            // 统计
            StatisticsView()
                .tag(1)
            
            // 设置
            SettingsView()
                .tag(2)
        }
    }
    
    // MARK: - Home Tab
    private var homeTab: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 12) {
                        progressRing
                        quickRecordSection
                        todayRecordsSection
                    }
                    .padding(.horizontal, 4)
                }
                
                if showUndoToast {
                    undoToast
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 4)
                }
            }
            .navigationTitle("💧 喝水")
            .sheet(isPresented: $showingRecordSheet) {
                RecordDrinkView { type, amount in
                    addRecord(type: type, amount: amount)
                }
            }
            .confirmationDialog("操作", isPresented: $showRecordActions, titleVisibility: .visible) {
                Button("编辑") {
                    if let record = selectedRecord {
                        editingRecord = record
                    }
                }
                Button("删除", role: .destructive) {
                    if let record = selectedRecord {
                        deleteRecord(record)
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                if let record = selectedRecord {
                    Text("\(record.drinkType.rawValue) \(Int(record.amount))ml")
                }
            }
            .sheet(item: $editingRecord) { record in
                EditRecordSheet(record: record) { type, amount in
                    dataManager.updateRecord(record, type: type, amount: amount)
                    WKInterfaceDevice.current().play(.success)
                }
            }
        }
    }
    
    // MARK: - Undo Toast
    private var undoToast: some View {
        HStack {
            Text("已删除")
                .font(.caption2)
                .foregroundColor(.white)
            Spacer()
            Button("撤销") {
                if let record = lastDeletedRecord {
                    dataManager.addRecord(type: record.drinkType, amount: record.amount)
                    WKInterfaceDevice.current().play(.success)
                }
                withAnimation { showUndoToast = false }
            }
            .font(.caption)
            .foregroundColor(.cyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.85))
        .cornerRadius(16)
        .padding(.horizontal, 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showUndoToast = false }
                lastDeletedRecord = nil
            }
        }
    }
    
    // MARK: - Progress Ring
    private var progressRing: some View {
        let isOverGoal = dataManager.todayTotal >= dataManager.dailyGoal
        let ringColors: [Color] = isOverGoal ? [.green, .mint, .green] : [.blue, .cyan, .blue]
        let textColor: Color = isOverGoal ? .green : .blue
        
        return ZStack {
            // 背景环
            Circle()
                .stroke(Color.blue.opacity(0.1), lineWidth: 12)
            
            // 进度环
            Circle()
                .trim(from: 0, to: dataManager.progress)
                .stroke(
                    AngularGradient(
                        colors: ringColors,
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: dataManager.progress)
            
            // 超量脉冲光环
            if isOverGoal {
                Circle()
                    .stroke(textColor.opacity(0.15), lineWidth: 4)
                    .scaleEffect(showCelebration ? 1.15 : 1.0)
                    .animation(
                        showCelebration
                            ? .easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)
                            : .default,
                        value: showCelebration
                    )
            }
            
            VStack(spacing: 2) {
                Text("\(Int(dataManager.todayTotal))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                
                Text("/ \(Int(dataManager.dailyGoal))ml")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                
                if isOverGoal {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                        Text("已达标")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
                } else {
                    Text("\(dataManager.percentage)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textColor)
                }
                
                // 连续打卡
                if dataManager.currentStreak > 0 {
                    HStack(spacing: 2) {
                        Text("🔥")
                            .font(.system(size: 8))
                        Text("\(dataManager.currentStreak)天")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .frame(width: 110, height: 110)
        .padding(.top, 4)
    }
    
    private var quickDrinkColumns: [GridItem] {
        dataManager.quickDrinks.count <= 2
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    // MARK: - Quick Record Section
    private var quickRecordSection: some View {
        VStack(spacing: 6) {
            // 动态快捷按钮
            LazyVGrid(columns: quickDrinkColumns, spacing: 6) {
                ForEach(dataManager.quickDrinks) { config in
                    Button(action: {
                        addRecord(type: config.drinkType, amount: config.amount)
                    }) {
                        HStack(spacing: 4) {
                            Text(config.drinkType.icon)
                            Text("\(config.drinkType.rawValue) \(Int(config.amount))ml")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(config.drinkType.color.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 自定义记录按钮
            Button(action: {
                showingRecordSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.caption)
                    Text("自定义记录")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            // 进度提示
            if dataManager.remaining > 0 {
                Text("还差 \(Int(dataManager.remaining))ml 达标")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("今日目标已达成！🎉")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Today's Records Section
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("今日记录")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(dataManager.todayRecords.count) 条")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            if dataManager.todayRecords.isEmpty {
                Text("暂无记录")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                let recentRecords = Array(dataManager.todayRecords.suffix(8).reversed())
                ForEach(recentRecords) { record in
                    Button(action: {
                        selectedRecord = record
                        showRecordActions = true
                    }) {
                        HStack(spacing: 8) {
                            Text(record.drinkType.icon)
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(record.drinkType.rawValue)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                Text(timeString(from: record.timestamp))
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(record.amount))ml")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Actions
    private func deleteRecord(_ record: WatchDrinkRecord) {
        lastDeletedRecord = record
        dataManager.deleteRecord(record)
        WKInterfaceDevice.current().play(.notification)
        withAnimation { showUndoToast = true }
    }
    
    private func addRecord(type: WatchDrinkType, amount: Double) {
        dataManager.addRecord(type: type, amount: amount)
        WKInterfaceDevice.current().play(.success)
        
        if dataManager.todayTotal >= dataManager.dailyGoal {
            withAnimation { showCelebration = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showCelebration = false }
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager())
}