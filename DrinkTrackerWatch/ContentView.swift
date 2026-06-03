import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var showingRecordSheet = false
    @State private var showCelebration = false
    @State private var editingRecord: WatchDrinkRecord?
    @State private var selectedRecord: WatchDrinkRecord?
    @State private var showRecordActions = false
    @State private var lastDeletedRecord: WatchDrinkRecord?
    @State private var showUndoToast = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
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
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.15), lineWidth: 14)
            
            Circle()
                .trim(from: 0, to: dataManager.progress)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .cyan, .blue],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: dataManager.progress)
            
            VStack(spacing: 2) {
                Text("\(Int(dataManager.todayTotal))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                
                Text("/ \(Int(dataManager.dailyGoal))ml")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(dataManager.percentage)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 120, height: 120)
        .padding(.top, 8)
    }
    
    // MARK: - Quick Record Section
    private var quickRecordSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                addRecord(type: .water, amount: 250)
            }) {
                HStack {
                    Text("💧")
                    Text("+250ml")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                showingRecordSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("记录饮品")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.cyan.opacity(0.15))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            if dataManager.remaining > 0 {
                Text("还差 \(Int(dataManager.remaining))ml")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("目标达成！")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Today's Records Section
    private var todayRecordsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日记录")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            if dataManager.todayRecords.isEmpty {
                Text("暂无记录")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(dataManager.todayRecords.suffix(5).reversed()) { record in
                    Button(action: {
                        selectedRecord = record
                        showRecordActions = true
                    }) {
                        HStack(spacing: 8) {
                            Text(record.drinkType.icon)
                                .font(.caption)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(record.drinkType.rawValue)
                                    .font(.system(size: 11))
                                    .fontWeight(.medium)
                                Text(timeString(from: record.timestamp))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(Int(record.amount))ml")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
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
