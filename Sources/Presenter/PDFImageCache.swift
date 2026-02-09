import AppKit
import PDFKit

final class PDFImageCache {
    let document: PDFDocument
    let pageCount: Int
    private var cache: [Int: NSImage] = [:]
    private var renderSize: NSSize

    init(document: PDFDocument, screenSize: NSSize) {
        self.document = document
        self.pageCount = document.pageCount
        self.renderSize = screenSize
    }

    func updateRenderSize(_ size: NSSize) {
        if size != renderSize {
            renderSize = size
            cache.removeAll()
        }
    }

    func image(forPage index: Int) -> NSImage? {
        guard index >= 0, index < pageCount else { return nil }

        if let cached = cache[index] {
            return cached
        }

        guard let page = document.page(at: index) else { return nil }

        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let scaledSize = NSSize(
            width: renderSize.width * scale,
            height: renderSize.height * scale
        )

        let image = page.thumbnail(of: scaledSize, for: .mediaBox)
        image.size = renderSize
        cache[index] = image
        return image
    }

    func preloadNeighbors(of index: Int) {
        let neighbors = [index - 1, index, index + 1]
        for i in neighbors {
            if i >= 0, i < pageCount, cache[i] == nil {
                _ = image(forPage: i)
            }
        }
    }
}
