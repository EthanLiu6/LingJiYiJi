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
    @Query(sort: \Category.orderIndex) private var categories: [Category]
    @Query private var inspirations: [Inspiration]
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var editingCategory: Category?
    @State private var editName: String = ""
    
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
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("灵机一记")
                        .font(.system(size: 16, weight: .bold))
                    Text("记录你的每一个灵感")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            List(selection: $selection) {
                Section("我的灵感") {
                    NavigationLink(value: NavigationItem.all) {
                        Label("全部灵感", systemImage: "lightbulb.fill")
                    }
                    NavigationLink(value: NavigationItem.completed) {
                        Label("已完成", systemImage: "checkmark.circle.fill")
                    }
                }
                
                Section {
                    // 1. 固定展示“未分类”在首位
                    if let unclassified = categories.first(where: { $0.name == "未分类" }) {
                        NavigationLink(value: NavigationItem.category(unclassified.name)) {
                            Label(unclassified.name, systemImage: unclassified.icon)
                        }
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            handleDrop(providers: providers, to: unclassified)
                        }
                    }
                    
                    // 2. 展示其他分类
                    ForEach(categories, id: \.persistentModelID) { category in
                        if category.name != "未分类" {
                            NavigationLink(value: NavigationItem.category(category.name)) {
                                Label(category.name, systemImage: category.icon)
                            }
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
                                        modelContext.delete(category)
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
                    NavigationLink(value: NavigationItem.stats) {
                        Label("统计报表", systemImage: "chart.pie.fill")
                    }
                    NavigationLink(value: NavigationItem.settings) {
                        Label("偏好设置", systemImage: "gearshape.fill")
                    }
                }
            }
            .listStyle(.sidebar)
            .background(.ultraThinMaterial)
            .accentColor(.primary)
            .navigationTitle("灵机一记")
        }
        .sheet(isPresented: $showingAddCategory) {
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
                        category.name = editName
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
