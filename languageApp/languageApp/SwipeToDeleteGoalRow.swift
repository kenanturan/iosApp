import SwiftUI

struct SwipeToDeleteGoalRow: View {
    let goal: Goal
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var showDeleteButton = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            // Red delete background
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "trash.fill")
                            .foregroundColor(.white)
                            .padding(.trailing, 25)
                    }
                    Spacer()
                }
            }
            .frame(width: abs(offset), height: nil)
            .background(Color.red)
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Main content
            GoalRow(goal: goal)
                .padding(.horizontal)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if !isSwiping {
                                isSwiping = true
                            }
                            
                            if gesture.translation.width < 0 {
                                // Sadece sola çekmeye izin ver
                                offset = gesture.translation.width
                                
                                if abs(offset) > 80 {
                                    showDeleteButton = true
                                } else {
                                    showDeleteButton = false
                                }
                            }
                        }
                        .onEnded { gesture in
                            isSwiping = false
                            
                            if abs(offset) > 70 {
                                // Eşik değerini geçtiyse silme onayı göster
                                withAnimation(.spring()) {
                                    offset = -80 // Silme butonu görünecek kadar kaydır
                                }
                                DispatchQueue.main.async {
                                    showDeleteAlert = true
                                }
                            } else {
                                // Eşik değerini geçmediyse eski konumuna geri getir
                                withAnimation(.spring()) {
                                    offset = 0
                                    showDeleteButton = false
                                }
                            }
                        }
                )
        }
        .padding(.vertical, 4)
        .alert(NSLocalizedString("delete_goal", comment: "Delete goal"), isPresented: $showDeleteAlert) {
            Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {
                // İptal edildiğinde kartları eski konumuna getir
                withAnimation(.spring()) {
                    offset = 0
                    showDeleteButton = false
                }
            }
            Button(NSLocalizedString("confirm_delete", comment: "Yes, Delete"), role: .destructive) {
                // Silme işlemini gerçekleştir
                withAnimation(.spring()) {
                    offset = -500 // Ekrandan çıkması için
                }
                
                // Silme efekti bittikten sonra gerçek silme işlemini yap
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
            }
        } message: {
            Text(NSLocalizedString("delete_goal_confirm", comment: "Confirm delete goal"))
        }
    }
}
