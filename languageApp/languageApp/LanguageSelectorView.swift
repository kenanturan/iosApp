import SwiftUI

struct LanguageSelectorView: View {
    @State private var showRestartAlert = false
    @State private var isPresented = false
    @State private var selectedLanguage: AppLanguage = LanguageManager.shared.getStoredLanguage()
    @EnvironmentObject var languageManager: AppLanguageManager
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            HStack {
                Image(systemName: "globe")
                Text(selectedLanguage.nativeName)
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .alert(isPresented: $showRestartAlert) {
            Alert(
                title: Text(NSLocalizedString("attention", comment: "Attention")),
                message: Text(NSLocalizedString("restart_required", comment: "App restart required message")),
                dismissButton: .default(Text(NSLocalizedString("ok", comment: "OK")))
            )
        }
        .sheet(isPresented: $isPresented) {
            LanguagePickerView(onLanguageSelected: {
                isPresented = false
                showRestartAlert = true
            }, selectedLanguage: $selectedLanguage)
            .environmentObject(languageManager)
        }
    }
}

struct LanguagePickerView: View {
    var onLanguageSelected: () -> Void
    @EnvironmentObject var languageManager: AppLanguageManager
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: AppLanguage
    
    var body: some View {
        NavigationView {
            List(AppLanguage.allCases, id: \.self) { language in
                Button(action: {
                    // AppleLanguages yöntemiyle dili değiştir
                    UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
                    UserDefaults.standard.synchronize()
                    languageManager.setLanguage(language)
                    selectedLanguage = language
                    dismiss()
                    onLanguageSelected()
                }) {
                    HStack {
                        Text(language.nativeName)
                        Spacer()
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Language")
        }
    }
}
