import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var inspirations: [Inspiration]
    
    @State private var newCategoryName: String = ""
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @State private var editingCategory: Category?
    @State private var editName: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionView(title: "智谱 AI 配置", icon: "sparkles") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.orange)
                            SecureField("智谱 AI API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Text("已切换至智谱 GLM-4.5-Flash 模型。输入您的 Key 后将启用自动分类，如果不输入则使用内置默认 Key。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .cornerRadius(12)
                }
                
                SectionView(title: "分类管理", icon: "folder.fill") {
                    VStack(spacing: 12) {
                        HStack {
                            TextField("新分类名称", text: $newCategoryName)
                                .textFieldStyle(.roundedBorder)
                            Button(action: addCategory) {
                                Label("添加", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newCategoryName.isEmpty)
                        }
                        .padding(.bottom, 8)
                        
                        VStack(spacing: 1) {
                            ForEach(categories) { category in
                                CategoryRow(category: category, isDefault: isDefaultCategory(category.name)) {
                                    editingCategory = category
                                    editName = category.name
                                } onDelete: {
                                    let catName = category.name
                                    // 将该分类下的所有灵感移动到"未分类"
                                    for inspiration in inspirations {
                                        if inspiration.category == catName {
                                            inspiration.category = "未分类"
                                        }
                                    }
                                    modelContext.delete(category)
                                    try? modelContext.save()
                                }
                            }
                        }
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            AIService.shared.setApiKey(apiKey)
        }
        .onChange(of: apiKey) { _, newValue in
            AIService.shared.setApiKey(newValue)
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
                        let oldName = category.name
                        let newName = editName.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if !newName.isEmpty && oldName != newName {
                            // 更新所有关联该分类的灵感
                            for inspiration in inspirations {
                                if inspiration.category == oldName {
                                    inspiration.category = newName
                                }
                            }
                            category.name = newName
                            try? modelContext.save()
                        }
                        editingCategory = nil
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
    
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !categories.contains(where: { $0.name == trimmed }) {
            let maxOrder = categories.map { $0.orderIndex }.max() ?? 0
            let newCat = Category(name: trimmed, orderIndex: maxOrder + 1)
            modelContext.insert(newCat)
            try? modelContext.save()
            newCategoryName = ""
        }
    }
    
    private func isDefaultCategory(_ name: String) -> Bool {
        name == "未分类"
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.secondary)
            content
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isDefault: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(category.name)
            Spacer()
            
            if !isDefault {
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("系统")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
