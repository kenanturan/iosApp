import Foundation

struct Config {
    // Varsayılan değerler (GitHub'dan çekilemediği durumlar için yedek olarak kullanılır)
    private static let defaultApiKey = "AIzaSyAE4LjYBSoHblCpvGJgZ-D9X9YMOcSRURI"
    private static let defaultChannelId = "UCASGyre6VNuPsF5f9f9nm8g"
    private static let defaultBaseUrl = "https://www.googleapis.com/youtube/v3"
    
    // GitHub'daki yapılandırma dosyasının URL'si
    static let configUrl = "https://raw.githubusercontent.com/kenanturan/english-words/refs/heads/main/api.json"
    static let wordsBaseUrl = "https://raw.githubusercontent.com/kenanturan/english-words/refs/heads/main"
    
    // Yapılandırma değerlerini saklayacak değişkenler
    private static var _apiKey: String? = nil
    private static var _channelId: String? = nil
    private static var _baseUrl: String? = nil
    
    // GitHub'dan en son ne zaman yapılandırma çekildiğini takip etmek için
    private static var lastConfigFetchTime: Date? = nil
    
    // Yapılandırma değerlerini getirir
    static var apiKey: String {
        get {
            if let key = _apiKey {
                return key
            }
            return defaultApiKey
        }
    }
    
    static var channelId: String {
        get {
            if let id = _channelId {
                return id
            }
            return defaultChannelId
        }
    }
    
    static var baseUrl: String {
        get {
            if let url = _baseUrl {
                return url
            }
            return defaultBaseUrl
        }
    }
    
    // GitHub'dan yapılandırma bilgilerini çeken fonksiyon
    static func fetchConfiguration(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: configUrl) else {
            print("Geçersiz yapılandırma URL'si")
            completion(false)
            return
        }
        
        // Son güncelleme zamanı kontrolü (isteğe bağlı - çok sık istek yapmamak için)
        if let lastFetch = lastConfigFetchTime, Date().timeIntervalSince(lastFetch) < 3600 { // 1 saat
            // Son 1 saat içinde zaten güncelledik, tekrar güncellemeye gerek yok
            completion(true)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Yapılandırma çekilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                completion(false)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Yapılandırma değerlerini güncelle
                    _apiKey = json["apiKey"] as? String
                    _channelId = json["channelId"] as? String
                    _baseUrl = json["baseUrl"] as? String
                    
                    // Son güncelleme zamanını kaydet
                    lastConfigFetchTime = Date()
                    
                    print("Yapılandırma başarıyla güncellendi")
                    completion(true)
                } else {
                    print("Geçersiz yapılandırma verisi")
                    completion(false)
                }
            } catch {
                print("Yapılandırma ayrıştırılamadı: \(error.localizedDescription)")
                completion(false)
            }
        }
        
        task.resume()
    }
    
    // Kanal ID'sini manuel olarak değiştirmek için fonksiyon
    static func setChannelId(_ newChannelId: String) {
        _channelId = newChannelId
    }
}
