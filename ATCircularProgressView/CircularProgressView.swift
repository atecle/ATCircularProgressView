//
//  CircularProgressView.swift
//  CircularProgressView
//
//  Created by Adam on 10/25/16.
//  Copyright © 2016 Adam Tecle. All rights reserved.
//

import UIKit

@IBDesignable @objc open class CircularProgressView: UIView {
    
    /// The width of the outer border. Defaults to 2px.
    @IBInspectable dynamic open var borderWidth: CGFloat = 2 {
        didSet {
            borderLayer.lineWidth = borderWidth
        }
    }
    /// The width of the progress bar. Defaults to 2px.
    @IBInspectable dynamic open var progressWidth: CGFloat = 2 {
        didSet {
            progressLayer.lineWidth = progressWidth
        }
    }
    
    /// The color of the outer border. Defaults to blue.
    @IBInspectable dynamic open var borderColor: UIColor = .blue {
        didSet {
            borderLayer.strokeColor = borderColor.cgColor
        }
    }
    
    /// The color of the progress bar. Defaults to red.
    @IBInspectable dynamic open var progressColor: UIColor = .red {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    /// The fill color of the view. Defaults to clear.
    @IBInspectable dynamic open var fillColor: UIColor = .clear {
        didSet {
            borderLayer.fillColor = fillColor.cgColor
        }
    }
    
    /// The value of the progress bar. Must be between 0.0 - 1.0. Defaults to 0.
    @IBInspectable dynamic open var progress: CGFloat = 0.0 {
        didSet {
            progressLayer.strokeEnd = progress
            progressChanged?(self, progress)
        }
    }
    
    /// A closure that's called each time the progress changes
    open var progressChanged: ((CircularProgressView, CGFloat) -> ())?
    
    open var centralView: UIView? {
        didSet {
           guard let view = centralView
            else { return }
            
            view.removeFromSuperview()
            addSubview(view)
        }
    }
    
    private let progressLayer = CAShapeLayer()
    
    private let borderLayer = CAShapeLayer()
    
    private var startAngle: CGFloat = 0.0
    
    private var endAngle: CGFloat = 0.0
    
    private var displayLink: CADisplayLink?
    
    private var destinationValue: CGFloat = 0.0
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    func setup() {
        backgroundColor = .clear
        
        progressLayer.lineWidth = progressWidth
        borderLayer.lineWidth = progressWidth
        
        progressLayer.fillColor = UIColor.clear.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        
        layer.addSublayer(borderLayer)
        layer.addSublayer(progressLayer)
        
        startAngle = CGFloat(-(M_PI * 0.5))
        endAngle   = CGFloat(3.0/4.0 * (M_PI * 2.0))
    }
    
    // MARK: - Overrides
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        progressLayer.frame = bounds
        progressLayer.strokeEnd = progress
        let borderPath = borderStrokePath(bounds: bounds)
        let progressPath = progressStrokePath(bounds: bounds)
        borderLayer.path = borderPath
        progressLayer.path = progressPath
        
        centralView?.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    open override func prepareForInterfaceBuilder() {
        updateAppearance()
    }
    
    // MARK: - Public
    
    open func setProgress(value: CGFloat, animated: Bool, duration: TimeInterval, completion: (() -> ())?) {
        destinationValue = max(min(value, 1.0), 0.0)
        
        if destinationValue == progress {
            return
        }
        
        if animated == true {
            createDisplayLink()
            displayLink?.isPaused = false
            
            progress = destinationValue
            let oldStrokeEnd = progressLayer.presentation()?.strokeEnd
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completion)
            let animation = CABasicAnimation()
            animation.fromValue = oldStrokeEnd
            animation.toValue = value
            animation.duration = duration
            progressLayer.add(animation, forKey: "strokeEnd")
            CATransaction.commit()
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = destinationValue
            CATransaction.commit()
            progress = destinationValue
        }
    }
    
    // MARK: - UI
    
    func stopAnimation() {
        progressLayer.removeAnimation(forKey: "strokeEnd")
        displayLink?.isPaused = true
    }
    
    func displayLinkDidFire(_: CADisplayLink) {
        guard let value = progressLayer.presentation()?.strokeEnd
            else { return }
        
        progressChanged?(self, value)
        if value == destinationValue {
            displayLink?.isPaused = true
        }
    }
    
    // MARK: - Helpers
    
    func borderStrokePath(bounds: CGRect) -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.midX
        
        let path = UIBezierPath.init(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return path.cgPath
    }
    
    func progressStrokePath(bounds: CGRect) -> CGPath {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.midX - borderWidth
        
        let path = UIBezierPath.init(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return path.cgPath
    }
    
    func updateAppearance() {
        progressLayer.strokeEnd = progress
        progressLayer.lineWidth = progressWidth
        progressLayer.path = progressStrokePath(bounds: bounds)
        progressLayer.strokeColor = progressColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.strokeColor = borderColor.cgColor
    }
    
    func createDisplayLink() {
        guard displayLink == nil
            else { return }
        displayLink = CADisplayLink.init(target: self, selector: #selector(displayLinkDidFire(_:)))
        displayLink?.isPaused = false
        displayLink?.add(to: .main, forMode: .commonModes)
    }
}
