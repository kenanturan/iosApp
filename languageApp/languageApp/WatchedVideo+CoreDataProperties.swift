import Foundation
import CoreData

extension WatchedVideo {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WatchedVideo> {
        return NSFetchRequest<WatchedVideo>(entityName: "WatchedVideo")
    }

    @NSManaged public var videoId: String?
    @NSManaged public var watchedDate: Date?
}
