import Foundation
import UserNotifications

/// 通知管理中心：负责应用内所有提醒通知的请求、调度与取消
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// 向系统请求通知发送权限（弹窗提示用户）
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已开启")
            } else if let error = error {
                print("通知权限开启失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 实现代理方法：确保应用在前台运行（Active）时也能正常显示横幅通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    /// 为指定的灵感项安排一个定时通知
    func scheduleNotification(for inspiration: Inspiration) {
        // 只有未完成且设置了提醒时间的灵感才需要排期
        guard let reminderDate = inspiration.reminderDate, !inspiration.isCompleted else {
            cancelNotification(for: inspiration)
            return
        }
        
        // 如果提醒时间已过期（早于当前时间），则不安排通知
        if reminderDate < Date() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "灵感提醒 💡"
        content.body = inspiration.title
        content.sound = .default
        content.userInfo = ["inspirationID": inspiration.id.uuidString]
        
        // 提取精确到分钟的时间组件
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // 使用灵感的 UUID 作为通知的唯一标识符
        let request = UNNotificationRequest(identifier: inspiration.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("调度通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 取消该灵感对应的待发送通知
    func cancelNotification(for inspiration: Inspiration) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [inspiration.id.uuidString])
    }
}
