import Foundation
import SwiftData

@Model
final class Inspiration {
    var id: UUID = UUID()
    var title: String = ""
    var notes: String = ""
    var createdAt: Date = Date()
    var reminderDate: Date?
    var isCompleted: Bool = false
    var isPinned: Bool = false
    var category: String = "未分类"
    var orderIndex: Int = 0
    
    init(title: String, notes: String = "", category: String = "未分类", orderIndex: Int = 0) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.isCompleted = false
        self.isPinned = false
        self.category = category
        self.orderIndex = orderIndex
        
        // 默认提醒时间：第二天晚上十点
        let calendar = Calendar.current
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) {
            var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = 22
            components.minute = 0
            self.reminderDate = calendar.date(from: components)
        }
    }
}
