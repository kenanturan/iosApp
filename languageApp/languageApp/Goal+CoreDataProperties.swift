import Foundation
import CoreData

extension Goal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Goal> {
        return NSFetchRequest<Goal>(entityName: "Goal")
    }

    @NSManaged public var type: String?
    @NSManaged public var targetCount: Int32
    @NSManaged public var currentCount: Int32
    @NSManaged public var createDate: Date?
    @NSManaged public var deadline: Date?
}
