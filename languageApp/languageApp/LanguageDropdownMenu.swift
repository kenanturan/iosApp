import SwiftUI

struct LanguageDropdownMenu: View {
    @Binding var isExpanded: Bool
    @State private var showRestartAlert = false
    @State private var selectedLanguage: AppLanguage
    @EnvironmentObject var languageManager: AppLanguageManager
    
    init(isExpanded: Binding<Bool> = .constant(false)) {
        self._isExpanded = isExpanded
        _selectedLanguage = State(initialValue: LanguageManager.shared.getStoredLanguage())
    }
    
    var body: some View {
        VStack {
            // Dropdown button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    Text(selectedLanguage.nativeName)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Dropdown menu
            if isExpanded {
                ZStack {
                    Color(.systemBackground)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(AppLanguage.allCases) { language in
                                Button(action: {
                                    UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
                                    UserDefaults.standard.synchronize()
                                    languageManager.setLanguage(language)
                                    selectedLanguage = language
                                    withAnimation {
                                        isExpanded = false
                                    }
                                    showRestartAlert = true
                                }) {
                                    HStack {
                                        Text(language.nativeName)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if language == selectedLanguage {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .contentShape(Rectangle())
                                }
                                
                                if language != AppLanguage.allCases.last {
                                    Divider()
                                        .padding(.horizontal, 8)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .frame(height: min(CGFloat(AppLanguage.allCases.count) * 44, 300))
                }
                .transition(.scale)
            }
        }
        .alert(isPresented: $showRestartAlert) {
            Alert(
                title: Text(NSLocalizedString("attention", comment: "Attention")),
                message: Text(NSLocalizedString("restart_required", comment: "App restart required message")),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "OK")))
            )
        }
    }
}

// Overlay extension to handle outside taps
extension View {
    func languageDropdownTapHandler(isExpanded: Binding<Bool>) -> some View {
        self.overlay(
            Color.black.opacity(isExpanded.wrappedValue ? 0.001 : 0)
                .onTapGesture {
                    withAnimation {
                        isExpanded.wrappedValue = false
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(isExpanded.wrappedValue)
        )
    }
}

struct LanguageDropdownMenu_Previews: PreviewProvider {
    static var previews: some View {
        LanguageDropdownMenu()
            .environmentObject(AppLanguageManager.shared)
            .padding()
    }
}
