import SwiftUI
import CoreData

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var hideCompletedGoals = false
    @Published var filteredGoals: [Goal] = []
    
    func fetchGoals() {
        GoalCoreDataManager.shared.updateAllGoalsProgress()
        let updatedGoals = GoalCoreDataManager.shared.fetchGoals()
        goals = updatedGoals.map { $0 }
        updateFilteredGoals()
    }
    
    func updateFilteredGoals() {
        if hideCompletedGoals {
            // Filter completed goals (progress 1.0 or higher is considered completed)
            filteredGoals = goals.filter { goal in
                // Calculate progress based on goal type
                let progress = calculateProgress(for: goal)
                return progress < 1.0 // Show only incomplete goals
            }
        } else {
            // Show all goals
            filteredGoals = goals
        }
    }
    
    // Calculate progress for goal
    private func calculateProgress(for goal: Goal) -> Double {
        if (goal.type ?? "") == "video" {
            let watchedCount = WatchedVideosManager.shared.watchedVideoCount(start: goal.createDate, end: goal.deadline)
            return Double(watchedCount) / max(1, Double(goal.targetCount))
        } else if (goal.type ?? "") == "kelime" {
            let rememberedCount = RememberedWordsManager.shared.rememberedWordCount(start: goal.createDate, end: goal.deadline)
            return Double(rememberedCount) / max(1, Double(goal.targetCount))
        }
        return 0.0
    }
    
    func toggleCompletedGoals() {
        hideCompletedGoals.toggle()
        updateFilteredGoals()
    }
}

struct GoalsView: View {
    var isActive: Bool
    @ObservedObject private var viewModel = GoalsViewModel()
    @State private var isShowingEmptyState = false
    
    // State properties
    @State private var showAddGoal = false
    @State private var selectedCalendarDate: Date? = nil
    @State private var showDaySummary = false
    @State private var showCalendar = false
    @State private var newGoalType: String = "video"
    @State private var newTargetCount: String = ""
    @State private var newDeadline: Date = Date().addingTimeInterval(86400 * 7)
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedGoalType = "video"
    @State private var selectedFrequency = NSLocalizedString("daily", comment: "Daily frequency")
    
    private let goalTypes = ["video", "kelime"]
    private let frequencies = [NSLocalizedString("daily", comment: "Daily frequency"), NSLocalizedString("weekly", comment: "Weekly frequency"), NSLocalizedString("monthly", comment: "Monthly frequency")]
    
    public init(isActive: Bool) {
        self.isActive = isActive
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Ana içerik alanı
                VStack(spacing: 0) {
                    if viewModel.goals.isEmpty || (viewModel.filteredGoals.isEmpty && viewModel.hideCompletedGoals) {
                        // Boş durum görünümü
                        VStack(spacing: 20) {
                            Image(systemName: viewModel.goals.isEmpty ? "target" : "checkmark.circle")
                                .font(.system(size: 70))
                                .foregroundColor(.gray.opacity(0.3))
                            Text(viewModel.goals.isEmpty ? 
                                 NSLocalizedString("no_goal_added", comment: "No goals added yet") : 
                                 NSLocalizedString("all_goals_completed", comment: "All goals completed"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(viewModel.goals.isEmpty ? 
                                 NSLocalizedString("motivation_message", comment: "Motivation message") : 
                                 NSLocalizedString("see_other_goals", comment: "See other goals"))
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary.opacity(0.8))
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 50)
                    } else {
                        // Hedef listesi
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 16) {
                                ForEach(viewModel.filteredGoals, id: \.objectID) { goal in
                                    SwipeToDeleteGoalRow(goal: goal, onDelete: {
                                        GoalCoreDataManager.shared.deleteGoal(goal)
                                        viewModel.fetchGoals()
                                    })
                                }
                                
                                // Tab bar ve butonlar için alt boşluk
                                Spacer(minLength: 80)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer() // Ana içerik ile günlük istatistikler butonu arasında
                    
                    // Günlük istatistikler butonu - tab bar'ın hemen üstünde
                    Button(action: { showCalendar.toggle() }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(NSLocalizedString("daily_stats", comment: "Daily statistics"))
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }
                
                // Takvim görünümü
                if showCalendar {
                    VStack {
                        Spacer()
                        VStack(alignment: .leading) {
                            CalendarView(onDateSelected: { date in
                                selectedCalendarDate = date
                                showDaySummary = true
                            }, allGoals: viewModel.goals)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 70) // Tab bar için alan bırak
                    }
                }
                
                // Artı butonu - her zaman göster, takvim açıkken konumunu ayarla
                VStack {
                    Spacer()
                    HStack {
                        Spacer() // Sağa yaslamak için
                        Button(action: { showAddGoal = true }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                                  startPoint: .topLeading,
                                                  endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.trailing, 24)
                    // Takvim açıkken daha yukarıda konumlandır, kapalıyken normal konumda göster
                    .padding(.bottom, showCalendar ? 400 : 80)
                    .animation(.easeInOut(duration: 0.3), value: showCalendar) // Konum değişimini animasyonlu yap
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            // Toolbar removed
            .sheet(isPresented: $showAddGoal) {
                addGoalSheet
            }
            .sheet(isPresented: Binding(
                get: { showDaySummary && selectedCalendarDate != nil },
                set: { newValue in showDaySummary = newValue }
            )) {
                if let date = selectedCalendarDate {
                    DaySummarySheet(
                        date: date,
                        goals: GoalsView.goalsFor(viewModel.goals, date: date),
                        watchedVideoCount: GoalsView.watchedVideoCount(for: date),
                        rememberedWordCount: GoalsView.rememberedWordCount(for: date)
                    )
                }
            }
            .onAppear {
                viewModel.fetchGoals()
            }
            .onChange(of: isActive) { newValue in
                if newValue {
                    viewModel.fetchGoals()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // Duruma göre renk değiştiren filtre butonu
                    Button(action: {
                        viewModel.toggleCompletedGoals()
                        // Boş durum kontrolü
                        isShowingEmptyState = viewModel.filteredGoals.isEmpty && viewModel.hideCompletedGoals
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.hideCompletedGoals ? "eye" : "eye.slash")
                                .font(.system(size: 14))
                            Text(viewModel.hideCompletedGoals ? NSLocalizedString("show_all", comment: "Show all items") : NSLocalizedString("hide_completed", comment: "Hide completed items"))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.hideCompletedGoals ? Color.green : Color.blue)
                        )
                        .foregroundColor(.white)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: viewModel.hideCompletedGoals ? Color.green.opacity(0.3) : Color.blue.opacity(0.3),
                               radius: 4, x: 0, y: 2)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("VideoWatchStatusChanged"))) { _ in
                viewModel.fetchGoals()
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(NSLocalizedString("warning", comment: "Warning")), message: Text(alertMessage), dismissButton: .default(Text(NSLocalizedString("ok", comment: "OK"))))
            }
        }
    }
    
    // GoalRow dosyaya taşındı

    private var addGoalSheet: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title and icon
                        VStack(spacing: 10) {
                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                            
                            Text(NSLocalizedString("create_new_goal", comment: "Create new goal"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(NSLocalizedString("track_progress", comment: "Track progress by setting goals"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        
                        // Goal type selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("goal_type", comment: "Goal type"))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                // Video Goal
                                Button(action: { selectedGoalType = "video" }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedGoalType == "video" ? Color.blue : Color(.systemGray5))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "play.rectangle.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(selectedGoalType == "video" ? .white : .gray)
                                        }
                                        
                                        Text(NSLocalizedString("video_watching", comment: "Video watching goal type"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedGoalType == "video" ? .primary : .secondary)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedGoalType == "video" ? Color.blue.opacity(0.1) : Color(.systemBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedGoalType == "video" ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Word Goal
                                Button(action: { selectedGoalType = "kelime" }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedGoalType == "kelime" ? Color.purple : Color(.systemGray5))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "text.book.closed.fill")
                                                .font(.system(size: 30))
                                                .foregroundColor(selectedGoalType == "kelime" ? .white : .gray)
                                        }
                                        
                                        Text(NSLocalizedString("word_memorization", comment: "Word memorization goal type"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedGoalType == "kelime" ? .primary : .secondary)
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedGoalType == "kelime" ? Color.purple.opacity(0.1) : Color(.systemBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedGoalType == "kelime" ? Color.purple : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Goal count settings
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("goal_count", comment: "Goal count"))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                Text("\(Int(newTargetCount) ?? 1)")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(selectedGoalType == "video" ? .blue : .purple)
                                
                                // Slider and indicators
                                ZStack(alignment: .top) {
                                    // Slider
                                    Slider(value: Binding(
                                        get: { Double(Int(newTargetCount) ?? 1) },
                                        set: { newValue in newTargetCount = String(Int(newValue)) }
                                    ), in: 1...100, step: 1)
                                    .accentColor(selectedGoalType == "video" ? .blue : .purple)
                                    .padding(.horizontal, 20)
                                    
                                    // Indicator markers
                                    HStack {
                                        ForEach([1, 25, 50, 75, 100], id: \.self) { value in
                                            VStack(spacing: 4) {
                                                Rectangle()
                                                    .fill(Color(.systemGray3))
                                                    .frame(width: 1, height: 6)
                                                
                                                Text("\(value)")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .padding(.top, 24)
                                    .padding(.horizontal, 20)
                                }
                                .padding(.bottom, 16)
                                
                                Text(selectedGoalType == "video" ? 
                                    String(format: NSLocalizedString("video_goal", comment: "Video goal with count"), Int(newTargetCount) ?? 1) : 
                                    String(format: NSLocalizedString("word_goal", comment: "Word goal with count"), Int(newTargetCount) ?? 1))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 16)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        // Duration selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("goal_period", comment: "Goal period"))
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 16) {
                                HStack(spacing: 20) {
                                    ForEach(frequencies, id: \.self) { freq in
                                        Button(action: { selectedFrequency = freq }) {
                                            VStack(spacing: 12) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedFrequency == freq ? Color.green : Color(.systemGray5))
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: freq == "Günlük" ? "clock" : (freq == "Haftalık" ? "calendar" : "calendar.badge.clock"))
                                                        .font(.system(size: 24))
                                                        .foregroundColor(selectedFrequency == freq ? .white : .gray)
                                                }
                                                
                                                Text(freq)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(selectedFrequency == freq ? .primary : .secondary)
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedFrequency == freq ? Color.green.opacity(0.1) : Color(.systemBackground))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedFrequency == freq ? Color.green : Color.clear, lineWidth: 2)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                Text(NSLocalizedString("goal_plan", comment: "Goal plan description"))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 16)
                        }
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        Spacer()
                        
                        // Bottom buttons
                        HStack {
                            Button(action: { showAddGoal = false }) {
                                HStack {
                                    Image(systemName: "xmark")
                                    Text(NSLocalizedString("cancel", comment: "Cancel"))
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: { addGoal() }) {
                                HStack {
                                    Image(systemName: "checkmark")
                                    Text(NSLocalizedString("add_goal", comment: "Add goal"))
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [selectedGoalType == "video" ? .blue : .purple, selectedGoalType == "video" ? Color.blue.opacity(0.8) : Color.purple.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: (selectedGoalType == "video" ? Color.blue : Color.purple).opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding([.horizontal, .bottom])
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: { showAddGoal = false }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            })
        }
    }
    
    // fetchGoals function is now managed within the viewModel
    
    private func addGoal() {
        guard let targetCount = Int32(newTargetCount), targetCount > 0 else {
            alertMessage = NSLocalizedString("enter_valid_goal", comment: "Enter a valid goal count")
            showAlert = true
            return
        }
        // Automatically set deadline based on frequency
        let today = Date()
        let deadline: Date
        switch selectedFrequency {
        case NSLocalizedString("daily", comment: "Daily frequency"):
            deadline = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        case NSLocalizedString("weekly", comment: "Weekly frequency"):
            deadline = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today
        case NSLocalizedString("monthly", comment: "Monthly frequency"):
            deadline = Calendar.current.date(byAdding: .month, value: 1, to: today) ?? today
        default:
            deadline = today
        }
        // Hedefe ulaşılmaması için hedefe başlanmazdan önce kullanıcı en az 1 kelime ezberlemelidir
        // Bu yüzden hedefin mevcut ilerleme sayısını -1 olarak ayarlayıp, hedefe ulaşmak için
        // kullanıcının en az 1 eylem yapmasını zorlayalım
        GoalCoreDataManager.shared.addGoal(type: selectedGoalType, targetCount: targetCount, startWithZero: false, deadline: deadline)
        viewModel.fetchGoals()
        showAddGoal = false
        newTargetCount = ""
        selectedGoalType = "video"
        selectedFrequency = NSLocalizedString("daily", comment: "Daily frequency")
    }

    
    private func deleteGoal(at offsets: IndexSet) {
        for index in offsets {
            let goal = viewModel.goals[index]
            GoalCoreDataManager.shared.deleteGoal(goal)
        }
        viewModel.fetchGoals()
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
