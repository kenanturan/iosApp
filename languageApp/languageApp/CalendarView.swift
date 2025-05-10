import SwiftUI

struct CalendarView: View {
    @State private var selectedDate: Date = Date()
    var onDateSelected: ((Date) -> Void)? = nil
    
    // All goals
    var allGoals: [Goal] = []
    
    var body: some View {
        VStack {
            // Ay ve yıl gösterimi
            Text(dateFormatter.string(from: selectedDate))
                .font(.headline)
                .padding(.top, 8)
            
            // Özel takvim görünümü
            CustomCalendarView(selectedDate: $selectedDate, allGoals: allGoals, onDateSelected: onDateSelected)
                .padding(.horizontal, 8)
        }
        .navigationTitle(NSLocalizedString("calendar", comment: "Calendar"))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        return formatter
    }
}

// Özel takvim görünümü - tam olarak tarih üzerinde işaretleme yapabilmek için
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    var allGoals: [Goal] = []
    var onDateSelected: ((Date) -> Void)? = nil
    
    @State private var currentMonth: Date = Date()
    
    // Takvim ayarları
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale.current
        cal.firstWeekday = 2 // Pazartesi
        return cal
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Ay geçiş kontrolleri
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Hafta günleri başlıkları
            HStack(spacing: 0) {
                ForEach(getWeekdaySymbols(), id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Takvim görünümü
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        DayView(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate), 
                               isCompleted: isDateCompleted(date))
                            .onTapGesture {
                                selectedDate = date
                                onDateSelected?(date)
                            }
                    } else {
                        // Boş gün hücresi
                        Rectangle()
                            .foregroundColor(.clear)
                    }
                }
            }
        }
        .padding(.bottom, 20)
    }
    
    // Her gün için görünüm
    private func DayView(date: Date, isSelected: Bool, isCompleted: Bool) -> some View {
        ZStack {
            // Seçili gün arka planı
            if isSelected {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
            }
            
            // Gün numarası ve tamamlanmış işareti
            if isCompleted {
                // Tamamlanmış gün için yeşil çerçeve ve tik işareti
                ZStack {
                    // Gün numarasını yeşil çerçeveyle çevrele
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .stroke(Color.green, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                    
                    // TAM OLARAK SAYININ ÜSTÜNDE tik işareti (BUNU ÖNE ÇIKAR)
                    ZStack {
                        // Tik işareti numarayı gizlemiyor, üstünde duruyor
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        // Tik işaretinin arka planı
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .offset(y: -16) // Tam olarak numaranın üstünde
                        
                        // Tik işareti
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 10, weight: .bold))
                            .offset(y: -16) // Tam olarak numaranın üstünde
                    }
                }
            } else {
                // Normal gün görünümü
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
        .frame(height: 40)
    }
    
    // Tarihin tamamlanmış bir gün olup olmadığını kontrol et
    private func isDateCompleted(_ date: Date) -> Bool {
        // Gerçekten tamamlanmış günleri kontrol et
        return GoalsView.areGoalsCompletedForDate(allGoals, date: date)
    }
    
    // Ay içindeki günleri hesapla
    private func getDaysInMonth() -> [Date?] {
        var days = [Date?]()
        
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Ayın ilk gününün haftanın hangi günü olduğunu bul
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let offsetDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Önceki ayın günlerini ekle (boş olarak)
        for _ in 0..<offsetDays {
            days.append(nil)
        }
        
        // Bu ayın günlerini ekle
        for day in 1...range.count {
            if let date = calendar.date(byAdding: .day, value: day-1, to: firstDay) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // Hafta günlerinin kısa adlarını al
    private func getWeekdaySymbols() -> [String] {
        var symbols = calendar.veryShortStandaloneWeekdaySymbols
        
        // Haftanın ilk gününe göre düzenleme
        let firstWeekdayIndex = calendar.firstWeekday - 1
        return Array(symbols[firstWeekdayIndex..<symbols.count]) + Array(symbols[0..<firstWeekdayIndex])
    }
    
    // Önceki aya git
    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    // Sonraki aya git
    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// CalendarView için bir ön izleme
#Preview {
    CalendarView()
}
