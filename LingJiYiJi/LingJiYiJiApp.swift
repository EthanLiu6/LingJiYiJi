//
//  LingJiYiJiApp.swift
//  LingJiYiJi
//
//  Created by Ethan.Liu on 2026/1/13.
//

import SwiftUI
import SwiftData
import AppKit

@main
struct LingJiYiJiApp: App {
    // 使用适配器连接传统的 NSApplicationDelegate 逻辑
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer
    
    init() {
        // 应用启动时请求通知权限
        NotificationManager.shared.requestAuthorization()
        
        do {
            // 配置 SwiftData 存储方案
            let schema = Schema([
                Inspiration.self,
                Category.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("无法创建数据库容器: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(.primary) // 统一应用主色调
        }
        .modelContainer(container) // 注入数据库上下文
    }
}

/// 处理 macOS 特定的应用生命周期行为
class AppDelegate: NSObject, NSApplicationDelegate {
    // 当所有窗口关闭时，不退出应用（使其在后台运行）
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // 处理点击 Dock 图标等重新打开应用的请求
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // 如果当前没有可见窗口，重新激活应用窗口
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}
