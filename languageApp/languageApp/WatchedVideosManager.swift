import Foundation
import CoreData

class WatchedVideosManager {
    static let shared = WatchedVideosManager()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    func markAsWatched(_ videoId: String) {
        coreDataManager.markVideoAsWatched(videoId)
        GoalCoreDataManager.shared.updateAllGoalsProgress()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("VideoWatchStatusChanged"), object: nil)
        }
    }
    
    func markAsUnwatched(_ videoId: String) {
        coreDataManager.markVideoAsUnwatched(videoId)
        GoalCoreDataManager.shared.updateAllGoalsProgress()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("VideoWatchStatusChanged"), object: nil)
        }
    }
    
    func isWatched(_ videoId: String) -> Bool {
        return coreDataManager.isVideoWatched(videoId)
    }
    
    // Belirli bir tarih aralığındaki izlenen video sayısını döndürür (tam zaman damgası kullanarak)
    func watchedVideoCount(start: Date?, end: Date?) -> Int {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        
        // Başlangıç tarihi olmadan tüm videoları saymaya izin vermeyelim
        guard let startDate = start else {
            print("[WatchedVideosManager] HATA: Başlangıç tarihi belirtilmedi, sıfır döndürülüyor")
            return 0
        }
        
        // Tarih geçerliliği için ekstra kontrol
        if startDate.timeIntervalSince1970 < 86400 { // 1 günden az (1970-01-01'e çok yakın tarih)
            print("[WatchedVideosManager] HATA: Başlangıç tarihi geçersiz, sıfır döndürülüyor")
            return 0
        }
        
        // Log bilgisi yazdıralım
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("[WatchedVideosManager] Video sayımı başlangıç: \(formatter.string(from: startDate)), " + 
              "bitiş: \(end != nil ? formatter.string(from: end!) : "yok")")
        
        // >ÖNEMLİ< Tam zaman damgası karşılaştırması için >= yerine > kullanıyoruz
        // Böylece hedef eklenme anı ile aynı anda (milisaniye farkı ile) kaydedilmiş videolar sayılmaz
        if let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "watchedDate > %@ AND watchedDate <= %@", startDate as NSDate, endDate as NSDate)
        } else {
            fetchRequest.predicate = NSPredicate(format: "watchedDate > %@", startDate as NSDate)
        }
        
        do {
            let count = try CoreDataManager.shared.context.count(for: fetchRequest)
            return count
        } catch {
            print("Video count hesaplama hatası: \(error)")
            return 0
        }
    }
}
