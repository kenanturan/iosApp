import UIKit

class FlashcardViewController: UIViewController {
    private var words: [Word] = []
    private var currentIndex = 0
    private var forgottenWords: Set<String> = [] // Ezberlenememiş kelimeleri takip etmek için
    private var totalWords = 0 // Toplam kelime sayısı
    
    private var cardCenterX: CGFloat = 0
    private var cardCenterY: CGFloat = 0
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 100, weight: .bold)
        let image = UIImage(systemName: "checkmark.circle.fill", withConfiguration: config)?
            .withTintColor(.systemGreen, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let crossImageView: UIImageView = {
        let config = UIImage.SymbolConfiguration(pointSize: 100, weight: .bold)
        let image = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)?
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.alpha = 0
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 20
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let wordLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sonraki", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Önceki", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private var isShowingEnglish = true
    private let videoId: String
    private let videoIndex: Int
    
    init(videoId: String, index: Int) {
        self.videoId = videoId
        self.videoIndex = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchWords()
    }
    
    private func setupUI() {
        title = NSLocalizedString("word_cards", comment: "Word Cards")
        view.backgroundColor = .systemBackground
        
        // Add back button
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        backButton.tintColor = .systemBlue
        navigationItem.leftBarButtonItem = backButton
        
        view.addSubview(cardView)
        cardView.addSubview(wordLabel)
        view.addSubview(nextButton)
        view.addSubview(previousButton)
        view.addSubview(counterLabel)
        view.addSubview(checkmarkImageView)
        view.addSubview(crossImageView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        wordLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cardView.heightAnchor.constraint(equalToConstant: 200),
            
            wordLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            wordLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            wordLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            
            nextButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 40),
            nextButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10),
            nextButton.widthAnchor.constraint(equalToConstant: 120),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            previousButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 40),
            previousButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10),
            previousButton.widthAnchor.constraint(equalToConstant: 120),
            previousButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Kelime sayacı
            counterLabel.bottomAnchor.constraint(equalTo: cardView.topAnchor, constant: -20),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Onay ve çarpı işaretleri
            checkmarkImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            crossImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            crossImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Add gestures to card
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(cardPanned(_:)))
        cardView.addGestureRecognizer(tapGesture)
        cardView.addGestureRecognizer(panGesture)
        
        // Store initial card position
        cardCenterX = self.view.center.x
        cardCenterY = self.view.center.y - 50 // Adjust for better visual placement
        
        // Add button actions
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        // Hide buttons as we'll use swipe gestures
        nextButton.isHidden = true
        previousButton.isHidden = true
    }
    
    private func fetchWords() {
        guard let url = URL(string: "\(Config.wordsBaseUrl)/\(videoIndex + 1).json") else {
            showDataLoadingMessage()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showDataLoadingMessage()
                return
            }
            
            guard let data = data else {
                self.showDataLoadingMessage()
                return
            }
            
            do {
                let words = try JSONDecoder().decode(WordResponse.self, from: data)
                DispatchQueue.main.async {
                    self.words = words
                    self.totalWords = words.count
                    self.updateCard()
                }
            } catch {
                self.showDataLoadingMessage()
            }
        }.resume()
    }
    
    private func updateCard() {
        // Kelime sayacını güncelle
        let remainingCount = words.count
        counterLabel.text = String(format: NSLocalizedString("remaining_count", comment: "Remaining count of words"), remainingCount, totalWords)
        guard !words.isEmpty else {
            wordLabel.text = NSLocalizedString("no_word_found", comment: "No word found message")
            return
        }
        
        let currentWord = words[currentIndex]
        wordLabel.text = isShowingEnglish ? currentWord.english : currentWord.turkish
        
        previousButton.isEnabled = currentIndex > 0
        previousButton.backgroundColor = currentIndex > 0 ? .systemBlue : .systemGray
        
        nextButton.isEnabled = currentIndex < words.count - 1
        nextButton.backgroundColor = currentIndex < words.count - 1 ? .systemBlue : .systemGray
    }
    
    @objc private func cardTapped() {
        UIView.transition(with: cardView, duration: 0.3, options: .transitionFlipFromRight) {
            self.isShowingEnglish.toggle()
            self.updateCard()
        }
    }
    
    @objc private func nextTapped() {
        moveToNextCard(markAsRemembered: false)
    }
    
    private func moveToNextCard(markAsRemembered: Bool) {
        let currentWord = words[currentIndex]
        
        if markAsRemembered {
            // Ezberlenen kelimeyi listeden çıkar
            // CoreData'ya kaydet
            CoreDataManager.shared.saveRememberedWord(word: currentWord.english, translation: currentWord.turkish, videoId: videoId)
            words.remove(at: currentIndex)
            WordStatusManager.shared.setStatus(.remembered, for: currentWord.english, in: videoId)
            
            if words.isEmpty {
                showCompletionAlert()
                return
            }
            
            // Eğer son kelimedeysek başa dön
            if (currentIndex >= words.count) {
                currentIndex = 0
            }
        } else {
            // Ezberlenemeyen kelime için normal ilerleme
            if currentIndex >= words.count - 1 {
                currentIndex = 0
            } else {
                currentIndex += 1;
            }
        }
        
        isShowingEnglish = true
        
        // Animate new card from right
        let originalCenter = cardView.center
        cardView.center = CGPoint(x: view.bounds.width + cardView.bounds.width/2, y: originalCenter.y)
        updateCard()
        
        UIView.animate(withDuration: 0.3) {
            self.cardView.center = originalCenter
        }
    }
    
    private func moveBackToPreviousCard() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isShowingEnglish = true
        
        // Animate new card from left
        let originalCenter = cardView.center
        cardView.center = CGPoint(x: -cardView.bounds.width/2, y: originalCenter.y)
        updateCard()
        
        UIView.animate(withDuration: 0.3) {
            self.cardView.center = originalCenter
        }
    }
    
    @objc private func previousTapped() {
        moveBackToPreviousCard()
    }
    
    @objc private func cardPanned(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let card = gesture.view!
        
        switch gesture.state {
        case .began:
            cardCenterX = card.center.x
            cardCenterY = card.center.y
            
        case .changed:
            card.center = CGPoint(x: cardCenterX + translation.x,
                                 y: cardCenterY + min(max(-100, translation.y), 100))
            
            // Rotate card based on x translation
            let rotationAngle = translation.x / view.bounds.width * 0.5
            card.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
        case .ended:
            let velocity = gesture.velocity(in: view)
            let translation = gesture.translation(in: view)
            
            if translation.x > 100 || velocity.x > 500 {
                // Sağa kaydırıldı - Ezberledim
                showFeedbackAnimation(isSuccess: true)
                animateCardOut(to: .right) {
                    self.moveToNextCard(markAsRemembered: true)
                }
            } else if translation.x < -100 || velocity.x < -500 {
                // Sola kaydırıldı - Ezberleyemedim
                showFeedbackAnimation(isSuccess: false)
                animateCardOut(to: .left) {
                    let currentWord = self.words[self.currentIndex]
                    WordStatusManager.shared.setStatus(.forgotten, for: currentWord.english, in: self.videoId)
                    
                    // Kelimeyi sona eklemek için işaretle
                    self.forgottenWords.insert(currentWord.english)
                    
                    self.moveToNextCard(markAsRemembered: false)
                }
            } else {
                // Geri döndür
                UIView.animate(withDuration: 0.2) {
                    card.center = CGPoint(x: self.cardCenterX, y: self.cardCenterY)
                    card.transform = .identity
                }
            }
            
        default:
            break
        }
    }
    
    private enum CardDirection {
        case left
        case right
    }
    
    private func showFeedbackAnimation(isSuccess: Bool) {
        let imageView = isSuccess ? checkmarkImageView : crossImageView
        imageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            imageView.alpha = 1
            imageView.transform = .identity
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 0.2, options: [], animations: {
                imageView.alpha = 0
            })
        }
    }
    
    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("completion_title", comment: "Completion title"),
            message: NSLocalizedString("completion_message", comment: "Completion message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK button"), style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func animateCardOut(to direction: CardDirection, completion: @escaping () -> Void) {
        let card = cardView
        let targetX = direction == .right ? view.bounds.width * 2 : -view.bounds.width
        
        UIView.animate(withDuration: 0.3, animations: {
            card.center = CGPoint(x: targetX, y: self.cardCenterY)
            card.transform = CGAffineTransform(rotationAngle: direction == .right ? 0.5 : -0.5)
        }) { _ in
            card.transform = .identity
            completion()
        }
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func showDataLoadingMessage() {
        DispatchQueue.main.async {
            let title = NSLocalizedString("word_cards_loading_title", comment: "Word cards loading title")
            let message = NSLocalizedString("word_cards_loading_message", comment: "Word cards loading message")
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: "OK button"), style: .default))
            self.present(alert, animated: true)
        }
    }
}
