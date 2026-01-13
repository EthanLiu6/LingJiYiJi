import SwiftUI
import SwiftData
import AppKit

/// 灵感列表视图：展示选定分类下的所有灵感，支持搜索、排序和快捷添加
struct InspirationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inspirations: [Inspiration]
    @Query private var categories: [Category]
    @Binding var selectedInspiration: Inspiration?   // 与父视图共享的选中项
    @Binding var selection: NavigationItem?          // 当前侧边栏选中项
    
    @State private var searchText: String = ""        // 搜索框文本
    @State private var quickInputText: String = ""    // 顶部快捷输入框文本
    @State private var isCompletedExpanded: Bool = true // “已完成”折叠状态
    @State private var isAddHovered: Bool = false     // 加号按钮悬停动画状态
    @State private var showingDeleteConfirmation = false // 删除确认弹窗
    @State private var inspirationToDelete: Inspiration? // 待删除的灵感项
    
    // 过滤出未完成的灵感（按置顶和自定义顺序排序）
    var pendingInspirations: [Inspiration] {
        filteredInspirations.filter { !$0.isCompleted }
            .sorted { 
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned
                }
                return $0.orderIndex < $1.orderIndex 
            }
    }
    
    // 过滤出已完成的灵感（按创建时间倒序）
    var completedInspirations: [Inspiration] {
        filteredInspirations.filter { $0.isCompleted }
            .sorted { 
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned
                }
                return $0.createdAt > $1.createdAt 
            }
    }
    
    // 根据搜索文本和侧边栏分类过滤后的灵感全集
    var filteredInspirations: [Inspiration] {
        if !searchText.isEmpty {
            return inspirations.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.notes.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        var filtered = inspirations
        if let filter = selection {
            switch filter {
            case .all:
                break
            case .completed:
                filtered = filtered.filter { $0.isCompleted }
            case .category(let cat):
                filtered = filtered.filter { $0.category == cat }
            case .stats, .settings:
                break
            }
        }
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部标题与新建按钮
            HStack {
                Text(titleForSelection)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: addInspiration) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 0.9), Color(red: 0.3, green: 0.6, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isAddHovered ? 1.1 : 1.0)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isAddHovered = hovering
                    }
                }
                .help("新建灵感 (Cmd+N)")
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // 2. 快捷灵感输入框（Sparkles 风格）
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.4, green: 0.5, blue: 0.9), Color(red: 0.6, green: 0.4, blue: 0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    TextField("记录灵感...", text: $quickInputText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .onSubmit {
                            quickAddInspiration()
                        }
                    
                    if !quickInputText.isEmpty {
                        Button(action: quickAddInspiration) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Color(red: 0.4, green: 0.5, blue: 0.9))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .textBackgroundColor).opacity(0.8))
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                Divider()
                    .padding(.horizontal, 24)
            }
            
            // 3. 灵感主列表
            if filteredInspirations.isEmpty {
                // 无数据时的空状态展示
                VStack {
                    Spacer()
                    ContentUnavailableView {
                        Label(searchText.isEmpty ? "尚无灵感" : "未找到匹配灵感", systemImage: "lightbulb.slash")
                    } description: {
                        Text(searchText.isEmpty ? "记录你的第一个灵感" : "尝试更换关键词")
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
            } else {
                List {
                        // 未完成部分
                        Section {
                            ForEach(pendingInspirations) { inspiration in
                                InspirationRowView(inspiration: inspiration, selectedInspiration: $selectedInspiration, searchText: $searchText, selection: $selection)
                                    .contentShape(Rectangle())
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedInspiration?.id == inspiration.id ? Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.1) : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(selectedInspiration?.id == inspiration.id ? Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.2) : Color.clear, lineWidth: 1)
                                            )
                                            .padding(.horizontal, 8)
                                    )
                                    .onDrag {
                                        NSItemProvider(object: inspiration.id.uuidString as NSString)
                                    }
                                    .contextMenu {
                                        rowContextMenu(inspiration)
                                    }
                            }
                            .onMove(perform: moveInspirations)
                        }
                        
                        // 已完成部分（带折叠功能）
                        if !completedInspirations.isEmpty {
                            Section(isExpanded: $isCompletedExpanded) {
                                ForEach(completedInspirations) { inspiration in
                                    InspirationRowView(inspiration: inspiration, selectedInspiration: $selectedInspiration, searchText: $searchText, selection: $selection)
                                        .contentShape(Rectangle())
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                        .listRowBackground(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedInspiration?.id == inspiration.id ? Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.1) : Color.clear)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(selectedInspiration?.id == inspiration.id ? Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.2) : Color.clear, lineWidth: 1)
                                                )
                                                .padding(.horizontal, 8)
                                        )
                                        .onDrag {
                                            NSItemProvider(object: inspiration.id.uuidString as NSString)
                                        }
                                        .contextMenu {
                                            rowContextMenu(inspiration)
                                        }
                                }
                            } header: {
                                HStack(spacing: 4) {
                                    Text("已完成")
                                    Text("\(completedInspirations.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .tint(.secondary)
                .onTapGesture {
                    // 点击空白处取消输入框聚焦
                    NSApp.sendAction(#selector(NSTextField.resignFirstResponder), to: nil, from: nil)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("")
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索灵感...")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredInspirations)
        .alert("确定要删除吗？", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let inspiration = inspirationToDelete {
                    deleteInspiration(inspiration)
                }
            }
            Button("取消", role: .cancel) {
                inspirationToDelete = nil
            }
        } message: {
            Text("删除后将无法找回该灵感。")
        }
        .background {
            // 快捷键支持（隐形按钮实现）
            Group {
                Button("") {
                    if let selected = selectedInspiration {
                        confirmDelete(selected)
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
                Button("") {
                    if let selected = selectedInspiration {
                        confirmDelete(selected)
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

    /// 右键菜单构建
    @ViewBuilder
    private func rowContextMenu(_ inspiration: Inspiration) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                inspiration.isPinned.toggle()
            }
        } label: {
            Label(inspiration.isPinned ? "取消置顶" : "置顶", systemImage: inspiration.isPinned ? "pin.slash" : "pin")
        }
        
        Button {
            inspiration.isCompleted.toggle()
            if inspiration.isCompleted {
                // 自动关闭提醒
                inspiration.reminderDate = nil
                NotificationManager.shared.cancelNotification(for: inspiration)
            }
        } label: {
            Label(inspiration.isCompleted ? "设为未完成" : "完成", systemImage: inspiration.isCompleted ? "circle" : "checkmark.circle")
        }
        
        Divider()
        
        Button(role: .destructive) {
            confirmDelete(inspiration)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
    // MARK: - 辅助方法与逻辑
    
    private var titleForSelection: String {
        if !searchText.isEmpty { return "搜索结果" }
        guard let filter = selection else { return "全部灵感" }
        switch filter {
        case .all: return "全部灵感"
        case .completed: return "已完成"
        case .category(let name): return name
        case .stats: return "数据统计"
        case .settings: return "偏好设置"
        }
    }
    
    /// 快捷添加灵感逻辑
    private func quickAddInspiration() {
        let trimmed = quickInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let minOrder = pendingInspirations.map { $0.orderIndex }.min() ?? 0
        let newInspiration = Inspiration(title: trimmed, orderIndex: minOrder - 1)
        
        modelContext.insert(newInspiration)
        try? modelContext.save()
        selectedInspiration = newInspiration
        quickInputText = ""
        
        // 异步调用 AI 进行自动分类
        Task {
            let availableCatNames = categories.map { $0.name }
            let category = await AIService.shared.classifyInspiration(title: newInspiration.title, notes: "", availableCategories: availableCatNames)
            newInspiration.category = category
        }
    }
    
    /// 标准添加灵感逻辑
    private func addInspiration() {
        let minOrder = pendingInspirations.map { $0.orderIndex }.min() ?? 0
        let newInspiration = Inspiration(title: "新灵感", orderIndex: minOrder - 1)
        modelContext.insert(newInspiration)
        selectedInspiration = newInspiration
    }
    
    private func confirmDelete(_ inspiration: Inspiration) {
        inspirationToDelete = inspiration
        showingDeleteConfirmation = true
    }
    
    private func deleteInspiration(_ inspiration: Inspiration) {
        modelContext.delete(inspiration)
        if selectedInspiration?.id == inspiration.id {
            selectedInspiration = nil
        }
        inspirationToDelete = nil
    }
    
    /// 手动拖拽排序逻辑
    private func moveInspirations(from source: IndexSet, to destination: Int) {
        var revisedItems = pendingInspirations
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for reverseIndex in 0..<revisedItems.count {
            revisedItems[reverseIndex].orderIndex = reverseIndex
        }
    }
}

/// 列表单行视图组件
struct InspirationRowView: View {
    @Bindable var inspiration: Inspiration
    @Binding var selectedInspiration: Inspiration?
    @Binding var searchText: String
    @Binding var selection: NavigationItem?
    @FocusState private var isFocused: Bool
    @State private var isEditing: Bool = false
    @State private var isHovered: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 1. 复选框（勾选框）
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(inspiration.isCompleted ? Color(red: 0.1, green: 0.7, blue: 0.4) : Color.primary.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inspiration.isCompleted ? Color(red: 0.1, green: 0.7, blue: 0.4).opacity(0.1) : Color.clear)
                    )
                
                if inspiration.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.1, green: 0.7, blue: 0.4))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                 withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                     inspiration.isCompleted.toggle()
                     if inspiration.isCompleted {
                         // 勾选已完成后，自动关闭提醒
                         inspiration.reminderDate = nil
                         NotificationManager.shared.cancelNotification(for: inspiration)
                         // 播放系统勾选音效
                         NSSound(named: "Glass")?.play()
                     }
                 }
            }
            
            // 2. 灵感标题展示
            VStack(alignment: .leading, spacing: 2) {
                Text(inspiration.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(inspiration.isCompleted)
                    .foregroundColor(inspiration.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
                
                // 辅助信息：分类和提醒图标
                HStack(spacing: 8) {
                    if !inspiration.category.isEmpty && inspiration.category != "未分类" {
                        Text(inspiration.category)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }
                    
                    if inspiration.reminderDate != nil {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.2))
                    }
                    
                    if inspiration.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.9))
                    }
                }
            }
            
            Spacer()
            
            // 3. 鼠标悬停时显示的箭头图标
            if isHovered || selectedInspiration?.id == inspiration.id {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            selectedInspiration = inspiration
        }
    }
}
