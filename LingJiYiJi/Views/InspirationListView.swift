import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct InspirationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inspirations: [Inspiration]
    @Query private var categories: [Category]
    @Binding var selectedInspiration: Inspiration?
    @Binding var selection: NavigationItem?
    
    @State private var searchText: String = ""
    @State private var quickInputText: String = ""
    @State private var isCompletedExpanded: Bool = true
    @State private var isAddHovered: Bool = false
    @State private var showingDeleteConfirmation = false
    @State private var inspirationToDelete: Inspiration?
    @State private var draggedItem: Inspiration?
    
    var pinnedInspirations: [Inspiration] {
        filteredInspirations.filter { !$0.isCompleted && $0.isPinned }
            .sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var unpinnedInspirations: [Inspiration] {
        filteredInspirations.filter { !$0.isCompleted && !$0.isPinned }
            .sorted { $0.orderIndex < $1.orderIndex }
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
        // 如果正在搜索，展示全局搜索结果
        if !searchText.isEmpty {
            return inspirations.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) || 
                $0.notes.localizedCaseInsensitiveContains(searchText) 
            }
        }
        
        var filtered = inspirations
        
        // 如果没有搜索，应用侧边栏导航过滤
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
            // 顶部导航/标题区域
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

            // 快捷输入框
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
                List {
                    if !pinnedInspirations.isEmpty {
                        Section {
                            ForEach(pinnedInspirations) { inspiration in
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
                                    .contextMenu {
                                        rowContextMenu(inspiration)
                                    }
                                    .onDrag {
                                        self.draggedItem = inspiration
                                        return NSItemProvider(object: inspiration.id.uuidString as NSString)
                                    }
                                    .onDrop(of: [.text], delegate: InspirationDropDelegate(
                                        item: inspiration,
                                        inspirations: pinnedInspirations,
                                        draggedItem: $draggedItem,
                                        moveAction: { from, to in
                                            moveInspiration(from: from, to: to, in: pinnedInspirations)
                                        }
                                    ))
                            }
                        } header: {
                            HStack {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 10))
                                Text("置顶")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        }
                    }

                    Section {
                        ForEach(unpinnedInspirations) { inspiration in
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
                                .contextMenu {
                                    rowContextMenu(inspiration)
                                }
                                .onDrag {
                                    self.draggedItem = inspiration
                                    return NSItemProvider(object: inspiration.id.uuidString as NSString)
                                }
                                .onDrop(of: [.text], delegate: InspirationDropDelegate(
                                    item: inspiration,
                                    inspirations: unpinnedInspirations,
                                    draggedItem: $draggedItem,
                                    moveAction: { from, to in
                                        moveInspiration(from: from, to: to, in: unpinnedInspirations)
                                    }
                                ))
                        }
                    } header: {
                        if !pinnedInspirations.isEmpty {
                            Text("灵感")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                    
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
                                    .contextMenu {
                                        rowContextMenu(inspiration)
                                    }
                                    .onDrag {
                                        NSItemProvider(object: inspiration.id.uuidString as NSString)
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
                .tint(.secondary) // 关键：强制设置强调色为灰色，消除系统默认的紫色
                .onTapGesture {
                    // 点击列表空白处，取消所有编辑状态
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
            // 隐形按钮用于处理删除快捷键
            Group {
                // Command + Backspace (标准 Mac 删除快捷键)
                Button("") {
                    if let selected = selectedInspiration {
                        confirmDelete(selected)
                    }
                }
                .keyboardShortcut(.delete, modifiers: .command)
                
                // 单独的 Backspace/Delete 键 (在选中列表项时)
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
            confirmDelete(inspiration)
        } label: {
            Label("删除", systemImage: "trash")
        }
    }
    
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
    
    private func quickAddInspiration() {
        let trimmed = quickInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // 计算新的 orderIndex (放在最前面)
        let minOrder = unpinnedInspirations.map { $0.orderIndex }.min() ?? 0
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
        let minOrder = unpinnedInspirations.map { $0.orderIndex }.min() ?? 0
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
    
    private func moveInspiration(from source: Inspiration, to destination: Inspiration, in list: [Inspiration]) {
        var revisedItems = list
        guard let fromIndex = revisedItems.firstIndex(of: source),
              let toIndex = revisedItems.firstIndex(of: destination) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            revisedItems.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
            
            // 更新所有项的 orderIndex
            for index in 0..<revisedItems.count {
                revisedItems[index].orderIndex = index
            }
            
            try? modelContext.save()
        }
    }
}

struct InspirationDropDelegate: DropDelegate {
    let item: Inspiration
    let inspirations: [Inspiration]
    @Binding var draggedItem: Inspiration?
    let moveAction: (Inspiration, Inspiration) -> Void

    func performDrop(info: DropInfo) -> Bool {
        self.draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let from = inspirations.firstIndex(of: draggedItem),
              let to = inspirations.firstIndex(of: item)
        else { return }

        if inspirations[to].id != draggedItem.id {
            moveAction(draggedItem, item)
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

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
            // 方形圆角勾选框
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
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.2)) // 鲜艳的能量橙
                        .rotationEffect(.degrees(45))
                }
                
                if isEditing {
                    TextField("灵感标题", text: $inspiration.title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(inspiration.isCompleted ? .secondary.opacity(0.6) : .primary)
                        .strikethrough(inspiration.isCompleted)
                        .focused($isFocused)
                        .onSubmit {
                            saveChanges()
                        }
                        .onAppear {
                            isFocused = true
                        }
                        .onChange(of: isFocused) { _, newValue in
                            if !newValue && isEditing {
                                saveChanges()
                            }
                        }
                } else {
                    Text(inspiration.title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(inspiration.isCompleted ? .secondary.opacity(0.6) : .primary)
                        .strikethrough(inspiration.isCompleted)
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditing = true
                            }
                        }
                }
            }
            
            Spacer()
            
            // 右侧元数据
            HStack(spacing: 12) {
                if !inspiration.notes.isEmpty {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                if !inspiration.category.isEmpty && inspiration.category != "未分类" {
                    Text(inspiration.category)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
            }
            .opacity(isEditing ? 0 : 1)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered && !isEditing ? 1.01 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectThisInspiration()
            }
        }
        .onChange(of: selectedInspiration) { _, newValue in
            // 如果选中的不是当前行，且当前行正在编辑，则保存并退出编辑
            if isEditing && newValue?.id != inspiration.id {
                saveChanges()
            }
        }
    }
    
    private func saveChanges() {
        isEditing = false
        isFocused = false
        try? inspiration.modelContext?.save()
    }
    
    private func selectThisInspiration() {
        selectedInspiration = inspiration
        // 如果是在搜索状态下点击，自动跳转到对应分类
        if !searchText.isEmpty {
            if inspiration.isCompleted {
                selection = .completed
            } else if !inspiration.category.isEmpty {
                selection = .category(inspiration.category)
            } else {
                selection = .all
            }
        }
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
