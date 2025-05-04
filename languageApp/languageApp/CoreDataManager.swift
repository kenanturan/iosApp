import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {
        // Singleton
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GoalData")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func markVideoAsWatched(_ videoId: String) {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        
        do {
            let results = try context.fetch(fetchRequest)
            if results.isEmpty {
                let watchedVideo = WatchedVideo(context: context)
                watchedVideo.videoId = videoId
                watchedVideo.watchedDate = Date()
                saveContext()
            }
        } catch {
            print("Error marking video as watched: \(error)")
        }
    }
    
    func markVideoAsUnwatched(_ videoId: String) {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        
        do {
            let results = try context.fetch(fetchRequest)
            for video in results {
                context.delete(video)
            }
            saveContext()
        } catch {
            print("Error marking video as unwatched: \(error)")
        }
    }
    
    func isVideoWatched(_ videoId: String) -> Bool {
        let fetchRequest: NSFetchRequest<WatchedVideo> = WatchedVideo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "videoId == %@", videoId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Error checking video watched status: \(error)")
            return false
        }
    }
    // MARK: - RememberedWord
    func saveRememberedWord(word: String, translation: String, videoId: String) {
        let rememberedWord = RememberedWord(context: context)
        rememberedWord.word = word
        rememberedWord.translation = translation
        rememberedWord.videoId = videoId
        rememberedWord.date = Date()
        saveContext()
        print("[CoreData] Kaydedildi: \(word) - \(translation) - videoId: \(videoId)")
        print("[CoreData] Context: \(context)")
    }

}
