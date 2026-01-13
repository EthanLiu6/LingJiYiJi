import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    @Attribute(.unique) var name: String = ""
    var icon: String = "folder"
    var createdAt: Date = Date()
    var orderIndex: Int = 0
    
    init(name: String, icon: String = "folder", orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.createdAt = Date()
        self.orderIndex = orderIndex
    }
    
    static var defaultCategories: [Category] {
        [
            Category(name: "生活", icon: "house"),
            Category(name: "工作", icon: "briefcase"),
            Category(name: "学习", icon: "book"),
            Category(name: "未分类", icon: "questionmark.circle")
        ]
    }
}
