import SwiftUI
import SwiftData
import AppKit

struct InspirationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inspirations: [Inspiration]
    @Query private var categories: [Category]
    @Binding var selectedInspiration: Inspiration?
    var filter: NavigationItem?
    
    @State private var searchText: String = ""
    @State private var quickInputText: String = ""
    @State private var isCompletedExpanded: Bool = true
    
    var pendingInspirations: [Inspiration] {
        filteredInspirations.filter { !$0.isCompleted }
            .sorted { 
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned
                }
                return $0.orderIndex < $1.orderIndex 
            }
    }
    
    var completedInspirations: [Inspiration] {
        filteredInspirations.filter { $0.isCompleted }
            .sorted { 
                if $0.isPinned != $1.isPinned {
                    return $0.isPinned
                }
                return $0.createdAt > $1.createdAt 
            }
    }
    
    var filteredInspirations: [Inspiration] {
        var filtered = inspirations
        
        // 侧边栏导航过滤
        if let filter = filter {
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
        
        // 搜索过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.notes.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航/标题区域
            HStack {
                Text(titleForSelection)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                
                Button(action: addInspiration) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // 快捷输入框
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
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
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                Divider()
                    .padding(.horizontal, 24)
            }
            
            if filteredInspirations.isEmpty {
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
                List(selection: $selectedInspiration) {
                        Section {
                            ForEach(pendingInspirations) { inspiration in
                                InspirationRowView(inspiration: inspiration)
                                    .tag(inspiration)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                                    .onTapGesture {
                                    selectedInspiration = inspiration
                                }
                                .onDrag {
                                    NSItemProvider(object: inspiration.id.uuidString as NSString)
                                }
                                .contextMenu {
                                    rowContextMenu(inspiration)
                                }
                            }
                            .onMove(perform: moveInspirations)
                        }
                        
                        if !completedInspirations.isEmpty {
                            Section(isExpanded: $isCompletedExpanded) {
                                ForEach(completedInspirations) {
                                    inspiration in
                                    InspirationRowView(inspiration: inspiration)
                                        .tag(inspiration)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                                        .onTapGesture {
                                            selectedInspiration = inspiration
                                        }
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
                .listStyle(.sidebar) // 使用 sidebar 样式以获得更好的悬停/选中效果
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("")
        .searchable(text: $searchText, placement: .toolbar, prompt: "搜索灵感...")
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: filteredInspirations)
        .background {
            // 隐形按钮用于处理 Cmd+Backspace 删除操作
            Button("") {
                if let selected = selectedInspiration {
                    deleteInspiration(selected)
                }
            }
            .keyboardShortcut(.delete, modifiers: .command)
            .opacity(0)
            .allowsHitTesting(false)
        }
    }

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
        } label: {
            Label(inspiration.isCompleted ? "设为未完成" : "完成", systemImage: inspiration.isCompleted ? "circle" : "checkmark.circle")
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteInspiration(inspiration)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
    private var titleForSelection: String {
        guard let filter = filter else { return "全部灵感" }
        switch filter {
        case .all: return "全部灵感"
        case .completed: return "已完成"
        case .category(let name): return name
        case .stats: return "数据统计"
        case .settings: return "偏好设置"
        }
    }
    
    private func quickAddInspiration() {
        let trimmed = quickInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 计算新的 orderIndex (放在最前面)
        let minOrder = pendingInspirations.map { $0.orderIndex }.min() ?? 0
        let newInspiration = Inspiration(title: trimmed, orderIndex: minOrder - 1)
        
        modelContext.insert(newInspiration)
        try? modelContext.save() // 显式保存
        selectedInspiration = newInspiration
        quickInputText = ""
        
        // 自动触发 AI 分类
        Task {
            let availableCatNames = categories.map { $0.name }
            let category = await AIService.shared.classifyInspiration(title: newInspiration.title, notes: "", availableCategories: availableCatNames)
            newInspiration.category = category
        }
    }
    
    private func addInspiration() {
        let minOrder = pendingInspirations.map { $0.orderIndex }.min() ?? 0
        let newInspiration = Inspiration(title: "新灵感", orderIndex: minOrder - 1)
        modelContext.insert(newInspiration)
        selectedInspiration = newInspiration
    }
    
    private func deleteInspiration(_ inspiration: Inspiration) {
        modelContext.delete(inspiration)
        if selectedInspiration?.id == inspiration.id {
            selectedInspiration = nil
        }
    }
    
    private func moveInspirations(from source: IndexSet, to destination: Int) {
        var revisedItems = pendingInspirations
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        // 更新所有受影响项的 orderIndex
        for reverseIndex in 0..<revisedItems.count {
            revisedItems[reverseIndex].orderIndex = reverseIndex
        }
    }
}

struct InspirationRowView: View {
    @Bindable var inspiration: Inspiration
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // 方形圆角勾选框
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(inspiration.isCompleted ? Color.green.opacity(0.5) : Color.primary.opacity(0.2), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(inspiration.isCompleted ? Color.green.opacity(0.1) : Color.clear)
                    )
                
                if inspiration.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                 withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                     inspiration.isCompleted.toggle()
                     if inspiration.isCompleted {
                         // 播放系统勾选音效
                         NSSound(named: "Glass")?.play()
                     }
                 }
             }
            
            // 标题
            HStack(spacing: 6) {
                if inspiration.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.8))
                        .rotationEffect(.degrees(45))
                }
                
                Text(inspiration.title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(inspiration.isCompleted ? .secondary.opacity(0.6) : .primary)
                    .strikethrough(inspiration.isCompleted)
            }
            
            Spacer()
            
            // 右侧元数据
            HStack(spacing: 12) {
                if !inspiration.category.isEmpty {
                    Text(inspiration.category)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.6))
                }
                
                Image(systemName: "text.justify.left")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.4))
                
                Text(formattedDate)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(dateColor)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(inspiration.createdAt) {
            return "今天"
        } else if calendar.isDateInYesterday(inspiration.createdAt) {
            return "昨天"
        } else {
            return inspiration.createdAt.formatted(.dateTime.month().day())
        }
    }
    
    private var dateColor: Color {
        let calendar = Calendar.current
        if inspiration.isCompleted {
            return .secondary.opacity(0.4)
        }
        if calendar.isDateInToday(inspiration.createdAt) {
            return .blue.opacity(0.8)
        } else if calendar.isDateInYesterday(inspiration.createdAt) {
            return .red.opacity(0.7)
        } else {
            return .secondary.opacity(0.6)
        }
    }
}
