import Foundation
import CoreData
import SwiftUI

extension GoalsView {
    static func goalsFor(_ allGoals: [Goal], date: Date) -> [Goal] {
        allGoals.filter { goal in
            guard let start = goal.createDate, let end = goal.deadline else { return false }
            let cal = Calendar.current
            // Seçili gün hedefin aralığında mı?
            return cal.isDate(date, inSameDayAs: start) || (date > start && date < end) || cal.isDate(date, inSameDayAs: end)
        }
    }
    
    // Bir günün hedeflerinin tümünün tamamlanıp tamamlanmadığını kontrol eder
    static func areGoalsCompletedForDate(_ allGoals: [Goal], date: Date) -> Bool {
        let goalsForDate = goalsFor(allGoals, date: date)
        
        if goalsForDate.isEmpty {
            return false // O gün için hedef yoksa tamamlanmış sayılmaz
        }
        
        // Tüm hedefler için ilerlemeyi kontrol et
        for goal in goalsForDate {
            let progress = calculateGoalProgress(goal, forDate: date)
            if progress < 1.0 { // 1.0 = %100 tamamlanmış
                return false // Herhangi bir hedef tamamlanmamışsa, false döndür
            }
        }
        
        return true // Tüm hedefler tamamlanmışsa, true döndür
    }
    
    // Hedefin ilerleme durumunu hesaplar
    static func calculateGoalProgress(_ goal: Goal, forDate date: Date) -> Double {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        if (goal.type ?? "") == "video" {
            let watchedCount = watchedVideoCount(for: date)
            return min(1.0, Double(watchedCount) / Double(goal.targetCount))
        } else if (goal.type ?? "") == "kelime" {
            let rememberedCount = rememberedWordCount(for: date)
            return min(1.0, Double(rememberedCount) / Double(goal.targetCount))
        }
        
        return 0.0
    }
    
    static func watchedVideoCount(for date: Date) -> Int {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "watchedDate >= %@ AND watchedDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        do {
            return try CoreDataManager.shared.context.count(for: fetchRequest)
        } catch {
            return 0
        }
    }
    
    static func rememberedWordCount(for date: Date) -> Int {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        do {
            return try CoreDataManager.shared.context.count(for: fetchRequest)
        } catch {
            return 0
        }
    }
}
