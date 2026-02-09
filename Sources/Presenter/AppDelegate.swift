import AppKit
import PDFKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    private var landingView: DropLandingView!
    private var presentationController: PresentationController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MenuBuilder.buildMainMenu()

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Presenter"
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

        window.title = url.lastPathComponent

        presentationController = PresentationController(window: window, document: document)
        presentationController?.start()
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
