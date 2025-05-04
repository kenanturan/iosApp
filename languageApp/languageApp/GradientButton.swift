import UIKit

class GradientButton: UIButton {
    private var gradientLayer: CAGradientLayer?
    var gradientColors: [CGColor] = [UIColor.systemOrange.cgColor, UIColor.systemYellow.cgColor]

    override func layoutSubviews() {
        super.layoutSubviews()
        if gradientLayer == nil {
            let gradient = CAGradientLayer()
            gradient.colors = gradientColors
            gradient.startPoint = CGPoint(x: 0, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 0.5)
            gradient.frame = bounds
            gradient.cornerRadius = layer.cornerRadius
            layer.insertSublayer(gradient, at: 0)
            gradientLayer = gradient
        } else {
            gradientLayer?.frame = bounds
            gradientLayer?.cornerRadius = layer.cornerRadius
        }
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
    }
}
