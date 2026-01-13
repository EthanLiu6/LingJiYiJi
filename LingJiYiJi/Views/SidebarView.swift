import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 侧边栏导航项枚举
enum NavigationItem: Hashable {
    case all                // 全部灵感
    case completed          // 已完成
    case category(String)   // 具体分类（关联分类名称）
    case stats              // 数据统计
    case settings           // 偏好设置
}

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selection: NavigationItem?           // 与父视图共享的选中状态
    @Binding var selectedInspiration: Inspiration?    // 与父视图共享的选中灵感项
    
    // 从数据库获取分类（按 orderIndex 排序）和灵感数据
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var inspirations: [Inspiration]
    
    @State private var showingAddCategory = false     // 控制新建分类弹窗
    @State private var newCategoryName = ""           // 新分类输入框文本
    @State private var editingCategory: Category?     // 当前正在重命名的分类
    @State private var editName: String = ""          // 重命名输入框文本
    @State private var hoveredItem: NavigationItem?   // 鼠标悬停项

    /// 辅助方法：构建统一风格的侧边栏链接按钮
    @ViewBuilder
    private func sidebarLink(title: String, icon: String, value: NavigationItem, count: Int? = nil) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selection != value {
                    selectedInspiration = nil // 切换分类时，清空当前选中的灵感详情
                    selection = value
                }
            }
        } label: {
            HStack {
                Label {
                    Text(title)
                        .foregroundColor(selection == value ? .white : .primary.opacity(0.8))
                } icon: {
                    Image(systemName: icon)
                        .symbolRenderingMode(.monochrome)
                        .foregroundColor(selection == value ? .white : Color(red: 0.2, green: 0.5, blue: 0.9))
                }
                Spacer()
                // 显示该分类下的灵感数量
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(selection == value ? .white : Color(red: 0.2, green: 0.5, blue: 0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(selection == value ? .white.opacity(0.2) : Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(hoveredItem == value ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredItem = hovering ? value : nil
            }
        }
        .listRowBackground(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(selection == value ? Color(red: 0.2, green: 0.5, blue: 0.9) : (hoveredItem == value ? Color.primary.opacity(0.05) : Color.clear))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                
                if selection == value {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .shadow(color: Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部 Logo 与品牌区域
            HStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("灵机一记")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("记录你的每一个灵感")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            List {
                Section("我的灵感") {
                    sidebarLink(title: "全部灵感", icon: "lightbulb.fill", value: .all, count: inspirations.count)
                    sidebarLink(title: "已完成", icon: "checkmark.circle.fill", value: .completed, count: inspirations.filter { $0.isCompleted }.count)
                }
                
                Section {
                    // 1. 固定展示“未分类”在分类列表首位
                    if let unclassified = categories.first(where: { $0.name == "未分类" }) {
                        sidebarLink(title: unclassified.name, icon: unclassified.icon, value: .category(unclassified.name), count: inspirations.filter { $0.category == unclassified.name }.count)
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDrop(providers: providers, to: unclassified)
                            }
                    }
                    
                    // 2. 动态展示用户自定义的其他分类
                    ForEach(categories, id: \.persistentModelID) { category in
                        if category.name != "未分类" {
                            sidebarLink(title: category.name, icon: category.icon, value: .category(category.name), count: inspirations.filter { $0.category == category.name }.count)
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    handleDrop(providers: providers, to: category)
                                }
                                .contextMenu {
                                    if !isDefaultCategory(category.name) {
                                        Button {
                                            editingCategory = category
                                            editName = category.name
                                        } label: {
                                            Label("重命名", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteCategory(category)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                    }
                    .onMove(perform: moveCategories)
                } header: {
                    HStack {
                        Text("分类")
                        Spacer()
                        Button {
                            showingAddCategory.toggle()
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("视图") {
                    sidebarLink(title: "统计报表", icon: "chart.pie.fill", value: .stats)
                    sidebarLink(title: "偏好设置", icon: "gearshape.fill", value: .settings)
                }
            }
            .listStyle(.sidebar)
            .background(.ultraThinMaterial)
            .tint(.secondary)
            .navigationTitle("灵机一记")
        }
        .sheet(isPresented: $showingAddCategory) {
            // 新建分类的浮层视图
            VStack(spacing: 16) {
                Text("新建分类")
                    .font(.headline)
                
                TextField("分类名称", text: $newCategoryName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        showingAddCategory = false
                        newCategoryName = ""
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button("创建") {
                        addCategory()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newCategoryName.isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding()
            .frame(width: 250)
        }
        .sheet(item: $editingCategory) { category in
            // 重命名分类的浮层视图
            VStack(spacing: 16) {
                Text("重命名分类")
                    .font(.headline)
                
                TextField("新名称", text: $editName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                HStack {
                    Button("取消") {
                        editingCategory = nil
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    
                    Button("保存") {
                        renameCategory(category)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(editName.isEmpty)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
    
    // MARK: - 逻辑方法
    
    /// 判断是否为系统预设分类（不可删除/重命名）
    private func isDefaultCategory(_ name: String) -> Bool {
        return name == "未分类"
    }
    
    /// 执行删除分类逻辑：同时将灵感归位
    private func deleteCategory(_ category: Category) {
        let categoryName = category.name
        
        // 1. 将该分类下的所有灵感移动到“未分类”
        for inspiration in inspirations {
            if inspiration.category == categoryName {
                inspiration.category = "未分类"
            }
        }
        
        // 2. 如果当前选中了该分类，切换回“全部灵感”
        if case .category(let name) = selection, name == categoryName {
            selection = .all
        }
        
        // 3. 删除分类模型并保存
        modelContext.delete(category)
        try? modelContext.save()
    }
    
    /// 添加新分类
    private func addCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // 检查是否重名
        if !categories.contains(where: { $0.name == trimmedName }) {
            let newCat = Category(name: trimmedName, orderIndex: categories.count)
            modelContext.insert(newCat)
            try? modelContext.save()
        }
        
        newCategoryName = ""
        showingAddCategory = false
    }
    
    /// 重命名分类并同步更新所属灵感的分类属性
    private func renameCategory(_ category: Category) {
        let oldName = category.name
        let trimmedName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty, trimmedName != oldName else {
            editingCategory = nil
            return
        }
        
        // 更新灵感中的分类记录
        for inspiration in inspirations {
            if inspiration.category == oldName {
                inspiration.category = trimmedName
            }
        }
        
        category.name = trimmedName
        try? modelContext.save()
        editingCategory = nil
    }
    
    /// 处理侧边栏分类的拖拽排序
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var revisedItems = categories
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for reverseIndex in 0..<revisedItems.count {
            revisedItems[reverseIndex].orderIndex = reverseIndex
        }
        try? modelContext.save()
    }
    
    /// 处理将灵感拖拽到分类上的“归类”操作
    private func handleDrop(providers: [NSItemProvider], to category: Category) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadObject(ofClass: NSString.self) { (idString, error) in
            if let idString = idString as? String, let uuid = UUID(uuidString: idString) {
                DispatchQueue.main.async {
                    let descriptor = FetchDescriptor<Inspiration>(predicate: #Predicate { $0.id == uuid })
                    if let inspiration = try? modelContext.fetch(descriptor).first {
                        withAnimation(.spring()) {
                            inspiration.category = category.name
                        }
                        try? modelContext.save()
                    }
                }
            }
        }
        return true
    }
}
