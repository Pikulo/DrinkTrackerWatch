import SwiftUI
import WatchKit

struct RecordDrinkView: View {
    @Environment(\.dismiss) private var dismiss
    let onRecord: (WatchDrinkType, Double) -> Void
    
    @State private var selectedType: WatchDrinkType = .water
    @State private var selectedAmount: Int = 250
    
    private let amounts = [100, 150, 200, 250, 300, 500]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Drink Type Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("饮品类型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(WatchDrinkType.allCases) { type in
                                Button(action: {
                                    selectedType = type
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
                                    .background(selectedType == type ? type.color.opacity(0.3) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Amount Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("饮水量")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 6) {
                            ForEach(amounts, id: \.self) { amount in
                                Button(action: {
                                    selectedAmount = amount
                                    WKInterfaceDevice.current().play(.click)
                                }) {
                                    Text("\(amount)ml")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(selectedAmount == amount ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .foregroundColor(selectedAmount == amount ? .blue : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Confirm Button
                    Button(action: {
                        onRecord(selectedType, Double(selectedAmount))
                        WKInterfaceDevice.current().play(.success)
                        dismiss()
                    }) {
                        HStack {
                            Text(selectedType.icon)
                            Text("记录 \(selectedAmount)ml")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
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
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("记录饮品")
        }
    }
}

#Preview {
    RecordDrinkView { _, _ in }
}