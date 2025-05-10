import Foundation
import CoreData

class GoalCoreDataManager {
    static let shared = GoalCoreDataManager()
    
    private init() {}
    
    var context: NSManagedObjectContext {
        return CoreDataManager.shared.context
    }
    
    func addGoal(type: String, targetCount: Int32, startWithZero: Bool = true, deadline: Date?) {
        // Kesin zaman kaydı için Calendar kullanarak şu anki zamanı milisaniye hassasiyetinde al
        // Önce hedefi oluştur, sonra ezberlenen kelimeleri/izlenen videoları kontrol et
        let goal = Goal(context: context)
        goal.type = type
        goal.targetCount = targetCount
        
        // Başlangıç ilerleme değeri: startWithZero false ise -1 yap (oluşturulduğunda tebrik mesajı görüntülenmesini engellemek için)
        // -1 değeri yalnızca göreceli karşılaştırmalarda kullanılır, kullanıcıya gösterilmez
        goal.currentCount = startWithZero ? 0 : -1
        
        // Hedef oluşturma tarihini, 1 saniye SONRASINA ayarlıyoruz
        // Böylece hedeften ÖNCE kayıtlı kelimeler ve videolar HESABA KATILMAYACAK
        // Ve SADECE hedeften SONRA eklenenler hesaba katılacak
        goal.createDate = Date(timeIntervalSinceNow: +1) // 1 saniye SONRASI
        goal.deadline = deadline
        
        // MUTLAKA önce hedefi kaydet, böylece Doğu Standart Zamanındaki zaman damgası kalıcı olsun
        saveContext()
        
        // Hedefin başlangıç tarihini daha sonraki kelime/video izleme tarihleriyle karşılaştırmak için
        // hem tarih hem saat kontrolü yapılmalı
        print("[GoalCoreData] Yeni hedef oluşturuldu - Başlangıç: \(goal.createDate!), Bitiş: \(goal.deadline ?? Date())")
    }
    
    func updateGoal(_ goal: Goal, currentCount: Int32) {
        goal.currentCount = currentCount
        saveContext()
    }
    
    func deleteGoal(_ goal: Goal) {
        context.delete(goal)
        saveContext()
    }
    
    func fetchGoals() -> [Goal] {
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("[GoalCoreData] Fetch error: \(error)")
            return []
        }
    }
    
    /// Tamamlanmış hedefleri döndürür (currentCount >= targetCount)
    func fetchCompletedGoals() -> [Goal] {
        let fetchRequest: NSFetchRequest<Goal> = Goal.fetchRequest()
        
        // currentCount >= targetCount olan hedefleri getir
        fetchRequest.predicate = NSPredicate(format: "currentCount >= targetCount AND targetCount > 0")
        
        do {
            let completedGoals = try context.fetch(fetchRequest)
            print("[GoalCoreData] Tamamlanmış hedef sayısı: \(completedGoals.count)")
            return completedGoals
        } catch {
            print("[GoalCoreData] Tamamlanmış hedef getirme hatası: \(error)")
            return []
        }
    }

    /// Updates all goals' currentCount based on Core Data (watched videos or remembered words)
    func updateAllGoalsProgress() {
        let goals = fetchGoals()
        for goal in goals {
            switch goal.type {
            case "video":
                // Sadece hedefin başlangıç ve deadline aralığındaki videoları say
                let watchedCount = fetchWatchedVideosCount(startDate: goal.createDate, endDate: goal.deadline)
                goal.currentCount = Int32(watchedCount)
            case "kelime":
                // Sadece hedefin başlangıç ve deadline aralığındaki ezberlenen kelimeleri say
                let rememberedCount = fetchRememberedWordsCount(startDate: goal.createDate, endDate: goal.deadline)
                goal.currentCount = Int32(rememberedCount)
            default:
                break
            }
        }
        saveContext()
    }

    /// Belirli bir tarih aralığında izlenen videoları sayar
    private func fetchWatchedVideosCount(startDate: Date?, endDate: Date?) -> Int {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        
        // MUTLAKA > (büyüktür) kullanmalıyız, >= (büyüktür eşittir) değil
        // Bu sayede hedef eklenme zamanından sonra izlenen videolar hesaba katılır
        if let start = startDate, let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate > %@ AND watchedDate <= %@", start as NSDate, end as NSDate)
        } else if let start = startDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate > %@", start as NSDate)
        } else if let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate <= %@", end as NSDate)
        }
        
        // Debugging için bilgi yazdır
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("[GoalManager] Video sayma - Başlangıç: \(startDate != nil ? formatter.string(from: startDate!) : "yok")")
        print("[GoalManager] Video sayma - Bitiş: \(endDate != nil ? formatter.string(from: endDate!) : "yok")")
        print("[GoalManager] Video sayma - Sorgu: watchedDate > \(startDate != nil ? formatter.string(from: startDate!) : "yok")")
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("[GoalCoreData] WatchedVideo count fetch error: \(error)")
            return 0
        }
    }

    /// Returns the number of watched videos
    private func fetchWatchedVideosCount() -> Int {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("[GoalCoreData] WatchedVideo count fetch error: \(error)")
            return 0
        }
    }

    /// Returns the number of remembered words in a date range
    private func fetchRememberedWordsCount(startDate: Date?, endDate: Date?) -> Int {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        
        // MUTLAKA > (büyüktür) kullanmalıyız, >= (büyüktür eşittir) değil
        // Bu sayede hedef eklenme zamanından sonra kayıt edilen kelimeler hesaba katılır
        if let start = startDate, let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "date > %@ AND date <= %@", start as NSDate, end as NSDate)
        } else if let start = startDate {
            fetchRequest.predicate = NSPredicate(format: "date > %@", start as NSDate)
        } else if let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "date <= %@", end as NSDate)
        }
        
        // Debugging için bilgi yazdır
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("[GoalManager] Kelime sayma - Başlangıç: \(startDate != nil ? formatter.string(from: startDate!) : "yok")")
        print("[GoalManager] Kelime sayma - Bitiş: \(endDate != nil ? formatter.string(from: endDate!) : "yok")")
        print("[GoalManager] Kelime sayma - Sorgu: date > \(startDate != nil ? formatter.string(from: startDate!) : "yok")")
        
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("[GoalCoreData] RememberedWord count fetch error: \(error)")
            return 0
        }
    }
    
    /// Returns the total number of remembered words (without date filter)
    private func fetchRememberedWordsCount() -> Int {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        do {
            let count = try context.count(for: fetchRequest)
            return count
        } catch {
            print("[GoalCoreData] RememberedWord count fetch error: \(error)")
            return 0
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("[GoalCoreData] Save error: \(error)")
            }
        }
    }

}
