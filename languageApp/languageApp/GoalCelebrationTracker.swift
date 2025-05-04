import Foundation

// Hedeflerin kutlamalarını takip etmek için yardımcı sınıf
class GoalCelebrationTracker {
    static let shared = GoalCelebrationTracker()
    
    private let userDefaults = UserDefaults.standard
    private let celebratedGoalsKey = "celebratedGoals"
    
    private init() {}
    
    // Bir hedefin kutlamasının gösterilip gösterilmediğini kontrol et
    func hasGoalBeenCelebrated(_ goal: Goal) -> Bool {
        guard let goalId = goal.objectID.uriRepresentation().absoluteString as String? else {
            return false
        }
        
        let celebratedGoals = userDefaults.stringArray(forKey: celebratedGoalsKey) ?? []
        return celebratedGoals.contains(goalId)
    }
    
    // Hedefin kutlandığını kaydet
    func markGoalAsCelebrated(_ goal: Goal) {
        guard let goalId = goal.objectID.uriRepresentation().absoluteString as String? else {
            return
        }
        
        var celebratedGoals = userDefaults.stringArray(forKey: celebratedGoalsKey) ?? []
        
        if !celebratedGoals.contains(goalId) {
            celebratedGoals.append(goalId)
            userDefaults.set(celebratedGoals, forKey: celebratedGoalsKey)
        }
    }
    
    // Test ve hata ayıklama amaçlı tüm kutlama kayıtlarını sil
    func resetAllCelebrations() {
        userDefaults.removeObject(forKey: celebratedGoalsKey)
    }
}
