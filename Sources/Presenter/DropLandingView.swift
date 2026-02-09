import AppKit

final class DropLandingView: NSView {
    private let label = NSTextField(labelWithString: "Drop a PDF here or use File → Open")
    private var isDragHighlighted = false {
        didSet { needsDisplay = true }
    }

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
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        registerForDraggedTypes([.fileURL])

        label.font = NSFont.systemFont(ofSize: 24, weight: .light)
        label.textColor = .secondaryLabelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -40),
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isDragHighlighted {
            NSColor.controlAccentColor.withAlphaComponent(0.3).setFill()
            dirtyRect.fill()
            let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 8, dy: 8), xRadius: 12, yRadius: 12)
            borderPath.lineWidth = 4
            NSColor.controlAccentColor.setStroke()
            borderPath.stroke()
        }
    }

    // MARK: - Drag and Drop

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if validateDrop(sender) {
            isDragHighlighted = true
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return validateDrop(sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragHighlighted = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDragHighlighted = false
        guard let url = extractPDFURL(from: sender) else { return false }

        if let delegate = NSApp.delegate as? AppDelegate {
            delegate.openPDF(at: url)
        }
        return true
    }

    private func validateDrop(_ info: NSDraggingInfo) -> Bool {
        return extractPDFURL(from: info) != nil
    }

    private func extractPDFURL(from info: NSDraggingInfo) -> URL? {
        guard let items = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
            .urlReadingContentsConformToTypes: ["com.adobe.pdf"],
        ]) as? [URL], let url = items.first else {
            return nil
        }
        return url.pathExtension.lowercased() == "pdf" ? url : nil
    }
}
