import Foundation
import Combine

class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()
    @Published var currentLanguage: AppLanguage = LanguageManager.shared.getStoredLanguage()

    func setLanguage(_ language: AppLanguage) {
        LanguageManager.shared.setLanguage(language)
        currentLanguage = language
        // No manual locale override; rely on system language
    }
}
