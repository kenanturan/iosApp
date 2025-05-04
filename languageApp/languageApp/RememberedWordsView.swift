import SwiftUI
import CoreData

struct RememberedWordsView: View {
    @FetchRequest(
        entity: RememberedWord.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \RememberedWord.date, ascending: false)]
    ) var rememberedWords: FetchedResults<RememberedWord>
    @State private var showFlashcards = false
    @State private var showDeleteAlert = false
    @State private var wordToDelete: RememberedWord? = nil
    @Environment(\.managedObjectContext) private var context

    private func deleteWord(_ word: RememberedWord) {
        context.delete(word)
        try? context.save()
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    
                    Text(String(format: NSLocalizedString("total_memorized", comment: "Total memorized words count"), rememberedWords.count))
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .padding(.top, 12)
                if rememberedWords.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundColor(.gray.opacity(0.7))
                        Text(NSLocalizedString("no_memorized_word", comment: "No memorized words yet"))
                            .font(.title2.bold())
                        Text(NSLocalizedString("memorize_info", comment: "Info about how to memorize words"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        Spacer()
                    }
                } else {
                    Button(action: {
                        showFlashcards = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.stack.fill")
                                .font(.title2)
                            Text(NSLocalizedString("study_words", comment: "Study Words button"))
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                        .shadow(radius: 4)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                List {
                    if rememberedWords.isEmpty {
                        EmptyView()
                    }
                    ForEach(Array(rememberedWords.enumerated()), id: \.element) { (index, word) in
                        SwipeableWordRow(word: word) {
                            wordToDelete = word
                            showDeleteAlert = true
                        }
                    }
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text(NSLocalizedString("delete_word", comment: "Delete word")),
                        message: Text(NSLocalizedString("delete_word_confirm", comment: "Delete word confirmation")),
                        primaryButton: .destructive(Text(NSLocalizedString("delete", comment: "Delete"))) {
                            if let word = wordToDelete {
                                deleteWord(word)
                            }
                        },
                        secondaryButton: .cancel(Text(NSLocalizedString("cancel", comment: "Cancel")))
                    )
                }
                // Navigation başlığını kaldırıldı
            }
            .sheet(isPresented: $showFlashcards) {
                RememberedFlashcardView(words: Array(rememberedWords))
            }
        }
    }
}

struct SwipeableWordRow: View {
    var word: RememberedWord
    var onDelete: (() -> Void)? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    var body: some View {
        ZStack {
            // Sola çekince kırmızı çarpı
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(radius: 8)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.red)
            }
            .opacity(dragOffset.width < -20 ? min(Double(-dragOffset.width / 30), 1.0) : 0)
            .offset(x: -60, y: 0)
            // Sağa çekince yeşil tik
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 64, height: 64)
                    .shadow(radius: 8)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundColor(.green)
            }
            .opacity(dragOffset.width > 20 ? min(Double(dragOffset.width / 30), 1.0) : 0)
            .offset(x: 60, y: 0)
            HStack {
                Text(word.word ?? "")
                    .font(.headline)
                Spacer()
                Text(word.translation ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .offset(dragOffset)
            .opacity(cardOpacity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        let distance = sqrt(pow(dragOffset.width, 2) + pow(dragOffset.height, 2))
                        cardOpacity = Double(1.0 - min(distance / 250, 0.5))
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 70
                        let distance = sqrt(pow(dragOffset.width, 2) + pow(dragOffset.height, 2))
                        if distance > threshold {
                            if dragOffset.width < -30 {
                                // Sola kaydırma ile silme isteği
                                onDelete?()
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                    cardOpacity = 1.0
                                }
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = CGSize(width: dragOffset.width * 3, height: dragOffset.height * 3)
                                    cardOpacity = 0
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    dragOffset = .zero
                                    cardOpacity = 1.0
                                }
                            }
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                                cardOpacity = 1.0
                            }
                        }
                    }
            )
        }
    }
}
