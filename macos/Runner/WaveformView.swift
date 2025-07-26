import Cocoa

// Real-time Waveform Visualization View
class WaveformView: NSView {
    private var waveformData: [Double] = []
    private var waveformLayers: [CAShapeLayer] = []
    private let numberOfBars = 60 // Match the Flutter side waveform samples
    private var barWidth: CGFloat = 3.0
    private var barSpacing: CGFloat = 1.0
    
    // Animation properties
    private var displayLink: CVDisplayLink?
    private var isAnimating = false
    
    // Colors
    private var primaryColor: NSColor = NSColor.systemBlue
    private var secondaryColor: NSColor = NSColor.systemBlue.withAlphaComponent(0.3)
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        self.wantsLayer = true
        
        // Initialize waveform data with zeros
        waveformData = Array(repeating: 0.0, count: numberOfBars)
        
        // Calculate bar dimensions based on view size
        updateBarDimensions()
        
        // Setup initial waveform bars
        setupWaveformBars()
    }
    
    private func updateBarDimensions() {
        let totalSpacing = CGFloat(numberOfBars - 1) * barSpacing
        let availableWidth = bounds.width - 20 // 10px margin on each side
        barWidth = max(2.0, (availableWidth - totalSpacing) / CGFloat(numberOfBars))
    }
    
    override func layout() {
        super.layout()
        updateBarDimensions()
        setupWaveformBars()
    }
    
    private func setupWaveformBars() {
        // Clear existing layers
        waveformLayers.forEach { $0.removeFromSuperlayer() }
        waveformLayers.removeAll()
        
        let startX: CGFloat = (bounds.width - (CGFloat(numberOfBars) * barWidth + CGFloat(numberOfBars - 1) * barSpacing)) / 2
        
        for i in 0..<numberOfBars {
            let layer = CAShapeLayer()
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            
            // Initial height (minimal)
            let height: CGFloat = 2.0
            let y = (bounds.height - height) / 2
            
            layer.frame = CGRect(x: x, y: y, width: barWidth, height: height)
            layer.backgroundColor = secondaryColor.cgColor
            layer.cornerRadius = barWidth / 2
            
            self.layer?.addSublayer(layer)
            waveformLayers.append(layer)
        }
    }
    
    func updateWaveformData(_ newData: [Double]) {
        guard newData.count == numberOfBars else {
            print("WaveformView: Invalid data length. Expected \(numberOfBars), got \(newData.count)")
            return
        }
        
        waveformData = newData
        updateVisualWaveform()
    }
    
    private func updateVisualWaveform() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.1)
        
        for (index, layer) in waveformLayers.enumerated() {
            let amplitude = waveformData[index]
            
            // Calculate bar height based on amplitude (0.0 to 1.0)
            let minHeight: CGFloat = 2.0
            let maxHeight: CGFloat = bounds.height * 0.8 // 80% of view height
            let height = minHeight + (maxHeight - minHeight) * CGFloat(amplitude)
            
            // Center the bar vertically
            let y = (bounds.height - height) / 2
            
            // Update layer frame
            layer.frame = CGRect(
                x: layer.frame.origin.x,
                y: y,
                width: barWidth,
                height: height
            )
            
            // Update color based on amplitude
            let alpha: CGFloat = 0.3 + (0.7 * CGFloat(amplitude)) // Alpha from 0.3 to 1.0
            layer.backgroundColor = primaryColor.withAlphaComponent(alpha).cgColor
        }
        
        CATransaction.commit()
    }
    
    func setColors(primary: NSColor, secondary: NSColor) {
        primaryColor = primary
        secondaryColor = secondary
        
        // Update existing layers
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        for (index, layer) in waveformLayers.enumerated() {
            let amplitude = waveformData[index]
            let alpha: CGFloat = 0.3 + (0.7 * CGFloat(amplitude))
            layer.backgroundColor = primaryColor.withAlphaComponent(alpha).cgColor
        }
        
        CATransaction.commit()
    }
    
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Add a subtle breathing animation to the entire waveform
        let breathingAnimation = CABasicAnimation(keyPath: "transform.scale")
        breathingAnimation.fromValue = 1.0
        breathingAnimation.toValue = 1.02
        breathingAnimation.duration = 1.5
        breathingAnimation.autoreverses = true
        breathingAnimation.repeatCount = .infinity
        breathingAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        layer?.add(breathingAnimation, forKey: "breathingAnimation")
    }
    
    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        
        layer?.removeAnimation(forKey: "breathingAnimation")
        
        // Fade out animation
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        
        for layer in waveformLayers {
            layer.backgroundColor = secondaryColor.cgColor
        }
        
        CATransaction.commit()
    }
    
    func reset() {
        waveformData = Array(repeating: 0.0, count: numberOfBars)
        updateVisualWaveform()
    }
} 