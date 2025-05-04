import Foundation
import UserNotifications
import UIKit

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Bildirimleri oluşturma ve sunma izni isteme
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Bildirim izni alınamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Gündüz planlanan bildirimleri temizle ve yeniden oluştur
    func scheduleMotivationNotifications() {
        // Önce mevcut bildirimleri temizleyelim
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Sabah bildirimi (11:00-13:00 arası rastgele)
        let morningHour = Int.random(in: 11...13)
        let morningMinute = Int.random(in: 0...59)
        scheduleNotification(at: morningHour, minute: morningMinute, 
                            title: NSLocalizedString("morning_notification_title", comment: "Good morning notification title"),
                            message: getRandomMotivationMessage(for: .morning))
        print("Sabah bildirimi planlandı: \(morningHour):\(morningMinute)")
        
        // Öğle bildirimi (14:00-17:00 arası rastgele)
        let noonHour = Int.random(in: 14...17)
        let noonMinute = Int.random(in: 0...59)
        scheduleNotification(at: noonHour, minute: noonMinute, 
                            title: NSLocalizedString("noon_notification_title", comment: "Noon notification title"),
                            message: getRandomMotivationMessage(for: .noon))
        print("Öğle bildirimi planlandı: \(noonHour):\(noonMinute)")
        
        // Akşam bildirimi (18:00-20:00 arası rastgele)
        let eveningHour = Int.random(in: 18...20)
        let eveningMinute = Int.random(in: 0...59)
        scheduleNotification(at: eveningHour, minute: eveningMinute, 
                            title: NSLocalizedString("evening_notification_title", comment: "Evening notification title"),
                            message: getRandomMotivationMessage(for: .evening))
        print("Akşam bildirimi planlandı: \(eveningHour):\(eveningMinute)")
        
        // Test bildirimi, hemen göndermek için
        // scheduleDevelopmentNotification()
    }
    
    private func scheduleDevelopmentNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Bildirimi"
        content.body = "Bildirim sistemi çalışıyor!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test bildirimi oluşturulamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Belirli bir saatte bildirim planlama
    private func scheduleNotification(at hour: Int, minute: Int, title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Günlük tetikleyici ayarla
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Benzersiz bir tanımlayıcı oluştur
        let identifier = "motivationNotification_\(hour)_\(minute)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Bildirimi planla
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Bildirim planlanamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Uygulama içi uyarı göster
    func showInAppMotivationAlert(on viewController: UIViewController, time: DayTime = .current) {
        let message = getRandomMotivationMessage(for: time)
        let alert = UIAlertController(
            title: NSLocalizedString("motivation_time", comment: "Motivation time alert title"),
            message: message,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("thanks", comment: "Thanks button"),
            style: .default))
        viewController.present(alert, animated: true)
    }
    
    // Günün zamanına göre farklı mesajlar 
    enum DayTime {
        case morning
        case noon
        case evening
        
        static var current: DayTime {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 11..<14: // Sabah 11-13 arası
                return .morning
            case 14..<18: // Öğle 14-17 arası
                return .noon
            default: // Akşam 18:00 ve sonrası
                return .evening
            }
        }
    }
    
    // Motivasyon mesajları için veri deposu
    private func getRandomMotivationMessage(for time: DayTime) -> String {
        // Her zaman dilimi için mesaj anahtarlarını tanımla
        let messageKeys: [DayTime: [String]] = [
            .morning: [
                "morning_motivation_1",
                "morning_motivation_2",
                "morning_motivation_3",
                "morning_motivation_4",
                "morning_motivation_5"
            ],
            .noon: [
                "noon_motivation_1",
                "noon_motivation_2",
                "noon_motivation_3",
                "noon_motivation_4",
                "noon_motivation_5"
            ],
            .evening: [
                "evening_motivation_1",
                "evening_motivation_2",
                "evening_motivation_3",
                "evening_motivation_4",
                "evening_motivation_5"
            ]
        ]
        
        // İlgili zaman dilimi için rastgele bir mesaj anahtarı seç
        guard let keys = messageKeys[time], !keys.isEmpty else {
            return NSLocalizedString("default_motivation", comment: "Default motivation message")
        }
        
        let randomKey = keys.randomElement()!
        
        // Seçilen anahtarı kullanarak yerelleştirilmiş mesajı döndür
        return NSLocalizedString(randomKey, comment: "Motivation message")
    }
}
