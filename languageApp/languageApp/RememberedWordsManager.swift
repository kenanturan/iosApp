import Foundation
import CoreData

class RememberedWordsManager {
    static let shared = RememberedWordsManager()
    
    private let context = CoreDataManager.shared.context
    
    private init() {}
    
    // VIDEO MANAGER İLE BİREBİR AYNI ÇALIŞAN FONKSİYON
    func rememberedWordCount(start: Date?, end: Date?) -> Int {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        
        // Başlangıç tarihi olmadan tüm kelimeleri saymaya izin vermeyelim
        guard let startDate = start else {
            print("[RememberedWordsManager] HATA: Başlangıç tarihi belirtilmedi, sıfır döndürülüyor")
            return 0
        }
        
        // Tarih geçerliliği için ekstra kontrol
        if startDate.timeIntervalSince1970 < 86400 { // 1 günden az (1970-01-01'e çok yakın tarih)
            print("[RememberedWordsManager] HATA: Başlangıç tarihi geçersiz, sıfır döndürülüyor")
            return 0
        }
        
        // Log bilgisi yazdıralım
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        print("[RememberedWordsManager] Kelime sayımı başlangıç: \(formatter.string(from: startDate)), " + 
              "bitiş: \(end != nil ? formatter.string(from: end!) : "yok")")
        
        // >ÖNEMLİ< Tam zaman damgası karşılaştırması için >= yerine > kullanıyoruz
        // Böylece hedef eklenme anı ile aynı anda (milisaniye farkı ile) kaydedilmiş kelimeler sayılmaz
        if let endDate = end {
            fetchRequest.predicate = NSPredicate(format: "date > %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        } else {
            fetchRequest.predicate = NSPredicate(format: "date > %@", startDate as NSDate)
        }
        
        do {
            let count = try CoreDataManager.shared.context.count(for: fetchRequest)
            return count
        } catch {
            print("Kelime count hesaplama hatası: \(error)")
            return 0
        }
    }
    
    // Belirli bir kelimenin hatırlanıp hatırlanmadığını kontrol et
    func isWordRemembered(word: String) -> Bool {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "word == %@", word)
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("[RememberedWords] isWordRemembered error: \(error)")
            return false
        }
    }
    
    // Belirli bir kelimenin hatırlanıp hatırlanmadığını kontrol et
    func isRemembered(_ wordId: String) -> Bool {
        let fetchRequest: NSFetchRequest<RememberedWord> = RememberedWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "wordId == %@", wordId)
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("Kelime kontrolünde hata: \(error.localizedDescription)")
            return false
        }
    }
}
