import AppKit
import PDFKit

protocol ReviewModeDelegate: AnyObject {
    func reviewModeDidRequestPresentation(fromSlide index: Int, onScreen screenIndex: Int, transition: TransitionStyle)
}

final class ReviewModeView: NSView {
    weak var delegate: ReviewModeDelegate?

    private let document: PDFDocument
    private let thumbnailTray = ThumbnailTrayView(frame: .zero)
    private let toolbar = ReviewToolbarView(frame: .zero)
    private let previewSlideView = SlideView(frame: .zero)

    private let thumbnailCache: PDFImageCache
    private let previewCache: PDFImageCache

    private var currentSlideIndex = 0
    private var eventMonitor: Any?

    private static let sidebarWidth: CGFloat = 200

    init(frame: NSRect, document: PDFDocument) {
        self.document = document
        self.thumbnailCache = PDFImageCache(document: document, screenSize: NSSize(width: 200, height: 150))
        self.previewCache = PDFImageCache(document: document, screenSize: NSSize(width: 800, height: 600))
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static let toolbarHeight: CGFloat = 44

    override func layout() {
        super.layout()
        layoutSubviews()
    }

    private func layoutSubviews() {
        let b = bounds
        let topInset = safeAreaInsets.top
        let sidebar = Self.sidebarWidth

        thumbnailTray.frame = NSRect(x: 0, y: 0, width: sidebar, height: b.height - topInset)

        let rightX = sidebar + 1 // 1pt for divider
        let rightW = b.width - rightX
        toolbar.frame = NSRect(x: rightX, y: b.height - topInset - Self.toolbarHeight, width: rightW, height: Self.toolbarHeight)

        let previewY: CGFloat = 0
        let previewH = b.height - topInset - Self.toolbarHeight
        let previewW = rightW
        let containerRect = NSRect(x: rightX, y: previewY, width: previewW, height: previewH)

        // Fit slide preview centered in the container with correct aspect ratio
        let aspect = previewCache.pageAspectRatio ?? (16.0 / 9.0)
        let pad: CGFloat = 8
        let availW = containerRect.width - pad * 2
        let availH = containerRect.height - pad * 2
        var slideW = availW
        var slideH = slideW / aspect
        if slideH > availH {
            slideH = availH
            slideW = slideH * aspect
        }
        let slideX = containerRect.origin.x + (containerRect.width - slideW) / 2
        let slideY = containerRect.origin.y + (containerRect.height - slideH) / 2
        previewSlideView.frame = NSRect(x: slideX, y: slideY, width: slideW, height: slideH)
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(white: 0.15, alpha: 1).cgColor

        // Thumbnail tray
        thumbnailTray.delegate = self
        thumbnailTray.pageAspectRatio = thumbnailCache.pageAspectRatio ?? (16.0 / 9.0)
        thumbnailTray.thumbnailProvider = { [weak self] index in
            self?.thumbnailCache.image(forPage: index)
        }

        addSubview(thumbnailTray)
        addSubview(toolbar)
        addSubview(previewSlideView)

        thumbnailTray.reload(pageCount: document.pageCount)
        toolbar.delegate = self
        toolbar.updateSlideCounter(current: 0, total: document.pageCount)

        // Show first slide
        DispatchQueue.main.async { [self] in
            thumbnailTray.selectItem(at: 0)
            showSlide(at: 0)
        }

        // Monitor for presenter remote keys (F5 to start, Page Down/Up to navigate thumbnails)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            switch event.keyCode {
            case 96: // F5 – start presentation (common Logitech presenter button)
                self.delegate?.reviewModeDidRequestPresentation(
                    fromSlide: self.currentSlideIndex,
                    onScreen: self.toolbar.selectedMonitorIndex,
                    transition: self.toolbar.selectedTransition
                )
                return nil
            case 121: // page down – next thumbnail
                let next = min(self.currentSlideIndex + 1, self.document.pageCount - 1)
                self.thumbnailTray.selectItem(at: next)
                self.showSlide(at: next)
                return nil
            case 116: // page up – previous thumbnail
                let prev = max(self.currentSlideIndex - 1, 0)
                self.thumbnailTray.selectItem(at: prev)
                self.showSlide(at: prev)
                return nil
            default:
                return event
            }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func suspendEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func resumeEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            switch event.keyCode {
            case 96: // F5
                self.delegate?.reviewModeDidRequestPresentation(
                    fromSlide: self.currentSlideIndex,
                    onScreen: self.toolbar.selectedMonitorIndex,
                    transition: self.toolbar.selectedTransition
                )
                return nil
            case 121: // page down
                let next = min(self.currentSlideIndex + 1, self.document.pageCount - 1)
                self.thumbnailTray.selectItem(at: next)
                self.showSlide(at: next)
                return nil
            case 116: // page up
                let prev = max(self.currentSlideIndex - 1, 0)
                self.thumbnailTray.selectItem(at: prev)
                self.showSlide(at: prev)
                return nil
            default:
                return event
            }
        }
    }

    func syncToSlide(_ index: Int) {
        currentSlideIndex = index
        thumbnailTray.selectItem(at: index)
        showSlide(at: index)
    }

    private func showSlide(at index: Int) {
        currentSlideIndex = index
        toolbar.updateSlideCounter(current: index, total: document.pageCount)

        let previewSize = previewSlideView.bounds.size
        if previewSize.width > 0 && previewSize.height > 0 {
            previewCache.updateRenderSize(previewSize)
        }

        if let image = previewCache.image(forPage: index) {
            previewSlideView.displayImage(image, transition: nil)
        }
    }
}

extension ReviewModeView: ThumbnailTrayDelegate {
    func thumbnailTray(_ tray: ThumbnailTrayView, didSelectSlideAt index: Int) {
        showSlide(at: index)
    }
}

extension ReviewModeView: ReviewToolbarDelegate {
    func reviewToolbarDidPresent(_ toolbar: ReviewToolbarView) {
        delegate?.reviewModeDidRequestPresentation(
            fromSlide: currentSlideIndex,
            onScreen: toolbar.selectedMonitorIndex,
            transition: toolbar.selectedTransition
        )
    }

    func reviewToolbar(_ toolbar: ReviewToolbarView, didSelectTransition style: TransitionStyle) {
        // Stored for when presentation starts
    }

    func reviewToolbar(_ toolbar: ReviewToolbarView, didSelectMonitor index: Int) {
        // Stored for when presentation starts
    }
}
