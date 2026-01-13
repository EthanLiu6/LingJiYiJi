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
                .frame(minWidth: 200)
        } content: {
            if isListSelected {
                InspirationListView(selectedInspiration: $selectedInspiration, selection: $selection)
                    .navigationSplitViewColumnWidth(min: 300, ideal: 400)
            } else {
                Text("") // 占位，当选择统计或设置时，中间栏留空或隐藏
                    .navigationSplitViewColumnWidth(0)
            }
        } detail: {
            detailView
        }
        .frame(minWidth: 900, maxWidth: .infinity, minHeight: 480, maxHeight: .infinity)
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
        
        var hasChanges = false
        
        // 1. 深度清理：同时处理名称重复和 ID 重复
        // 先按名称清理
        let nameGrouped = Dictionary(grouping: existingCategories, by: { $0.name })
        for (_, cats) in nameGrouped where cats.count > 1 {
            let sortedCats = cats.sorted { $0.createdAt < $1.createdAt }
            for i in 1..<sortedCats.count {
                modelContext.delete(sortedCats[i])
            }
            hasChanges = true
        }
        
        // 再按 ID 清理（针对后台报错的 ID 重复问题）
        let idGrouped = Dictionary(grouping: existingCategories, by: { $0.id })
        for (_, cats) in idGrouped where cats.count > 1 {
            // 如果 ID 相同但还没被上面的名称清理掉，则保留第一个
            let sortedCats = cats.sorted { $0.createdAt < $1.createdAt }
            for i in 1..<sortedCats.count {
                modelContext.delete(sortedCats[i])
            }
            hasChanges = true
        }
        
        if hasChanges {
            try? modelContext.save()
            // 如果清理了数据，直接返回，等待下次刷新
            return
        }
        
        // 2. 检查并添加缺失的默认分类
        let currentNames = Set(existingCategories.map { $0.name })
        let defaults = Category.defaultCategories
        
        for (index, defaultCat) in defaults.enumerated() {
            if !currentNames.contains(defaultCat.name) {
                let newCat = Category(name: defaultCat.name, icon: defaultCat.icon, orderIndex: index)
                modelContext.insert(newCat)
                hasChanges = true
            }
        }
        
        if hasChanges {
            try? modelContext.save()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Inspiration.self, Category.self], inMemory: true)
}
