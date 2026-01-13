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
    @State private var selection: NavigationItem? = .all       // 侧边栏当前选中项
    @State private var selectedInspiration: Inspiration?      // 列表当前选中灵感项
    @State private var columnVisibility: NavigationSplitViewVisibility = .all // 控制三栏显示状态
    
    // 判断当前侧边栏选中是否属于“列表类”视图
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
        // 使用三栏式布局结构
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第一栏：侧边栏导航
            SidebarView(selection: $selection, selectedInspiration: $selectedInspiration)
                .frame(minWidth: 200)
        } content: {
            // 第二栏：灵感列表
            if isListSelected {
                InspirationListView(selectedInspiration: $selectedInspiration, selection: $selection)
                    .navigationSplitViewColumnWidth(min: 250, ideal: 360, max: 600)
            } else {
                Text("") // 当选中统计或设置时，中间栏占位隐藏
                    .navigationSplitViewColumnWidth(0)
            }
        } detail: {
            // 第三栏：灵感详情
            detailView
                .navigationSplitViewColumnWidth(min: 400, ideal: 450)
        }
        .frame(minWidth: 950, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selection)
        .onAppear {
            setupDefaultCategories() // 首次运行初始化默认分类
            NotificationManager.shared.requestAuthorization()
        }
        .background {
            shortcutsBackground // 注册全局快捷键支持
        }
    }
    
    /// 根据侧边栏选中项动态生成右侧详情视图
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
    
    /// 统计和设置等功能性视图
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
    
    /// 全局快捷键背景层
    @ViewBuilder
    private var shortcutsBackground: some View {
        Group {
            // 使用数字键快速切换分类 (Cmd+1, Cmd+2...)
            Button("") { selection = .all }
                .keyboardShortcut("1", modifiers: .command)
            Button("") { selection = .completed }
                .keyboardShortcut("2", modifiers: .command)
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
    
    /// 初始化默认分类逻辑
    private func setupDefaultCategories() {
        let descriptor = FetchDescriptor<Category>()
        if let count = try? modelContext.fetchCount(descriptor), count == 0 {
            for category in Category.defaultCategories {
                modelContext.insert(category)
            }
        }
    }
}
