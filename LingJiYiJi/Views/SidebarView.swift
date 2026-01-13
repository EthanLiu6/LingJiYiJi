import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum NavigationItem: Hashable {
    case all
    case completed
    case category(String)
    case stats
    case settings
}

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selection: NavigationItem?
    @Binding var selectedInspiration: Inspiration?
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var inspirations: [Inspiration]
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: Category?
    @State private var editName: String = ""
    
    @State private var hoveredItem: NavigationItem?

    @ViewBuilder
    private func sidebarLink(title: String, icon: String, value: NavigationItem, count: Int? = nil) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selection != value {
                    selectedInspiration = nil // 仅在切换分类时清空详情
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
            // 品牌 Logo 区域
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
                    // 1. 固定展示“未分类”在首位
                    if let unclassified = categories.first(where: { $0.name == "未分类" }) {
                        sidebarLink(title: unclassified.name, icon: unclassified.icon, value: .category(unclassified.name), count: inspirations.filter { $0.category == unclassified.name }.count)
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDrop(providers: providers, to: unclassified)
                            }
                    }
                    
                    // 2. 展示其他分类
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
            .tint(.secondary) // 强制设置侧边栏强调色为灰色
            .navigationTitle("灵机一记")
        }
        .sheet(isPresented: $showingAddCategory) {
            // ... (rest of the file remains same)
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
            VStack(spacing: 16) {
                Text("重命名分类")
                    .font(.headline)
                TextField("名称", text: $editName)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("取消") { editingCategory = nil }
                    Button("保存") {
                        renameCategory(category, to: editName)
                        editingCategory = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
    
    private func isDefaultCategory(_ name: String) -> Bool {
        name == "未分类"
    }
    
    private func deleteCategory(_ category: Category) {
        let categoryName = category.name
        
        // 1. 将该分类下的所有灵感归入“未分类”
        for inspiration in inspirations {
            if inspiration.category == categoryName {
                inspiration.category = "未分类"
            }
        }
        
        // 2. 如果当前选中了该分类，切换到“全部灵感”
        if case .category(let selectedName) = selection, selectedName == categoryName {
            selection = .all
        }
        
        // 3. 删除分类
        modelContext.delete(category)
        try? modelContext.save()
    }
    
    private func renameCategory(_ category: Category, to newName: String) {
        let oldName = category.name
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedNewName.isEmpty && trimmedNewName != oldName else { return }
        
        // 1. 更新所有相关灵感的分类名称
        for inspiration in inspirations {
            if inspiration.category == oldName {
                inspiration.category = trimmedNewName
            }
        }
        
        // 2. 如果当前选中了该分类，更新选中状态
        if case .category(let selectedName) = selection, selectedName == oldName {
            selection = .category(trimmedNewName)
        }
        
        // 3. 更新分类名称
        category.name = trimmedNewName
        try? modelContext.save()
    }
    
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            // 检查是否已存在同名分类（由于 UI 层面可能滞后）
            if !categories.contains(where: { $0.name == trimmed }) {
                let newCat = Category(name: trimmed, orderIndex: categories.count)
                modelContext.insert(newCat)
                try? modelContext.save()
            }
            newCategoryName = ""
            showingAddCategory = false
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var revisedItems = categories
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for index in 0..<revisedItems.count {
            revisedItems[index].orderIndex = index
        }
    }
    
    private func handleDrop(providers: [NSItemProvider], to category: Category) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadObject(ofClass: NSString.self) { (idString, error) in
            if let idString = idString as? String, let uuid = UUID(uuidString: idString) {
                DispatchQueue.main.async {
                    // 查找对应的灵感并更新分类
                    let descriptor = FetchDescriptor<Inspiration>(predicate: #Predicate { $0.id == uuid })
                    if let inspiration = try? modelContext.fetch(descriptor).first {
                        inspiration.category = category.name
                        try? modelContext.save()
                    }
                }
            }
        }
        return true
    }
}
