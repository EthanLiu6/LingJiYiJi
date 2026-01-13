import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("通知权限已开启")
            } else if let error = error {
                print("通知权限开启失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 让应用在前台时也能显示通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    func scheduleNotification(for inspiration: Inspiration) {
        guard let reminderDate = inspiration.reminderDate, !inspiration.isCompleted else {
            cancelNotification(for: inspiration)
            return
        }
        
        // 如果提醒时间已过，不再发送通知
        if reminderDate < Date() {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "灵感提醒 💡"
        content.body = inspiration.title
        content.sound = .default // 改回标准声音，确保兼容性
        content.userInfo = ["inspirationID": inspiration.id.uuidString]
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: inspiration.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("调度通知失败: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for inspiration: Inspiration) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [inspiration.id.uuidString])
    }
}
