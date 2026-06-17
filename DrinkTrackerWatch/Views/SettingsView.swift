import SwiftUI
import WatchKit

struct SettingsView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var showGoalPicker = false
    @State private var showReminderPicker = false
    @State private var showThemePicker = false
    @State private var notificationGranted = false
    
    private let goalOptions: [Double] = [1000, 1500, 2000, 2500, 3000, 3500, 4000]
    private let reminderOptions: [(label: String, value: Int)] = [
        ("关闭", 0),
        ("15 分钟", 15),
        ("30 分钟", 30),
        ("1 小时", 60),
        ("1.5 小时", 90),
        ("2 小时", 120),
        ("3 小时", 180)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // 每日目标
                    goalSection
                    
                    // 通知提醒
                    reminderSection
                    
                    // 主题
                    themeSection
                    
                    // 快捷饮品
                    quickDrinkSection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("⚙️ 设置")
            .onAppear {
                checkNotificationPermission()
            }
        }
    }
    
    // MARK: - Goal Section
    private var goalSection: some View {
        Button(action: { showGoalPicker = true }) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("每日目标")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("\(Int(dataManager.dailyGoal)) ml")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showGoalPicker) {
            goalPickerSheet
        }
    }
    
    private var goalPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(goalOptions, id: \.self) { goal in
                        Button(action: {
                            dataManager.updateGoal(goal)
                            WKInterfaceDevice.current().play(.click)
                            showGoalPicker = false
                        }) {
                            HStack {
                                Text("\(Int(goal)) ml")
                                    .font(.body)
                                    .fontWeight(dataManager.dailyGoal == goal ? .semibold : .regular)
                                
                                Spacer()
                                
                                if dataManager.dailyGoal == goal {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(dataManager.dailyGoal == goal ? Color.blue.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("每日目标")
        }
    }
    
    // MARK: - Reminder Section
    private var reminderSection: some View {
        Button(action: {
            if !notificationGranted {
                dataManager.requestNotificationPermission { granted in
                    notificationGranted = granted
                    if granted { showReminderPicker = true }
                }
            } else {
                showReminderPicker = true
            }
        }) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("喝水提醒")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text(reminderLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showReminderPicker) {
            reminderPickerSheet
        }
    }
    
    private var reminderLabel: String {
        if let option = reminderOptions.first(where: { $0.value == dataManager.reminderInterval }) {
            return option.label
        }
        return "关闭"
    }
    
    private var reminderPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(reminderOptions, id: \.value) { option in
                        Button(action: {
                            dataManager.updateReminderInterval(option.value)
                            WKInterfaceDevice.current().play(.click)
                            showReminderPicker = false
                        }) {
                            HStack {
                                Text(option.label)
                                    .font(.body)
                                    .fontWeight(dataManager.reminderInterval == option.value ? .semibold : .regular)
                                
                                Spacer()
                                
                                if dataManager.reminderInterval == option.value {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(dataManager.reminderInterval == option.value ? Color.blue.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("提醒间隔")
        }
    }
    
    // MARK: - Theme Section
    private var themeSection: some View {
        Button(action: { showThemePicker = true }) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("外观主题")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text(dataManager.appTheme.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showThemePicker) {
            themePickerSheet
        }
    }
    
    private var themePickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(AppTheme.allCases) { theme in
                        Button(action: {
                            dataManager.updateTheme(theme)
                            WKInterfaceDevice.current().play(.click)
                            showThemePicker = false
                        }) {
                            HStack {
                                Text(theme.rawValue)
                                    .font(.body)
                                    .fontWeight(dataManager.appTheme == theme ? .semibold : .regular)
                                
                                Spacer()
                                
                                if dataManager.appTheme == theme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(dataManager.appTheme == theme ? Color.blue.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("外观主题")
        }
    }
    
    // MARK: - Quick Drink Section
    private var quickDrinkSection: some View {
        NavigationLink(destination: QuickDrinkEditView()) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("快捷饮品")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Text("\(dataManager.quickDrinks.count) 个快捷项")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationGranted = settings.authorizationStatus == .authorized
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WatchDataManager())
}