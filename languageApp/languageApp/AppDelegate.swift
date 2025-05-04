import UIKit
import CoreData
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Notification center için delegate atama
        UNUserNotificationCenter.current().delegate = self
        
        // Bildirim izni iste ve bildirimleri planla
        NotificationManager.shared.requestPermission { granted in
            if granted {
                NotificationManager.shared.scheduleMotivationNotifications()
                print("Bildirimler için izin alındı ve motivasyon bildirimleri planlandı")
            } else {
                print("Bildirim izni reddedildi")
            }
        }
        
        return true
    }
    
    // Uygulama açıkken bildirim geldiğinde nasıl davranacağını belirtme
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Uygulama açıkken de bildirimi göster
        completionHandler([.banner, .sound, .badge])
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - Core Data
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "GoalData")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("CoreData store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
