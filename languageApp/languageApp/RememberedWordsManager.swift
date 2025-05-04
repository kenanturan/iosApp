import Foundation
import CoreData

class RememberedWordsManager {
    static let shared = RememberedWordsManager()
    
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // Belirlenen tarih aralığındaki hatırlanan kelimelerin sayısını hesapla
    func rememberedWordCount(start: Date?, end: Date?) -> Int {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        
        // Tarih aralığı belirli ise, bu aralıktaki kelimeleri filtrele
        if let startDate = start, let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        } else if let startDate = start {
            fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        } else if let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "date <= %@", endDate as NSDate)
        }
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Hatırlanan kelime sayısını hesaplarken hata: \(error.localizedDescription)")
            return 0
        }
    }
    
    // Belirli bir kelimenin hatırlanıp hatırlanmadığını kontrol et
    func isRemembered(_ wordId: String) -> Bool {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "wordId == %@", wordId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Kelime kontrolünde hata: \(error.localizedDescription)")
            return false
        }
    }
}
