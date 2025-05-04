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
    
    // Belirli bir tarih aralığındaki izlenen video sayısını döndürür
    func watchedVideoCount(start: Date?, end: Date?) -> Int {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        
        // Tarih aralığı filtreleme
        if let startDate = start, let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "watchedDate >= %@ AND watchedDate <= %@", startDate as NSDate, endDate as NSDate)
        } else if let startDate = start {
            fetchRequest.predicate = NSPredicate(format: "watchedDate >= %@", startDate as NSDate)
        } else if let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "watchedDate <= %@", endDate as NSDate)
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
