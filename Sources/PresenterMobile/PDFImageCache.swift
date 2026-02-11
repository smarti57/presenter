#if os(iOS)
import UIKit
import PDFKit

final class PDFImageCache {
    let document: PDFDocument
    let pageCount: Int
    private var cache: [Int: UIImage] = [:]
    private var renderSize: CGSize
    private let lock = NSLock()

    var pageAspectRatio: CGFloat? {
        guard let page = document.page(at: 0) else { return nil }
        let box = page.bounds(for: .mediaBox)
        guard box.height > 0 else { return nil }
        return box.width / box.height
    }

    init(document: PDFDocument, renderSize: CGSize) {
        self.document = document
        self.pageCount = document.pageCount
        self.renderSize = renderSize
    }

    func updateRenderSize(_ size: CGSize) {
        lock.lock()
        defer { lock.unlock() }
        if size != renderSize {
            renderSize = size
            cache.removeAll()
        }
    }

    func image(forPage index: Int) -> UIImage? {
        guard index >= 0, index < pageCount else { return nil }

        lock.lock()
        if let cached = cache[index] {
            lock.unlock()
            return cached
        }
        let currentSize = renderSize
        lock.unlock()

        guard let page = document.page(at: index) else { return nil }

        let scale = UIScreen.main.scale
        let scaledSize = CGSize(
            width: currentSize.width * scale,
            height: currentSize.height * scale
        )

        let image = page.thumbnail(of: scaledSize, for: .mediaBox)

        lock.lock()
        cache[index] = image
        lock.unlock()

        return image
    }

    func preloadNeighbors(of index: Int) {
        let neighbors = [index - 1, index, index + 1]
        for i in neighbors {
            lock.lock()
            let missing = i >= 0 && i < pageCount && cache[i] == nil
            lock.unlock()
            if missing {
                _ = image(forPage: i)
            }
        }
    }
}
#endif
