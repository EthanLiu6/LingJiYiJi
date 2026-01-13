import Foundation
import SwiftData

/// 分类数据模型：用于对灵感进行归类管理
@Model
final class Category {
    var id: UUID = UUID()
    @Attribute(.unique) var name: String = "" // 分类名称，设为唯一属性
    var icon: String = "folder"               // 分类图标（SF Symbols 名称）
    var createdAt: Date = Date()              // 创建时间
    var orderIndex: Int = 0                   // 分类在侧边栏的排序位置
    
    init(name: String, icon: String = "folder", orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }
    
    /// 预置的默认分类
    static var defaultCategories: [Category] {
        [
            Category(name: "生活", icon: "house"),
            Category(name: "工作", icon: "briefcase"),
            Category(name: "学习", icon: "book"),
            Category(name: "未分类", icon: "questionmark.circle")
        ]
    }
}
