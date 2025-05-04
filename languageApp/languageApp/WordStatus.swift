import Foundation

enum WordStatus {
    case unknown
    case remembered
    case forgotten
}

class WordStatusManager {
    static let shared = WordStatusManager()
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    private func key(for videoId: String, word: String) -> String {
        return "word_status_\(videoId)_\(word)"
    }
    
    func setStatus(_ status: WordStatus, for word: String, in videoId: String) {
        let statusString: String
        switch status {
        case .remembered:
            statusString = "remembered"
        case .forgotten:
            statusString = "forgotten"
        case .unknown:
            statusString = "unknown"
        }
        defaults.set(statusString, forKey: key(for: videoId, word: word))
    }
    
    func getStatus(for word: String, in videoId: String) -> WordStatus {
        guard let statusString = defaults.string(forKey: key(for: videoId, word: word)) else {
            return .unknown
        }
        
        switch statusString {
        case "remembered":
            return .remembered
        case "forgotten":
            return .forgotten
        default:
            return .unknown
        }
    }
}
