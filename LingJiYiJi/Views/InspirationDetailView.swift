import SwiftUI
import SwiftData

struct InspirationDetailView: View {
    @Bindable var inspiration: Inspiration
    @Query private var categories: [Category]
    @State private var isAIHovered: Bool = false
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $inspiration.title)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("备注")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if inspiration.notes.isEmpty {
                            Text("记录更详细的想法...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $inspiration.notes)
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                    }
                    .frame(minHeight: 200)
                    .padding(6)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
                }
            }
            
            Section("分类") {
                HStack(spacing: 12) {
                    Picker("所属类别", selection: $inspiration.category) {
                        ForEach(Array(Set(categories.map { $0.name })).sorted(), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 200)
                    
                    Button {
                        Task {
                            let availableCatNames = categories.map { $0.name }
                            let category = await AIService.shared.classifyInspiration(title: inspiration.title, notes: inspiration.notes, availableCategories: availableCatNames)
                            withAnimation(.spring()) {
                                inspiration.category = category
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .symbolEffect(.pulse, options: .repeating)
                            Text("AI 自动分类")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.4, green: 0.4, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.3), radius: isAIHovered ? 6 : 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isAIHovered ? 1.05 : 1.0)
                    .onHover { hovering in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isAIHovered = hovering
                        }
                    }
                    .keyboardShortcut("l", modifiers: .command)
                }
            }
            
            Section("提醒") {
                Toggle(isOn: Binding(
                    get: { inspiration.reminderDate != nil },
                    set: { isOn in
                        if isOn {
                            let calendar = Calendar.current
                            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
                                var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                                components.hour = 22
                                components.minute = 0
                                inspiration.reminderDate = calendar.date(from: components)
                            }
                        } else {
                            inspiration.reminderDate = nil
                        }
                    }
                )) {
                    Label("开启提醒", systemImage: "bell.badge.fill")
                        .foregroundColor(inspiration.reminderDate != nil ? Color(red: 1.0, green: 0.4, blue: 0.2) : .secondary)
                }
                .toggleStyle(.switch)
                
                if let _ = inspiration.reminderDate {
                    DatePicker("提醒时间", selection: Binding(
                        get: { inspiration.reminderDate ?? Date() },
                        set: { 
                            inspiration.reminderDate = $0
                            NotificationManager.shared.scheduleNotification(for: inspiration)
                        }
                    ))
                }
            }
            
            Section("状态") {
                Toggle("已完成", isOn: $inspiration.isCompleted)
                    .onChange(of: inspiration.isCompleted) { oldValue, newValue in
                        if newValue {
                            NotificationManager.shared.cancelNotification(for: inspiration)
                        } else {
                            NotificationManager.shared.scheduleNotification(for: inspiration)
                        }
                    }
                Toggle("置顶", isOn: $inspiration.isPinned)
                
                LabeledContent("创建时间") {
                    Text(inspiration.createdAt, style: .date)
                    Text(inspiration.createdAt, style: .time)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("灵感详情")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    // 触发搜索框聚焦
                    NSApp.sendAction(#selector(NSTextField.becomeFirstResponder), to: nil, from: nil)
                } label: {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
