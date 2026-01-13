import SwiftUI
import SwiftData

struct InspirationDetailView: View {
    @Bindable var inspiration: Inspiration
    @Query private var categories: [Category]
    @State private var isAIHovered: Bool = false
    @State private var cachedReminderDate: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Calendar.current.date(byAdding: .day, value: 1, to: Date())!) ?? Date()
    
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
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $inspiration.notes)
                            .font(.system(size: 14))
                            .scrollContentBackground(.hidden)
                    }
                    .frame(height: 100)
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
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { inspiration.reminderDate != nil },
                        set: { isOn in
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if isOn {
                                    // 优先使用缓存的时间，如果缓存时间已过期，则设为明天晚上10点
                                    let dateToSet = cachedReminderDate > Date() ? cachedReminderDate : defaultReminderDate()
                                    inspiration.reminderDate = dateToSet
                                    NotificationManager.shared.scheduleNotification(for: inspiration)
                                } else {
                                    if let current = inspiration.reminderDate {
                                        cachedReminderDate = current
                                    }
                                    inspiration.reminderDate = nil
                                    NotificationManager.shared.cancelNotification(for: inspiration)
                                }
                            }
                        }
                    )) {
                        Label("开启提醒", systemImage: "bell.badge.fill")
                            .foregroundColor(inspiration.reminderDate != nil ? (inspiration.isCompleted ? .secondary : Color(red: 1.0, green: 0.4, blue: 0.2)) : .secondary)
                    }
                    .toggleStyle(.switch)
                    .tint(Color(red: 1.0, green: 0.4, blue: 0.2))
                    .disabled(inspiration.isCompleted)
                    
                    if let reminderDate = inspiration.reminderDate {
                        VStack(alignment: .leading, spacing: 10) {
                            // 快捷预设按钮
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    presetButton("1小时后", icon: "clock") { setReminderRelative(hours: 1) }
                                    presetButton("今晚 20:00", icon: "moon.stars") { setReminderToday(hour: 20) }
                                    presetButton("明天 09:00", icon: "sunrise") { setReminderTomorrow(hour: 9) }
                                    presetButton("明天 22:00", icon: "moon") { setReminderTomorrow(hour: 22) }
                                }
                            }
                            
                            DatePicker("精确时间", selection: Binding(
                                get: { reminderDate },
                                set: { 
                                    inspiration.reminderDate = $0
                                    cachedReminderDate = $0
                                    NotificationManager.shared.scheduleNotification(for: inspiration)
                                }
                            ))
                            .datePickerStyle(.field)
                        }
                        .padding(.top, 4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .opacity(inspiration.isCompleted ? 0.5 : 1.0)
                        .disabled(inspiration.isCompleted)
                    }
                }
            }
            
            Section("状态") {
                Toggle("已完成", isOn: $inspiration.isCompleted)
                    .tint(.green)
                    .onChange(of: inspiration.isCompleted) { oldValue, newValue in
                        if newValue {
                            NotificationManager.shared.cancelNotification(for: inspiration)
                        } else {
                            NotificationManager.shared.scheduleNotification(for: inspiration)
                        }
                    }
                Toggle("置顶", isOn: $inspiration.isPinned)
                    .tint(.blue)
                
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
    
    // MARK: - 提醒助手方法
    
    private func presetButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.2), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func defaultReminderDate() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        return calendar.date(bySettingHour: 22, minute: 0, second: 0, of: tomorrow) ?? Date()
    }
    
    private func setReminderRelative(hours: Int) {
        let date = Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date()
        updateReminder(date)
    }
    
    private func setReminderToday(hour: Int) {
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        // 如果设定时间已过，自动设为明天
        if date < Date() {
            setReminderTomorrow(hour: hour)
        } else {
            updateReminder(date)
        }
    }
    
    private func setReminderTomorrow(hour: Int) {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) ?? Date()
        updateReminder(date)
    }
    
    private func updateReminder(_ date: Date) {
        withAnimation(.spring()) {
            inspiration.reminderDate = date
            cachedReminderDate = date
            NotificationManager.shared.scheduleNotification(for: inspiration)
        }
    }
}
