import UIKit
import AVKit
import SwiftUI
import SafariServices

class VideoListViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var videos: [PlaylistItem] = []
    private var displayedVideos: [PlaylistItem] = []
    private var filteredVideos: [PlaylistItem] = [] // Filtrelenmiş videolar için yeni dizi
    private var currentPage = 0
    private let videosPerPage = 8
    private var nextPageToken: String?
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var hideWatchedVideos = false // İzlenen videoları gizleme durumu
    private var languageSelector: UIView?
    private lazy var pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPageIndicatorTintColor = UIColor.systemBlue
        control.pageIndicatorTintColor = UIColor.systemGray5
        control.backgroundColor = UIColor.systemBackground
        
        // Kenar çizgisi ve gölge ekleme
        control.layer.borderWidth = 1.0
        control.layer.borderColor = UIColor.systemGray5.cgColor
        control.layer.cornerRadius = 20
        
        // Gölge efekti
        control.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        control.layer.shadowOffset = CGSize(width: 0, height: 2)
        control.layer.shadowRadius = 6
        control.layer.shadowOpacity = 1.0
        
        control.addTarget(self, action: #selector(pageControlValueChanged(_:)), for: .valueChanged)
        return control
    }()
    
    // Sağa ve sola geçiş için ok butonları
    private lazy var leftArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Şık, transparan iç içe daire tasarımı
        let size: CGFloat = 44
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let arrowImage = renderer.image { context in
            // Dış daire (mavi ton)
            let outerCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.systemBlue.withAlphaComponent(0.3).setFill()
            outerCirclePath.fill()
            
            // İç daire (daha koyu mavi)
            let innerCirclePath = UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: size-10, height: size-10))
            UIColor.systemBlue.withAlphaComponent(0.5).setFill()
            innerCirclePath.fill()
            
            // Ok ikonu
            let arrowPath = UIBezierPath()
            let centerY = size/2
            let arrowWidth: CGFloat = 14
            let arrowHeight: CGFloat = 14
            
            arrowPath.move(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY))
            arrowPath.addLine(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY + arrowHeight/2))
            
            arrowPath.lineWidth = 2.5
            UIColor.white.setStroke()
            arrowPath.stroke()
        }
        
        button.setImage(arrowImage, for: .normal)
        
        // Görsel efektler
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.layer.shadowOpacity = 1
        
        button.addTarget(self, action: #selector(previousPageTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var rightArrowButton: UIButton = {
        let button = UIButton(type: .custom)
        
        // Şık, transparan iç içe daire tasarımı
        let size: CGFloat = 44
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        
        let arrowImage = renderer.image { context in
            // Dış daire (mavi ton)
            let outerCirclePath = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size))
            UIColor.systemBlue.withAlphaComponent(0.3).setFill()
            outerCirclePath.fill()
            
            // İç daire (daha koyu mavi)
            let innerCirclePath = UIBezierPath(ovalIn: CGRect(x: 5, y: 5, width: size-10, height: size-10))
            UIColor.systemBlue.withAlphaComponent(0.5).setFill()
            innerCirclePath.fill()
            
            // Ok ikonu
            let arrowPath = UIBezierPath()
            let centerY = size/2
            let arrowWidth: CGFloat = 14
            let arrowHeight: CGFloat = 14
            
            arrowPath.move(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY - arrowHeight/2))
            arrowPath.addLine(to: CGPoint(x: size/2 + arrowWidth/2, y: centerY))
            arrowPath.addLine(to: CGPoint(x: size/2 - arrowWidth/2, y: centerY + arrowHeight/2))
            
            arrowPath.lineWidth = 2.5
            UIColor.white.setStroke()
            arrowPath.stroke()
        }
        
        button.setImage(arrowImage, for: .normal)
        
        // Görsel efektler
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        button.layer.shadowOpacity = 1
        
        button.addTarget(self, action: #selector(nextPageTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var segmentedContainer: UIView = {
        let container = UIView()
        container.backgroundColor = .systemBlue
        container.layer.cornerRadius = 20
        container.layer.masksToBounds = true
        
        // Üst parlaklık efekti
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        // İkon oluştur
        let iconType = "eye.slash"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iconImage = UIImage(systemName: iconType, withConfiguration: iconConfig)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .white
        
        // Metin için etiket
        let textLabel = UILabel()
        textLabel.text = NSLocalizedString("hide_watched", comment: "Hide watched")
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        // Stack'e içerikleri ekle
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textLabel)
        
        // Parlaklık efekti için overlay'i ekle
        overlayView.frame = CGRect(x: 0, y: 0, width: 160, height: 20) // Sadece üst yarısına parlaklık ekle
        container.addSubview(overlayView)
        
        // Container'a stack'i ekle
        container.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        // Tıklama işlevi
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleWatchedVideos))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        return container
    }()
    
    // Dil seçimi için kullanılacak dropdown menu
    private var languageTableView: UITableView?
    private var languageDropdown: UIView?
    private var isLanguageDropdownVisible = false
    private var outsideTapGesture: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchChannelUploadsPlaylistId()
        
        // İzlendi durumu değiştiğinde listeyi yenile
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(videoWatchStatusChanged),
                                             name: NSNotification.Name("VideoWatchStatusChanged"),
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func videoWatchStatusChanged() {
        collectionView.reloadData()
    }
    
    private func setupUI() {
        title = NSLocalizedString("videos", comment: "Videos title")
        view.backgroundColor = .systemBackground
        
        // UI öğelerini oluştur
        createFilterButton()  // Filtreleme butonunu oluştur
        setupNavigationBarItems()
        
        // Collection view yapılandırması
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        // 8 video göstermek için (her satırda 2 video) daha kompakt düzen
        let screenWidth = UIScreen.main.bounds.width
        let itemsPerRow: CGFloat = 2
        let padding: CGFloat = 12 // Kenar boşluklarını azalttık
        let spacing: CGFloat = 12 // Hücreler arası mesafeyi azalttık
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        let availableWidth = screenWidth - (2 * padding) - spacing
        let itemWidth = floor(availableWidth / itemsPerRow)
        
        // 16:9 aspect ratio için daha kompakt height hesaplama
        let itemHeight = itemWidth * 9/16 + 28 // Başlık alanını azalttık
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding) // 1.4 aspect ratio for thumbnail + text
        layout.sectionInset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        // Setup collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VideoCollectionViewCell.self, forCellWithReuseIdentifier: VideoCollectionViewCell.reuseIdentifier)
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        // OK butonlarını diğer view'lardan sonra ekleyelim ki en üstte görünsün
        view.addSubview(leftArrowButton)
        view.addSubview(rightArrowButton)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: pageControl.topAnchor),
            
            pageControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            pageControl.heightAnchor.constraint(equalToConstant: 40),
            pageControl.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            leftArrowButton.centerYAnchor.constraint(equalTo: pageControl.centerYAnchor),
            leftArrowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),  
            leftArrowButton.widthAnchor.constraint(equalToConstant: 44),
            leftArrowButton.heightAnchor.constraint(equalToConstant: 44),
            
            rightArrowButton.centerYAnchor.constraint(equalTo: pageControl.centerYAnchor),
            rightArrowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),  
            rightArrowButton.widthAnchor.constraint(equalToConstant: 44),
            rightArrowButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Butonları en üste getir
        view.bringSubviewToFront(leftArrowButton)
        view.bringSubviewToFront(rightArrowButton)
    }
    
    private func setupLanguageSelector() {
        // SwiftUI view'ını eklemek için bir controller oluştur
        let languageSelectorVC = UIHostingController(rootView: 
            LanguageSelectorView()
                .environmentObject(AppLanguageManager.shared)
                .frame(width: 100, height: 40)
        )
        languageSelectorVC.view.backgroundColor = .clear
        
        // View Controller hiyerarşisini düzgün kurmadan sadece view'ı alalım
        languageSelector = languageSelectorVC.view
    }
    
    private func setupNavigationBarItems() {
        // Dil seçici butonu için
        let languageButton = UIButton(type: .system)
        languageButton.setTitle(AppLanguageManager.shared.currentLanguage.nativeName, for: .normal)
        languageButton.setImage(UIImage(systemName: "globe"), for: .normal)
        languageButton.tintColor = .systemBlue
        languageButton.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        languageButton.addTarget(self, action: #selector(showLanguageSelector), for: .touchUpInside)
        
        // Dil seçici butonu sola yerleştir
        let leftItem = UIBarButtonItem(customView: languageButton)
        navigationItem.leftBarButtonItem = leftItem
        
        // Filtre butonu sağa yerleştir
        let rightItem = UIBarButtonItem(customView: segmentedContainer)
        navigationItem.rightBarButtonItem = rightItem
    }
    
    @objc private func showLanguageSelector() {
        // Önce mevcut dropdown'ı kaldıralım ve durumu tersine çevirelim
        if isLanguageDropdownVisible {
            hideLanguageDropdown()
            return
        }
        
        isLanguageDropdownVisible = true
        
        // Dropdown container oluştur
        let dropdownContainer = UIView()
        dropdownContainer.backgroundColor = .systemBackground
        dropdownContainer.layer.cornerRadius = 10
        dropdownContainer.layer.shadowColor = UIColor.black.cgColor
        dropdownContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        dropdownContainer.layer.shadowRadius = 5
        dropdownContainer.layer.shadowOpacity = 0.2
        dropdownContainer.layer.borderWidth = 1
        dropdownContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Tablo görünümü oluştur
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.bounces = false
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        tableView.rowHeight = 44
        
        // Dropdown pozisyonunu ayarla
        if let leftBarButton = navigationItem.leftBarButtonItem?.customView {
            let buttonFrame = leftBarButton.convert(leftBarButton.bounds, to: view)
            let dropdownWidth: CGFloat = 160
            let dropdownHeight: CGFloat = CGFloat(AppLanguage.allCases.count * 44)
            
            // Dropdown'ı butonun altında konumlandır - Arapça için RTL desteği
            let isRTL = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
            
            var xPosition: CGFloat = 0
            if isRTL {
                // Arapça gibi sağdan sola diller için
                xPosition = view.bounds.width - dropdownWidth - 20 // Sağ kenara yakın
            } else {
                // Soldan sağa diller için
                xPosition = max(20, buttonFrame.minX) // En azından 20px sol kenardan uzak
            }
            
            let yPosition = buttonFrame.maxY + 10 + (navigationController?.navigationBar.frame.height ?? 0)
            
            dropdownContainer.frame = CGRect(x: xPosition, y: yPosition, width: dropdownWidth, height: dropdownHeight)
            
            // Z düzeninde en üstte göster
            dropdownContainer.layer.zPosition = 1000
            
            // Tablo görünümünü dropdown container'a ekle
            dropdownContainer.addSubview(tableView)
            tableView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                tableView.topAnchor.constraint(equalTo: dropdownContainer.topAnchor),
                tableView.leadingAnchor.constraint(equalTo: dropdownContainer.leadingAnchor),
                tableView.trailingAnchor.constraint(equalTo: dropdownContainer.trailingAnchor),
                tableView.bottomAnchor.constraint(equalTo: dropdownContainer.bottomAnchor)
            ])
            
            // Dropdown'ı ana görünüme ekle
            view.addSubview(dropdownContainer)
            
            // Tablo ve dropdown referanslarını kaydet
            languageTableView = tableView
            languageDropdown = dropdownContainer
            
            // Dropdown'ı gösterirken animasyon ekle
            dropdownContainer.alpha = 0
            dropdownContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            
            UIView.animate(withDuration: 0.2) {
                dropdownContainer.alpha = 1
                dropdownContainer.transform = .identity
            }
            
            // Dropdown dışına tıklandığında kapatmak için gesture recognizer ekle
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
            outsideTapGesture = tapGesture
        }
    }
    
    @objc private func handleOutsideTap(gesture: UITapGestureRecognizer) {
        if let dropdown = languageDropdown {
            let location = gesture.location(in: view)
            if !dropdown.frame.contains(location) {
                hideLanguageDropdown()
            }
        }
    }
    
    private func hideLanguageDropdown() {
        guard isLanguageDropdownVisible, let dropdown = languageDropdown else { return }
        
        // Dropdown'ı gizle
        UIView.animate(withDuration: 0.2, animations: {
            dropdown.alpha = 0
            dropdown.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            dropdown.removeFromSuperview()
            self.languageDropdown = nil
            self.languageTableView = nil
            
            // Gesture recognizer'ı kaldır
            if let tapGesture = self.outsideTapGesture {
                self.view.removeGestureRecognizer(tapGesture)
                self.outsideTapGesture = nil
            }
        }
        
        isLanguageDropdownVisible = false
    }
    
    private func createFilterButton() {
        // Button container ayarla (daha önce tanımlanmış)
        segmentedContainer.layer.cornerRadius = 20
        segmentedContainer.layer.masksToBounds = true
        segmentedContainer.backgroundColor = hideWatchedVideos ? .systemGreen : .systemBlue
        
        // İçerik stack'i oluştur
        let contentStack = UIStackView()
        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 8
        
        // Üst parlaklık efekti
        let overlayView = UIView()
        overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        
        // İkon oluştur
        let iconType = hideWatchedVideos ? "eye" : "eye.slash"
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        let iconImage = UIImage(systemName: iconType, withConfiguration: iconConfig)
        let iconView = UIImageView(image: iconImage)
        iconView.tintColor = .white
        
        // Metin için etiket
        let textLabel = UILabel()
        textLabel.text = hideWatchedVideos ? NSLocalizedString("show_all", comment: "Show all") : NSLocalizedString("hide_watched", comment: "Hide watched")
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        
        // Stack'e içerikleri ekle
        contentStack.addArrangedSubview(iconView)
        contentStack.addArrangedSubview(textLabel)
        
        // Parlaklık efekti için overlay'i ekle
        overlayView.frame = CGRect(x: 0, y: 0, width: 160, height: 20) // Sadece üst yarısına parlaklık ekle
        segmentedContainer.addSubview(overlayView)
        
        // Container'a stack'i ekle
        segmentedContainer.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: segmentedContainer.topAnchor, constant: 10),
            contentStack.bottomAnchor.constraint(equalTo: segmentedContainer.bottomAnchor, constant: -10),
            contentStack.leadingAnchor.constraint(equalTo: segmentedContainer.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: segmentedContainer.trailingAnchor, constant: -16)
        ])
        
        // Tıklama işlevi
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleWatchedVideos))
        segmentedContainer.addGestureRecognizer(tapGesture)
        segmentedContainer.isUserInteractionEnabled = true
    }
    
    private func fetchChannelUploadsPlaylistId() {
        activityIndicator.startAnimating()
        collectionView.isHidden = true
        
        let urlString = "\(Config.baseUrl)/channels?key=\(Config.apiKey)&id=\(Config.channelId)&part=contentDetails"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Invalid URL configuration")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self?.showError("No data received")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChannelResponse.self, from: data)
                if let playlistId = response.items.first?.contentDetails.relatedPlaylists.uploads {
                    self?.fetchVideos(playlistId: playlistId)
                } else {
                    DispatchQueue.main.async {
                        self?.showError("Could not find uploads playlist")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self?.showError("Failed to decode channel data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    @objc private func toggleWatchedVideos() {
        print("Toggle butonuna tıklandı. Mevcut durum: \(hideWatchedVideos)")
        
        // İzlenen videoları gizleme/gösterme durumunu değiştir
        hideWatchedVideos = !hideWatchedVideos
        
        print("Yeni durum: \(hideWatchedVideos)")
        
        // Buton görünümünü güncelle
        updateFilterButtonAppearance()
        
        // Videoları güncelle ve koleksiyonu yeniden yükle
        currentPage = 0 // İlk sayfaya dön
        updateDisplayedVideos()
        collectionView.reloadData()
        
        // Sayfada hiç içerik kalmadıysa bilgilendirme göster
        if displayedVideos.isEmpty && hideWatchedVideos {
            let emptyView = createEmptyStateView()
            collectionView.backgroundView = emptyView
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    private func updateFilterButtonAppearance() {
        // Buton metni ve ikonunu güncelle
        print("Container alt elemanları taranıyor")
        
        var foundLabel = false
        
        // Duruma göre buton rengini belirle
        let newColor = hideWatchedVideos ? UIColor.systemGreen : UIColor.systemBlue
        
        // Butonun arka plan rengini güncelle
        segmentedContainer.backgroundColor = newColor
        
        // Gölgeyi güncelle
        segmentedContainer.layer.shadowColor = newColor.withAlphaComponent(0.3).cgColor
        
        // Container içindeki stack view'ı bul
        for subview in segmentedContainer.subviews {
            // ContentStack'i bul
            if let contentStack = subview as? UIStackView {
                print("StackView bulundu, eleman sayısı: \(contentStack.arrangedSubviews.count)")
                
                // Stack view içindeki elemanları tara
                for (index, view) in contentStack.arrangedSubviews.enumerated() {
                    if index == 0, let iconView = view as? UIImageView {
                        // İkon görselini güncelle
                        let newIconName = hideWatchedVideos ? "eye" : "eye.slash"
                        print("İkon güncelleniyor: \(newIconName)")
                        iconView.image = UIImage(systemName: newIconName)?.withRenderingMode(.alwaysTemplate)
                    } else if index == 1, let textLabel = view as? UILabel {
                        // Metin etiketini güncelle
                        let newText = hideWatchedVideos ? NSLocalizedString("show_all", comment: "Show all videos") : NSLocalizedString("hide_watched", comment: "Hide watched videos")
                        print("Etiket güncelleniyor: \(newText)")
                        textLabel.text = newText
                        foundLabel = true
                    }
                }
            }
        }
        
        if !foundLabel {
            print("HATA: Metin etiketi bulunamadı!")
        }
        
        // Basma ve renk değişimi için animasyon
        UIView.animate(withDuration: 0.2, animations: {
            self.segmentedContainer.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.2, animations: {
                self.segmentedContainer.transform = .identity
            })
        })
    }
    
    private func createEmptyStateView() -> UIView {
        let containerView = UIView()
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        
        let imageView = UIImageView(image: UIImage(systemName: "play.slash.fill"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = NSLocalizedString("all_videos_watched", comment: "All videos watched")
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .systemGray
        
        let descriptionLabel = UILabel()
        descriptionLabel.text = NSLocalizedString("show_all_videos_info", comment: "Tap 'Show All' to see more videos")
        descriptionLabel.font = UIFont.systemFont(ofSize: 15)
        descriptionLabel.textColor = .systemGray2
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            stackView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor, constant: -40)
        ])
        
        return containerView
    }
    
    private func fetchVideos(playlistId: String, pageToken: String? = nil) {
        var urlString = "\(Config.baseUrl)/playlistItems?key=\(Config.apiKey)&playlistId=\(playlistId)&part=snippet&maxResults=50"
        if let pageToken = pageToken {
            urlString += "&pageToken=\(pageToken)"
        }
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { [weak self] in
                self?.showError("Invalid URL configuration")
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.showError("No data received")
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlaylistResponse.self, from: data)
                
                DispatchQueue.main.async {
                    // Append new videos to existing ones
                    self.videos.append(contentsOf: response.items)
                    
                    // If there are more pages, fetch them
                    if let nextPageToken = response.nextPageToken {
                        self.fetchVideos(playlistId: playlistId, pageToken: nextPageToken)
                    } else {
                        // All videos fetched, now sort them by date and update UI
                        self.videos.sort { $0.snippet.publishedAt < $1.snippet.publishedAt }
                        self.updateDisplayedVideos()
                        self.pageControl.numberOfPages = Int(ceil(Double(self.videos.count) / Double(self.videosPerPage)))
                        self.collectionView.reloadData()
                        self.activityIndicator.stopAnimating()
                        self.collectionView.isHidden = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError("Failed to decode video data: \(error.localizedDescription)")
                    self.activityIndicator.stopAnimating()
                    self.collectionView.isHidden = false
                }
            }
        }.resume()
    }
    
    @objc private func openVideo(videoId: String, index: Int) {
        let playerVC = VideoPlayerViewController(videoId: videoId, index: index)
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated: true)
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: NSLocalizedString("warning", comment: "Warning"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
            self?.present(alert, animated: true)
        }
    }
}

// Sayfa değişikliğini yönetmek için yeni fonksiyonlar
extension VideoListViewController {
    // Sayfa değiştirme işlemleri için yeni buton eventi
    @objc private func previousPageTapped() {
        if currentPage > 0 {
            let newPage = currentPage - 1
            pageControl.currentPage = newPage
            animatePageChange(to: newPage)
        }
    }
    
    @objc private func nextPageTapped() {
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        if currentPage < totalPages - 1 {
            let newPage = currentPage + 1
            pageControl.currentPage = newPage
            animatePageChange(to: newPage)
        }
    }
    
    private func animatePageChange(to page: Int) {
        // Butonun basılma animasyonu
        let button = page > currentPage ? rightArrowButton : leftArrowButton
        UIView.animate(withDuration: 0.1, animations: {
            button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                button.transform = CGAffineTransform.identity
            }
        }
        
        // Sayfa geçiş animasyonu
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self = self else { return }
            self.currentPage = page
            self.updateDisplayedVideos()
            self.collectionView.reloadData()
            self.updateArrowButtons()
        })
    }
    
    private func updateArrowButtons() {
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        leftArrowButton.isEnabled = currentPage > 0
        rightArrowButton.isEnabled = currentPage < totalPages - 1
        
        // Devre dışı butonlar için görsel geribildirim
        UIView.animate(withDuration: 0.3) {
            self.leftArrowButton.alpha = self.currentPage > 0 ? 1.0 : 0.3
            self.rightArrowButton.alpha = self.currentPage < totalPages - 1 ? 1.0 : 0.3
        }
    }
    
    private func updateDisplayedVideos() {
        // Önce tüm videoları veya sadece izlenmemiş videoları filtrele
        if hideWatchedVideos {
            filteredVideos = videos.filter { videoItem in
                // WatchedVideosManager kullanarak izlenen videoları kontrol et
                return !WatchedVideosManager.shared.isWatched(videoItem.snippet.resourceId.videoId)
            }
        } else {
            filteredVideos = videos
        }
        
        // Görüntülenecek sayfayı güncelle
        let totalPages = Int(ceil(Double(filteredVideos.count) / Double(videosPerPage)))
        if totalPages > 0 && currentPage >= totalPages {
            currentPage = totalPages - 1 // Sayfa sayısı azaldıysa, geçerli sayfayı güncelle
        }
        
        // Gösterilecek videoları ayarla
        let startIndex = currentPage * videosPerPage
        let endIndex = min(startIndex + videosPerPage, filteredVideos.count)
        
        if startIndex < endIndex {
            displayedVideos = Array(filteredVideos[startIndex..<endIndex])
        } else {
            displayedVideos = []
        }
        
        // Sayfa kontrolünü güncelle
        pageControl.numberOfPages = totalPages
        pageControl.isHidden = (totalPages <= 1)
        
        // Ok butonlarını güncelle
        updateArrowButtons()
    }
    
    @objc private func pageControlValueChanged(_ sender: UIPageControl) {
        // Animasyonlu sayfa geçişi
        UIView.transition(with: collectionView, duration: 0.3, options: .transitionCrossDissolve, animations: { [weak self] in
            guard let self = self else { return }
            self.currentPage = sender.currentPage
            self.updateDisplayedVideos()
            self.collectionView.reloadData()
            self.updateArrowButtons()
            
            // Butonları en üste getir
            self.view.bringSubviewToFront(self.leftArrowButton)
            self.view.bringSubviewToFront(self.rightArrowButton)
        })
        
        // Page control animasyonu
        UIView.animate(withDuration: 0.2) {
            self.pageControl.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.pageControl.transform = CGAffineTransform.identity
            }
        }
    }
}

extension VideoListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.reuseIdentifier, for: indexPath) as? VideoCollectionViewCell else {
            fatalError("Failed to dequeue VideoCollectionViewCell")
        }
        
        let video = displayedVideos[indexPath.row]
        let absoluteIndex = currentPage * videosPerPage + indexPath.row
        cell.configure(with: video, index: absoluteIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = displayedVideos[indexPath.row]
        let absoluteIndex = currentPage * videosPerPage + indexPath.row
        openVideo(videoId: video.snippet.resourceId.videoId, index: absoluteIndex)
        
        // Tıklama animasyonunu tetikle
        if let cell = collectionView.cellForItem(at: indexPath) as? VideoCollectionViewCell {
            cell.handleTap()
        }
    }
}

extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AppLanguage.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        cell.textLabel?.text = AppLanguage.allCases[indexPath.row].nativeName
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)
        cell.textLabel?.textColor = .systemGray
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Seçilen dili güncelle
        let selectedLanguage = AppLanguage.allCases[indexPath.row]
        
        // Dil değişimini yönet
        let currentLanguage = AppLanguageManager.shared.currentLanguage
        if currentLanguage != selectedLanguage {
            // Dil seçimini güncelle
            AppLanguageManager.shared.currentLanguage = selectedLanguage
            
            // Dil değişimini LanguageManager ile de uygula (bu UserDefaults'u ve Bundle'ı günceller)
            LanguageManager.shared.setLanguage(selectedLanguage)
            
            // Dil butonunu güncelle
            if let languageButton = navigationItem.leftBarButtonItem?.customView as? UIButton {
                languageButton.setTitle(selectedLanguage.nativeName, for: .normal)
            }
            
            // Dil değişikliği yapıldığını ve yeniden başlatılması gerektiğini kullanıcıya bildir
            let message = NSLocalizedString("restart_required", comment: "Restart required message")
            let alert = UIAlertController(title: NSLocalizedString("attention", comment: "Attention title"), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK"), style: .default))
            present(alert, animated: true)
        }
        
        // Dil seçicisini gizle
        hideLanguageDropdown()
    }
}
