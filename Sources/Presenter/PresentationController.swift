import AppKit
import PDFKit

final class PresentationController {
    private let window: NSWindow
    private let cache: PDFImageCache
    private let slideView: SlideView
    private var savedContentView: NSView?
    private var eventMonitor: Any?
    private var currentIndex = 0
    private var transitionStyle: TransitionStyle = .fade

    init(window: NSWindow, document: PDFDocument) {
        let screenSize = window.screen?.frame.size ?? NSSize(width: 1920, height: 1080)
        self.window = window
        self.cache = PDFImageCache(document: document, screenSize: screenSize)
        self.slideView = SlideView(frame: window.contentView?.bounds ?? .zero)
        self.slideView.autoresizingMask = [.width, .height]
    }

    var pageCount: Int { cache.pageCount }

    func start() {
        savedContentView = window.contentView

        window.contentView = slideView
        window.backgroundColor = .black

        if !window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }

        installEventMonitor()
        goToSlide(0)
        NSCursor.hide()
    }

    func endPresentation() {
        removeEventMonitor()
        NSCursor.unhide()

        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }

        window.backgroundColor = .windowBackgroundColor
        if let saved = savedContentView {
            window.contentView = saved
            savedContentView = nil
        }
    }

    // MARK: - Navigation

    private func goToSlide(_ index: Int, direction: TransitionDirection? = nil) {
        guard index >= 0, index < cache.pageCount else { return }

        let dir = direction ?? (index >= currentIndex ? .forward : .backward)
        let isFirstSlide = (currentIndex == 0 && index == 0)
        currentIndex = index

        let screenSize = window.screen?.frame.size ?? NSSize(width: 1920, height: 1080)
        cache.updateRenderSize(screenSize)

        if let image = cache.image(forPage: index) {
            let transition = isFirstSlide ? nil : transitionStyle.makeTransition(direction: dir)
            slideView.displayImage(image, transition: transition)
        }

        DispatchQueue.global(qos: .userInitiated).async { [cache] in
            cache.preloadNeighbors(of: index)
        }
    }

    private func nextSlide() {
        if currentIndex < cache.pageCount - 1 {
            goToSlide(currentIndex + 1, direction: .forward)
        }
    }

    private func previousSlide() {
        if currentIndex > 0 {
            goToSlide(currentIndex - 1, direction: .backward)
        }
    }

    // MARK: - Event Handling

    private func installEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            return self.handleEvent(event) ? nil : event
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleEvent(_ event: NSEvent) -> Bool {
        if event.type == .leftMouseDown {
            nextSlide()
            return true
        }

        guard event.type == .keyDown else { return false }

        switch event.keyCode {
        case 123, 126: // left arrow, up arrow
            previousSlide()
            return true
        case 124, 125: // right arrow, down arrow
            nextSlide()
            return true
        case 49: // space
            nextSlide()
            return true
        case 36: // return
            nextSlide()
            return true
        case 53: // escape
            endPresentation()
            return true
        case 17: // T key
            transitionStyle = transitionStyle.next()
            return true
        default:
            return false
        }
    }
}
