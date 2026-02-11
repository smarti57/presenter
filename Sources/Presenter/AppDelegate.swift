import AppKit
import PDFKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var landingView: DropLandingView!
    private var reviewModeView: ReviewModeView?
    private var presentationController: PresentationController?
    private var currentDocument: PDFDocument?
    private var externalPresentationWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MenuBuilder.buildMainMenu()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Presenter"
        window.minSize = NSSize(width: 800, height: 500)
        window.center()
        window.setFrameAutosaveName("PresenterMainWindow")

        landingView = DropLandingView(frame: window.contentView!.bounds)
        landingView.autoresizingMask = [.width, .height]
        window.contentView = landingView

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Check for command-line PDF argument
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            let url = URL(fileURLWithPath: path)
            openPDF(at: url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        return true
    }

    // MARK: - Open PDF

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a PDF to present"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        openPDF(at: url)
    }

    func openPDF(at url: URL) {
        guard let document = PDFDocument(url: url) else {
            showAlert("Could not open PDF", message: "The file could not be read as a PDF document.")
            return
        }
        guard document.pageCount > 0 else {
            showAlert("Empty PDF", message: "This PDF has no pages.")
            return
        }

        currentDocument = document
        window.title = url.lastPathComponent

        let review = ReviewModeView(frame: window.contentView!.bounds, document: document)
        review.autoresizingMask = [.width, .height]
        review.delegate = self
        reviewModeView = review
        window.contentView = review
    }

    // MARK: - Presentation

    @objc func startPresentation(_ sender: Any?) {
        guard let review = reviewModeView else { return }
        // Trigger present via the toolbar's current settings
        review.delegate?.reviewModeDidRequestPresentation(
            fromSlide: 0,
            onScreen: 0,
            transition: .fade
        )
    }

    private func beginPresentation(fromSlide index: Int, onScreen screenIndex: Int, transition: TransitionStyle) {
        guard let document = currentDocument else { return }

        reviewModeView?.suspendEventMonitor()

        let targetScreen = resolveScreen(monitorIndex: screenIndex)
        let isExternal = targetScreen != window.screen && NSScreen.screens.count > 1

        if isExternal, let screen = targetScreen {
            // External monitor presentation
            let extWindow = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            extWindow.level = .screenSaver
            extWindow.setFrame(screen.frame, display: true)
            extWindow.backgroundColor = .black
            extWindow.makeKeyAndOrderFront(nil)
            externalPresentationWindow = extWindow

            let controller = PresentationController(window: extWindow, document: document, usesNativeFullscreen: false)
            controller.onEnd = { [weak self] lastIndex in
                self?.handlePresentationEnd(lastSlideIndex: lastIndex)
            }
            presentationController = controller
            controller.start(at: index, transition: transition)
        } else {
            // Same-screen fullscreen presentation
            let controller = PresentationController(window: window, document: document, usesNativeFullscreen: true)
            controller.onEnd = { [weak self] lastIndex in
                self?.handlePresentationEnd(lastSlideIndex: lastIndex)
            }
            presentationController = controller
            controller.start(at: index, transition: transition)
        }
    }

    private func handlePresentationEnd(lastSlideIndex: Int) {
        if let extWindow = externalPresentationWindow {
            extWindow.orderOut(nil)
            externalPresentationWindow = nil
            window.makeKeyAndOrderFront(nil)
        }

        presentationController = nil
        reviewModeView?.syncToSlide(lastSlideIndex)
        reviewModeView?.resumeEventMonitor()
    }

    private func resolveScreen(monitorIndex: Int) -> NSScreen? {
        let screens = NSScreen.screens

        if monitorIndex == 0 {
            // Automatic: pick the screen the window is NOT on, or main screen
            if screens.count >= 2, let windowScreen = window.screen {
                return screens.first { $0 != windowScreen } ?? screens.first
            }
            return NSScreen.main
        }

        // monitorIndex 1..N corresponds to NSScreen.screens[0..N-1]
        let screenIdx = monitorIndex - 1
        guard screenIdx >= 0, screenIdx < screens.count else { return NSScreen.main }
        return screens[screenIdx]
    }

    private func showAlert(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - ReviewModeDelegate

extension AppDelegate: ReviewModeDelegate {
    func reviewModeDidRequestPresentation(fromSlide index: Int, onScreen screenIndex: Int, transition: TransitionStyle) {
        beginPresentation(fromSlide: index, onScreen: screenIndex, transition: transition)
    }
}
