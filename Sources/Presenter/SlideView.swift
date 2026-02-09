import AppKit
import QuartzCore

final class SlideView: NSView {
    private let imageLayer = CALayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        imageLayer.contentsGravity = .resizeAspect
        imageLayer.frame = bounds
        imageLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(imageLayer)
    }

    override func layout() {
        super.layout()
        imageLayer.frame = bounds
    }

    func displayImage(_ image: NSImage, transition: CATransition?) {
        if let transition = transition {
            imageLayer.add(transition, forKey: kCATransition)
        }
        imageLayer.contents = image
    }
}
