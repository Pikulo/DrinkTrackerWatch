import SwiftUI
import WatchKit

struct QuickDrinkEditView: View {
    @EnvironmentObject var dataManager: WatchDataManager
    @State private var editingDrink: QuickDrinkConfig?
    @State private var showAddSheet = false
    @State private var newType: WatchDrinkType = .water
    @State private var newAmount: Double = 250
    
    private let amounts: [Double] = [100, 150, 200, 250, 300, 400, 500]
    
    var body: some View {
        List {
            // 现有快捷饮品列表
            ForEach(dataManager.quickDrinks) { drink in
                Button(action: {
                    editingDrink = drink
                    newType = drink.drinkType
                    newAmount = drink.amount
                }) {
                    HStack(spacing: 8) {
                        Text(drink.drinkType.icon)
                            .font(.caption)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(drink.drinkType.rawValue)
                                .font(.system(size: 11, weight: .medium))
                            Text("\(Int(drink.amount))ml")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .onDelete { indexSet in
                var drinks = dataManager.quickDrinks
                drinks.remove(atOffsets: indexSet)
                dataManager.updateQuickDrinks(drinks)
                WKInterfaceDevice.current().play(.retry)
            }
            
            // 添加按钮
            Button(action: { showAddSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("添加快捷饮品")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("⚡ 快捷饮品")
        .sheet(isPresented: $showAddSheet) {
            quickDrinkPicker(isEditing: false)
        }
        .sheet(item: $editingDrink) { drink in
            quickDrinkPicker(isEditing: true, originalDrink: drink)
        }
    }
    
    private func quickDrinkPicker(isEditing: Bool, originalDrink: QuickDrinkConfig? = nil) -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // 饮品类型选择
                    VStack(alignment: .leading, spacing: 6) {
                        Text("饮品类型")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(WatchDrinkType.allCases) { type in
                                Button(action: {
                                    newType = type
                                    WKInterfaceDevice.current().play(.click)
                                }) {
                                    VStack(spacing: 2) {
                                        Text(type.icon)
                                            .font(.title3)
                                        Text(type.rawValue)
                                            .font(.system(size: 9))
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(newType == type ? type.color.opacity(0.3) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 量选择
                    VStack(alignment: .leading, spacing: 6) {
                        Text("饮水量")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(amounts, id: \.self) { amount in
                                Button(action: {
                                    newAmount = amount
                                    WKInterfaceDevice.current().play(.click)
                                }) {
                                    Text("\(Int(amount))ml")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(newAmount == amount ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(newAmount == amount ? .blue : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 确认按钮
                    Button(action: {
                        saveQuickDrink(isEditing: isEditing, originalDrink: originalDrink)
                    }) {
                        HStack {
                            Text(newType.icon)
                            Text(isEditing ? "保存修改" : "添加")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    // 删除按钮（编辑模式）
                    if isEditing, let drink = originalDrink {
                        Button(action: {
                            var drinks = dataManager.quickDrinks
                            drinks.removeAll { $0.id == drink.id }
                            dataManager.updateQuickDrinks(drinks)
                            editingDrink = nil
                            WKInterfaceDevice.current().play(.retry)
                        }) {
                            Text("删除此项")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(isEditing ? "编辑快捷" : "新增快捷")
        }
    }
    
    private func saveQuickDrink(isEditing: Bool, originalDrink: QuickDrinkConfig?) {
        let newConfig = QuickDrinkConfig(
            id: originalDrink?.id ?? UUID(),
            drinkType: newType,
            amount: newAmount
        )
        
        var drinks = dataManager.quickDrinks
        if isEditing, let original = originalDrink,
           let index = drinks.firstIndex(where: { $0.id == original.id }) {
            drinks[index] = newConfig
        } else {
            drinks.append(newConfig)
        }
        
        dataManager.updateQuickDrinks(drinks)
        WKInterfaceDevice.current().play(.success)
        
        if isEditing {
            editingDrink = nil
        } else {
            showAddSheet = false
        }
    }
}

#Preview {
    QuickDrinkEditView()
        .environmentObject(WatchDataManager())
}