import AppKit

final class ThumbnailCell: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("ThumbnailCell")

    private let slideNumberLabel = NSTextField(labelWithString: "")
    private let thumbnailImageView = NSImageView()

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 120))
        container.wantsLayer = true
        container.layer?.cornerRadius = 6
        self.view = container

        thumbnailImageView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(thumbnailImageView)

        slideNumberLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        slideNumberLabel.textColor = .secondaryLabelColor
        slideNumberLabel.alignment = .center
        slideNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(slideNumberLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            thumbnailImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            thumbnailImageView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            thumbnailImageView.bottomAnchor.constraint(equalTo: slideNumberLabel.topAnchor, constant: -2),
            slideNumberLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            slideNumberLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            slideNumberLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
            slideNumberLabel.heightAnchor.constraint(equalToConstant: 16),
        ])

        updateAppearance()
    }

    func configure(image: NSImage?, slideNumber: Int) {
        thumbnailImageView.image = image
        slideNumberLabel.stringValue = "\(slideNumber)"
    }

    private func updateAppearance() {
        guard isViewLoaded else { return }
        if isSelected {
            view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            view.layer?.borderColor = NSColor.controlAccentColor.cgColor
            view.layer?.borderWidth = 2
        } else {
            view.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.1).cgColor
            view.layer?.borderColor = nil
            view.layer?.borderWidth = 0
        }
    }
}
