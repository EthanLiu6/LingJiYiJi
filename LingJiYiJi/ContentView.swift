//
//  ContentView.swift
//  LingJiYiJi
//
//  Created by Ethan.Liu on 2026/1/13.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: NavigationItem? = .all
    @State private var selectedInspiration: Inspiration?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    private var isListSelected: Bool {
        if let selection = selection {
            switch selection {
            case .all, .completed, .category:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selection, selectedInspiration: $selectedInspiration)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            if isListSelected {
                InspirationListView(selectedInspiration: $selectedInspiration, selection: $selection)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 360)
            } else {
                Text("") // 占位，当选择统计或设置时，中间栏留空或隐藏
                    .navigationSplitViewColumnWidth(0)
            }
        } detail: {
            detailView
                .navigationSplitViewColumnWidth(min: 400, ideal: 450)
        }
        .frame(minWidth: 1000, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selection)
        .onAppear {
            setupDefaultCategories()
            NotificationManager.shared.requestAuthorization()
        }
        .background {
            shortcutsBackground
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        if isListSelected {
            ZStack {
                if let inspiration = selectedInspiration {
                    InspirationDetailView(inspiration: inspiration)
                        .id(inspiration.id)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom).combined(with: .scale(scale: 0.98))),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                } else {
                    ContentUnavailableView("请选择一个灵感", systemImage: "lightbulb", description: Text("从列表中选择一个灵感来查看详情或编辑"))
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedInspiration?.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        } else {
            utilitySection
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }
    
    @ViewBuilder
    private var utilitySection: some View {
        Group {
            if selection == .stats {
                StatsView()
                    .navigationTitle("数据统计")
            } else if selection == .settings {
                SettingsView()
                    .navigationTitle("偏好设置")
            } else {
                Text("选择一个分类")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var shortcutsBackground: some View {
        Group {
            Button("") { selection = .all }
                .keyboardShortcut("1", modifiers: .command)
            Button("") { selection = .completed }
                .keyboardShortcut("2", modifiers: .command)
            Button("") { selection = .stats }
                .keyboardShortcut("3", modifiers: .command)
            Button("") { selection = .settings }
                .keyboardShortcut(",", modifiers: .command)
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
    
    private func setupDefaultCategories() {
        let descriptor = FetchDescriptor<Category>()
        guard let existingCategories = try? modelContext.fetch(descriptor) else { return }
        
        // 如果已经有任何分类了，说明已经初始化过，不再强制添加默认分类
        // 这样用户删除或重命名默认分类后，下次启动就不会再自动创建
        if !existingCategories.isEmpty {
            // 仍然保留清理逻辑，防止数据异常
            var hasChanges = false
            
            // 1. 深度清理：同时处理名称重复和 ID 重复
            let nameGrouped = Dictionary(grouping: existingCategories, by: { $0.name })
            for (_, cats) in nameGrouped where cats.count > 1 {
                let sortedCats = cats.sorted { $0.createdAt < $1.createdAt }
                for i in 1..<sortedCats.count {
                    modelContext.delete(sortedCats[i])
                }
                hasChanges = true
            }
            
            let idGrouped = Dictionary(grouping: existingCategories, by: { $0.id })
            for (_, cats) in idGrouped where cats.count > 1 {
                let sortedCats = cats.sorted { $0.createdAt < $1.createdAt }
                for i in 1..<sortedCats.count {
                    modelContext.delete(sortedCats[i])
                }
                hasChanges = true
            }
            
            if hasChanges {
                try? modelContext.save()
            }
            return
        }
        
        // 只有在完全没有任何分类时（第一次启动），才添加默认分类
        let defaults = Category.defaultCategories
        for (index, defaultCat) in defaults.enumerated() {
            let newCat = Category(name: defaultCat.name, icon: defaultCat.icon, orderIndex: index)
            modelContext.insert(newCat)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Inspiration.self, Category.self], inMemory: true)
}
