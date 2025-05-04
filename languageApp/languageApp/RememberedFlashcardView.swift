import SwiftUI

struct RememberedFlashcardView: View {
    @State var words: [RememberedWord]
    @State private var currentIndex = 0
    @State private var showTranslation = false
    @State private var dragOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 32) {
            Text("\(currentIndex+1) / \(words.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color(.black).opacity(0.15), radius: 8, x: 0, y: 4)
                // Sola çekince kırmızı çarpı
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.red)
                }
                .opacity(dragOffset.width < -20 ? min(Double(-dragOffset.width / 30), 1.0) : 0)
                .offset(x: -80, y: 0)
                // Sağa çekince yeşil tik
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.green)
                }
                .opacity(dragOffset.width > 20 ? min(Double(dragOffset.width / 30), 1.0) : 0)
                .offset(x: 80, y: 0)
                Text(showTranslation ? (words[currentIndex].translation ?? "") : (words[currentIndex].word ?? ""))
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(height: 200)
            .padding(.horizontal, 20)
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width) / 18))
            .opacity(cardOpacity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        // Kart uzaklaştıkça şeffaflaşsın
                        let distance = sqrt(pow(dragOffset.width, 2) + pow(dragOffset.height, 2))
                        cardOpacity = Double(1.0 - min(distance / 250, 0.6))
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 120
                        let distance = sqrt(pow(dragOffset.width, 2) + pow(dragOffset.height, 2))
                        if distance > threshold {
                            // Kartı fırlat (yön fark etmez)
                            let direction = CGSize(width: dragOffset.width * 3, height: dragOffset.height * 3)
                            withAnimation(.spring()) {
                                dragOffset = direction
                                cardOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                if dragOffset.width < 0 {
                                    // Sola çekildi: kelimeyi listenin sonuna ekle
                                    let word = words[currentIndex]
                                    words.append(word)
                                    words.remove(at: currentIndex)
                                    // Aynı indexte yeni kelime göster
                                    // Eğer son kelimeyse başa dön
                                    if currentIndex >= words.count {
                                        currentIndex = 0
                                    }
                                } else if dragOffset.width > 0 {
                                    // Sağa çekildi: kelimeyi listeden çıkar
                                    words.remove(at: currentIndex)
                                    if words.isEmpty {
                                        // Tüm kelimeler bitti
                                        currentIndex = 0
                                    } else if currentIndex >= words.count {
                                        currentIndex = 0
                                    }
                                }
                                showTranslation = false
                                dragOffset = .zero
                                cardOpacity = 1.0
                            }
                        } else {
                            // Yeterince çekilmedi, eski yerine dön
                            withAnimation(.spring()) {
                                dragOffset = .zero
                                cardOpacity = 1.0
                            }
                        }
                    }
            )
            .onTapGesture {
                withAnimation {
                    showTranslation.toggle()
                }
            }
            Spacer()

            Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.top, 24)
        }
        .padding()
    }
}
