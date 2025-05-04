import SwiftUI

struct FireworkParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var color: Color
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
}

class CelebrationManager: ObservableObject {
    static let shared = CelebrationManager()
    
    @Published var isActive = false
    @Published var particles: [FireworkParticle] = []
    @Published var message: String = ""
    
    private var timer: Timer?
    
    func showCelebration(message: String = "Hedefe Ulaştın!") {
        self.message = message
        self.isActive = true
        self.particles = []
        
        // Başlangıçta 10 havai fişek parçacığı oluştur
        createFireworks(count: 10)
        
        // Her 0.5 saniyede bir yeni havai fişekler oluştur
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.createFireworks(count: 5)
        }
        
        // 5 saniye sonra kutlamayı sonlandır
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.stopCelebration()
        }
    }
    
    func stopCelebration() {
        timer?.invalidate()
        timer = nil
        
        withAnimation {
            isActive = false
        }
    }
    
    private func createFireworks(count: Int) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        for _ in 0..<count {
            // Rastgele konumlar
            let x = CGFloat.random(in: 0...screenWidth)
            let y = CGFloat.random(in: screenHeight/3...screenHeight)
            
            // Rastgele renk
            let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
            let color = colors.randomElement() ?? .red
            
            // Rastgele boyut
            let scale = CGFloat.random(in: 0.5...2.0)
            
            // Yeni parçacık ekle
            let particle = FireworkParticle(
                position: CGPoint(x: x, y: y),
                color: color,
                scale: scale,
                opacity: 1.0,
                rotation: Double.random(in: 0...360)
            )
            
            withAnimation {
                particles.append(particle)
            }
            
            // Parçacıkları 1-2 saniye sonra kaldır
            let duration = Double.random(in: 1.0...2.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                withAnimation {
                    if let index = self?.particles.firstIndex(where: { $0.id == particle.id }) {
                        self?.particles.remove(at: index)
                    }
                }
            }
        }
    }
}

struct CelebrationView: View {
    @ObservedObject private var celebrationManager = CelebrationManager.shared
    
    var body: some View {
        ZStack {
            if celebrationManager.isActive {
                // Arka plan
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .animation(.easeInOut, value: celebrationManager.isActive)
                
                // Havai fişekler
                ForEach(celebrationManager.particles) { particle in
                    FireworkView(particle: particle)
                }
                
                // Kutlama mesajı
                VStack {
                    Text(celebrationManager.message)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding()
                    
                    Button(action: {
                        celebrationManager.stopCelebration()
                    }) {
                        Text(NSLocalizedString("ok", comment: "OK button"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.top, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: celebrationManager.isActive)
            }
        }
        .animation(.easeInOut, value: celebrationManager.isActive)
    }
}

struct FireworkView: View {
    let particle: FireworkParticle
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "star.fill")
            .foregroundColor(particle.color)
            .scaleEffect(isAnimating ? particle.scale * 1.5 : particle.scale)
            .opacity(isAnimating ? 0.3 : 1.0)
            .rotationEffect(.degrees(isAnimating ? particle.rotation + 180 : particle.rotation))
            .position(particle.position)
            .onAppear {
                withAnimation(Animation.easeOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// Uygulama genelinde kullanılabilecek extension
extension View {
    func celebration() -> some View {
        ZStack {
            self
            CelebrationView()
        }
    }
}
