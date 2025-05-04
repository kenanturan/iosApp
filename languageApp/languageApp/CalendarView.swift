import SwiftUI

struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    var onDateSelected: ((Date) -> Void)? = nil
    
    // List of completed dates
    var completedDates: [Date] = []
    // All goals
    var allGoals: [Goal] = []
    
    var body: some View {
    // Use current locale for the calendar
    let currentLocale = Locale.current
    let currentCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = currentLocale
        calendar.firstWeekday = 2 // Monday
        return calendar
    }()
    let daySymbols = currentCalendar.veryShortStandaloneWeekdaySymbols

        VStack {
            // Day-of-week header, starting from Monday
            HStack(spacing: 0) {
                ForEach(0..<7) { i in
                    let index = (i + currentCalendar.firstWeekday - 1) % 7
                    Text(daySymbols[index].capitalized)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)

            ZStack(alignment: .topLeading) {
                // Main DatePicker
                DatePicker(
                    NSLocalizedString("select_date", comment: "Select date"),
                    selection: Binding(
                        get: { selectedDate },
                        set: { newDate in
                            selectedDate = newDate
                            onDateSelected?(newDate)
                        }
                    ),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .environment(\.locale, currentLocale)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .scaleEffect(0.85)
                .frame(height: 300)
                
                // Show checkmarks for completed days
                GeometryReader { geometry in
                    ForEach(0..<42) { index in // Takvimde maksimum 42 gün görüntülenebilir (6 hafta x 7 gün)
                        let dayDate = self.dateFor(dayIndex: index, baseDate: selectedDate)
                        if self.isDateCompleted(dayDate) {
                            // Green checkmark
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 12))
                                .position(self.positionFor(dayIndex: index, in: geometry))
                        }
                    }
                }
                .frame(height: 300)
            }
        }
        .navigationTitle(NSLocalizedString("calendar", comment: "Calendar"))
    }
    
    // Check if goals for a date are completed
    private func isDateCompleted(_ date: Date) -> Bool {
        return GoalsView.areGoalsCompletedForDate(allGoals, date: date)
    }
    
    // Calculate date for a specific day index (based on displayed month)
    private func dateFor(dayIndex: Int, baseDate: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.firstWeekday = 2 // Monday

        // Find the beginning of month
        let components = calendar.dateComponents([.year, .month], from: baseDate)
        guard let startOfMonth = calendar.date(from: components) else { return Date() }

        // Find which day of the week is the first day of the month
        let weekdayOfFirstDay = calendar.component(.weekday, from: startOfMonth)

        // Shift so that the first day of the week is Monday
        let shift = (weekdayOfFirstDay - calendar.firstWeekday + 7) % 7
        let dayOffset = dayIndex - shift

        return calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) ?? Date()
    }
    
    // Calculate approximate position for day index
    private func positionFor(dayIndex: Int, in geometry: GeometryProxy) -> CGPoint {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.firstWeekday = 2 // Monday
        let width = geometry.size.width
        let height = geometry.size.height
        
        // Calculate the row and column in the calendar matrix (0-indexed)
        let column = dayIndex % 7
        let row = dayIndex / 7
        
        // Approximate position
        let cellWidth = width / 7
        let cellHeight = height / 6 // 6 weeks maximum calendar height
        
        // Position by day of the week (Sunday-Saturday)
        return CGPoint(
            x: cellWidth * CGFloat(column) + cellWidth * 0.5 + 20,
            y: cellHeight * CGFloat(row) + cellHeight * 0.5 + 40
        )
    }
}

// Add a new initializer for CalendarView
extension CalendarView {
    init(onDateSelected: ((Date) -> Void)? = nil, allGoals: [Goal] = []) {
        self.onDateSelected = onDateSelected
        self.allGoals = allGoals
    }
}

#Preview {
    CalendarView()
}
