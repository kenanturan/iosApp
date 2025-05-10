import SwiftUI

struct GoalRow: View {
    let goal: Goal
    @FetchRequest(
        entity: WatchedVideo.entity(),
        sortDescriptors: []
    ) var watchedVideos: FetchedResults<WatchedVideo>
    @FetchRequest(
        entity: RememberedWord.entity(),
        sortDescriptors: []
    ) var rememberedWords: FetchedResults<RememberedWord>
    
    // Tracking celebration with a persistent tracking system instead of local state
    @State private var isCheckingCompletion = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                // Goal type icon
                ZStack {
                    Circle()
                        .fill(goalTypeColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: (goal.type ?? "") == "video" ? "play.rectangle.fill" : "text.book.closed.fill")
                        .foregroundColor(goalTypeColor)
                        .font(.system(size: 18, weight: .medium))
                }
                .padding(.trailing, 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.type == "video" ? NSLocalizedString("video_watching", comment: "Video Watching") : NSLocalizedString("word_memorization", comment: "Word Memorization"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let deadline = goal.deadline {
                        Text(String.localizedStringWithFormat(NSLocalizedString("deadline", comment: "Deadline"), dateString(deadline)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Goal Count Badge
                ZStack {
                    Capsule()
                        .fill(goalTypeColor.opacity(0.15))
                        .frame(height: 30)
                    Text(String.localizedStringWithFormat(NSLocalizedString("goal", comment: "Goal"), goal.targetCount))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(goalTypeColor)
                        .padding(.horizontal, 10)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(String.localizedStringWithFormat(NSLocalizedString("progress", comment: "Progress"), Int(progress * 100)))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(currentCount)/\(goal.targetCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray5))
                            .frame(height: 10)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    goalTypeColor.opacity(0.7), 
                                    goalTypeColor
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(width: max(0, min(geometry.size.width * CGFloat(progress), geometry.size.width)), height: 10)
                    }
                }
                .frame(height: 10)
            }
            
            // Bottom Details
            HStack(spacing: 16) {
                if (goal.type ?? "") == "video" {
                    // DÜZELTME: Tutarlılık için goal.currentCount değerini kullan
                    // Bu değer GoalCoreDataManager tarafından doğru hesaplanan ve ilerleme çubuğunda da kullanılan değer
                    let watchedCount = Int(goal.currentCount)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String.localizedStringWithFormat(NSLocalizedString("watched", comment: "Watched"), watchedCount))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                        Text(String.localizedStringWithFormat(NSLocalizedString("remaining", comment: "Remaining"), max(0, Int(goal.targetCount) - watchedCount)))
                    }
                } else if (goal.type ?? "") == "kelime" {
                    // DÜZELTME: Tutarlılık için goal.currentCount değerini kullan
                    // Bu değer GoalCoreDataManager tarafından doğru hesaplanan ve ilerleme çubuğunda da kullanılan değer
                    let rememberedCount = Int(goal.currentCount)
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(String.localizedStringWithFormat(NSLocalizedString("memorized", comment: "Memorized"), rememberedCount))
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "circle")
                            .foregroundColor(.orange)
                        Text(String.localizedStringWithFormat(NSLocalizedString("remaining", comment: "Remaining"), max(0, Int(goal.targetCount) - rememberedCount)))
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        // Check goal completion status when the view is created
        .onAppear {
            checkGoalCompletion()
        }
        // Track goal completion status when progress changes
        .onChange(of: progress) { newProgress in
            checkGoalCompletion()
        }
    }
    
    // Check goal completion status and show celebration
    private func checkGoalCompletion() {
        // Use flag to prevent double calling
        if isCheckingCompletion {
            return
        }
        
        isCheckingCompletion = true
        
        // Hedef tamamlandı mı kontrol et - ama çok daha katı kurallarla
        // 1. Hedef sayısı en az 1 olmalı 
        // 2. Mevcut ilerleme sayısı en az 1 olmalı (yani en az bir eylem)
        // 3. İlerleme 1.0 veya üzerinde olmalı (hedefe ulaşılmalı)
        // 4. Kutlama daha önce yapılmamış olmalı
        if goal.targetCount > 0 && goal.currentCount > 0 && progress >= 1.0 && !GoalCelebrationTracker.shared.hasGoalBeenCelebrated(goal) {
            // Determine message based on goal type
            let message = (goal.type ?? "") == "video" ?
                String.localizedStringWithFormat(NSLocalizedString("congrats_video_goal", comment: "Congratulations video goal"), goal.targetCount) :
                String.localizedStringWithFormat(NSLocalizedString("congrats_word_goal", comment: "Congratulations word goal"), goal.targetCount)
            
            // Mark the goal as celebrated
            GoalCelebrationTracker.shared.markGoalAsCelebrated(goal)
            
            // Show celebration animation with a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                CelebrationManager.shared.showCelebration(message: message)
                self.isCheckingCompletion = false
            }
        } else {
            // Reset the flag if celebration won't be shown
            isCheckingCompletion = false
        }
    }
    
    // Calculate progress
    private var currentCount: Int32 {
        // Core Data'dan gelen mevcut sayıyı kullan
        // Bu değer doğrudan GoalCoreDataManager tarafından, tam tarih ve saat kontrolü yapılarak hesaplanıyor
        return goal.currentCount
        
        // Aşağıdaki kodlar ESKI KODLARDIR ve sorunun kaynağıdır
        // Bu hesaplama burada yapılmamalı, GoalCoreDataManager ve WatchedVideosManager sınıflarında yapılmalıdır
        // Oradaki hesaplamalar doğru tarih ve saat kontrolü yapıyor, buradakiler yanlış
    }
    
    private var progress: Double {
        return Double(currentCount) / max(1, Double(goal.targetCount))
    }
    
    // Color based on goal type
    private var goalTypeColor: Color {
        return (goal.type ?? "") == "video" ? Color.blue : Color.purple
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
