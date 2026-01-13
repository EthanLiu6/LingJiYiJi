import Foundation
import SwiftData

/// 灵感数据模型：代表用户记录的每一条灵感想法
@Model
final class Inspiration {
    var id: UUID = UUID()
    var title: String = ""              // 灵感标题
    var notes: String = ""              // 灵感备注详情
    var createdAt: Date = Date()        // 创建时间
    var reminderDate: Date?             // 提醒时间（可选）
    var isCompleted: Bool = false       // 是否已完成
    var isPinned: Bool = false          // 是否置顶
    var category: String = "未分类"      // 所属分类名称
    var orderIndex: Int = 0             // 手动排序索引
    
    init(title: String, notes: String = "", category: String = "未分类", orderIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.isCompleted = false
        self.isPinned = false
        self.category = category
        self.orderIndex = orderIndex
        
        // 默认初始化逻辑：自动设置提醒时间为第二天晚上十点
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 22
            components.minute = 0
            self.reminderDate = calendar.date(from: components)
        }
    }
}
