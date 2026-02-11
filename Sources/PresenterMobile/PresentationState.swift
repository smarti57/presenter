#if os(iOS)
import SwiftUI
import PDFKit

@Observable
final class PresentationState {
    var document: PDFDocument?
    var pageCount: Int = 0
    var currentSlideIndex: Int = 0
    var selectedTransition: TransitionStyle = .fade
    var isPresenting: Bool = false
    var cache: PDFImageCache?

    func openPDF(at url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard let doc = PDFDocument(url: url) else { return }
        self.document = doc
        self.pageCount = doc.pageCount
        self.currentSlideIndex = 0

        let screenBounds = UIScreen.main.bounds
        let screenScale = UIScreen.main.scale
        let renderSize = CGSize(
            width: screenBounds.width * screenScale,
            height: screenBounds.height * screenScale
        )
        self.cache = PDFImageCache(document: doc, renderSize: renderSize)
    }

    func selectSlide(_ index: Int) {
        guard index >= 0, index < pageCount else { return }
        currentSlideIndex = index
    }

    func thumbnailImage(for index: Int, fitting size: CGSize) -> UIImage? {
        guard let page = document?.page(at: index) else { return nil }
        let box = page.bounds(for: .mediaBox)
        guard box.height > 0, size.height > 0 else { return nil }
        let pageAspect = box.width / box.height
        let fitAspect = size.width / size.height
        let renderSize: CGSize
        if pageAspect > fitAspect {
            renderSize = CGSize(width: size.width, height: size.width / pageAspect)
        } else {
            renderSize = CGSize(width: size.height * pageAspect, height: size.height)
        }
        return page.thumbnail(of: renderSize, for: .mediaBox)
    }
}
#endif
