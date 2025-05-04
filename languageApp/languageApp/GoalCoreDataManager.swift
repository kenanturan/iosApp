import Foundation
import CoreData

class GoalCoreDataManager {
    static let shared = GoalCoreDataManager()
    
    private init() {}
    
    var context: NSManagedObjectContext {
        return CoreDataManager.shared.context
    }
    
    func addGoal(type: String, targetCount: Int32, deadline: Date?) {
        let goal = Goal(context: context)
        goal.type = type
        goal.targetCount = targetCount
        goal.currentCount = 0
        goal.createDate = Date()
        goal.deadline = deadline
        saveContext()
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
                let rememberedCount = fetchRememberedWordsCount()
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
        if let start = startDate, let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate >= %@ AND watchedDate <= %@", start as NSDate, end as NSDate)
        } else if let start = startDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate >= %@", start as NSDate)
        } else if let end = endDate {
            fetchRequest.predicate = NSPredicate(format: "watchedDate <= %@", end as NSDate)
        }
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

    /// Returns the number of remembered words
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
