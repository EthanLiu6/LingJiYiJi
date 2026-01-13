import SwiftUI
import SwiftData

struct InspirationDetailView: View {
    @Bindable var inspiration: Inspiration
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Query private var categories: [Category]
    @State private var newTag: String = ""
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $inspiration.title)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                
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
                .frame(minHeight: 150)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            }
            
            Section("分类与标签") {
                HStack {
                    Picker("分类", selection: $inspiration.category) {
                        // 使用唯一名称进行去重展示
                        ForEach(Array(Set(categories.map { $0.name })).sorted(), id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    
                    Button {
                        Task {
                            let availableCatNames = categories.map { $0.name }
                            let category = await AIService.shared.classifyInspiration(title: inspiration.title, notes: inspiration.notes, availableCategories: availableCatNames)
                            inspiration.category = category
                        }
                    } label: {
                        Label("AI 自动分类", systemImage: "sparkles")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("l", modifiers: .command)
                }
                
                VStack(alignment: .leading) {
                    Text("标签")
                        .font(.headline)
                    
                    HStack {
                        TextField("添加新标签", text: $newTag)
                            .onSubmit {
                                addTag()
                            }
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTag.isEmpty)
                    }
                    
                    FlowLayout(items: inspiration.tags) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            
            Section("提醒") {
                Toggle("开启提醒", isOn: Binding(
                    get: { inspiration.reminderDate != nil },
                    set: { isOn in
                        if isOn {
                            // 设置默认提醒时间：第二天晚上十点
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
                ))
                
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
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !inspiration.tags.contains(trimmed) {
            inspiration.tags.append(trimmed)
            newTag = ""
        }
    }
    
    private func removeTag(_ tag: String) {
        inspiration.tags.removeAll { $0 == tag }
    }
}

// 简单的 FlowLayout 实现，用于显示标签
struct FlowLayout<Content: View, Item: Hashable>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            var width = CGFloat.zero
            var height = CGFloat.zero
            
            ForEach(items, id: \.self) { item in
                content(item)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > 300) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { d in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}
