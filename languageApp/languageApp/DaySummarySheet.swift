import SwiftUI

struct DaySummarySheet: View {
    let date: Date
    let goals: [Goal]
    let watchedVideoCount: Int
    let rememberedWordCount: Int
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text(formattedDate)
                .font(.title3)
                .bold()
                .padding(.top)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: NSLocalizedString("total_goal", comment: "Total goal count"), goals.count))
                Text(String(format: NSLocalizedString("watched_video", comment: "Watched video count"), watchedVideoCount))
                Text(String(format: NSLocalizedString("memorized_word", comment: "Memorized word count"), rememberedWordCount))
            }
            .font(.headline)
            Spacer()
        }
        .padding()
        .presentationDetents([.height(220)])
    }
}

#Preview {
    DaySummarySheet(date: Date(), goals: [], watchedVideoCount: 2, rememberedWordCount: 5)
}
