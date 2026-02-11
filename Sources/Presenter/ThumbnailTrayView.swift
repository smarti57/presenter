import AppKit

protocol ThumbnailTrayDelegate: AnyObject {
    func thumbnailTray(_ tray: ThumbnailTrayView, didSelectSlideAt index: Int)
}

final class ThumbnailTrayView: NSView {
    weak var delegate: ThumbnailTrayDelegate?

    private let scrollView = NSScrollView()
    private let collectionView = NSCollectionView()
    private let flowLayout = NSCollectionViewFlowLayout()
    private var pageCount = 0
    var thumbnailProvider: ((Int) -> NSImage?)?
    var pageAspectRatio: CGFloat = 16.0 / 9.0

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        flowLayout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView.collectionViewLayout = flowLayout
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [.clear]
        collectionView.register(ThumbnailCell.self, forItemWithIdentifier: ThumbnailCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override func layout() {
        super.layout()
        updateItemSize()
    }

    private func updateItemSize() {
        let inset = flowLayout.sectionInset
        let availableWidth = bounds.width - inset.left - inset.right
        guard availableWidth > 0 else { return }
        let thumbWidth = availableWidth
        let thumbHeight = thumbWidth / pageAspectRatio + 20 // +20 for slide number label
        let newSize = NSSize(width: thumbWidth, height: thumbHeight)
        if flowLayout.itemSize != newSize {
            flowLayout.itemSize = newSize
            flowLayout.invalidateLayout()
        }
    }

    func reload(pageCount: Int) {
        self.pageCount = pageCount
        updateItemSize()
        collectionView.reloadData()
    }

    func selectItem(at index: Int) {
        guard index >= 0, index < pageCount else { return }
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.deselectAll(nil)
        collectionView.selectItems(at: [indexPath], scrollPosition: .centeredVertically)
    }
}

extension ThumbnailTrayView: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageCount
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: ThumbnailCell.identifier, for: indexPath) as! ThumbnailCell
        let index = indexPath.item
        let image = thumbnailProvider?(index)
        cell.configure(image: image, slideNumber: index + 1)
        return cell
    }
}

extension ThumbnailTrayView: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        delegate?.thumbnailTray(self, didSelectSlideAt: indexPath.item)
    }
}
