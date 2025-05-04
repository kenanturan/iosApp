import Foundation
import CoreData

extension RememberedWord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RememberedWord> {
        return NSFetchRequest<RememberedWord>(entityName: "RememberedWord")
    }

    @NSManaged public var date: Date?
    @NSManaged public var translation: String?
    @NSManaged public var videoId: String?
    @NSManaged public var word: String?
}
