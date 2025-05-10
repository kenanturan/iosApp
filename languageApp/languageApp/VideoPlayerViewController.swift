import UIKit
import WebKit

class VideoPlayerViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let webView: WKWebView
    
    private let watchedButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)
        button.setTitle("  " + NSLocalizedString("watched_status", comment: "Watched status"), for: .normal)
        button.setImage(image, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 25
        button.layer.masksToBounds = true
        return button
    }()
    
    private let unwatchedButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        button.setTitle("  " + NSLocalizedString("not_watched", comment: "Not watched status"), for: .normal)
        button.setImage(image, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.layer.cornerRadius = 25
        button.layer.masksToBounds = true
        return button
    }()
    
    private let flashcardsButton: GradientButton = {
        let button = GradientButton(type: .system)
        button.gradientColors = [UIColor.systemOrange.cgColor, UIColor.systemYellow.cgColor]
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let image = UIImage(systemName: "rectangle.stack.fill", withConfiguration: config)?.withRenderingMode(.alwaysOriginal)
        button.setTitle("  " + NSLocalizedString("word_cards", comment: "Word Cards"), for: .normal)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.numberOfLines = 2
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        button.layer.cornerRadius = 28
        button.layer.masksToBounds = true
        button.isEnabled = true
        button.alpha = 1.0
        return button
    }()

    private let videoId: String
    private let videoIndex: Int
    
    init(videoId: String, index: Int) {
        self.videoId = videoId
        self.videoIndex = index
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadVideo()
        setupActions()
        
        // Set initial button states based on watched status
        updateButtonAppearance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Karanlık/açık mod değişikliğini kontrol et
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                // Butonların görünümünü güncelle
                updateButtonAppearance()
            }
        }
    }
    
    private func updateButtonAppearance() {
        if WatchedVideosManager.shared.isWatched(videoId) {
            // İzlendi durumu - Dinamik renk kullan
            watchedButton.backgroundColor = UIColor.systemGreen
            watchedButton.tintColor = .white
            watchedButton.setTitleColor(.white, for: .normal)
            watchedButton.layer.borderWidth = 2.0
            
            if #available(iOS 13.0, *) {
                let borderColor = traitCollection.userInterfaceStyle == .dark ? 
                    UIColor.lightGray : UIColor.white
                watchedButton.layer.borderColor = borderColor.cgColor
            } else {
                watchedButton.layer.borderColor = UIColor.white.cgColor
            }
            
            // İzlenmedi butonu pasif göster
            if #available(iOS 13.0, *) {
                unwatchedButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? 
                    UIColor.darkGray : UIColor.systemGray4
            } else {
                unwatchedButton.backgroundColor = UIColor.systemGray4
            }
            
            unwatchedButton.tintColor = UIColor.lightGray
            unwatchedButton.setTitleColor(UIColor.lightGray, for: .normal)
            unwatchedButton.layer.borderWidth = 0
        } else {
            // İzlenmedi durumu - Dinamik renk kullan
            unwatchedButton.backgroundColor = UIColor.systemRed
            unwatchedButton.tintColor = .white
            unwatchedButton.setTitleColor(.white, for: .normal)
            unwatchedButton.layer.borderWidth = 2.0
            
            if #available(iOS 13.0, *) {
                let borderColor = traitCollection.userInterfaceStyle == .dark ? 
                    UIColor.lightGray : UIColor.white
                unwatchedButton.layer.borderColor = borderColor.cgColor
            } else {
                unwatchedButton.layer.borderColor = UIColor.white.cgColor
            }
            
            // İzlendi butonu pasif göster
            if #available(iOS 13.0, *) {
                watchedButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? 
                    UIColor.darkGray : UIColor.systemGray4
            } else {
                watchedButton.backgroundColor = UIColor.systemGray4
            }
            
            watchedButton.tintColor = UIColor.lightGray
            watchedButton.setTitleColor(UIColor.lightGray, for: .normal)
            watchedButton.layer.borderWidth = 0
        }
    }
    
    private func setupUI() {
        title = String(format: NSLocalizedString("video_title", comment: "Video title with number"), videoIndex + 1)
        view.backgroundColor = .systemBackground
        
        // Add back button
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        backButton.tintColor = .systemBlue
        navigationItem.leftBarButtonItem = backButton
        
        // Setup scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup content view with video player and description
        contentView.addSubview(webView)

        contentView.addSubview(watchedButton)
        contentView.addSubview(unwatchedButton)
        contentView.addSubview(flashcardsButton)

        
        webView.translatesAutoresizingMaskIntoConstraints = false

        watchedButton.translatesAutoresizingMaskIntoConstraints = false
        unwatchedButton.translatesAutoresizingMaskIntoConstraints = false
        flashcardsButton.translatesAutoresizingMaskIntoConstraints = false

        

        
        // Layout constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.heightAnchor.constraint(equalTo: webView.widthAnchor, multiplier: 9.0/16.0),
            
            watchedButton.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 16),
            watchedButton.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 8),
            watchedButton.widthAnchor.constraint(equalToConstant: 200),
            watchedButton.heightAnchor.constraint(equalToConstant: 60),
            
            unwatchedButton.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 20),
            unwatchedButton.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -16),
            unwatchedButton.widthAnchor.constraint(equalToConstant: 200),
            unwatchedButton.heightAnchor.constraint(equalToConstant: 60),
            
            flashcardsButton.topAnchor.constraint(equalTo: unwatchedButton.bottomAnchor, constant: 20),
            flashcardsButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            flashcardsButton.widthAnchor.constraint(equalToConstant: 260),
            flashcardsButton.heightAnchor.constraint(equalToConstant: 66),
            flashcardsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func loadVideo() {
        let embedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { margin: 0; background-color: #f1f1f1; }
                .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe width="100%" height="100%"
                    src="https://www.youtube.com/embed/\(videoId)?playsinline=1&autoplay=1"
                    frameborder="0"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
                </iframe>
            </div>
        </body>
        </html>
        """
        
        webView.loadHTMLString(embedHTML, baseURL: nil)
    }
    

    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func setupActions() {
        watchedButton.addTarget(self, action: #selector(watchedTapped), for: .touchUpInside)
        unwatchedButton.addTarget(self, action: #selector(unwatchedTapped), for: .touchUpInside)
        flashcardsButton.addTarget(self, action: #selector(flashcardsTapped), for: .touchUpInside)
    }
    
    @objc private func flashcardsTapped() {
        let flashcardsVC = FlashcardViewController(videoId: videoId, index: videoIndex)
        let navController = UINavigationController(rootViewController: flashcardsVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    @objc private func watchedTapped() {
        // İzlendi olarak işaretle
        WatchedVideosManager.shared.markAsWatched(videoId)
        
        // Buton görünümlerini güncelle
        updateButtonAppearance()
        
        // Bildirim gönder
        NotificationCenter.default.post(name: NSNotification.Name("VideoWatchStatusChanged"), object: nil)
    }
    
    @objc private func unwatchedTapped() {
        // İzlenmedi olarak işaretle
        WatchedVideosManager.shared.markAsUnwatched(videoId)
        
        // Buton görünümlerini güncelle
        updateButtonAppearance()
        
        // Bildirim gönder
        NotificationCenter.default.post(name: NSNotification.Name("VideoWatchStatusChanged"), object: nil)
    }
}
