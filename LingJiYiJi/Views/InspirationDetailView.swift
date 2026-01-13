import SwiftUI
import SwiftData

/// 灵感详情视图：支持编辑标题、备注、分类以及设置时间提醒
struct InspirationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var inspiration: Inspiration          // 当前正在编辑的灵感模型
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    
    @State private var showingCategoryPicker = false // 控制分类选择弹窗
    @State private var isAIClassifying = false      // AI 自动分类加载状态
    @State private var cachedReminderDate: Date?    // 缓存提醒时间，用于取消/恢复逻辑
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 1. 标题编辑区域
                VStack(alignment: .leading, spacing: 8) {
                    TextField("灵感标题", text: $inspiration.title, axis: .vertical)
                        .font(.system(size: 28, weight: .bold))
                        .textFieldStyle(.plain)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // 分类选择按钮
                        Menu {
                            ForEach(categories) { category in
                                Button(category.name) {
                                    inspiration.category = category.name
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                Text(inspiration.category.isEmpty ? "未分类" : inspiration.category)
                            }
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                        }
                        .menuStyle(.plain)
                        
                        // AI 自动分类按钮
                        Button(action: autoClassify) {
                            HStack(spacing: 4) {
                                if isAIClassifying {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.6)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isAIClassifying ? "AI 分类中..." : "AI 自动分类")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .disabled(isAIClassifying)
                        
                        Spacer()
                        
                        // 创建时间展示
                        Text(inspiration.createdAt.formatted(.dateTime.year().month().day().hour().minute()))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // 2. 提醒时间设置区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("时间提醒", systemImage: "bell.badge.fill")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Spacer()
                        
                        // 提醒开关
                        Toggle("", isOn: Binding(
                            get: { inspiration.reminderDate != nil },
                            set: { isEnabled in
                                withAnimation {
                                    if isEnabled {
                                        // 开启提醒：恢复缓存时间或默认设为 1 小时后
                                        inspiration.reminderDate = cachedReminderDate ?? Date().addingTimeInterval(3600)
                                        NotificationManager.shared.scheduleNotification(for: inspiration)
                                    } else {
                                        // 关闭提醒：备份当前时间并清空
                                        cachedReminderDate = inspiration.reminderDate
                                        inspiration.reminderDate = nil
                                        NotificationManager.shared.cancelNotification(for: inspiration)
                                    }
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }
                    
                    if let reminderDate = inspiration.reminderDate {
                        VStack(alignment: .leading, spacing: 12) {
                            // 日期选择器
                            DatePicker("", selection: Binding(
                                get: { reminderDate },
                                set: { newDate in
                                    inspiration.reminderDate = newDate
                                    NotificationManager.shared.scheduleNotification(for: inspiration)
                                }
                            ))
                            .datePickerStyle(.stepperField)
                            .labelsHidden()
                            
                            // 预设快捷时间按钮（带颜色区分）
                            HStack(spacing: 8) {
                                presetButton("1小时后", icon: "clock", color: .blue) {
                                    setReminder(hours: 1)
                                }
                                presetButton("明天", icon: "sunrise", color: .orange) {
                                    setReminder(days: 1)
                                }
                                presetButton("3天后", icon: "calendar", color: .purple) {
                                    setReminder(days: 3)
                                }
                                presetButton("下周", icon: "calendar.badge.clock", color: .green) {
                                    setReminder(days: 7)
                                }
                            }
                        }
                        .padding()
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                
                // 3. 备注内容编辑区域
                VStack(alignment: .leading, spacing: 12) {
                    Label("备注内容", systemImage: "doc.text.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    TextEditor(text: $inspiration.notes)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .frame(minHeight: 120) // 调整备注框最小高度，保持紧凑
                        .padding(8)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(8)
                        .scrollContentBackground(.hidden)
                }
                
                Spacer(minLength: 40)
            }
            .padding(32)
        }
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - 辅助组件与逻辑
    
    /// 构建带有特定颜色的预设按钮
    private func presetButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundColor(color)
            .background(color.opacity(0.12))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
    
    /// 快捷设置提醒时间逻辑
    private func setReminder(hours: Int = 0, days: Int = 0) {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hours
        components.day = days
        
        if let newDate = calendar.date(byAdding: components, to: Date()) {
            withAnimation {
                inspiration.reminderDate = newDate
                NotificationManager.shared.scheduleNotification(for: inspiration)
            }
        }
    }
    
    /// 调用 AI 服务自动识别灵感分类
    private func autoClassify() {
        guard !inspiration.title.isEmpty else { return }
        
        isAIClassifying = true
        Task {
            let availableCatNames = categories.map { $0.name }
            let category = await AIService.shared.classifyInspiration(
                title: inspiration.title,
                notes: inspiration.notes,
                availableCategories: availableCatNames
            )
            
            await MainActor.run {
                withAnimation {
                    inspiration.category = category
                    isAIClassifying = false
                }
            }
        }
    }
}
