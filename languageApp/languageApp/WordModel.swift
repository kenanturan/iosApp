import Foundation

typealias WordResponse = [Word]

struct Word: Codable {
    let word: String
    let translation: String
    
    var english: String { word }
    var turkish: String { translation }
}
